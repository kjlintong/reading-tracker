import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../ai/ai_client.dart';
import '../data/date_range.dart';
import '../data/profile_store.dart';
import '../data/reading_profile.dart';
import '../l10n/app_loc.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'archive_section.dart';
import 'bubble_chart.dart';
import 'palette.dart';

/// 「阅读档案」内联展示的两块：**偏好分布 → 性格标签**。
///
/// 两块都**可以在这里直接改**：标签点一下就进编辑弹窗（改文字 / 删除），
/// 旁边还有「新建」；偏好分布只读（它由藏书结构推导，改不了）。
/// 以前这两块是「只读结论版」，改标签要跳一层二级页——用户反馈
/// 点了没反应像坏了，现在完整能力都内联在这里。
///
/// 两块共用一次数据加载：都是 [ReadingProfile.build] 的产物，
/// 分两次查库既慢又可能落在不同的数据快照上（一边显示 38 本、
/// 另一边 39 本，看起来就像 bug）。
class ProfileSections extends ConsumerStatefulWidget {
  const ProfileSections({super.key});

  @override
  ConsumerState<ProfileSections> createState() => _ProfileSectionsState();
}

/// 「生成分享图片」点下去之后的两条路。
///
/// 做成枚举而不是两个回调：动作单的结果是「用户选了哪条路」这一个值，
/// 用 `String` 哨兵（`'share'` / `'save'`）容易拼错且编译期不查。
enum _ShareAction { share, save }

class _ProfileSectionsState extends ConsumerState<ProfileSections> {
  /// 画像固定按「全部时间」算。**必须每次现取**——`StatsRange.all`
  /// 的 label 是本地化字符串，`static final` 只求值一次会把语言钉死。
  static StatsRange get _range => StatsRange.all;

  List<Book> _books = const [];
  ReadingProfile _profile = const ReadingProfile();
  List<ProfileTagItem>? _mainTags;
  List<AiTagSet> _aiHistory = const [];
  bool _loading = true;
  bool _aiBusy = false;
  String? _aiError;

