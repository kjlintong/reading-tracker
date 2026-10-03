import 'dart:async';
import '../app_info.dart';
import '../l10n/app_loc.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai/ai_client.dart';
import '../ai/llm_protocol.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'backup_page.dart';
import 'theme.dart';

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
      _resultOk = null;
      _resultText = null;
    });
    _save();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appLoc.s_b6477017(name: p.name))),
    );
  }

  Future<void> _pullModels() async {
    setState(() {
      _busy = appLoc.s_533f5118;
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
          _resultText = appLoc.s_648219b9(id: picked.id);
        });
      } else {
        setState(() => _resultText = appLoc.s_baf95794(length: models.length));
      }
    } catch (e) {
      if (mounted) setState(() => _resultText = _readable(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _testLlm() async {
    setState(() {
      _busy = appLoc.s_e37cab47;
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
        _resultText = appLoc.s_c17c1a05(model: ping.model, latencyMs: ping.latencyMs, reply: ping.reply);
      });
    } catch (e) {
      if (mounted) setState(() => _resultText = _readable(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _testWeread() async {
    setState(() {
      _busy = appLoc.s_5df0d12b;
      _resultOk = null;
      _resultText = null;
    });
    await _save(toast: false);
    try {
      final n = await ref.read(wereadGatewayProvider).ping();
      if (mounted) {
        setState(() {
          _resultOk = true;
          _resultText = appLoc.s_bd245b07(n: n);
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
              // 外观与语言排在配置类项目前面：它们是「看一眼就想调」的，
              // 而 API Key 是装完基本不再碰的一次性配置。
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
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: null,
                    groupValue: locale?.languageCode,
                    onChanged: (_) async {
                      await saveSetting(ref, 'app_locale', '');
                      if (mounted) setState(() {});
                    },
                    title: Text(l10n.settingsLanguageSystem,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  for (final l in S.supportedLocales)
                    RadioListTile<String?>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: l.languageCode,
                      groupValue: locale?.languageCode,
                      onChanged: (_) async {
                        await saveSetting(ref, 'app_locale', l.languageCode);
                        if (mounted) setState(() {});
                      },
                      title: Text(languageName(l.languageCode),
                          style: const TextStyle(fontSize: 14)),
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
                  if (_resultText != null) ...[
                    const SizedBox(height: 10),
                    _ResultBanner(ok: _resultOk, text: _resultText!),
                  ],
                ],
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
                        _resultOk = null;
                        _resultText = null;
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

                  if (_resultText != null) ...[
                    const SizedBox(height: 10),
                    _ResultBanner(ok: _resultOk, text: _resultText!),
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
                    isDense: true,
                    decoration: const InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                    items:  [
                      DropdownMenuItem(value: 'auto', child: Text(appLoc.s_ed144a76)),
                      DropdownMenuItem(value: 'vision', child: Text(appLoc.s_c7bab837)),
                      DropdownMenuItem(value: 'device', child: Text(appLoc.s_d8f3da2a)),
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
                  // 打赏链接是内置常量而不是输入框：本应用的变现方式就是
                  // 「免费 + 打赏」，链接必须开箱即用。早先做成可编辑字段时，
                  // 全新安装点这个按钮只会提示「请先填写链接」，等于入口失效。
                  FilledButton.tonalIcon(
                    onPressed: () => _openExternal(AppInfo.tipUrl),
                    icon: const Icon(Icons.favorite_outline, size: 18),
                    label: Text(l10n.openTipPage),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppInfo.tipUrl,
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
                      // 应用介绍页放**第一位**：它是这一块里唯一「介绍这个应用本身」
                      // 的链接，另两个分别指向开发者和法律文本。用户点进「关于」
                      // 的动机，绝大多数是想知道这应用是干什么的。
                      OutlinedButton.icon(
                        // 按界面语言选介绍页：中文页与英文页是两份独立页面
                        // （各自内的导航里也有互跳），这里直接给对的那一份，
                        // 不让英文用户先落在一屏中文上再自己找语言开关。
                        onPressed: () => _openExternal(
                          Localizations.localeOf(context).languageCode == 'zh'
                              ? AppInfo.appPage
                              : AppInfo.appPageEn,
                        ),
                        icon: const Icon(Icons.menu_book_outlined, size: 18),
                        label: Text(l10n.appIntroPage),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openExternal(AppInfo.homepage),
                        icon: const Icon(Icons.language_outlined, size: 18),
                        label: Text(l10n.developerHomepage),
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
                  const SizedBox(height: 4),
                  Text(
                    AppInfo.email,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
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

/// 皮肤选择器：横向一排圆形色块，选中的带勾与描边。
///
/// 用色块而不是下拉列表：换肤是「看」出来的，让用户直接看到候选颜色
/// 比读一串名字直观得多。色块里的颜色取该皮肤的浅色种子色——
/// 它决定了整界面的主色，所见即所得。
class _ThemePicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ThemePicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final t in appThemes)
          Tooltip(
            message: t.label,
            child: InkWell(
              onTap: () => onChanged(t.id),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: t.lightSeed,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: t.id == value ? cs.onSurface : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: t.id == value
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// 语言代码 → 该语言的自称。
///
/// 用「自称」（Deutsch 而不是「德语」）是本地化界面的通行做法：
/// 用户在自己看不懂的语言里找「德语」这两个汉字，是找不到的。
/// 未知语言码回落到大写代码，至少不是空白。
String languageName(String code) => switch (code) {
      'zh' => '简体中文',
      'en' => 'English',
      'de' => 'Deutsch',
      'fr' => 'Français',
      'es' => 'Español',
      'ja' => '日本語',
      'ko' => '한국어',
      _ => code.toUpperCase(),
    };
