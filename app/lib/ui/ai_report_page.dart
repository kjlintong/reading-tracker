import 'dart:convert';
import '../l10n/app_loc.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_client.dart';
import '../data/database.dart';
import '../data/date_range.dart';
import '../data/encouragement.dart';
import '../data/report_style.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../providers.dart';
import '../data/report_period.dart';
import '../models/book.dart';
import 'markdown_view.dart';

/// AI 阅读报告 —— **全 App 唯一的报告入口**。
///
/// 拆成「可复用的面板」[AiReportPanel] + 一个独立页 [AiReportPage]：
/// 报告正文、周期选择、生成与历史全在面板里，独立页只负责包一层 AppBar。
/// 这样面板将来可以内嵌到别处（比如统计页顶部），而测试也能直接渲染整页。
///
/// 周期按自然年 / 自然月归档（不是「近 30 天」这类滑动窗口）：
/// 只有能对上日历的周期才谈得上「年报」「月报」，也才可能自动补生成。
class AiReportPanel extends ConsumerStatefulWidget {
  /// 是否在面板顶部显示那句鼓励语。
  /// 内嵌到已有鼓励语的页面时可关掉，免得同一句话出现两遍。
  final bool showEncouragement;

  const AiReportPanel({super.key, this.showEncouragement = true});

  @override
  ConsumerState<AiReportPanel> createState() => _AiReportPanelState();
}

class AiReportPage extends ConsumerStatefulWidget {
  const AiReportPage({super.key});

  @override
  ConsumerState<AiReportPage> createState() => _AiReportPageState();
}

/// 独立报告页：只负责包一层带标题的 Scaffold，正文全部交给 [AiReportPanel]。
///
/// 这样 [AiReportPanel] 既能内嵌到统计页顶部，也能当整页用——
/// 测试里直接 render 这个页仍然成立。
class _AiReportPageState extends ConsumerState<AiReportPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text(appLoc.s_96009a7e)),
      body: const AiReportPanel(showEncouragement: false),
    );
  }
}

/// 报告正文页。
///
/// 正文之所以单独一页而不是在列表里展开：
/// 一份完整报告有六节、上千字，列表里展开会把「历史列表」这个
/// 用来挑报告的界面撑得没法用。独立页还能顺带解决滚动位置的问题——
/// 从列表点进来从顶部读起，返回时列表停在原位。
///
/// 顶部**不放鼓励语句**：这一页是来看具体内容的，
/// 鼓励语属于「打开统计页」那一刻的情绪，混在正文页只是干扰。
class ReportDetailPage extends StatelessWidget {
  /// 报告标题（如「2026 年 9 月」）。
  final String title;

  /// Markdown 正文。
  final String content;

  /// 副标题（模型 · 生成时间），可为空。
  final String? subtitle;