  /// 正在生成分享图片。避免连点叠出多张图。
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<ProfileTagItem> get _shownTags =>
      _mainTags ??
      [
        for (final t in _profile.tags)
          ProfileTagItem(text: t.text, reason: t.reason, source: 'rule'),
      ];

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final all = await repo.all();
    final books = all.where(_range.containsBook).toList();
    final activity = await repo.readingActivity(_range);
    final mainRaw = await repo.getSetting(profileMainTagsKey);
    final aiRaw = await repo.getSetting(profileAiHistoryKey);
    if (!mounted) return;
    setState(() {
      _books = books;
      _profile = ReadingProfile.build(books, activity: activity);
      _mainTags = decodeMainTags(mainRaw);
      _aiHistory = decodeAiHistory(aiRaw);
      _loading = false;
    });
  }

  /// 与 ProfilePage 同口径的聚合统计（发书名清单出去不是必要代价）。
  Map<String, dynamic> get _summary {
    final status = <String, int>{};
    final categories = <String, int>{};
    final sources = <String, int>{};
    for (final b in _books) {
      status[b.status.label] = (status[b.status.label] ?? 0) + 1;
      final label = categoryLabel(b.categoryPrimary ?? kUncategorized);
      categories[label] = (categories[label] ?? 0) + 1;
      sources[b.source.label] = (sources[b.source.label] ?? 0) + 1;
    }
    return {
      appLoc.s_c048f107: _range.label,
      appLoc.s_89c61e4a: _books.length,
      appLoc.s_9da15a74: status,
      appLoc.s_130a42ae: categories,
      appLoc.s_98f42577: sources,
    };
  }

  Future<void> _generateAiTags() async {
    final llm = ref.read(llmClientProvider);
    if (!llm.available) {
      setState(() => _aiError = appLoc.s_7be1388c);
      return;
    }
    setState(() {
      _aiBusy = true;
      _aiError = null;
    });
    try {
      final tags = await llm.suggestProfileTags(_summary);
      if (!mounted) return;
      if (tags.isEmpty) {
        setState(() => _aiError = appLoc.s_992d7786);
        return;
      }
      final next = appendAiHistory(
          _aiHistory, AiTagSet(tags: tags, at: DateTime.now()));
      await ref.read(repoProvider).setSetting(
            profileAiHistoryKey,
            jsonEncode([for (final s in next) s.toJson()]),
          );
      // 生成出来就直接用上：用户在档案首页点「生成」的意图就是
      // 「给我一组新标签」，还要他去历史里再点一次「应用」是多余的一步。
      final merged = [
        for (final t in tags) ProfileTagItem(text: t, source: 'ai'),
      ];
      await ref.read(repoProvider).setSetting(
            profileMainTagsKey,
            encodeMainTags(merged),
          );
      if (!mounted) return;
      setState(() {
        _aiHistory = next;
        _mainTags = merged;
      });
    } catch (e) {
      if (mounted) setState(() => _aiError = describeLlmError(e));
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_books.isEmpty) {
      return archiveEmpty(cs, appLoc.s_a38881a0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /* ---------------------- ① 偏好分布 ---------------------- */
        archiveSection(
          theme,
          title: appLoc.s_7ae84af3,
          subtitle: appLoc.s_aeed65e7(length: _profile.preferences.length),
          // 偏好分布也要能导出：用户想分享的常常正是这张气泡图
          // （「我的阅读口味长这样」），分享的是标签时才发现没有出口
          // 就太晚了。两张区块用同一个 [_shareButton]，行为完全一致。
          trailing: _shareButton(),
          child: _preferenceChart(cs),
        ),
        const SizedBox(height: 16),

        /* ---------------------- ② 性格标签 ---------------------- */
        archiveSection(
          theme,
          title: appLoc.s_6c64acc5,
          subtitle: appLoc.s_03bf36af(length: _books.length),
          trailing: _shareButton(),
          child: _tags(cs),
        ),
      ],
    );
  }

  /// 区块标题行上的「导出分享」按钮。生成中换成转圈，且不可再点。
  ///
  /// 抽成一个方法而不是在两处各写一遍：这两颗按钮必须长得一样、
  /// 禁用条件一样——各写一份迟早只在其中一处改了 disabled 条件。
  Widget _shareButton() => _sharing
      ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      : IconButton(
          tooltip: appLoc.s_14f92b04,
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: _shareImage,
          icon: const Icon(Icons.ios_share),
        );

  /// 偏好分布：气泡图 + 文本图例。
  ///
  /// 图例是必须的，不是装饰：气泡图只给出相对大小，
  /// 没有文字图例就读不出「这一类到底占多少」。
  Widget _preferenceChart(ColorScheme cs) {
    if (_profile.preferences.isEmpty) {
      return Text(
        appLoc.s_f2a9e2a4,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PreferenceBubbleChart(
          bubbles: _profile.bubbles,
          // 传进去的是当前语言的显示名，与图例同一口径；
          // 气泡里的文字由 painter 直接画，不走 Text，本地化必须在这里完成。
          displayNames: {
            for (final p in _profile.preferences)
              p.label: categoryLabel(p.label),
          },
          colors: chartColorsFor([
            for (final p in _profile.preferences) categoryLabel(p.label),
          ]),
        ),
        const SizedBox(height: 12),
        // 折行紧凑图例。分类数可变（最多 20），一列一行的写法会把
        // 整个区块撑成一屏；图例是参考信息，不该占这么多地方。
        CompactLegend(
          items: [
            for (var i = 0; i < _profile.preferences.length; i++)
              LegendItem(
                color: chartColorAt(i, context),
                // ⚠️ 必须过 categoryLabel()：PreferenceSlice.label 存的是规范值，
                // 它是气泡图取色的 key，不能本地化。
                label: categoryLabel(_profile.preferences[i].label),
                count: '${_profile.preferences[i].count}',
                ratio:
                    '${(_profile.preferences[i].share * 100).toStringAsFixed(1)}%',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(appLoc.s_f2a9e2a4,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _tags(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_shownTags.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(appLoc.s_a789d74f,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 点标签 = 改它 / 删它。之前这里只弹一段只读的依据说明，
            // 用户点完发现改不了，反馈说「点击无法修改」。
            for (var i = 0; i < _shownTags.length; i++)
              InputChip(
                label:
                    Text(_shownTags[i].text, style: const TextStyle(fontSize: 13)),
                onPressed: () => _editTag(i),
                showCheckmark: false,
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 15),
              label: Text(appLoc.s_a1d885c1,
                  style: const TextStyle(fontSize: 13)),
              onPressed: _addTag,
            ),
            ActionChip(
              avatar: const Icon(Icons.auto_awesome, size: 15),
              label: Text(
                _aiBusy ? appLoc.s_84bf2c49 : appLoc.s_5a251fee,
                style: const TextStyle(fontSize: 13),
              ),
              onPressed: _aiBusy ? null : _generateAiTags,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(appLoc.s_64bff158,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        if (_aiError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child:
                Text(_aiError!, style: TextStyle(fontSize: 11.5, color: cs.error)),
          ),
      ],
    );
  }

  /* -------------------------- 标签编辑 -------------------------- */

  /// 把当前画像渲染成一张图片，然后让用户选：分享出去，还是存进相册。
  ///
  /// 渲染的是**离屏**的 [_ProfileShareCard]，不是截当前页面——页面里有
  /// 滚动条、导航栏、按钮这些不该出现在分享图里的东西。卡片自带白底与
  /// 固定宽度，与 App 主题解耦，分享出去在谁那儿看都是干净的一张。
  ///
  /// 为什么要给「保存到相册」一个独立出口：`Share.shareXFiles` 只是把图
  /// 交给别的 App，一旦用户想「先攒着，回头拼九宫格」就没有落点——
  /// 分享和保存是两件事，不能互相替代。
  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await ScreenshotController().captureFromWidget(
        _ProfileShareCard(
          profile: _profile,
          tags: _shownTags,
          rangeLabel: _range.label,
          bookCount: _books.length,
        ),
        pixelRatio: 3.0,
        context: context,
      );
      if (!mounted) return;
      final action = await _askShareAction();
      if (action == null) return;
      switch (action) {
        case _ShareAction.share:
          await _doShare(bytes);
        case _ShareAction.save:
          await _doSave(bytes);
      }
    } catch (e) {
      if (mounted) _toast(appLoc.s_783e43af(e: e));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// 弹一个从底部升起的动作单。用户点遮罩关掉返回 null（= 什么都不做）。
  Future<_ShareAction?> _askShareAction() => showModalBottomSheet<_ShareAction>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(appLoc.s_14f92b04),
                onTap: () => Navigator.pop(ctx, _ShareAction.share),
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(appLoc.s_b8e4c9a1),
                onTap: () => Navigator.pop(ctx, _ShareAction.save),
              ),
            ],
          ),
        ),
      );

  /// 走系统分享面板。先把 PNG 落到临时目录——`shareXFiles` 要的是路径。
  Future<void> _doShare(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/reading-profile-'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: appLoc.s_e97565e5,
    );
  }

  /// 存进系统相册。
  ///
  /// gal 要求传**文件路径**而不是字节流，所以同样先落一份到临时目录。
  /// 权限自己弹（Android 13+ 走 READ_MEDIA_IMAGES，以下走
  /// WRITE_EXTERNAL_STORAGE），不要再叠一层自己的权限引导。
  Future<void> _doSave(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/readnest-profile-'
      '${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);
    try {
      await Gal.putImage(file.path, album: 'Readnest');
      if (mounted) _toast(appLoc.s_a17c4e02);
    } on GalException catch (e) {
      if (mounted) _toast(appLoc.s_3f81d5b6(e: e.type.message));
    }
  }

  Future<void> _saveMain() async {
    final v = _mainTags;
    await ref.read(repoProvider).setSetting(
          profileMainTagsKey,
          v == null ? '' : encodeMainTags(v),
        );
  }

  /// 编辑一个标签：弹窗里既能改文字，也能删除。
  ///
  /// 与完整画像页（原 [ProfilePage]）保持同一套交互——两处行为不一致
  /// 会被读成 bug。删除走 `'__delete__'` 哨兵值，因为 `showDialog<String>`
  /// 用 `null` 表示「取消」，不能拿它兼职表达「删除」。
  Future<void> _editTag(int index) async {
    final current = _shownTags[index];
    final ctrl = TextEditingController(text: current.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLoc.s_8eb8d18d),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 12,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 10),
            Text(current.reason ?? appLoc.s_35c48d07,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, '__delete__'),
            child: Text(appLoc.s_ecbd7449,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(appLoc.s_a0451c97)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(appLoc.s_abfe9512)),
        ],
      ),
    );
    if (result == null) return;
    if (result == '__delete__') {
      final list = [..._shownTags];
      final removed = list.removeAt(index);
      setState(() => _mainTags = list);
      await _saveMain();
      if (mounted) _toast(appLoc.s_284dfaab(text: removed.text));
      return;
    }
    final v = result.trim();
    if (v.isEmpty) return;
    final list = [..._shownTags];
    list[index] = list[index].withText(v);
    setState(() => _mainTags = list);
    await _saveMain();
  }

  Future<void> _addTag() async {
    final text = await _askText(
      title: appLoc.s_724386f0,
      initial: '',
      hint: appLoc.s_fdd8c684,
    );
    if (text == null) return;
    final v = text.trim();
    if (v.isEmpty) return;
    setState(() => _mainTags = [
      ..._shownTags,
      ProfileTagItem(text: v, source: 'edited'),
    ]);
    await _saveMain();
  }

  Future<String?> _askText({
    required String title,
    required String initial,
    required String hint,
  }) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 12,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
            const SizedBox(height: 10),
            Text(hint,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(appLoc.s_a0451c97)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: Text(appLoc.s_abfe9512)),
        ],
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// 分享用的画像卡片。
///
/// 关键点：**不依赖 Theme**。它会被离屏渲染（截图时没有 MaterialApp 祖先），
/// 所有颜色与字号都写死，白底深字，保证分享到任何地方都是同一张干净的图。
class _ProfileShareCard extends StatelessWidget {
  final ReadingProfile profile;
  final List<ProfileTagItem> tags;
  final String rangeLabel;
  final int bookCount;

  const _ProfileShareCard({
    required this.profile,
    required this.tags,
    required this.rangeLabel,
    required this.bookCount,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = profile.preferences;
    final maxCount =
        prefs.isEmpty ? 1 : prefs.map((p) => p.count).reduce(math.max);

    return Material(
      color: Colors.white,
      child: Container(
        width: 360,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appLoc.s_e97565e5,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20))),
            const SizedBox(height: 4),
            Text(appLoc.s_d9579b73(rangeLabel: rangeLabel, bookCount: bookCount),
                style: const TextStyle(fontSize: 12, color: Colors.black54)),

            if (tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(appLoc.s_bfc50de8,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t.text,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF2E7D32))),
                    ),
                ],
              ),
            ],

            if (prefs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(appLoc.s_ab5cc063,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 10),
              for (var i = 0; i < prefs.length && i < 8; i++) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(categoryLabel(prefs[i].label),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: prefs[i].count / maxCount,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor:
                              AlwaysStoppedAnimation(chartColorAt(i, context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${prefs[i].count}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.menu_book, size: 14, color: Colors.black38),
                const SizedBox(width: 6),
                Text(appLoc.s_9de44e0f,
                    style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
