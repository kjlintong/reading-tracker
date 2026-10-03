import 'package:flutter/material.dart';
import '../l10n/app_loc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'book_detail_page.dart';
import 'add_book_sheet.dart';
import 'book_cover.dart';

/// 排序方式 → SQL orderBy
///
/// 显示名不能放进枚举构造函数：枚举常量的实参必须是编译期常量，
/// 而 `appLoc.*` 是运行时取值。所以只把 orderBy 存为字段，label 用 getter 算。
enum ShelfSort {
  updated('updatedAt DESC'),
  finished('finishedAt DESC'),
  rating('rating DESC'),
  progress('progressPercent DESC'),
  title('title ASC');

  final String orderBy;
  const ShelfSort(this.orderBy);

  String get label => switch (this) {
        ShelfSort.updated => appLoc.s_9b3c95d4,
        ShelfSort.finished => appLoc.s_97428491,
        ShelfSort.rating => appLoc.s_8f38c041,
        ShelfSort.progress => appLoc.s_50a7317f,
        ShelfSort.title => appLoc.s_b5538557,
      };
}

/// 书架页：网格 / 列表双视图 + 状态、来源、分类筛选 + 搜索 + 排序
class ShelfPage extends ConsumerStatefulWidget {
  const ShelfPage({super.key});

