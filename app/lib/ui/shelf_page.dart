import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'book_detail_page.dart';

/// 排序方式 → SQL orderBy
enum ShelfSort {
  updated('最近更新', 'updatedAt DESC'),
  finished('最近读完', 'finishedAt DESC'),
  rating('评分最高', 'rating DESC'),
  progress('进度最深', 'progressPercent DESC'),
  title('书名升序', 'title ASC');

  final String label;
  final String orderBy;
  const ShelfSort(this.label, this.orderBy);
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
        title: const Text('书架'),
        actions: [
          PopupMenuButton<ShelfSort>(
            tooltip: '排序',
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
            tooltip: _grid ? '切换为列表' : '切换为封面网格',
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
                hintText: '搜索书名 / 作者 / 出版社',
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
                    child: Text(_hasFilter ? '没有符合筛选条件的书' : '还没有书，去「导入」页添加吧'),
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
          Text('共 ${books.length} 本',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Text('在读 $reading · 已读 $finished',
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
          _chip('全部', !_hasFilter, () {
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
                    : (_category ?? '更多筛选'),
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
              const Text('来源平台', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('全部', style: TextStyle(fontSize: 12)),
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
              const Text('分类', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                const Text('暂无分类数据', style: TextStyle(fontSize: 12))
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
                          label: const Text('全部', style: TextStyle(fontSize: 12)),
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
                      child: const Text('重置'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('应用'),
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

/// 网络封面底座。
///
/// 列表与网格共用：断网、封面链接失效、书籍本身就没有封面，
/// 三种情况都会走到占位块，不能各有各的画法。
class _Cover extends StatelessWidget {
  final Book book;
  final double radius;

  const _Cover({required this.book, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    final url = book.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(context),
              loadingBuilder: (ctx, child, p) =>
                  p == null ? child : _placeholder(context),
            )
          : _placeholder(context),
    );
  }

  /// 占位封面：用书名哈希取一个稳定颜色，再放首字。
  ///
  /// 比统一的灰块好认得多——一眼能分辨出「这本和那本不是一个东西」，
  /// 也不会因为颜色随机而在每次重建时闪来闪去。
  Widget _placeholder(BuildContext context) {
    final h = book.title.hashCode.abs();
    final hue = (h % 360).toDouble();
    final base = HSLColor.fromAHSL(1, hue, 0.28, 0.72).toColor();
    final fg = HSLColor.fromAHSL(1, hue, 0.45, 0.28).toColor();
    final chars = book.title.replaceAll(RegExp(r'[《》「」]'), '');
    return Container(
      color: base,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Text(
        chars.isEmpty ? '?' : chars.substring(0, chars.length >= 2 ? 2 : 1),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: 15,
          height: 1.15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
                _Cover(book: book),
                if (showBadge)
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
                            ? '已读完'
                            : '${progress.toStringAsFixed(progress < 10 ? 1 : 0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                if (book.rating > 0)
                  Positioned(
                    right: 3,
                    top: 3,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
        child: _Cover(book: book, radius: 4),
      ),
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (book.authors.isNotEmpty) book.authors.join('、'),
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
                  child: _badge(context, book.categoryPrimary!, cs.secondaryContainer,
                      cs.onSecondaryContainer),
                ),
              ],
              if (book.daysUntilDue != null && book.daysUntilDue! <= 3) ...[
                const SizedBox(width: 6),
                _badge(context, '应还 ${book.daysUntilDue} 天', cs.errorContainer, cs.onErrorContainer),
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
