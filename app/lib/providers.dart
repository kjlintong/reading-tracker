import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'ai/llm_protocol.dart';
import 'data/category_prefs.dart';
import 'data/database.dart';
import 'data/report_period.dart';
import 'data/report_style.dart';
import 'ai/ai_client.dart';
import 'import/import_manager.dart';
import 'l10n/app_loc.dart';
import 'services/auto_report_service.dart';
import 'services/plan_reminder.dart';
import 'services/secret_store.dart';
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

/// 截图识别是否允许调用大模型整理 OCR 文本
final ocrUseLlmProvider = StateProvider<bool>((ref) => true);

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
const _secretKeys = {'weread_key', 'llm_key'};

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

/// 阅读计划提醒。本地通知，不依赖任何后端；未授权时静默降级。
final planReminderProvider =
    Provider<PlanReminderService>((ref) => PlanReminderService());

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
    case 'ocr_enhance':
      ref.read(ocrEnhanceProvider.notifier).state = value == 'true';
    case 'ocr_use_llm':
      ref.read(ocrUseLlmProvider.notifier).state = value == 'true';
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
