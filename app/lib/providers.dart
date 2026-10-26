import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'ai/llm_protocol.dart';
import 'ai/search_client.dart';
import 'data/category_prefs.dart';
import 'data/database.dart';
import 'data/report_period.dart';
import 'data/report_style.dart';
import 'data/recommendation_service.dart';
import 'ai/ai_client.dart';
import 'import/import_manager.dart';
import 'l10n/app_loc.dart';
import 'services/auto_report_service.dart';
import 'services/plan_reminder.dart';
import 'services/secret_store.dart';
import 'services/auto_shelve.dart';
import 'models/enums.dart';
import 'ui/theme.dart';

/// 本地数据库仓库
final repoProvider = Provider<BookRepository>((ref) {
  return BookRepository(AppDatabase.instance);
});

/// 全局 HTTP 客户端。
///
/// 必须在这里给超时——各 Client 若共用同一个 Dio 实例，
/// 它们自己构造函数里的 BaseOptions 是不生效的，会退化成「永不超时」，
/// 网络有问题时界面就一直转圈，用户完全不知道发生了什么。
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 180),
  ));
});

/// 配置：微信读书 API Key、大模型 Key / 端点 / 协议
/// 用户自填，App 不代持任何密钥；敏感 Key 存系统密钥库，其余配置存本地数据库
final wereadKeyProvider = StateProvider<String?>((ref) => null);
final llmKeyProvider = StateProvider<String?>((ref) => null);

// 默认指向商汤 SenseNova：已实测可用（响应约 3 秒，支持 json_object 模式）。
// 换成任意 OpenAI 兼容服务均可，在设置页选预设或改 Base URL 即可。
final llmBaseUrlProvider =
    StateProvider<String>((ref) => 'https://token.sensenova.cn/v1');
final llmModelProvider = StateProvider<String>((ref) => 'sensenova-6.8-flash-lite');

/// 接口协议：OpenAI 兼容 / Anthropic Claude
final llmProtocolProvider =
    StateProvider<LlmProtocol>((ref) => LlmProtocol.openai);

/// 截图识别前是否做图像增强（灰度 + 提对比 + 放大）
final ocrEnhanceProvider = StateProvider<bool>((ref) => true);

/// 闲置「在读」书是否自动挪到「搁置」。默认开启。
final autoShelveEnabledProvider = StateProvider<bool>((ref) => true);

/// 截图识别是否允许调用大模型整理 OCR 文本
final ocrUseLlmProvider = StateProvider<bool>((ref) => true);

/// 通用搜索服务的 API Key（推荐书单第 4 档用）。
///
/// 用户自填，存系统密钥库——与微信读书 Key、大模型 Key 同一套处置。
final searchKeyProvider = StateProvider<String?>((ref) => null);

/// 搜索服务的地址。留空则用 [SearchClient.defaultEndpoint]（Bing Web Search v7）。
///
/// 做成可配置而不是写死一家：各家的订阅与配额不一样，
/// 写死等于「没订那家就这一档直接废掉」。
final searchEndpointProvider =
    StateProvider<String>((ref) => SearchClient.defaultEndpoint);

/// 搜索服务额外请求头（JSON 字符串）。
///
/// 某些服务要 `Ocp-Apim-Subscription-Key` 之外的别的头，
/// 留个口子省得每次都要改代码。
final searchHeadersProvider = StateProvider<String>((ref) => '');

/// 图片识别通道：`auto` 多模态优先、失败回落端侧 OCR；
/// `device` 只用端侧 OCR；`vision` 只走多模态大模型。
///
/// 默认 `auto` 而不是 `device`：端侧 OCR 对竖排书名、封面美术字、
/// 被截断的标题几乎无解，而多模态模型能读懂版面。
/// 但端侧通道必须保留——离线、没配 Key、模型不支持图片时它是唯一出路。
final ocrVisionModeProvider = StateProvider<String>((ref) => 'auto');

/// 系统密钥库（Android Keystore / iOS Keychain）封装。
///
/// 微信读书 Key 与大模型 Key 等敏感凭据只走这里，绝不写明文 SQLite。
final secretStoreProvider = Provider<SecretStore>((ref) => SecretStore());

/// 外观：当前皮肤（[AppTheme.id]）。默认取注册表第一项。
final appThemeProvider = StateProvider<String>((ref) => appThemes.first.id);

