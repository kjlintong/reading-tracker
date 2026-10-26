import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recommendation.dart';
import '../data/recommendation_service.dart';
import '../l10n/app_loc.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'book_cover.dart';

/// 推荐书单页。
///
/// ## 四档书源
///
/// 顶部四个分段按钮切换来源。档位不同，**需要的东西也不同**：
/// 本地书架那一档零凭据永远可用，其余三档分别要微信读书 Key、
/// 大模型 Key、搜索 Key + 大模型 Key。
///
/// 不可用的档位**显示出来但置灰**并说明缺什么，而不是直接隐藏——
/// 隐藏的话用户根本不知道 App 还有这个功能，只会觉得「怎么只有三种推荐」。
class RecommendPage extends ConsumerStatefulWidget {
  const RecommendPage({super.key});

  @override
  ConsumerState<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends ConsumerState<RecommendPage> {
  final _ctrl = TextEditingController();

  RecommendSource _source = RecommendSource.shelfUnread;
  bool _busy = false;
  bool _loaded = false;
  String? _error;
  List<Recommendation> _items = const [];
  final Set<int> _selected = {};

  /// 入库成功后的提示小字。3 秒后自动消失。
  ///
  /// 不用 SnackBar：它跨页留存、2 秒就消失，用户往往来不及看。
  /// 写在页面里更稳（见记忆里的「SnackBar 不可用于确认反馈」）。
  String? _notice;

  @override
  void initState() {
    super.initState();
    // 进页面就出第一档的结果：用户是来看书的，等他点一下才出结果
    // 等于多一次无谓的空白。
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  RecommendationService get _svc => ref.read(recommendationServiceProvider);

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final items = await _svc.recommend(
        _source,
        keyword: _ctrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _items = items;
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
      // 书架里已有的书（档①的推荐）不能再插一条——那会造出重复记录。
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
      _notice = appLoc.recommendAdded(n: added);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = ref.watch(recommendationServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(appLoc.recommendTitle)),
      body: Column(
        children: [
          _sourceBar(svc),
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
                      hintText: appLoc.recommendKeywordHint,
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
                  tooltip: appLoc.recommendRefresh,
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
                  child: Text(appLoc.recommendAddSelected(n: _selected.length)),
                ),
              ),
            ),
    );
  }

  /// 四个档位的分段按钮。
  Widget _sourceBar(RecommendationService svc) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final s in RecommendSource.values) ...[
            _chip(s, svc.available(s)),
            const SizedBox(width: 8),
          ],
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

  String _sourceLabel(RecommendSource s) => switch (s) {
        RecommendSource.shelfUnread => appLoc.recommendSourceShelf,
        RecommendSource.llm => appLoc.recommendSourceLlm,
        RecommendSource.weread => appLoc.recommendSourceWeread,
        RecommendSource.search => appLoc.recommendSourceSearch,
      };

  IconData _sourceIcon(RecommendSource s) => switch (s) {
        RecommendSource.shelfUnread => Icons.local_library_outlined,
        RecommendSource.llm => Icons.auto_awesome,
        RecommendSource.weread => Icons.menu_book,
        RecommendSource.search => Icons.travel_explore,
      };

  Widget _body(RecommendationService svc, ColorScheme cs) {
    if (_busy && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _message(cs, Icons.error_outline, _error!);
    }
    if (!_loaded) {
      return const SizedBox.shrink();
    }
    if (_items.isEmpty) {
      return _message(cs, Icons.inbox_outlined, appLoc.recommendEmpty);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _items.length,
      itemBuilder: (ctx, i) {
        final r = _items[i];
        final picked = _selected.contains(i);
        return _tile(r, picked, () {
          // 已在书架的书不能入库，点了没反应等于坏了——直接不响应。
          if (r.alreadyInShelf) return;
          setState(() {
            if (!picked) {
              _selected.add(i);
            } else {
              _selected.remove(i);
            }
          });
        });
      },
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
                      if (r.reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.reason,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
}
