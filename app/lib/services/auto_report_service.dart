import 'dart:async';

import '../ai/ai_client.dart';
import '../data/database.dart';
import '../data/report_pipeline.dart';
import '../data/report_period.dart';
import '../data/report_style.dart';
import '../l10n/app_loc.dart';

/// 跑完一轮自动生成的结果。
class AutoReportOutcome {
  /// 成功生成并已存档的周期。
  final List<ReportPeriod> generated;

  /// 生成失败（模型报错 / 周期内无书）的周期。
  final List<ReportPeriod> failed;

  const AutoReportOutcome({
    this.generated = const [],
    this.failed = const [],
  });

  bool get isEmpty => generated.isEmpty && failed.isEmpty;

  int get ok => generated.length;
  int get bad => failed.length;
}

/// 「过期周期自动补生成」的决策逻辑。
///
/// ## 为什么单独抽出来
///
/// 这一段全是**纯计算**：给定期望周期集合、已存档集合与开关，得出该生成什么。
/// 把它与「真的去调大模型」分开，好处有两个：
///
///  1. 能单测。规则本身最容易错（跨年、1 月回退、开关组合），
///     真跑一遍要数据库 + 网络 + Key，测不动也测不准。
///  2. 失败代价不对称。自动生成会**烧用户的 token**。
///     规则一旦判错就是白花钱或漏生成，必须能穷举验证。
///
/// ## 规则
///
/// - 只看**已结束**的周期：上月月报、去年年报（见 [ReportPeriod.autoTargets]）。
/// - 每月/每年只补**一次**：靠 [_lastRunKey] 记「上次尝试的 yyyy-MM」，
///   同月内不再重复尝试。这样即使模型持续失败，一天也只试一次，
///   不会每次打开 App 都发一轮请求。
/// - 已存档的不再生成（按 period 去重）。
/// - 开关关闭时直接返回，连库都不查。
class AutoReportPlanner {
  /// 设置键：是否启用自动生成。
  static const enabledKey = 'auto_report_enabled';

  /// 设置键：启用哪几种（逗号分隔，`year` / `month`）。
  static const kindsKey = 'auto_report_kinds';

  /// 设置键：上次尝试的月份（yyyy-MM）。
  static const lastRunKey = 'auto_report_last_run';

  /// 走完一轮之后展示给用户的一句话。
  static String summary(AutoReportOutcome o) => o.generated.isEmpty
      ? appLoc.reportAutoNothingDone
      : appLoc.reportAutoDone(count: o.ok);

  /// 该不该在这一轮动手。返回 false 时**任何 IO 都不做**。
  ///
  /// [enabled] / [wantYear] / [wantMonth] 来自设置；
  /// [alreadyRanThisMonth] 是「本月已经试过一次」。
  static bool shouldRun({
    required bool enabled,
    required bool wantYear,
    required bool wantMonth,
    required bool alreadyRanThisMonth,
    required DateTime now,
  }) {
    if (!enabled) return false;
    if (!wantYear && !wantMonth) return false;
    if (alreadyRanThisMonth) return false;
    return true;
  }

  /// 从 [targets] 里挑出「该生成且还没生成」的周期。
  ///
  /// [existing] 是已存档报告的 period 集合。
  static List<ReportPeriod> pending({
    required List<ReportPeriod> targets,
    required Set<String> existing,
    required bool wantYear,
    required bool wantMonth,
  }) =>
      targets
          .where((p) => p.isYear ? wantYear : wantMonth)
          .where((p) => !existing.contains(p.key))
          .toList();

  /// 本月的标记串（yyyy-MM），用于 [_lastRunKey] 节流。
  static String monthTag([DateTime? now]) {
    final t = now ?? DateTime.now();
    return '${t.year.toString().padLeft(4, '0')}-'
        '${t.month.toString().padLeft(2, '0')}';
  }
}

/// 跑一轮自动生成。
///
/// 需要显式注入仓库与模型客户端，而不是在内部读 provider：
/// 这样它既能在启动流程里跑，也能在测试里用假实现跑。
class AutoReportRunner {
  final BookRepository repo;
  final LlmClient llm;
  final String model;
  final ReportStyle style;
  final String customPrompt;

  /// 生成失败时的回调（用于打日志 / 统计）。
  final void Function(ReportPeriod period, Object error)? onError;

  AutoReportRunner({
    required this.repo,
    required this.llm,
    required this.model,
    required this.style,
    required this.customPrompt,
    this.onError,
  });

  /// 依次为 [periods] 生成并存档。
  ///
  /// **串行**而不是并发：每个周期都要向同一个大模型端点发请求，
  /// 并发只会提高被限流与中途失败的概率，而且失败要重试一轮，
  /// 串行把「最坏情况等待」压到可控范围。
  ///
  /// 单个周期失败不中断整轮：年报失败不该让月报也没了。
  ///
  /// 「周期内没有书」是第三种情况：**无事可做**，既不是成功也不是失败。
  /// 把它算进 generated 会让用户看到「已生成 1 份」却在历史里找不到；
  /// 算进 failed 又会弹「没生成成功」——两头都在骗人，所以直接跳过。
  Future<AutoReportOutcome> run(List<ReportPeriod> periods) async {
    final ok = <ReportPeriod>[];
    final bad = <ReportPeriod>[];
    for (final p in periods) {
      try {
        if (await _isEmpty(p)) continue;
        await _generateOne(p);
        ok.add(p);
      } catch (e) {
        bad.add(p);
        onError?.call(p, e);
      }
    }
    return AutoReportOutcome(generated: ok, failed: bad);
  }

  /// 该周期里有没有可纳入报告的书。
  Future<bool> _isEmpty(ReportPeriod p) async =>
      !(await repo.all()).any(p.range.containsBook);

  Future<void> _generateOne(ReportPeriod p) async {
    final all = await repo.all();
    final books = all.where(p.range.containsBook).toList();
    // 调用方已用 [_isEmpty] 过滤；这里再兜一层，避免「检查与使用之间
    // 数据变了」时对着空书单也发一次请求、白烧 token。
    if (books.isEmpty) return;

    final bundle = await buildReportBundle(
      repo: repo,
      books: books,
      range: p.range,
    );
    final text = await llm.generateReportInsights(
      facts: bundle.facts,
      bookList: bundle.bookList,
      nextCandidates: bundle.nextCandidates,
      style: style,
      customPrompt: customPrompt,
    );
    final rendered = renderReport(
      parseReportPayload(text ?? '', knownBookIds: bundle.knownIds),
      facts: bundle.facts,
      titleById: bundle.titleById,
    );
    // 渲染后是空的 = 模型没给出可用内容（老问题：部分推理型模型
    // 会把思考过程当正文返回，或烧光 token 后返回空串）。
    // 这属于失败，让用户看到「没生成成功」比悄悄什么都没有强。
    if (rendered.trim().isEmpty) {
      throw StateError('empty report body for ${p.key}');
    }
    await repo.saveReport(
      period: p.key,
      model: model,
      content: rendered,
      metrics: {...bundle.facts, 'raw': text, 'lang': appLoc.localeName},
    );
  }
}
