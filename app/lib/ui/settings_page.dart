import 'dart:async';
import '../app_info.dart';
import '../l10n/app_loc.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai/ai_client.dart';
import '../ai/llm_protocol.dart';
import '../data/category_prefs.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'backup_page.dart';
import 'theme.dart';
import '../l10n/language_names.dart';

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

  /// 文本框自动保存的防抖。停下打字才落库，避免每敲一个字都写一次库。
  Timer? _saveDebounce;

  /// 微信读书（第三方渠道）验证结果
  bool? _wereadOk;
  String? _wereadText;

  /// 大模型连通性测试结果（测试 / 拉取模型共用）
  bool? _llmOk;
  String? _llmText;

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
    _saveDebounce?.cancel();
    _wereadKey.dispose();
    _llmKey.dispose();
    _llmBase.dispose();
    _llmModel.dispose();
    super.dispose();
  }

  /// 文本框改动后自动保存（防抖）。用户不用再手动点「保存配置」。
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _save);
  }

  /// 把当前所有填写内容落到本地库。
  ///
  /// 自动保存走这里（[toast]=false 静默），「测试 / 拉取」前也会显式调一次，
  /// 保证「测到什么就存什么」这条口径不因改成自动保存而失效。
  Future<void> _save({bool toast = false}) async {
    await saveSetting(ref, 'weread_key', _wereadKey.text.trim());
    await saveSetting(ref, 'llm_key', _llmKey.text.trim());
    await saveSetting(ref, 'llm_base_url', _llmBase.text.trim());
    await saveSetting(ref, 'llm_model', _llmModel.text.trim());
    await saveSetting(ref, 'llm_protocol', _protocol.name);
    if (toast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(appLoc.s_72cca1f6)),
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

  /// 打开应用外部的链接：打赏页、开发者主页、隐私政策。
  ///
  /// 这些地址全部是 [AppInfo] 里的编译期常量，不存在用户输入，
  /// 因此不需要再做「是不是合法 URL」的格式校验——唯一可能的失败
  /// 是设备上没有可用的浏览器，那时给一句可读的提示即可。
  Future<void> _openExternal(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw StateError('no app available to open $url');
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_readable(e))));
    }
  }

  void _applyPreset(LlmPreset p) {
    setState(() {
      _protocol = p.protocol;
      _llmBase.text = p.baseUrl;
      _llmModel.text = p.model;
      _llmKey.clear();
      _wereadOk = null;
      _wereadText = null;
      _llmOk = null;
      _llmText = null;
    });
    _save();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appLoc.s_b6477017(name: p.name))),
    );
  }

  Future<void> _pullModels() async {
    setState(() {
      _busy = appLoc.s_533f5118;
      _llmOk = null;
      _llmText = null;
    });
    try {
      final models = await _formClient().listModels();
      if (!mounted) return;
      final picked = await _pickModel(models);
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          _llmModel.text = picked.id;
          _llmOk = true;
          _llmText = appLoc.s_648219b9(id: picked.id);
        });
      } else {
        setState(() => _llmText = appLoc.s_baf95794(length: models.length));
      }
    } catch (e) {
      if (mounted) setState(() => _llmText = _readable(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _testLlm() async {
    setState(() {
      _busy = appLoc.s_e37cab47;
      _llmOk = null;
      _llmText = null;
    });
    // 先落库再测：测通了什么，存下来的就是什么
    await _save(toast: false);
    try {
      final ping = await _formClient().testConnection();
      if (!mounted) return;
      setState(() {
        _llmOk = true;
        _llmText = appLoc.s_c17c1a05(model: ping.model, latencyMs: ping.latencyMs, reply: ping.reply);
      });
    } catch (e) {
      if (mounted) setState(() => _llmText = _readable(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _testWeread() async {
    setState(() {
      _busy = appLoc.s_5df0d12b;
      _wereadOk = null;
      _wereadText = null;
    });
    await _save(toast: false);
    try {
      final n = await ref.read(wereadGatewayProvider).ping();
      if (mounted) {
        setState(() {
          _wereadOk = true;
          _wereadText = appLoc.s_bd245b07(n: n);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _wereadText = _readable(e));
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
          appLoc.s_73f89115(host: host),
        DioExceptionType.receiveTimeout => appLoc.s_9038e16e,
        DioExceptionType.badResponse =>
          appLoc.s_e0710bf5(statusCode: e.response?.statusCode, e: _bodyOf(e)),
        _ => appLoc.s_24d6c7ae(name: e.message ?? e.type.name),
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
                      decoration:  InputDecoration(
                        hintText: appLoc.s_4d3eb2b3,
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
                        Text(appLoc.s_17d94005(length: models.length),
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const Spacer(),
                         Text(appLoc.s_a48ae43a,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = S.of(context);
    final presets = llmPresets;
    final ocrEnhance = ref.watch(ocrEnhanceProvider);
    final ocrUseLlm = ref.watch(ocrUseLlmProvider);
    final visionMode = ref.watch(ocrVisionModeProvider);
    final themeId = ref.watch(appThemeProvider);
    final brightness = ref.watch(appBrightnessProvider);
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      appBar: AppBar(title:  Text(appLoc.s_b5c7b82d)),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /* ---------------------- 外观 ---------------------- */
              // 整页顺序按「多久会用到一次」排，不按功能归属排：
              //   ① 外观 / 语言 / 分类 —— 装完就想调的，一屏之内；
              //   ② 大模型 / 截图识别 —— 用得上的能力配置，且识别依赖 ① 之外
              //      的同一把 Key，放在一起省得来回找；
              //   ③ 第三方渠道 —— 凭据类，装完基本不碰，压到功能配置之后；
              //   ④ 数据 / 支持 / 关于 —— 偶尔为之，留在最下面。
              // 每一节内部也遵循同一条：先看后改（摘要、说明），再给控件。
              _Section(
                title: l10n.settingsAppearance,
                subtitle: l10n.settingsAppearanceDesc,
                children: [
                  Text(l10n.settingsTheme,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  _ThemePicker(
                    value: themeId,
                    onChanged: (id) async {
                      await saveSetting(ref, 'app_theme', id);
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(l10n.settingsBrightness,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  SegmentedButton<AppBrightness>(
                    segments: [
                      for (final b in AppBrightness.values)
                        ButtonSegment(
                          value: b,
                          label: Text(b.label),
                          icon: Icon(b.icon, size: 16),
                        ),
                    ],
                    selected: {brightness},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) async {
                      await saveSetting(ref, 'app_brightness', s.first.id);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),

              /* ---------------------- 语言 ---------------------- */
              _Section(
                title: l10n.settingsLanguage,
                subtitle: l10n.settingsLanguageDesc,
                children: [
                  // 选项从 supportedLocales 动态生成：将来往 l10n/ 里放一个
                  // app_de.arb，德语就自动出现在这里，无需改本页代码。
                  //
                  // 原来这里是 6 行 RadioListTile（跟随系统 + 5 种语言），
                  // 光这一个设置就吃掉大半屏，而它恰恰是「装完基本只调一次」
                  // 的那一类。收成下拉：一行占位，点开才展开。
                  DropdownButtonFormField<String?>(
                    value: locale?.languageCode,
                    isDense: true,
                    isExpanded: true,
                    // 不给 label：卡片标题就是「界面语言」，再挂一个同名
                    // floating label 纯属重复，还多占一行高度。
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.settingsLanguageSystem,
                            overflow: TextOverflow.ellipsis),
                      ),
                      for (final l in S.supportedLocales)
                        DropdownMenuItem<String?>(
                          value: l.languageCode,
                          child: Text(languageName(l.languageCode),
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) async {
                      // 空串 = 跟随系统，与老数据里 app_locale 的写法一致
                      await saveSetting(ref, 'app_locale', v ?? '');
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),

              /* ---------------------- 分类 ---------------------- */
              // 放在语言后面：两者都是「这套 App 怎么称呼你的书」的层面，
              // 比 API Key 之类的一次性配置更靠近日常使用。
              _Section(
                title: appLoc.s_4b2c9e58,
                subtitle: appLoc.s_8d3f6a12,
                children: const [_CategoryManager()],
              ),

              _Section(
                title: appLoc.s_75bf6943,
                subtitle: appLoc.s_9e8f6691,
                children: [
                  // 协议选择放在最前面：它决定后面 Base URL 和请求体的形状，
                  // 先选协议再填地址，比填完发现不对再回头改要省事
                  SegmentedButton<LlmProtocol>(
                    segments:  [
                      ButtonSegment(
                        value: LlmProtocol.openai,
                        label: Text(appLoc.s_2ad3b6ba),
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
                    onSelectionChanged: (s) {
                      setState(() {
                        _protocol = s.first;
                        _wereadOk = null;
                        _wereadText = null;
                        _llmOk = null;
                        _llmText = null;
                      });
                      _save();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(_protocol.hint,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 12),

                  // 预设收成一个下拉：10 个 ActionChip 铺一排又长又乱，
                  // 下拉点开才展开，选完自动收起，也顺手把 Base URL / 模型填好。
                  DropdownButtonFormField<LlmPreset>(
                    value: null,
                    isDense: true,
                    decoration:  InputDecoration(
                      labelText: appLoc.s_cc3c9556,
                      hintText: appLoc.s_9021b9f9,
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in presets)
                        DropdownMenuItem(value: p, child: Text(p.name)),
                    ],
                    // 值恒为 null：选一次即应用，再点开还是完整列表
                    onChanged: (p) {
                      if (p != null) _applyPreset(p);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _llmBase,
                    onChanged: (_) => _scheduleSave(),
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _llmKey,
                    obscureText: _obscure,
                    onChanged: (_) => _scheduleSave(),
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
                    onChanged: (_) => _scheduleSave(),
                    decoration:  InputDecoration(
                      labelText: appLoc.s_1fd51aaa,
                      helperText: appLoc.s_209e1f28,
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
                        label:  Text(appLoc.s_ab135d7c),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _busy != null ? null : _testLlm,
                        icon: const Icon(Icons.bolt_outlined, size: 18),
                        label:  Text(appLoc.s_a46a5664),
                      ),
                      OutlinedButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        child: Text(_obscure ? appLoc.s_e4f7e107 : appLoc.s_b13be56e),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                   Text(
                    appLoc.s_9ac01f6b,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                  if (_llmText != null) ...[
                    const SizedBox(height: 10),
                    _ResultBanner(ok: _llmOk, text: _llmText!),
                  ],
                ],
              ),

              _Section(
                title: appLoc.s_0001747c,
                subtitle: appLoc.s_3f5cbdbf,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: ocrEnhance,
                    onChanged: (v) async {
                      await saveSetting(ref, 'ocr_enhance', '$v');
                      if (mounted) setState(() {});
                    },
                    title:  Text(appLoc.s_9130a4ed, style: TextStyle(fontSize: 14)),
                    subtitle:  Text(
                      appLoc.s_b79fc99c,
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
                    title:  Text(appLoc.s_9695a603, style: TextStyle(fontSize: 14)),
                    subtitle:  Text(
                      appLoc.s_267118b5,
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 6),
                   Text(appLoc.s_6d7e1f9f, style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: visionMode,
                    isExpanded: true,
                    isDense: true,
                    decoration: const InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                    items:  [
                      DropdownMenuItem(
                          value: 'auto',
                          child: Text(appLoc.s_ed144a76,
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 'vision',
                          child: Text(appLoc.s_c7bab837,
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 'device',
                          child: Text(appLoc.s_d8f3da2a,
                              overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) async {
                      if (v == null) return;
                      await saveSetting(ref, 'ocr_vision_mode', v);
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 6),
                   Text(
                    appLoc.s_f22e4cd2,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              /* ------------------- 第三方渠道（高级） ------------------- */
              // 从「设置第一屏的微信读书专属 Key」降级成通用渠道分组：
              //  1) 不同平台的对接方式千差万别（微信读书走官方 Skill 网关，
              //     国际平台多靠 CSV 导出），把它们塞进同一个「Key 输入框」
              //     的模型本身就是错的；
              //  2) 首位放一个国内平台，对国际用户是噪音。
              // 导入页仍是这些渠道的实际使用入口，这里只负责凭据。
              _Section(
                title: l10n.settingsChannels,
                subtitle: l10n.settingsChannelsDesc,
                children: [
                  TextField(
                    controller: _wereadKey,
                    obscureText: _obscure,
                    onChanged: (_) => _scheduleSave(),
                    decoration: const InputDecoration(
                      labelText: 'WeRead API Key',
                      hintText: 'wrk-xxxxxxxx',
                      helperText:
                          '在微信读书 App「我 → 设置 → 微信读书 Skill」获取',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy != null ? null : _testWeread,
                    icon: const Icon(Icons.wifi_tethering, size: 18),
                    label:  Text(appLoc.s_e44e9f26),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 15,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.settingsChannelAddHint,
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  if (_wereadText != null) ...[
                    const SizedBox(height: 10),
                    _ResultBanner(ok: _wereadOk, text: _wereadText!),
                  ],
                ],
              ),

              _Section(
                title: appLoc.s_67677b3d,
                subtitle: appLoc.s_d596ba9b,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BackupPage()),
                    ),
                    icon: const Icon(Icons.ios_share_outlined),
                    label:  Text(appLoc.s_39239742),
                  ),
                ],
              ),

              _Section(
                title: l10n.supportDev,
                subtitle: l10n.supportDevDesc,
                children: [
                  // 打赏入口内置两个：国内（爱发电）+ 国外（Ko-fi）。
                  // 国内链接留空则不显示，便于没有国内渠道时只保留 Ko-fi。
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (AppInfo.tipUrlDomestic.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _openExternal(AppInfo.tipUrlDomestic),
                          icon: const Icon(Icons.favorite_outline, size: 18),
                          label: Text(l10n.openTipDomestic),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _openExternal(AppInfo.tipUrl),
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: Text(l10n.openTipForeign),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppInfo.tipUrlDomestic.isNotEmpty
                        ? '${AppInfo.tipUrlDomestic}\n${AppInfo.tipUrl}'
                        : AppInfo.tipUrl,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              _Section(
                title: l10n.about,
                subtitle: l10n.aboutDesc,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // 应用介绍页：它是这一块里唯一「介绍这个应用本身」的链接。
                      // 按界面语言选介绍页：中文页与英文页是两份独立页面，
                      // 这里直接给对的那一份，不让英文用户先落在一屏中文上。
                      OutlinedButton.icon(
                        onPressed: () => _openExternal(
                          Localizations.localeOf(context).languageCode == 'zh'
                              ? AppInfo.appPage
                              : AppInfo.appPageEn,
                        ),
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        label: Text(l10n.appIntroPage),
                      ),
                      OutlinedButton.icon(
                        // 中文设备看中文版政策，其余看英文版；
                        // 两个地址都由 store/web/ 生成，与商店后台填写的一致。
                        onPressed: () => _openExternal(
                          AppInfo.privacyPolicyFor(Localizations.localeOf(context)),
                        ),
                        icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                        label: Text(l10n.privacyPolicy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${AppInfo.name} · '
                    '${l10n.appVersionLabel(version: AppInfo.versionLabel)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 15, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appLoc.s_3c21597a,
                      style: TextStyle(fontSize: 12, color: cs.primary),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
               Text(
                appLoc.s_68885a92,
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

/// 皮肤选择器：一个预览块 + 一个下拉。
///
/// ## 为什么不是一排色块
///
/// 早期版本把 5 套皮肤铺成 5 个圆形色块。皮肤加到 10 套之后这条路走不通：
/// 46px 的色块要占两行、占掉设置页里最贵的一块竖向空间，而且
/// **看不出差别**——所有色块都只填种子色，而一套皮肤的气质大半在
/// **纸色**上（见[AppTheme.paperTint]），不填纸色的色块等于
/// 10 个几乎一样的圆点。
///
/// 现在改成「左边看、右边选」：预览块显示这套皮肤的**真实纸色与主色**
/// （就是界面上真正会出现的那个配色），右边一个下拉列出全部皮肤名。
/// 用户在下拉里读名字、在预览块里看效果，与设置页其他长选项的交互一致。
class _ThemePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ThemePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = AppTheme.byId(value);
    final scheme = buildTheme(theme, Brightness.light).colorScheme;

    return Row(
      children: [
        // 预览块：外圈纸色 + 内芯主色，一眼看出这套皮肤的整体调子。
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: cs.outlineVariant, width: 1),
          ),
          padding: const EdgeInsets.all(7),
          child: DecoratedBox(
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                // 用皮肤名首字：不同皮肤的首字大多不同，色盲用户也能区分
                theme.label.isEmpty ? '?' : theme.label.characters.first,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: DropdownButtonFormField<String>(
            // ⚠️ Flutter 3.24 是 `value`，`initialValue` 要3.35+ 才有。
            // 记忆里已记过这条（DropdownButtonFormField<String?> 是测试
            // 里的唯一身份），这里再踩一次属于没长记性。
            value: theme.id,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: [
              for (final t in appThemes)
                DropdownMenuItem<String>(
                  value: t.id,
                  child: Row(
                    children: [
                      // 每项右侧带一个色点，方便在列表里横向对比
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: buildTheme(t, Brightness.light).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(t.label, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
            ],
            onChanged: (id) {
              if (id != null && id != value) onChanged(id);
            },
          ),
        ),
      ],
    );
  }
}

/// 分类词表管理：改名 / 删除 / 新增 / 恢复默认。
///
/// 独立成一个 Widget 而不是塞进设置页的 build：它要维护输入框、
/// 要弹确认框、要写两张 settings 表，混进那个上千行的 build 里
/// 会让任何一处改动都要在长方法里翻找。
class _CategoryManager extends ConsumerStatefulWidget {
  const _CategoryManager();

  @override
  ConsumerState<_CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends ConsumerState<_CategoryManager> {
  final _ctrl = TextEditingController();

  /// 下拉里当前选中的分类；「改名 / 删除」都作用于它。
  ///
  /// 默认分类就有二十来个，逐行铺开能把整页设置撑到三屏，而分类管理
  /// 本身是低频操作——绝大多数人一辈子只改两三个词条。所以改成
  /// 「下拉选一个 → 对它做操作」，词表整体收进下拉里。
  String? _picked;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// 词表改动落盘。
  ///
  /// 两个名单一起写：只写一个会出现「新增了 A、却还隐藏着 B」的半截状态。
  Future<void> _persist() async {
    await saveSetting(ref, kCustomCategoriesKey,
        encodeCategoryList(categoryVocabulary.custom));
    await saveSetting(
        ref, kHiddenCategoriesKey, encodeCategoryList(categoryVocabulary.hidden));
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      _snack(appLoc.s_9f4e7a35);
      return;
    }
    if (!addCategory(name)) {
      _snack(appLoc.s_7a2d6c81);
      return;
    }
    _ctrl.clear();
    await _persist();
    _snack(appLoc.s_5e9c1b47(name: name));
  }

  /// 重命名：先改词表，再把存量书迁移到新名字。
  ///
  /// 顺序不能反——先迁书的话，万一词表写入失败，库里就躺着一个
  /// 没有任何分类会承认它的值。
  Future<void> _rename(String old) async {
    final ctrl = TextEditingController(text: old);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLoc.s_6a9e4c27),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: appLoc.s_2c8b5d09,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(appLoc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(appLoc.s_fe93ef35),
          ),
        ],
      ),
    );
    if (next == null || next.isEmpty || next == old) return;
    if (categoryVocabulary.contains(next)) {
      _snack(appLoc.s_7a2d6c81);
      return;
    }
    renameCategory(old, next);
    final moved = await ref.read(repoProvider).recategorize(old, next);
    await _persist();
    // 旧名已经不在词表里，选中项要跟着走，否则下拉会断言 value 不在 items 中
    if (mounted) setState(() => _picked = next);
    _snack(appLoc.s_9d2e7f13(name: next, count: '$moved'));
  }

  /// 删除：先把书迁到「未分类」，再从词表里去掉。
  ///
  /// 确认框里带上受影响的数量。「删除『宗教』」和「删除『宗教』
  /// （12 本书会归入未分类）」是两个完全不同的决定——
  /// 用户有权在按下之前知道自己要动多少数据。
  Future<void> _delete(String name) async {
    final count = await ref.read(repoProvider).categoryCount(name);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLoc.s_8c4a1e92(name: name)),
        content: Text(appLoc.s_1d7b3f08(count: '$count')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(appLoc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(appLoc.s_ecbd7449),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (count > 0) {
      await ref.read(repoProvider).recategorize(name, kUncategorized);
    }
    removeCategory(name);
    await _persist();
    if (mounted) setState(() => _picked = null);
    _snack(appLoc.s_3b7f2d64(name: name));
  }

  Future<void> _restore() async {
    restoreDefaultCategories();
    await _persist();
    _snack(appLoc.s_4e1c7a69);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10nPick = S.of(context).settingsCategoryPick;
    final l10nEmpty = S.of(context).settingsCategoryEmpty;
    final active = categoryVocabulary.active;
    // 每次 build 都校准一次选中项：改名 / 删除之后旧名已经不在词表里，
    // 而 DropdownButton 的 value 必须命中 items 中某一项，否则直接抛断言。
    // 词表非空时默认落在第一项，省掉一次无谓的点击。
    if (_picked != null && !active.contains(_picked)) _picked = null;
    if (_picked == null && active.isNotEmpty) _picked = active.first;
    final picked = _picked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (active.isEmpty)
          Text(l10nEmpty,
              style: TextStyle(
                  fontSize: 12, color: theme.colorScheme.onSurfaceVariant))
        else ...[
          // 不用 ListView：外面已经是可滚动的设置页，嵌套可滚动组件
          // 会让这一块的高度算不出来（shrinkWrap 在这里也不解决问题）。
          DropdownButtonFormField<String>(
            value: picked,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10nPick,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final c in active)
                DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Flexible(
                          child: Text(categoryLabel(c),
                              overflow: TextOverflow.ellipsis)),
                      if (categoryVocabulary.isCustom(c)) ...[
                        const SizedBox(width: 6),
                        Text(appLoc.s_9c3f5d21,
                            style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _picked = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: picked == null ? null : () => _rename(picked),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(appLoc.s_6a9e4c27),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: picked == null ? null : () => _delete(picked),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(appLoc.s_ecbd7449),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  labelText: appLoc.s_2c8b5d09,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _add,
              child: Text(appLoc.s_a1d885c1),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: categoryVocabulary.isEmpty ? null : _restore,
            child: Text(appLoc.s_2f5d8b13),
          ),
        ),
      ],
    );
  }
}

