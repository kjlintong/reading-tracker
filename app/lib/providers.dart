import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'ai/llm_protocol.dart';
import 'data/category_prefs.dart';
import 'data/database.dart';
import 'ai/ai_client.dart';
import 'import/import_manager.dart';
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