/// 底部导航当前选中第几栏。
///
/// 做成 provider 而不是 HomeShell 的私有 state，是为了**别的页面能切栏**：
/// 「发现」页里有个「去设置」的按钮（联网推荐缺凭据时提示用户去配），
/// 它得能把用户直接送到设置栏，而不是只把页面关掉让他自己找。
final homeTabProvider = StateProvider<int>((ref) => 0);

/// 底部导航各栏的序号。
///
/// 常量放在这里而不是 [HomeShell] 里：`ui/discover_page.dart` 要用它，
/// 而 HomeShell 在 main.dart 里——从 ui 反向导入 main 会形成循环依赖
/// （main → notes_page → plan_section → discover_page → main）。
class HomeTabs {
  const HomeTabs._();

  static const int shelf = 0;
  static const int notes = 1;
  static const int stats = 2;
  static const int insights = 3;
  static const int settings = 4;
}

/// 外观：明暗模式。默认跟随系统。
final appBrightnessProvider =
    StateProvider<AppBrightness>((ref) => AppBrightness.system);

/// 界面语言。null = 跟随系统。
///
/// 存 `Locale.languageCode`（如 `zh` / `en` / 将来的 `de` / `fr` / `es`），
/// 不存国家码——本项目没有「简体中文 / 繁体中文」这类需要区分地区的场景，
/// 只按语言匹配即可，用户从哪个地区来都能落到对应语言。
final appLocaleProvider = StateProvider<Locale?>((ref) => null);

/// 机密项（API Key 等）存系统密钥库而非明文 SQLite。
const _secretKeys = {'weread_key', 'llm_key', 'search_key'};

/// 是否允许把书架截图上传到用户自填的多模态大模型端点。
///
/// 默认关闭；开启前必须在 UI 层获得用户一次性明示同意，
/// 因为该图片会离开本机发往第三方服务（隐私政策 §数据出境）。
final imageLlmConsentProvider = StateProvider<bool>((ref) => false);

final wereadGatewayProvider = Provider<WereadGateway>((ref) {
  return WereadGateway(
    dio: ref.watch(dioProvider),
    apiKey: ref.watch(wereadKeyProvider),
  );
});

final llmClientProvider = Provider<LlmClient>((ref) {
  return LlmClient(
    dio: ref.watch(dioProvider),
    apiKey: ref.watch(llmKeyProvider),
    baseUrl: ref.watch(llmBaseUrlProvider),
    model: ref.watch(llmModelProvider),
    protocol: ref.watch(llmProtocolProvider),
  );
});

final metadataClientProvider = Provider<MetadataClient>((ref) {
  return MetadataClient(
    dio: ref.watch(dioProvider),
    weread: ref.watch(wereadGatewayProvider),
  );
});

/// 通用搜索服务客户端。用于推荐书单第 4 档。
final searchClientProvider = Provider<SearchClient>((ref) {
  // 额外请求头以 JSON 存；解析失败就当没有——
  // 一个手滑打错的括号不该让整个推荐功能不可用。
  var headers = <String, String>{};
  final raw = ref.watch(searchHeadersProvider).trim();
  if (raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        headers = {
          for (final e in decoded.entries)
            if (e.key is String && e.value != null)
              e.key as String: e.value.toString(),
        };
      }
    } catch (_) {
      headers = const {};
    }
  }
  return SearchClient(
    dio: ref.watch(dioProvider),
    apiKey: ref.watch(searchKeyProvider),
    endpoint: ref.watch(searchEndpointProvider),
    extraHeaders: headers,
  );
});

/// 推荐书单服务。
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService(
    repo: ref.watch(repoProvider),
    llm: ref.watch(llmClientProvider),
    weread: ref.watch(wereadGatewayProvider),
    search: ref.watch(searchClientProvider),
    metadata: ref.watch(metadataClientProvider),
  );
});

/// 阅读计划提醒。本地通知，不依赖任何后端；未授权时静默降级。
final planReminderProvider =
    Provider<PlanReminderService>((ref) => PlanReminderService());