  const ReportDetailPage({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: appLoc.s_049eca89,
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(appLoc.s_50bf9961)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null) ...[
              Text(subtitle!,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
            ],
            SelectionArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(14),
                ),
                // 报告正文是 LLM 返回的 Markdown。以前直接塞给 Text，
                // 于是 ##、**、- 这些记号连着星号印在屏幕上。
                // MarkdownView 把它们排成真正的标题、列表与书目高亮。
                child: content.trim().isEmpty
                    ? Text(l10n.reportNoContent,
                        style: TextStyle(color: cs.onSurfaceVariant))
                    : MarkdownView(content),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _autoReportEnabledKey = 'auto_report_enabled';
const _autoReportKindsKey = 'auto_report_kinds';
const _reportStyleKey = 'report_style';
const _reportCustomPromptKey = 'report_custom_prompt';

class _AiReportPanelState extends ConsumerState<AiReportPanel> {
  late List<ReportPeriod> _candidates;
  late ReportPeriod _period;

  bool _generating = false;
  String? _error;
  Map<String, dynamic>? _metrics;
  List<Map<String, dynamic>> _history = const [];

  /// 报告风格。默认取预设列表第一项（理性罗列）。
  ReportStyle _style = reportStyles.first;

  /// 自定义风格的提示词（仅 _style 为自定义时使用）。
  String _customPrompt = '';
  final _customPromptCtl = TextEditingController();


  @override
  void initState() {
    super.initState();
    _candidates = ReportPeriod.candidates();
    _period = _candidates.first;
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadHistory();
    await _loadStyle();
  }

  Future<void> _loadStyle() async {
    final repo = ref.read(repoProvider);
    final id = await repo.getSetting(_reportStyleKey);
    final prompt = await repo.getSetting(_reportCustomPromptKey);
    if (!mounted) return;
    setState(() {
      _style = ReportStyle.byId(id);
      _customPrompt = prompt ?? '';
      _customPromptCtl.text = _customPrompt;
    });
  }

  @override
  void dispose() {
    _customPromptCtl.dispose();
    super.dispose();
  }


  Future<void> _loadHistory() async {
    final rows = await ref.read(repoProvider).reports();
    if (mounted) setState(() => _history = rows);
  }

  /// 为 [p] 生成并存档。返回正文；无书时返回 null。

  /// 为 [p] 生成并存档。返回正文；无书时返回 null。
  Future<String?> _generateFor(ReportPeriod p, {bool silent = false}) async {
    final repo = ref.read(repoProvider);
    final all = await repo.all();
    final books = all.where(p.range.containsBook).toList();
    if (books.isEmpty) return null;

    // 用目标周期自身的口径重建摘要，而不是复用当前页面的 _period——
    // 用户可能正停在上个月的月报上，却让系统补今年的年报。
    // 摘要构建走共享实现，保证与设置页的补生成口径一致。
    final summary = await buildReportSummary(
      repo: repo,
      books: books,
      range: p.range,
      periodLabel: p.label,
    );

    final text = await ref.read(llmClientProvider).generateReport(
          p.label,
          summary,
          style: _style,
          customPrompt: _customPrompt,
        );
    if (text.trim().isEmpty) {
      throw LlmException(appLoc.s_d2a3748e,
          hint: appLoc.s_3abdc334);
    }
    await repo.saveReport(
      period: p.key,
      model: ref.read(llmModelProvider),
      content: text,
      metrics: summary,
    );
    if (!silent && mounted) {
      // 只保留指标 chips；正文交给独立页面展示，不在面板里留副本
      setState(() => _metrics = summary);
      // 生成完成直接进正文页：用户点「生成」就是想看报告，
      // 让他再回列表里找一次是多余的一步。
      _showReport(
        title: p.label,
        content: text,
        model: ref.read(llmModelProvider),
        generatedAt: DateTime.now().toIso8601String(),
      );
    }
    return text;
  }

  Future<void> _generate() async {
    final key = ref.read(llmKeyProvider);
    if (key == null || key.isEmpty) {
      setState(() => _error = appLoc.s_cc72f973);
      return;
    }
    if (ref.read(llmModelProvider).trim().isEmpty) {
      setState(() => _error = appLoc.s_9e51ce93);
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      final text = await _generateFor(_period);
      if (text == null && mounted) {
        setState(() {
          _error = appLoc.s_c6e18e89;
        });
      }
      await _loadHistory();
    } catch (e) {
      if (mounted) {
        // 走 describeLlmError 而不是 `'生成失败：${e}'`：
        // 后者会把 DioException 的原始串（含 uri、堆栈）糊到界面上
        setState(() => _error = describeLlmError(e));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  /// 打开一份历史报告：跳到正文页，同时把周期下拉同步到该报告。
  ///
  /// 不在这里 setState 里塞正文——正文已经交给独立页面展示，
  /// 面板的 _report 只在「刚生成完」的短暂窗口里有值。
  void _openHistory(Map<String, dynamic> r) {
    final p = ReportPeriod.parse(r['period'] as String?);
    if (p != null) {
      // ⚠️ 下拉的 value 与 items 之间是「同一实例」比较——ReportPeriod
      // 没有重载 ==，candidates() 里已有的周期如果另外 parse 一个新实例
      // 赋给 _period，DropdownButton 会断言「value 不在 items 里」当场崩
      // （点开任何一条历史报告就是这个路径）。必须复用候选里的原实例。
      final idx = _candidates.indexWhere((c) => c.key == p.key);
      if (idx >= 0) {
        _period = _candidates[idx];
      } else {
        // 历史里可能有候选列表之外的旧周期，补进去免得下拉框选不中
        _candidates = [p, ..._candidates];
        _period = p;
      }
    }
    _showReport(
      title: p?.label ?? (r['period'] as String? ?? ''),
      content: r['content'] as String? ?? '',
      model: r['model'] as String?,
      generatedAt: r['generatedAt'] as String?,
    );
  }

  /// 删除一份历史报告。先确认，避免误触；删除后刷新列表。
  Future<void> _deleteReport(Map<String, dynamic> r) async {
    final period = r['period'] as String? ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(appLoc.reportDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(appLoc.reportDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repoProvider).deleteReport(period);
    await _loadHistory();
  }

  /// 打开报告正文页。生成完成与点历史条目都走这里，
  /// 保证「看报告」这件事只有一个出口、一种版式。
  void _showReport({
    required String title,
    required String content,
    String? model,
    String? generatedAt,
  }) {
    final meta = [
      if (model != null && model.isNotEmpty) model,
      if (generatedAt != null && generatedAt.isNotEmpty)
        generatedAt.replaceAll('T', ' ').split('.').first,
    ].join(' · ');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportDetailPage(
          title: title,
          content: content,
          subtitle: meta.isEmpty ? null : meta,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showEncouragement) ...[
            _EncouragementLine(),
            const SizedBox(height: 14),
          ],

          /* ------------------- 标题行 + 设置入口 ------------------- */
          // 报告风格、时间范围、自动生成全部收进二级页。
          // 主页面只留「看历史报告」+「生成一份」两件事：
          // 配置是设一次就不动的，摆在主页面只会把真正要看的内容顶下去。
          Row(
            children: [
              Expanded(
                child: Text(appLoc.s_a3dfa2a6, style: theme.textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.tune, size: 17),
                label: Text(appLoc.reportSettings),
              ),
            ],
          ),
          const SizedBox(height: 8),

          /* ------------------------- 历史 ------------------------- */
          // 每份报告只显示成一张摘要卡（周期 + 模型/时间 + 首行），
          // 点进去才是正文页。摘要卡让列表保持可扫读——
          // 六节上千字的正文摊在列表里，用户根本找不到想找的那份。
          if (_history.isEmpty)
            _emptyHistory(cs)
          else
            ..._history.map((r) {
              final p = ReportPeriod.parse(r['period'] as String?);
              final content = r['content'] as String? ?? '';
              final model = r['model'] as String? ?? '';
              final at = (r['generatedAt'] as String? ?? '')
                  .replaceAll('T', ' ')
                  .split('.')
                  .first;
              final meta = [
                if (model.isNotEmpty) model,
                if (at.isNotEmpty) at,
              ].join(' · ');
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(p?.label ?? r['period'] as String? ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (meta.isNotEmpty)
                        Text(meta, style: const TextStyle(fontSize: 11)),
                      if (_excerpt(content).isNotEmpty)
                        Text(
                          _excerpt(content),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'delete') _deleteReport(r);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'delete', child: Text(appLoc.reportDelete)),
                    ],
                  ),
                  onTap: () => _openHistory(r),
                ),
              );
            }),

          /* ------------------------- 生成 ------------------------- */
          const SizedBox(height: 16),
          // 周期仍然放在生成按钮上方：它是「这次要生成哪一份」的唯一开关，
          // 属于本次操作的一部分，不是「设一次就不动」的配置。
          DropdownButtonFormField<ReportPeriod>(
            value: _period,
            isDense: true,
            decoration: InputDecoration(
              labelText: appLoc.s_8bb45b34,
              isDense: true,
              border: const OutlineInputBorder(),
              hintText: appLoc.s_8bd59fb2,
            ),
            items: [
              for (final p in _candidates)
                DropdownMenuItem(value: p, child: Text(p.label)),
            ],
            onChanged: (v) => setState(() => _period = v ?? _period),
          ),
          const SizedBox(height: 6),
          Text(appLoc.s_53bea04d,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_generating ? appLoc.s_a14e36dc : appLoc.s_b36c173d),
          ),
          const SizedBox(height: 8),
          Text(
            appLoc.s_c94ade95,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style:
                            TextStyle(color: cs.onErrorContainer, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          if (_metrics != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: appLoc.s_5e05e92a, value: appLoc.s_be9a1551(total: _metrics!['total'])),
                _StatChip(label: appLoc.s_44c14529, value: appLoc.s_ce115766(finished: _metrics!['finished'])),
                _StatChip(label: appLoc.s_b9bf9b53, value: appLoc.s_8b46a11f(reading: _metrics!['reading'])),
                _StatChip(label: appLoc.s_5a833930, value: appLoc.s_81e94993(wish: _metrics!['wish'])),
                _StatChip(label: appLoc.s_09b589b4, value: '${_metrics!['avgRating']}'),
              ],
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 一份报告都没有时的空态。
  ///
  /// 顺手把「模型没配好」这个最常见的阻塞点说清楚：空列表本身
  /// 不解释原因，用户会以为是 App 坏了，其实是没填 Key。
  Widget _emptyHistory(ColorScheme cs) {
    final hasKey = ref.watch(llmKeyProvider)?.isNotEmpty ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(Icons.summarize_outlined, size: 28, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            hasKey ? appLoc.reportHistoryEmpty : appLoc.reportNoKey,
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReportSettingsPage()),
    );
    // 二级页里可能改了风格、也可能点了「补生成」，回来都要重读
    await _loadStyle();
    await _loadHistory();
  }

  /// 给摘要卡用的正文首行。
  ///
  /// 取第一个「有实际文字的段落」——报告开头几行往往是 Markdown 标题
  /// （`## 概览`）与空行，直接取前 N 字符会得到一串井号，看着像乱码。
  static String _excerpt(String content) {
    for (final raw in content.split('\n')) {
      final line = raw
          .replaceAll(RegExp(r'^#+\s*'), '') // 去掉标题的井号
          .replaceAll('**', '')
          .replaceAll('《', '')
          .replaceAll('》', '')
          .trim();
      if (line.length >= 6) return line;
    }
    return '';
  }

}

/// 报告设置（二级页）：风格 + 自动生成 + 模型连通性测试。
///
/// 为什么单开一页而不是在主页面下方留一块：
///  - 这些配置**设一次就不动**，留在主页面只会把「历史报告」
///    这个真正高频的内容顶到屏幕外；
///  - 「补生成缺失报告」是个明确的重操作（会连发多次大模型请求），
///    放在二级页里点，比摆在首页让用户误触要安全得多。
class ReportSettingsPage extends ConsumerStatefulWidget {
  const ReportSettingsPage({super.key});

  @override
  ConsumerState<ReportSettingsPage> createState() => _ReportSettingsPageState();
}

class _ReportSettingsPageState extends ConsumerState<ReportSettingsPage> {
  ReportStyle _style = reportStyles.first;
  String _customPrompt = '';
  final _customPromptCtl = TextEditingController();

  bool _autoEnabled = true;
  bool _autoYear = true;
  bool _autoMonth = false;

  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  bool _busy = false;
  String? _note;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customPromptCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final id = await repo.getSetting(_reportStyleKey);
    final prompt = await repo.getSetting(_reportCustomPromptKey);
    final enabled = await repo.getSetting(_autoReportEnabledKey);
    final kinds = await repo.getSetting(_autoReportKindsKey);
    if (!mounted) return;
    setState(() {
      _style = ReportStyle.byId(id);
      _customPrompt = prompt ?? '';
      _customPromptCtl.text = _customPrompt;
      _autoEnabled = enabled != '0';
      final k = kinds ?? 'year';
      _autoYear = k.contains('year');
      _autoMonth = k.contains('month');
      _loading = false;
    });
  }

  Future<void> _saveStyle() async {
    final repo = ref.read(repoProvider);
    await repo.setSetting(_reportStyleKey, _style.id);
    await repo.setSetting(_reportCustomPromptKey, _customPrompt);
  }

  Future<void> _saveAuto() async {
    final repo = ref.read(repoProvider);
    await repo.setSetting(_autoReportEnabledKey, _autoEnabled ? '1' : '0');
    await repo.setSetting(
      _autoReportKindsKey,
      [
        if (_autoYear) 'year',
        if (_autoMonth) 'month',
      ].join(','),
    );
  }

  /// 手动补生成缺失的当期报告。
  ///
  /// 只补**已经结束**的周期（今年年报 + 上一个自然月月报），
  /// 当月月报要等下个月才生成——否则每点一次就多一份只差几天的
  /// 重复报告，还白烧 token。
  Future<void> _backfill() async {
    final llm = ref.read(llmClientProvider);
    if (!llm.available) {
      setState(() => _note = appLoc.s_cc72f973);
      return;
    }
    final repo = ref.read(repoProvider);
    final history = await repo.reports();
    final done = history.map((r) => '${r['period']}').toSet();

    final targets = ReportPeriod.autoTargets().where((p) {
      if (p.isYear ? !_autoYear : !_autoMonth) return false;
      return !done.contains(p.key);
    }).toList();

    if (targets.isEmpty) {
      setState(() => _note = appLoc.reportNothingToBackfill);
      return;
    }

    setState(() {
      _busy = true;
      _note = appLoc.s_4343b7b3(
          join: targets.map((p) => p.label).join(appLoc.s_f5d99c16));
    });

    var ok = 0;
    var failed = 0;
    for (final p in targets) {
      final text = await _generateFor(p);
      if (text != null) {
        ok++;
      } else {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = failed == 0
          ? appLoc.s_a6c57a43(ok: ok)
          : appLoc.s_f71dea06(ok: ok, failed: failed);
    });
  }

  /// 为指定周期生成一份并存档。失败返回 null。
  Future<String?> _generateFor(ReportPeriod p) async {
    try {
      final repo = ref.read(repoProvider);
      final all = await repo.all();
      final books = all.where(p.range.containsBook).toList();
      if (books.isEmpty) return null;

      final summary = await buildReportSummary(
        repo: repo,
        books: books,
        range: p.range,
        periodLabel: p.label,
      );
      final text = await ref.read(llmClientProvider).generateReport(
            p.label,
            summary,
            style: _style,
            customPrompt: _customPrompt,
          );
      if (text.trim().isEmpty) return null;
      await repo.saveReport(
        period: p.key,
        model: ref.read(llmModelProvider),
        content: text,
        metrics: summary,
      );
      return text;
    } catch (_) {
      return null;
    }
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final ping = await ref.read(llmClientProvider).testConnection();
      if (mounted) {
        setState(() {
          _testOk = true;
          _testResult =
              appLoc.s_e93308dd(model: ping.model, latencyMs: ping.latencyMs);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testOk = false;
          _testResult = describeLlmError(e);
        });
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  String _styleDescription(ReportStyle s) {
    final l10n = S.of(context);
    return switch (s.id) {
      'rational' => l10n.reportStyleRationalDesc,
      'warm' => l10n.reportStyleWarmDesc,
      'direct' => l10n.reportStyleDirectDesc,
      'concise' => l10n.reportStyleConciseDesc,
      'custom' => l10n.reportStyleCustomDesc,
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = S.of(context);
    final model = ref.watch(llmModelProvider);
    final base = ref.watch(llmBaseUrlProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(appLoc.reportSettings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(appLoc.reportSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /* ------------------------- 模型 ------------------------- */
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.memory, size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$model · $base',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
                TextButton(
                  onPressed: _testing ? null : _test,
                  child: Text(_testing ? appLoc.s_1f048ed9 : appLoc.s_38fb1115,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _testOk ? cs.primaryContainer : cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult!,
                style: TextStyle(
                  fontSize: 12,
                  color: _testOk ? cs.onPrimaryContainer : cs.onErrorContainer,
                ),
              ),
            ),
          ],

          /* ------------------------- 报告风格 ------------------------- */
          const SizedBox(height: 22),
          Text(l10n.reportStyle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.reportStyleDesc,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in reportStyles)
                ChoiceChip(
                  selected: s.id == _style.id,
                  avatar: Icon(s.icon,
                      size: 16,
                      color: s.id == _style.id
                          ? cs.onSecondaryContainer
                          : cs.onSurfaceVariant),
                  label: Text(reportStyleName(s.id).split(' · ').first),
                  onSelected: (_) {
                    setState(() => _style = s);
                    _saveStyle();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_styleDescription(_style),
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          if (_style.isCustom) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customPromptCtl,
              maxLines: 4,
              minLines: 3,
              onChanged: (v) => _customPrompt = v,
              onEditingComplete: _saveStyle,
              onTapOutside: (_) => _saveStyle(),
              decoration: InputDecoration(
                hintText: l10n.reportStyleCustomHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],

          /* ---------------------- 自动生成 ---------------------- */
          const SizedBox(height: 22),
          Text(appLoc.s_772cbfcf, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(appLoc.s_01955ddf,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(appLoc.s_b2a52a3d, style: const TextStyle(fontSize: 13)),
            value: _autoEnabled,
            onChanged: (v) {
              setState(() => _autoEnabled = v);
              _saveAuto();
            },
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(appLoc.s_b233138e,
                      style: const TextStyle(fontSize: 13)),
                  value: _autoYear,
                  onChanged: _autoEnabled
                      ? (v) {
                          setState(() => _autoYear = v ?? false);
                          _saveAuto();
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(appLoc.s_877b864d,
                      style: const TextStyle(fontSize: 13)),
                  value: _autoMonth,
                  onChanged: _autoEnabled
                      ? (v) {
                          setState(() => _autoMonth = v ?? false);
                          _saveAuto();
                        }
                      : null,
                ),
              ),
            ],
          ),

          /* --------------------- 补生成缺失 --------------------- */
          // 曾经是「打开页面就自动补」，现在改成显式按钮：
          // 自动补生成会在用户毫无察觉的情况下连发大模型请求并计费。
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _backfill,
            icon: _busy
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check, size: 18),
            label: Text(appLoc.reportBackfill),
          ),
          if (_note != null) ...[
            const SizedBox(height: 8),
            Text(_note!,
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// 报告页顶部的一句话。
///
/// 单独包一层 StatefulWidget：鼓励语要读库，而报告页本身已经够重了，
/// 再塞一个 Future 进去只会让 build 更难读。
class _EncouragementLine extends ConsumerStatefulWidget {
  const _EncouragementLine();

  @override
  ConsumerState<_EncouragementLine> createState() => _EncouragementLineState();
}

class _EncouragementLineState extends ConsumerState<_EncouragementLine> {
  String? _line;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final all = await repo.all();
    final range = StatsRange.year(DateTime.now().year);
    final activity = await repo.readingActivity(range);
    final streak = await repo.readingStreakDays();
    if (!mounted) return;
    final finished = all
        .where(range.containsBook)
        .where((b) => b.status == BookStatus.finished)
        .length;
    setState(() {
      _line = encouragementLine(
        finished: finished,
        streak: streak,
        minutes: activity.minutes,
        total: all.length,
        now: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    if (line == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(line, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// 报告数据摘要。**面板与设置页共用同一实现**——
/// 两处各算一遍，很容易出现「首页生成的报告」与「补生成的报告」
/// 口径不同（比如一个带计划数据、一个不带）。
Future<Map<String, dynamic>> buildReportSummary({
  required BookRepository repo,
  required List<Book> books,
  required StatsRange range,
  required String periodLabel,
}) async {
  final status = <String, int>{};
    final categoryCount = <String, int>{};
    final sourceCount = <String, int>{};
    for (final b in books) {
      status[b.status.label] = (status[b.status.label] ?? 0) + 1;
      final k = b.categoryPrimary ?? kUncategorized;
      categoryCount[k] = (categoryCount[k] ?? 0) + 1;
      sourceCount[b.source.label] = (sourceCount[b.source.label] ?? 0) + 1;
    }
    final categories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sources = sourceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final rated = books.where((b) => b.rating > 0).toList();
    final avgRating = rated.isEmpty
        ? 0.0
        : rated.map((b) => b.rating).reduce((a, b) => a + b) / rated.length;

    final finished = books.where((b) => b.status == BookStatus.finished).length;
    final reading = books.where((b) => b.status == BookStatus.reading).length;
    final wish = books.where((b) => b.status == BookStatus.wish).length;

    // 在读但进度极低 = 开了坑没填，是阅读结构里最值得指出的部分
    final stalled = books
        .where((b) => b.status == BookStatus.reading && b.progressPercent < 15)
        .length;

    Map<String, dynamic>? wereadStats;
    final raw = await repo.getSetting('wereadAnnualStats');
    if (raw != null) {
      try {
        wereadStats = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }

    // 阅读计划的达成情况。只取**这个周期内仍然有效**的计划：
    // 报告是「这段时间读得怎么样」的复盘，把一条 2023 年就删掉的计划
    // 塞进去，模型会拿它当成近况来分析。
    // 完成快照走 repo.planProgress —— 与计划卡片同一入口，避免两处口径打架。
    final plans = <Map<String, dynamic>>[];
    for (final pr in await repo.activePlanProgress()) {
      final created = DateTime.tryParse(pr.plan.createdAt);
      if (created != null && !range.containsIso(pr.plan.createdAt)) {
        continue;
      }
      plans.add(pr.toReportJson());
    }

    return {
      'period': periodLabel,
      'total': books.length,
      'finished': finished,
      'reading': reading,
      'wish': wish,
      'stalledReading': stalled,
      'statusCounts': status,
      'categoryDistribution':
          categories.map((e) => {'name': e.key, 'count': e.value}).toList(),
      'sourceDistribution':
          sources.map((e) => {'name': e.key, 'count': e.value}).toList(),
      'avgRating': double.parse(avgRating.toStringAsFixed(2)),
      'readingMinutes': await repo.totalReadingMinutes(),
      'streakDays': await repo.readingStreakDays(),
      if (plans.isNotEmpty) 'readingPlans': plans,
      // 书名清单：没有它，报告只能说「你读了 12 本」这种谁都能套的话。
      // 只发标题层面的字段，不发笔记正文与划线内容。
      'bookList': [
        for (final b in books.take(60))
          {
            'title': b.title,
            if (b.authors.isNotEmpty) 'author': b.authors.first,
            if (b.categoryPrimary != null) 'category': categoryLabel(b.categoryPrimary!),
            'status': b.status.label,
            if (b.rating > 0) 'rating': b.rating,
            if (b.progressPercent > 0)
              'progress': b.progressPercent.toStringAsFixed(0),
            if (b.finishedAt != null) 'finishedAt': b.finishedAt,
          },
      ],
      if (wereadStats != null) 'wereadAnnual': wereadStats,
    };
}
