import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_client.dart';
import '../ai/llm_protocol.dart';
import '../data/seed_import.dart';
import '../providers.dart';

/// 设置页。
///
/// 所有密钥由用户自填并只存本地数据库，App 不内置、不上传任何凭证。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _wereadKey;
  late final TextEditingController _llmKey;
  late final TextEditingController _llmBase;
  late final TextEditingController _llmModel;
  late LlmProtocol _protocol;

  bool _obscure = true;
  String? _hint;

  /// 最近一次操作结果：true 成功 / false 失败，null 表示还没操作过
  bool? _resultOk;
  String? _resultText;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _wereadKey = TextEditingController(text: ref.read(wereadKeyProvider) ?? '');
    _llmKey = TextEditingController(text: ref.read(llmKeyProvider) ?? '');
    _llmBase = TextEditingController(text: ref.read(llmBaseUrlProvider));
    _llmModel = TextEditingController(text: ref.read(llmModelProvider));
    _protocol = ref.read(llmProtocolProvider);
  }

  @override
  void dispose() {
    _wereadKey.dispose();
    _llmKey.dispose();
    _llmBase.dispose();
    _llmModel.dispose();
    super.dispose();
  }

  Future<void> _save({bool toast = true}) async {
    await saveSetting(ref, 'weread_key', _wereadKey.text.trim());
    await saveSetting(ref, 'llm_key', _llmKey.text.trim());
    await saveSetting(ref, 'llm_base_url', _llmBase.text.trim());
    await saveSetting(ref, 'llm_model', _llmModel.text.trim());
    await saveSetting(ref, 'llm_protocol', _protocol.name);
    if (!mounted) return;
    setState(() => _hint = '已保存到本地数据库');
    if (toast) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存到本地')),
      );
    }
  }

  /// 用「输入框当前的值」构造客户端，而不是用已保存的配置——
  /// 用户填完就想点测试，不该被迫先保存一次再测。
  LlmClient _formClient() => LlmClient(
        dio: ref.read(dioProvider),
        apiKey: _llmKey.text.trim(),
        baseUrl: _llmBase.text.trim(),
        model: _llmModel.text.trim(),
        protocol: _protocol,
      );

  void _applyPreset(LlmPreset p) {
    setState(() {
      _protocol = p.protocol;
      _llmBase.text = p.baseUrl;
      _llmModel.text = p.model;
      _llmKey.clear();
      _resultOk = null;
      _resultText = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已填入 ${p.name}，还需要填 API Key')),
    );
  }

  Future<void> _pullModels() async {
    setState(() {
      _busy = '正在拉取模型列表…';
      _resultOk = null;
      _resultText = null;
    });
    try {
      final models = await _formClient().listModels();
      if (!mounted) return;
      final picked = await _pickModel(models);
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          _llmModel.text = picked.id;
          _resultOk = true;
          _resultText = '已选择模型：${picked.id}';
        });
      } else {
        setState(() => _resultText = '共 ${models.length} 个可用模型（未选择）');
      }
    } catch (e) {
      if (mounted) setState(() => _resultText = _readable(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _testLlm() async {
    setState(() {
      _busy = '正在测试连通性…';
      _resultOk = null;
      _resultText = null;
    });
    // 先落库再测：测通了什么，存下来的就是什么
    await _save(toast: false);
    try {
      final ping = await _formClient().testConnection();
      if (!mounted) return;
      setState(() {
        _resultOk = true;
        _resultText = '连通正常 · ${ping.model}\n'
            '耗时 ${ping.latencyMs} ms，模型回复「${ping.reply}」';
      });
    } catch (e) {
      if (mounted) setState(() => _resultText = _readable(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _testWeread() async {
    setState(() {
      _busy = '正在验证微信读书 Key…';
      _resultOk = null;
      _resultText = null;
    });
    await _save(toast: false);
    try {
      final n = await ref.read(wereadGatewayProvider).ping();
      if (mounted) {
        setState(() {
          _resultOk = true;
          _resultText = 'Key 有效，书架当前 $n 本';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _resultText = _readable(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// 把异常翻成人能看懂的一句话。DioException 的原始字符串
  /// （`[unknown]: null Error: HttpException: ...`）对用户毫无意义。
  static String _readable(Object e) {
    if (e is LlmException) return e.toString();
    if (e is StateError) return e.message;
    if (e is DioException) {
      final host = e.requestOptions.uri.host;
      return switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.connectionError =>
          '连不上 $host\n检查网络、Base URL 是否写全（含 /v1），以及该服务是否需要代理',
        DioExceptionType.receiveTimeout => '对端响应超时（180 秒）',
        DioExceptionType.badResponse =>
          '服务返回 ${e.response?.statusCode}：${_bodyOf(e)}',
        _ => '请求失败：${e.message ?? e.type.name}',
      };
    }
    return e.toString();
  }

  static String _bodyOf(DioException e) {
    final d = e.response?.data;
    if (d is Map) {
      final err = d['error'];
      if (err is Map && err['message'] != null) return '${err['message']}';
      for (final k in ['message', 'msg', 'detail']) {
        if (d[k] != null) return '${d[k]}';
      }
    }
    final s = d?.toString() ?? '';
    return s.length <= 120 ? s : '${s.substring(0, 120)}…';
  }

  Future<LlmModel?> _pickModel(List<LlmModel> models) {
    return showModalBottomSheet<LlmModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        var keyword = '';
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final list = keyword.isEmpty
                ? models
                : models
                    .where((m) => m.id.toLowerCase().contains(keyword.toLowerCase()))
                    .toList();
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      autofocus: false,
                      decoration: const InputDecoration(
                        hintText: '搜索模型',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setSheet(() => keyword = v.trim()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text('共 ${models.length} 个',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Spacer(),
                        const Text('点选即写入模型名',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (ctx, i) {
                        final m = list[i];
                        final selected = m.id == _llmModel.text.trim();
                        return ListTile(
                          dense: true,
                          selected: selected,
                          leading: Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 18,
                          ),
                          title: Text(m.id, style: const TextStyle(fontSize: 13)),
                          subtitle: m.displayName == null || m.displayName == m.id
                              ? null
                              : Text(m.displayName!,
                                  style: const TextStyle(fontSize: 11)),
                          onTap: () => Navigator.pop(ctx, m),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reseed() async {
    final repo = ref.read(repoProvider);
    final n = await SeedImporter(repo).forceImport();
    if (mounted) {
      setState(() => _hint = '已重新导入种子书库 $n 本');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已重新导入 $n 本')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final presets = llmPresets;
    final ocrEnhance = ref.watch(ocrEnhanceProvider);
    final ocrUseLlm = ref.watch(ocrUseLlmProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: '微信读书',
                subtitle:
                    '用于同步书架与阅读进度。扫码打开 weread.qq.com/r/weread-skills 可获取。',
                children: [
                  TextField(
                    controller: _wereadKey,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'wrk-xxxxxxxx',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy != null ? null : _testWeread,
                    icon: const Icon(Icons.wifi_tethering, size: 18),
                    label: const Text('验证 Key'),
                  ),
                ],
              ),

              _Section(
                title: '大模型',
                subtitle: '用于元数据兜底补全、截图识别整理与阅读报告。',
                children: [
                  // 协议选择放在最前面：它决定后面 Base URL 和请求体的形状，
                  // 先选协议再填地址，比填完发现不对再回头改要省事
                  SegmentedButton<LlmProtocol>(
                    segments: const [
                      ButtonSegment(
                        value: LlmProtocol.openai,
                        label: Text('OpenAI 兼容'),
                        icon: Icon(Icons.memory, size: 16),
                      ),
                      ButtonSegment(
                        value: LlmProtocol.anthropic,
                        label: Text('Claude'),
                        icon: Icon(Icons.auto_awesome, size: 16),
                      ),
                    ],
                    selected: {_protocol},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() {
                      _protocol = s.first;
                      _resultOk = null;
                      _resultText = null;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(_protocol.hint,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),

                  const Text('服务商预设', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presets
                        .map((p) => ActionChip(
                              label: Text(p.name, style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onPressed: () => _applyPreset(p),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _llmBase,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _llmKey,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: _protocol == LlmProtocol.anthropic
                          ? 'sk-ant-xxxxxxxx'
                          : 'sk-xxxxxxxx',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _llmModel,
                    decoration: const InputDecoration(
                      labelText: '模型名称',
                      helperText: '建议点「拉取模型」从账号实际可用的列表里选',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _busy != null ? null : _pullModels,
                        icon: const Icon(Icons.cloud_download_outlined, size: 18),
                        label: const Text('拉取模型'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _busy != null ? null : _testLlm,
                        icon: const Icon(Icons.bolt_outlined, size: 18),
                        label: const Text('测试连通性'),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        child: Text(_obscure ? '显示密钥' : '隐藏密钥'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '测试与拉取都会先保存当前填写的内容，测到什么就存什么。',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                  if (_resultText != null) ...[
                    const SizedBox(height: 10),
                    _ResultBanner(ok: _resultOk, text: _resultText!),
                  ],
                ],
              ),

              _Section(
                title: '截图识别',
                subtitle: '决定拍照/截图导入的识别效果。',
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: ocrEnhance,
                    onChanged: (v) async {
                      await saveSetting(ref, 'ocr_enhance', '$v');
                      if (mounted) setState(() {});
                    },
                    title: const Text('图像增强预处理', style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      '识别前放大到 1200px 宽并转灰度、提对比度。小字书名识别率明显更高。',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: ocrUseLlm,
                    onChanged: (v) async {
                      await saveSetting(ref, 'ocr_use_llm', '$v');
                      if (mounted) setState(() {});
                    },
                    title: const Text('用大模型整理识别结果', style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      '把 OCR 文本交给大模型挑出真正的书名并补全被截断的标题。需要配置大模型 Key，会消耗 token。',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),

              _Section(
                title: '数据',
                subtitle: '种子书库为首次启动自动导入的 38 本示例书（合成数据，不含任何真实书单）。',
                children: [
                  OutlinedButton.icon(
                    onPressed: _reseed,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('重新导入种子书库'),
                  ),
                ],
              ),

              if (_hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_hint!, style: TextStyle(color: cs.primary)),
                ),

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('保存配置'),
              ),

              const SizedBox(height: 24),
              const Text(
                '密钥仅保存在本机数据库中，不会随应用分发或上传。',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (_busy != null)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(_busy!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 测试结果条。消息里常带换行（错误提示 + 处理建议），所以用多行文本。
class _ResultBanner extends StatelessWidget {
  final bool? ok;
  final String text;

  const _ResultBanner({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final good = ok == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: good ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(good ? Icons.check_circle_outline : Icons.error_outline,
              size: 18, color: good ? cs.onPrimaryContainer : cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: good ? cs.onPrimaryContainer : cs.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _Section({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