/// 补排所有「开了提醒」的计划提醒。
///
/// ## 为什么每次启动都要补一遍
///
/// 本地通知的闹钟由 AlarmManager 持有，它**不会自己回来**。这些情况都会让它消失：
///  - 国产 ROM 的「清理后台 / 省电策略」（最常见）；
///  - 用户在系统里对 App「强制停止」；
///  - 覆盖安装（应用数据被换掉）；
///  - 系统时间/时区被改，原排期失效。
///
/// 从前只有「用户手动改一次计划」才会重排，于是用户看到的现象是
/// **「提醒只在打开 App 时才有」**——那次保存把闹钟补上了，
/// 而闹钟再被 ROM 清掉之后，就再也没有下一次了。
///
/// 现在每次启动、每次回到前台都补一遍，把丢失的排期找回来。
/// 失败一律自己吞掉：提醒是增强功能，绝不能拖住启动。
///
/// [resetFirst] 用于「整库覆盖」的场景（恢复备份）：
/// 先把系统里所有旧排期撤掉，再按新数据重排。
/// 不撤的话，备份里已经删除的计划会留下**孤儿闹钟**——
/// 到了那个点照样弹一条提醒，而用户在这台设备上根本没有这条计划。
Future<void> resyncPlanReminders(WidgetRef ref, {bool resetFirst = false}) async {
  try {
    final repo = ref.read(repoProvider);
    final plans = await repo.activePlans();
    final reminders = ref.read(planReminderProvider);
    if (resetFirst) await reminders.cancelAll();
    await reminders.resync(plans);
  } catch (_) {}
}

/// 「过期周期自动补生成」的结果，供档案页显示提示条。
///
/// 存 null 表示「这一轮没有新报告」——也就是绝大多数时候，
/// 档案页不该多出任何东西。
final autoReportNoticeProvider = StateProvider<String?>((ref) => null);

/// 启动后跑一轮自动生成：补上该出的月报 / 年报，完成后发通知。
///
/// ## 为什么放在 `loadSettings` 之后
///
/// 它要读「是否启用 / 启用哪几种 / 上次跑到哪」这三项设置，
/// 而它们只在 [loadSettings] 之后才装载。顺序反了会读到空值，
/// 于是自动生成永远判成「未启用」——一个不会报错的静默失效。
///
/// ## 为什么不 await 到首帧之后
///
/// 生成要发大模型请求，通常几秒到几十秒。挡住首帧等于 App 打开时白屏
/// 等报告。所以这里 fire-and-forget：UI 先出来，报告在后台补，
/// 好了再通过 [autoReportNoticeProvider] 与系统通知告知。
///
/// ## 为什么必须先查 llmClient.available
///
/// 没配 Key 时 `generateReportInsights` 会直接抛。放在可用性检查之后，
/// 没配 Key 的用户连一次网络请求都不会发生。
Future<void> runAutoReportsIfDue(WidgetRef ref) async {
  final repo = ref.read(repoProvider);

  final enabled = await repo.getSetting(AutoReportPlanner.enabledKey);
  if (enabled == '0') return;
  // 兜底 'year,month'，与报告设置页的默认值保持一致——
  // 两处不一致会让「设置里没写过这个键」的用户看到一个关着的月报开关，
  // 却每月照样自动生成月报。两边必须同源。
  final kinds = (await repo.getSetting(AutoReportPlanner.kindsKey)) ?? 'year,month';
  final wantYear = kinds.contains('year');
  final wantMonth = kinds.contains('month');
  final now = DateTime.now();
  final ranThisMonth = await repo.getSetting(AutoReportPlanner.lastRunKey) ==
      AutoReportPlanner.monthTag(now);

  if (!AutoReportPlanner.shouldRun(
    enabled: true,
    wantYear: wantYear,
    wantMonth: wantMonth,
    alreadyRanThisMonth: ranThisMonth,
    now: now,
  )) {
    return;
  }

  final llm = ref.read(llmClientProvider);
  // 没配 Key：标记「本月已试过」也无意义，直接返回。
  // 下次用户配好 Key 再打开时会重新判定——那时才该真的发请求。
  if (!llm.available) return;

  // 现有 period 集合。用 String 而不是 Map 存：只判存在性。
  final existing = (await repo.reports(limit: 200))
      .map((r) => '${r['period']}')
      .toSet();
  final pending = AutoReportPlanner.pending(
    targets: ReportPeriod.autoTargets(now: now),
    existing: existing,
    wantYear: wantYear,
    wantMonth: wantMonth,
  );
  // 没有待生成的也要记节流标记吗？**要**。否则每次打开都重算一遍
  // 全量 reports（几百行）只为得出「没事干」，纯属浪费。
  await repo.setSetting(
      AutoReportPlanner.lastRunKey, AutoReportPlanner.monthTag(now));
  if (pending.isEmpty) return;

  final styleId = await repo.getSetting('report_style');
  final custom = await repo.getSetting('report_custom_prompt');

  final outcome = await AutoReportRunner(
    repo: repo,
    llm: llm,
    model: ref.read(llmModelProvider),
    style: ReportStyle.byId(styleId),
    customPrompt: custom ?? '',
  ).run(pending);

  if (outcome.generated.isEmpty) return;

  // 两处提醒，缺一不可：
  //  - 系统通知：用户在别的页面甚至没打开 App 时也能知道；
  //  - 档案页提示条：系统通知常被静音/免打扰吃掉，用户回到 App 里
  //    仍然必须看得到这份报告已经存在了。
  await ref.read(planReminderProvider).notifyNow(
        id: 0x524e, // 'RN'
        title: appLoc.reportAutoNoticeTitle,
        body: appLoc.reportAutoDone(count: outcome.ok),
      );
  ref.read(autoReportNoticeProvider.notifier).state =
      appLoc.reportAutoDone(count: outcome.ok);
}

