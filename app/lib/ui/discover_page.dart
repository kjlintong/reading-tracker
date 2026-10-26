import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recommendation.dart';
import '../data/recommendation_service.dart';
import '../l10n/app_loc.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../perf.dart';
import '../providers.dart';
import 'book_cover.dart';

/// 「发现」页：给一个兴趣，排一份书单。
///
/// ## 两种来源
///
/// 顶部两个分段切换：**我的书架** 与 **联网**。
///
/// 联网内部具体走哪条路（大模型 / 微信读书 / 搜索）由 App 自己决定，
/// 用户不需要知道也不用管——他配了哪个 Key 就走哪条。
/// 一个凭据都没有时联网置灰，并给一个「去设置」的入口，
/// 而不是让用户对着一个点不动的按钮猜。
///
/// ## 每条推荐给两样东西
///
/// 除了书名与作者，还给**一句话介绍**和**建议的阅读顺序**。
/// 只给书名的书单用户无从判断该不该读；给出顺序则可以照着读。
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _ctrl = TextEditingController();

  RecommendSource _source = RecommendSource.shelf;
  bool _busy = false;
  bool _loaded = false;
  String? _error;
  List<Recommendation> _items = const [];
  final Set<int> _selected = {};

  /// 书单的**总体介绍 / 选书指南**。
  ///
  /// 联网档由大模型写——它知道这批书之间是什么关系（两条线？先读哪本？）。
  /// 书架档没有模型，用本地固定文案。
  ///
  /// 没有它，书单只是一列书名：用户看得到书，却不知道该从哪本开始。
  String _guide = '';

  /// 入库成功后的提示小字。3 秒后自动消失。
  ///
  /// 不用 SnackBar：它跨页留存、2 秒就消失，用户往往来不及看。
  /// 写在页面里更稳（见记忆里的「SnackBar 不可用于确认反馈」）。
  String? _notice;

  @override
  void initState() {
    super.initState();
    perfMark('Discover.initState');
    // 进页面就出第一档的结果：用户是来看书的，等他点一下才出结果
    // 等于多一次无谓的空白。
    //
    // 放在**下一帧**而不是立刻：首帧要先把这个页面画出来，
    // 查询跟着挤在首帧里做，转场动画就会被拖住（真机上卡一秒）。
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    perfMark('Discover.dispose');
    _ctrl.dispose();
    super.dispose();
  }

  RecommendationService get _svc => ref.read(recommendationServiceProvider);

  Future<void> _refresh() async {
    if (_busy) return;
    perfMark('Discover.refresh.start');
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final bundle = await _svc.recommend(
        _source,
        keyword: _ctrl.text.trim(),
      );
      perfMark('Discover.refresh.done');
      if (!mounted) return;
      setState(() {
        _items = bundle.items;
        _guide = bundle.intro;
        _selected.clear();
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loaded = true;
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switchSource(RecommendSource s) {
    if (_source == s) return;
    setState(() {
      _source = s;
      _items = const [];
      _guide = '';
      _loaded = false;
      _error = null;
      _notice = null;
      _selected.clear();
    });
    _refresh();
  }

  /// 把勾选的书加入书架。
  ///
  /// 入库后**从列表里移除**这些条目——它们已经在书架里了，
  /// 还留在推荐列表里会被再次勾选、再次入库。
  Future<void> _addSelected() async {
    if (_selected.isEmpty) return;
    final picked = <int>[
      for (var i = 0; i < _items.length; i++)
        if (_selected.contains(i)) i,
    ];
    if (picked.isEmpty) return;

    final repo = ref.read(repoProvider);
    var added = 0;
    for (final i in picked) {
      final r = _items[i];
      // 书架里已有的书（书架那档的推荐）不能再插一条——那会造出重复记录。
      if (r.alreadyInShelf) continue;
      final b = r.book;
      if (b.title.trim().isEmpty) continue;
      // 归一化统一收口：外部来源的分类先折成受控词表。
      // copyWith 改不了 id 与时间戳，所以直接构造新 Book。
      final now = DateTime.now().toUtc().toIso8601String();
      await repo.insert(Book(
        id: 'rec_${DateTime.now().microsecondsSinceEpoch}_${b.title.hashCode}',
        title: b.title,
        subtitle: b.subtitle,
        authors: b.authors,
        translators: b.translators,
        publisher: b.publisher,
        publishedAt: b.publishedAt,
        isbn13: b.isbn13,
        coverUrl: b.coverUrl,
        categoryPrimary: normalizeCategory(b.categoryRaw),
        categoryRaw: b.categoryRaw,
        tags: b.tags,
        description: b.description,
        language: b.language,
        pageCount: b.pageCount,
        format: b.format,
        source: b.source,
        status: BookStatus.wish,
        createdAt: now,
        updatedAt: now,
      ));
      added++;
    }
    if (!mounted) return;

    // 移除已入库的条目，重新编号选中集合。
    final removed = picked.toSet();
    setState(() {
      final kept = <Recommendation>[];
      final remap = <int, int>{};
      for (var i = 0; i < _items.length; i++) {
        if (removed.contains(i)) continue;
        remap[i] = kept.length;
        kept.add(_items[i]);
      }
      _items = kept;
      _selected
        ..clear()
        ..addAll(remap.entries
            .where((e) => _selected.contains(e.key))
            .map((e) => e.value));
      _notice = appLoc.discoverAdded(n: added);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = ref.watch(recommendationServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(appLoc.discoverTitle)),
      body: Column(
        children: [
          _intro(cs),
          _sourceBar(svc, cs),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _refresh(),
                    decoration: InputDecoration(
                      hintText: appLoc.discoverKeywordHint,
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _busy ? null : _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: appLoc.discoverRefresh,
                ),
              ],
            ),
          ),
          if (_notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    _notice!,
                    style: TextStyle(fontSize: 12.5, color: cs.primary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(child: _body(svc, cs)),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: _addSelected,
                  child: Text(appLoc.discoverAddSelected(n: _selected.length)),
                ),
              ),
            ),
    );
  }

  /// 顶部那句说明。
  ///
  /// 这个页面叫「发现」，光看名字不知道能干什么。
  /// 一句话把「说出你感兴趣的东西 → 得到一份排好序的书单」讲清楚，
  /// 比任何引导教程都省事。
  Widget _intro(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              appLoc.discoverIntro,
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  /// 两个来源的分段按钮。
  Widget _sourceBar(RecommendationService svc, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(RecommendSource.shelf, true),
              const SizedBox(width: 8),
              _chip(RecommendSource.online,
                  svc.available(RecommendSource.online)),
            ],
          ),
          // 联网不可用时，**置灰之外还得说清楚缺什么**。
          // 只放一个点不动的按钮，用户会以为功能坏了。
          if (!svc.available(RecommendSource.online)) _needConfig(cs),
        ],
      ),
    );
  }

  Widget _chip(RecommendSource s, bool ok) {
    final selected = _source == s;
    return Opacity(
      opacity: ok ? 1 : 0.45,
      child: ChoiceChip(
        selected: selected,
        onSelected: ok ? (_) => _switchSource(s) : null,
        label: Text(_sourceLabel(s)),
        avatar: Icon(_sourceIcon(s), size: 16),
      ),
    );
  }

  /// 联网不可用时的提示行。
  ///
  /// 只置灰不解释，用户会以为功能坏了。
  /// 给一句「缺什么」+ 一个直达设置的按钮，用户才知道下一步做什么。
  Widget _needConfig(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.key_off_outlined, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                appLoc.discoverNeedConfig,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: _goSettings,
              child: Text(appLoc.discoverGoSettings),
            ),
          ],
        ),
      ),
    );
  }

  /// 跳到设置栏。
  ///
  /// 先把底部导航切到设置，再关掉本页——
  /// 顺序反了的话，关掉本页时 HomeShell 还没重建，用户看到的仍是旧栏。
  void _goSettings() {
    ref.read(homeTabProvider.notifier).state = HomeTabs.settings;
    Navigator.of(context).pop();
  }

  String _sourceLabel(RecommendSource s) => switch (s) {
        RecommendSource.shelf => appLoc.discoverSourceShelf,
        RecommendSource.online => appLoc.discoverSourceOnline,
      };

  IconData _sourceIcon(RecommendSource s) => switch (s) {
        RecommendSource.shelf => Icons.local_library_outlined,
        RecommendSource.online => Icons.travel_explore,
      };

  Widget _body(RecommendationService svc, ColorScheme cs) {
    if (_busy && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              appLoc.discoverLoading,
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return _message(cs, Icons.error_outline, _error!);
    }
    if (!_loaded) {
      return const SizedBox.shrink();
    }
    if (_items.isEmpty) {
      return _message(cs, Icons.inbox_outlined, appLoc.discoverEmpty);
    }
    return _list(cs);
  }

  /// 要显示的导语。
  ///
  /// 联网档用模型写的那段；模型没写就退回本地文案。
  /// 书架档没有模型，永远用本地文案。
  String get _introText {
    final t = _guide.trim();
    if (t.isNotEmpty) return t;
    if (_source == RecommendSource.shelf) return appLoc.discoverShelfIntro;
    return '';
  }

  /// 书单正文。
  ///
  /// 自上而下四层：
  ///   1. **总体介绍**——一段选书指南（模型写的），告诉用户这批书怎么读；
  ///   2. 「建议按这个顺序读」——只在联网档出现。书架档的顺序是
  ///      「最近加入的」，说成阅读顺序是误导；
  ///   3. 分段标题——「你书架上已有的」+ 模型给的分组（如「零基础通俗入门」）；
  ///   4. 逐条推荐。
  ///
  /// 一次构建全部行（最多十几条），不做懒加载——
  /// 这个量级下懒加载只会换来「滑动时白一下」的小毛病。
  Widget _list(ColorScheme cs) {
    final rows = <Widget>[];

    final intro = _introText;
    if (intro.isNotEmpty) rows.add(_introCard(intro, cs));

    if (_source == RecommendSource.online) {
      rows.add(_orderHint(cs));
    }

    var localHeaderShown = false;
    String? lastGroup;
    for (var i = 0; i < _items.length; i++) {
      final r = _items[i];
      final picked = _selected.contains(i);
      if (r.alreadyInShelf) {
        // 联网档里的「你已有的那几本」，单独起一段。
        // 书架档整档都是书架里的书，不需要这个标题。
        if (_source == RecommendSource.online && !localHeaderShown) {
          rows.add(_groupTitle(appLoc.discoverLocalGroup, cs));
          localHeaderShown = true;
        }
      } else {
        final g = r.group;
        if (g != null && g != lastGroup) {
          rows.add(_groupTitle(g, cs));
          lastGroup = g;
        }
      }
      rows.add(_tile(r, picked, () {
        // 已在书架的书不能入库，点了没反应等于坏了——直接不响应。
        if (r.alreadyInShelf) return;
        setState(() {
          if (!picked) {
            _selected.add(i);
          } else {
            _selected.remove(i);
          }
        });
      }));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: rows,
    );
  }

  /// 总体介绍卡片。
  ///
  /// 左边一道主色竖条：它是「导读」不是「一条推荐」，
  /// 竖条能把两者的视觉层级分开。
  Widget _introCard(String text, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: cs.primary, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 15, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 「建议按这个顺序读」提示。
  Widget _orderHint(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.format_list_numbered, size: 15, color: cs.primary),
          const SizedBox(width: 5),
          Text(
            appLoc.discoverOrderHint,
            style: TextStyle(fontSize: 12, color: cs.primary),
          ),
        ],
      ),
    );
  }

  /// 分段标题。
  Widget _groupTitle(String text, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 0, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _message(ColorScheme cs, IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34, color: cs.onSurfaceVariant),
              const SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );

  Widget _tile(Recommendation r, bool picked, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    final b = r.book;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _orderBadge(r.order, cs),
                const SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  height: 64,
                  child: BookCover(book: b, radius: 4, placeholderFontSize: 13),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title,
                        // 书名 key：封面占位块里也会画一遍书名，
                        // 测试要能精确指到标题这一行。
                        key: ValueKey('rec_title_${b.title}'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (b.authors.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          b.authors.join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                        ),
                      ],
                      if (r.reason.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.reason.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ] else if (r.alreadyInShelf &&
                          r.source == RecommendSource.shelf) ...[
                        const SizedBox(height: 4),
                        Text(
                          appLoc.discoverFromShelf,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                      // 联网档里的本地书要标出来：它跟「建议再读」的那些
                      // 不是一回事——这本你已经买了。
                      if (r.alreadyInShelf &&
                          r.source == RecommendSource.online) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              appLoc.discoverInShelf,
                              style: TextStyle(
                                  fontSize: 11, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (r.alreadyInShelf)
                  // 已在书架的书不可入库（那会造出重复记录），
                  // 用一个静态标记说明它为什么不勾选。
                  Icon(Icons.check, size: 20, color: cs.onSurfaceVariant)
                else
                  Icon(
                    picked ? Icons.check_circle : Icons.add_circle_outline,
                    color: picked ? cs.primary : cs.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 阅读顺序的序号徽章。
  ///
  /// 放在封面左边而不是标题前面：标题前的数字会跟书名挤在一起，
  /// 徽章则像一个独立的标记，一眼能扫到「这是第几本」。
  Widget _orderBadge(int order, ColorScheme cs) {
    if (order <= 0) return const SizedBox(width: 20);
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$order',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.onPrimary,
        ),
      ),
    );
  }
}