  @override
  ConsumerState<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends ConsumerState<ShelfPage> {
  BookStatus? _status;
  BookSource? _source;
  String? _category;
  ShelfSort _sort = ShelfSort.updated;
  bool _grid = true;
  String _keyword = '';
  final _searchCtrl = TextEditingController();

  /// 查询结果缓存为 state 字段。
  ///
  /// 不要在 build 里直接写 `future: _load()`：那样每次重建都会生成新 Future，
  /// FutureBuilder 识别到 future 变化会重新订阅并再次触发重建，
  /// 结果是界面永远停在 loading（真机上表现为书架一直转圈）。
  late Future<List<Book>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// 筛选条件变化后主动重查
  ///
  /// 注意：不能在 setState 回调里直接写 `_future = _load()` —— 箭头函数会把
  /// Future 作为返回值交出去，而 setState 的回调必须同步返回 void，
  /// 否则框架会抛 "setState() callback argument returned a Future"，
  /// 状态更新整段失效（表现就是搜索框输入后列表纹丝不动）。
  void _reload() {
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  /// 添加图书：升起底部抽屉，列出全部入库方式。
  ///
  /// 抽屉自己负责写入与成功提示；这里只负责「回来后刷新列表」。
  /// 不在这里做插入，是因为能加书进来的路径有七条（手填 / 截图 / 拍照 /
  /// 渠道同步 / 进度同步 / CSV / Goodreads / 书库搜索），
  /// 把插入逻辑摊在这一层会让每条路径各写一遍刷新。
  Future<void> _addBook() async {
    await showAddBookSheet(context);
    // 无条件重查：抽屉里可能加了好几本才关，也可能一本没加。
    // 一次 SQLite 查询远比漏刷一个新入库的书便宜。
    if (mounted) _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Book>> _load() {
    return ref.read(repoProvider).all(
          status: _status,
          source: _source,
          category: _category,
          keyword: _keyword.isEmpty ? null : _keyword,
          orderBy: _sort.orderBy,
        );
  }

  bool get _hasFilter =>
      _status != null || _source != null || _category != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(appLoc.s_296fc9b4),
        actions: [
          // 这里是**全部**入库方式的唯一入口：点开是底部抽屉，里面既有
          // 手动填写，也有截图 / 拍照 / 渠道同步 / CSV / 公开书库搜索。
          // 所以 tooltip 用中性的「添加图书」，不再叫「手动添加图书」——
          // 后者会让只用截图的用户以为这个按钮跟他无关。
          IconButton(
            tooltip: appLoc.addBookSheetTitle,
            icon: const Icon(Icons.add),
            onPressed: _addBook,
          ),
          PopupMenuButton<ShelfSort>(
            tooltip: appLoc.s_a444b428,
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (v) {
              _sort = v;
              _reload();
            },
            itemBuilder: (_) => ShelfSort.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                .toList(),
          ),
          IconButton(
            tooltip: _grid ? appLoc.s_fa0a5cdd : appLoc.s_cb4a4231,
            icon: Icon(_grid ? Icons.view_list_outlined : Icons.grid_view_outlined),
            onPressed: () => setState(() => _grid = !_grid),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: appLoc.s_78966c42,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              onChanged: (v) {
                _keyword = v.trim();
                _reload();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Book>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final books = snap.data ?? [];
                if (books.isEmpty) {
                  return Center(
                    child: Text(_hasFilter ? appLoc.s_8ed41c6c : appLoc.s_bd33274a),
                  );
                }
                return Column(
                  children: [
                    _summary(books),
                    Expanded(
                      child: _grid ? _gridView(books) : _listView(books),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(List<Book> books) {
    final cs = Theme.of(context).colorScheme;
    final reading = books.where((b) => b.status == BookStatus.reading).length;
    final finished = books.where((b) => b.status == BookStatus.finished).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Text(appLoc.s_0cd6d0f8(length: books.length),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Text(appLoc.s_ff7e02df(reading: reading, finished: finished),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(_sort.label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _gridView(List<Book> books) {
    return LayoutBuilder(
      builder: (context, c) {
        // 按可用宽度决定列数：手机上通常 3 列，平板上自动变多，
        // 写死列数在窄屏上封面会小到看不清书名
        final columns = (c.maxWidth / 116).floor().clamp(2, 6);
        const gap = 10.0;
        const pad = 12.0;
        final cellW = (c.maxWidth - pad * 2 - gap * (columns - 1)) / columns;
        // 封面按 3:4 预留给文字块固定高度，剩余空间由封面自己消化——
        // 直接算一个固定比例会在窄屏上把书名挤出去
        final ratio = cellW / (cellW * 1.42 + 50);

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(pad, 4, pad, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: 14,
            childAspectRatio: ratio,
          ),
          itemCount: books.length,
          itemBuilder: (context, i) => _GridCell(
            book: books[i],
            onTap: () => _open(books[i]),
          ),
        );
      },
    );
  }

  Widget _listView(List<Book> books) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _BookTile(
        book: books[i],
        onTap: () => _open(books[i]),
      ),
    );
  }

  Future<void> _open(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailPage(bookId: book.id)),
    );
    // 详情页可能改了状态/评分，返回后重查
    _reload();
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _chip(appLoc.s_68022ee7, !_hasFilter, () {
            _status = null;
            _source = null;
            _category = null;
            _reload();
          }),
          ...BookStatus.values.map((s) => _chip(
                s.label,
                _status == s,
                () {
                  _status = _status == s ? null : s;
                  _reload();
                },
              )),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: Icon(
                _source != null || _category != null
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                size: 16,
              ),
              label: Text(
                _source != null
                    ? BookSource.fromString(_source!.name).label
                    : (_category ?? appLoc.s_542b67cc),
                style: const TextStyle(fontSize: 13),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: _openFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  /// 来源与分类放到弹层里：品类有 20 个、平台有 7 个，
  /// 全铺在顶部横向条里会把状态筛选挤没
  Future<void> _openFilterSheet() async {
    final repo = ref.read(repoProvider);
    final categories = await repo.categoryDistribution();
    if (!mounted) return;

    var source = _source;
    var category = _category;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(appLoc.s_ec977df0, style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label:  Text(appLoc.s_68022ee7, style: TextStyle(fontSize: 12)),
                    selected: source == null,
                    onSelected: (_) => setSheet(() => source = null),
                  ),
                  ...BookSource.values.map((s) => ChoiceChip(
                        label: Text(s.label, style: const TextStyle(fontSize: 12)),
                        selected: source == s,
                        onSelected: (_) =>
                            setSheet(() => source = source == s ? null : s),
                      )),
                ],
              ),
              const SizedBox(height: 16),
               Text(appLoc.s_b32f0afe, style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                 Text(appLoc.s_9fe34cff, style: TextStyle(fontSize: 12))
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.35,
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label:  Text(appLoc.s_68022ee7, style: TextStyle(fontSize: 12)),
                          selected: category == null,
                          onSelected: (_) => setSheet(() => category = null),
                        ),
                        ...categories.map((c) => ChoiceChip(
                              label: Text(
                                '${c['name']} ${c['c']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: category == c['name'],
                              onSelected: (_) => setSheet(
                                  () => category = category == c['name'] ? null : c['name'] as String),
                            )),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setSheet(() {
                        source = null;
                        category = null;
                      }),
                      child:  Text(appLoc.s_50d471b2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child:  Text(appLoc.s_fe93ef35),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (applied == true) {
      _source = source;
      _category = category;
      _reload();
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 13)),
        selected: selected,
        onSelected: (_) => onTap(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/* ------------------------------ 封面 ------------------------------ */

// 封面实现已抽到 ui/book_cover.dart（BookCover）。书架与详情页原本
// 各写了一份，且都只判 coverUrl，导致用户选的本地封面永远显示不出来。
// 现在两处共用一套「本地 > 远程 > 占位」的优先级与降级链。

/// 网格单元：封面 + 进度角标 + 书名
class _GridCell extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _GridCell({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = book.progressPercent;
    final showBadge = book.status == BookStatus.reading ||
        book.status == BookStatus.finished;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                BookCover(book: book),                if (showBadge)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(6)),
                      ),
                      child: Text(
                        book.status == BookStatus.finished
                            ? appLoc.s_44c14529
                            : '${progress.toStringAsFixed(progress < 10 ? 1 : 0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                // 借阅角标：借来的书和「什么时候该还」是用户必须一眼看到的，
                // 埋在详情页里等于没有提醒
                if (book.isBorrowed)
                  Positioned(
                    right: 3,
                    bottom: 3,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.local_library_outlined,
                          size: 11, color: cs.onTertiaryContainer),
                    ),
                  ),
                if (book.rating > 0)
                  Positioned(
                    right: 3,
                    top: 3,
                    child: Container(
                      padding:                          const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        book.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.25),
            ),
          ),
          SizedBox(
            height: 14,
            child: Text(
              book.authors.isEmpty ? book.status.label : book.authors.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// 列表单元
class _BookTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookTile({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 40,
        height: 56,
        child: BookCover(book: book, radius: 4),
      ),
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (book.authors.isNotEmpty) book.authors.join(appLoc.s_f5d99c16),
              if (book.publisher != null) book.publisher!,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _badge(context, book.status.label, cs.primaryContainer, cs.onPrimaryContainer),
              const SizedBox(width: 6),
              _badge(context, book.source.label, cs.surfaceContainerHighest, cs.onSurfaceVariant),
              if (book.categoryPrimary != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: _badge(context, categoryLabel(book.categoryPrimary!),
                        cs.secondaryContainer,
                      cs.onSecondaryContainer),
                ),
              ],
              if (book.daysUntilDue != null && book.daysUntilDue! <= 3) ...[
                const SizedBox(width: 6),
                _badge(context, appLoc.s_9380d869(daysUntilDue: book.daysUntilDue), cs.errorContainer, cs.onErrorContainer),
              ],
            ],
          ),
          if (book.status == BookStatus.reading) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (book.progressPercent / 100).clamp(0.0, 1.0),
              minHeight: 3,
            ),
          ],
        ],
      ),
      trailing: book.rating > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(book.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12)),
              ],
            )
          : null,
    );
  }

  Widget _badge(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: fg)),
    );
  }
}