final importManagerProvider = Provider<ImportManager>((ref) {
  return ImportManager(
    repo: ref.watch(repoProvider),
    metadata: ref.watch(metadataClientProvider),
    llm: ref.watch(llmClientProvider),
    ocrUseLlm: ref.watch(ocrUseLlmProvider),
  );
});

/// 自动搁置这一轮挪走了哪些书，以及提示文案。
///
/// 存进 provider 后，书架页据此显示一条可撤销的提示条；撤销后清空。
class AutoShelveNotice {
  final List<String> movedIds;
  final String message;
  AutoShelveNotice(this.movedIds, this.message);
}

/// 自动搁置执行结果，供书架页显示「撤销」提示条。
final autoShelveNoticeProvider = StateProvider<AutoShelveNotice?>((ref) => null);

/// 闲置「在读」书自动挪到「搁置」，每天最多跑一次。
///
/// 与 [runAutoReportsIfDue] 同样的节奏：放在 loadSettings 之后、**不 await**，
/// 首帧出来之后再后台慢慢算。失败一律自己吞掉——挪书绝不该拖住启动，
/// 更不该因为一次异常让 App 打不开。
Future<void> runAutoShelveIfDue(WidgetRef ref) async {
  final repo = ref.read(repoProvider);

  // 默认开启，写 '0' 才关。和自动报告一致：没写过这个键的用户不该被静默跳过。
  final enabled = await repo.getSetting(AutoShelve.enabledKey);
  if (enabled == '0') return;

  // 一天最多跑一次，免得每次冷启动都对着整座书架算一遍。
  final today = AutoShelve.dayKey(DateTime.now());
  if (await repo.getSetting(AutoShelve.lastRunKey) == today) return;

  final now = DateTime.now();
  final shelf = await repo.all();
  final busy =
      (await repo.activePlans()).map((p) => p.bookId).whereType<String>().toSet();
  final toShelve = AutoShelve.pendingShelve(shelf, now, busyBookIds: busy);

  // 无论有没有真挪走都记节流标记：否则每次冷启动都重算整座书架只为
  // 得出「没事干」，纯属浪费 I/O。
  await repo.setSetting(AutoShelve.lastRunKey, today);
  if (toShelve.isEmpty) return;

  for (final b in toShelve) {
    await repo.update(b.copyWith(status: BookStatus.shelved));
  }

  final ids = toShelve.map((b) => b.id).toList();
  ref.read(autoShelveNoticeProvider.notifier).state =
      AutoShelveNotice(ids, appLoc.autoShelveDone(count: ids.length));
}

/// 撤销这一轮自动搁置：把被挪走的书恢复到「在读」，并顺手记一次阅读活动，
/// 这样它们不会在明天的同一轮里又被挪走。
Future<void> undoAutoShelve(WidgetRef ref, List<String> ids) async {
  final repo = ref.read(repoProvider);
  for (final id in ids) {
    final b = await repo.byId(id);
    if (b == null) continue;
    await repo.update(b.withReadNow().copyWith(status: BookStatus.reading));
  }
  ref.read(autoShelveNoticeProvider.notifier).state = null;
}

