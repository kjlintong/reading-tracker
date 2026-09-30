import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'ai/llm_protocol.dart';
import 'data/database.dart';
import 'ai/ai_client.dart';
import 'import/import_manager.dart';

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
/// 用户自填，App 不代持任何密钥，全部存在本地数据库
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
];

/// 从本地库加载用户配置（启动时调用一次）
Future<void> loadSettings(WidgetRef ref) async {
  final repo = ref.read(repoProvider);
  for (final key in _settingKeys) {
    final v = await repo.getSetting(key);
    if (v == null || v.isEmpty) continue;
    _apply(ref, key, v);
  }
}

/// 写库 + 同步内存中的 provider
Future<void> saveSetting(WidgetRef ref, String key, String value) async {
  final repo = ref.read(repoProvider);
  await repo.setSetting(key, value);
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
  }
}
