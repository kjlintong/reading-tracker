/// 大模型接口协议。
///
/// 只支持两族：
/// - [LlmProtocol.openai]：`POST {base}/chat/completions`，`Authorization: Bearer`。
///   DeepSeek / 商汤 / 通义 / 智谱 / Kimi / 硅基流动 / OpenRouter / Ollama 都走这条。
/// - [LlmProtocol.anthropic]：`POST {base}/messages`，`x-api-key` + `anthropic-version`。
///   Claude 的 body 结构与 OpenAI 不同（system 在顶层、必须给 max_tokens、
///   content 是分块数组），所以不能靠改 URL 蒙混过去，必须单独一条分支。
enum LlmProtocol {
  openai,
  anthropic;

  static LlmProtocol fromString(String? s) => switch (s?.trim().toLowerCase()) {
        'anthropic' || 'claude' => anthropic,
        _ => openai,
      };

  String get label => switch (this) {
        LlmProtocol.openai => 'OpenAI 兼容',
        LlmProtocol.anthropic => 'Anthropic Claude',
      };

  /// 该协议下的对话端点相对路径
  String get chatPath => switch (this) {
        LlmProtocol.openai => 'chat/completions',
        LlmProtocol.anthropic => 'messages',
      };

  String get hint => switch (this) {
        LlmProtocol.openai => 'Base URL 填到 /v1 为止，例如 https://api.deepseek.com/v1',
        LlmProtocol.anthropic => 'Base URL 通常为 https://api.anthropic.com（不带 /v1）',
      };
}

/// 服务商预设：只填 Base URL 与一个「起点模型」。
///
/// 刻意不写死「唯一正确模型」——各家的模型名变化很快，写死必然过期。
/// 正确的用法是：选预设 → 填 Key → 点「拉取模型」拿到该 Key 真实可用的列表。
class LlmPreset {
  final String name;
  final LlmProtocol protocol;
  final String baseUrl;
  final String model;
  final String keyHint;

  const LlmPreset({
    required this.name,
    required this.protocol,
    required this.baseUrl,
    required this.model,
    this.keyHint = 'sk-xxxxxxxx',
  });
}

/// 预设清单。顺序即界面上的展示顺序，把国内直连友好的放前面。
const List<LlmPreset> llmPresets = [
  LlmPreset(
    name: '商汤 SenseNova',
    protocol: LlmProtocol.openai,
    baseUrl: 'https://token.sensenova.cn/v1',
    model: 'sensenova-6.8-flash-lite',
  ),
  LlmPreset(
    name: 'DeepSeek',
    protocol: LlmProtocol.openai,
    baseUrl: 'https://api.deepseek.com/v1',
    model: 'deepseek-chat',
  ),
  LlmPreset(
    name: '通义千问',
    protocol: LlmProtocol.openai,
    baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    model: 'qwen-plus',
  ),
  LlmPreset(
    name: '智谱 GLM',
    protocol: LlmProtocol.openai,
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
    model: 'glm-4-flash',
  ),
  LlmPreset(
    name: '月之暗面 Kimi',
    protocol: LlmProtocol.openai,
    baseUrl: 'https://api.moonshot.cn/v1',
    model: 'moonshot-v1-8k',
  ),
  LlmPreset(
    name: '硅基流动',
    protocol: LlmProtocol.openai,
    baseUrl: 'https://api.siliconflow.cn/v1',
    model: 'Qwen/Qwen2.5-7B-Instruct',
  ),
  LlmPreset(
    name: 'OpenAI',
    protocol: LlmProtocol.openai,
    baseUrl: 'https://api.openai.com/v1',
    model: 'gpt-5-mini',
  ),
  LlmPreset(
    name: 'OpenRouter',
    protocol: LlmProtocol.openai,
    baseUrl: 'https://openrouter.ai/api/v1',
    model: 'openai/gpt-5-mini',
  ),
  LlmPreset(
    name: 'Claude',
    protocol: LlmProtocol.anthropic,
    baseUrl: 'https://api.anthropic.com',
    model: 'claude-sonnet-5',
    keyHint: 'sk-ant-xxxxxxxx',
  ),
  LlmPreset(
    name: 'Ollama 本地',
    protocol: LlmProtocol.openai,
    baseUrl: 'http://localhost:11434/v1',
    model: 'qwen2.5:7b',
    keyHint: '任意非空字符串',
  ),
];

/// 按名字取预设（找不到返回 null）
LlmPreset? presetOf(String name) {
  for (final p in llmPresets) {
    if (p.name == name) return p;
  }
  return null;
}

/// 把用户填的 Base URL 规范化成「可拼接端点」的前缀。
///
/// 用户经常直接把完整的对话地址粘进来（`.../v1/chat/completions`），
/// 也有人只填域名。这里统一剥掉尾部斜杠和已知的端点后缀，
/// 避免拼出 `/v1/chat/completions/chat/completions` 这种地址。
String normalizeBaseUrl(String raw, LlmProtocol protocol) {
  var s = raw.trim();
  if (s.isEmpty) return s;
  s = s.replaceAll(RegExp(r'/+$'), '');
  for (final suffix in [
    '/chat/completions',
    '/completions',
    '/messages',
    '/responses',
  ]) {
    if (s.toLowerCase().endsWith(suffix)) {
      s = s.substring(0, s.length - suffix.length);
      s = s.replaceAll(RegExp(r'/+$'), '');
    }
  }
  return s;
}