/// 设置项 ↔ provider 的映射。集中一处，避免两个地方各写一遍字符串。
const _settingKeys = <String>[
  'weread_key',
  'llm_key',
  'llm_base_url',
  'llm_model',
  'llm_protocol',
  'ocr_enhance',
  'ocr_use_llm',
  'ocr_vision_mode',
  'image_llm_consent',
  'app_theme',
  'app_brightness',
  'app_locale',
];

/// 从本地库加载用户配置（启动时调用一次）
Future<void> loadSettings(WidgetRef ref) async {
  final repo = ref.read(repoProvider);
  final secrets = ref.read(secretStoreProvider);
  for (final key in _settingKeys) {
    String? v;
    if (_secretKeys.contains(key)) {
      // 机密项：优先从系统密钥库读取
      v = await secrets.read(key);
      if (v == null || v.isEmpty) {
        // 迁移：把旧版明文 SQLite 里的 Key 搬到密钥库，并从明文库清除
        final legacy = await repo.getSetting(key);
        if (legacy != null && legacy.isNotEmpty) {
          await secrets.write(key, legacy);
          await repo.setSetting(key, '');
          v = legacy;
        }
      }
    } else {
      v = await repo.getSetting(key);
    }
    if (v == null || v.isEmpty) continue;
    _apply(ref, key, v);
  }

  // 分类词表要两个键合起来才有意义（新增 + 移除），所以单独读，
  // 不走上面那个一次处理一个键的循环。
  //
  // 注意这里跑在首帧之后，来不及覆盖启动期的迁移——那条路径由
  // AppDatabase._onUpgrade 自己装载词表（它才是在重算分类之前）。
  // 这里负责的是运行期：导入、元数据补全、界面下拉都在此之后。
  await loadCategoryVocabulary(ref);
}

/// 从 settings 表装载用户对分类词表的修改。
Future<void> loadCategoryVocabulary(WidgetRef ref) async {
  final repo = ref.read(repoProvider);
  applyCategoryVocabulary(
    custom: await repo.getSetting(kCustomCategoriesKey),
    hidden: await repo.getSetting(kHiddenCategoriesKey),
  );
}

/// 写库 + 同步内存中的 provider
Future<void> saveSetting(WidgetRef ref, String key, String value) async {
  if (_secretKeys.contains(key)) {
    // 机密项：只写系统密钥库，并清掉任何残留的明文副本
    final secrets = ref.read(secretStoreProvider);
    if (value.isEmpty) {
      await secrets.delete(key);
    } else {
      await secrets.write(key, value);
    }
    await ref.read(repoProvider).setSetting(key, '');
    _apply(ref, key, value);
    return;
  }
  await ref.read(repoProvider).setSetting(key, value);
  _apply(ref, key, value);
}

void _apply(WidgetRef ref, String key, String value) {
  switch (key) {
    case 'weread_key':
      ref.read(wereadKeyProvider.notifier).state = value;
    case 'llm_key':
      ref.read(llmKeyProvider.notifier).state = value;
    case 'llm_base_url':
      ref.read(llmBaseUrlProvider.notifier).state = value;
    case 'llm_model':
      ref.read(llmModelProvider.notifier).state = value;
    case 'llm_protocol':
      ref.read(llmProtocolProvider.notifier).state =
          LlmProtocol.fromString(value);
    case 'search_key':
      ref.read(searchKeyProvider.notifier).state = value;
    case 'search_endpoint':
      ref.read(searchEndpointProvider.notifier).state = value;
    case 'search_headers':
      ref.read(searchHeadersProvider.notifier).state = value;
    case 'ocr_enhance':
      ref.read(ocrEnhanceProvider.notifier).state = value == 'true';
    case 'ocr_use_llm':
      ref.read(ocrUseLlmProvider.notifier).state = value == 'true';
    case AutoShelve.enabledKey:
      ref.read(autoShelveEnabledProvider.notifier).state = value == 'true';
    case 'ocr_vision_mode':
      ref.read(ocrVisionModeProvider.notifier).state = value;
    case 'image_llm_consent':
      ref.read(imageLlmConsentProvider.notifier).state = value == 'true';
    case 'app_theme':
      ref.read(appThemeProvider.notifier).state = value;
    case 'app_brightness':
      ref.read(appBrightnessProvider.notifier).state =
          AppBrightness.fromString(value);
    case 'app_locale':
      // 空值 = 跟随系统（不写 locale，让 MaterialApp 自己解析）
      ref.read(appLocaleProvider.notifier).state =
          value.isEmpty ? null : Locale(value);
  }
}
