import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'book_detail_page.dart';
import 'plan_section.dart';
import 'theme.dart';

/// 记录页：笔记 + 阅读计划。
///
/// ## 为什么把笔记和阅读计划放在一起
///
/// 两者是同一件事的两面：**笔记是「我已经记下的」，计划是「我打算做的」**，
/// 都挂在书上、都由用户亲手产出、都在动态增长。以前计划被塞进「阅读档案」，
/// 但档案讲的是「我是怎样的读者」（回顾性），而计划讲的是「我接下来读什么」
/// （前瞻性），放进去语义不合；而笔记页当时只有一份笔记流，功能偏弱。
/// 合到一栏后，用户为「记录自己的阅读」只需记住一个入口。
///
/// 排布顺序：**计划在上、笔记在下**。计划是前瞻性的，进门第一眼就该看见
/// 「今天要读什么」；笔记是回顾性的，翻起来没有时效压力。
///
/// ## 两种视图
///
/// - **按时间**：一条倒序的流。回答「最近我记了什么」。
/// - **按书**：按书分组，组内仍按时间倒序。回答「这本书我记了什么」。
///
/// 两者共用同一份查询结果，只是分组方式不同——不做两次查询。
///
/// ## 为什么不在这里做「新增笔记」
///
/// 笔记必须挂在某本书上，脱离书籍的笔记没有上下文（不知道是哪一页、
/// 哪一章的感想）。所以笔记部分只做**聚合与跳转**，新增入口仍在书籍详情页：
/// 点任意一条笔记都会跳到它的书，用户在那里接着写。
/// 阅读计划则是独立实体，自带新增按钮（见 [PlanSection]）。
class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

/// 笔记页的两种看法。
enum NotesView { time, book }

class _NotesPageState extends ConsumerState<NotesPage> {
  bool _loaded = false;
  NotesView _view = NotesView.time;

  /// 当前筛选的书。`null` = 全部书。
  String? _bookId;

  List<NoteWithBook> _items = const <NoteWithBook>[];

  /// 写过笔记的书，**只用来填筛选下拉**。
  List<Book> _filterBooks = const <Book>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final items = await repo.allNotes(bookId: _bookId);
    final books = await repo.booksWithNotes();
    if (!mounted) return;
    setState(() {
      _items = items;
      _filterBooks = books;
      _loaded = true;
    });
  }

  Future<void> _pickBook(String? bookId) async {
    // 下拉在「选中同一项」时也会回调一次，不判等就会白查一次库，
    // 并且把已经滚到底的列表弹回顶部。
    if (bookId == _bookId) return;
    setState(() => _bookId = bookId);
    await _load();
  }

  void _openBook(String bookId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => BookDetailPage(bookId: bookId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 整页包一层 Material：本页在 HomeShell 里由 Scaffold 提供画布，
    // 但单独渲染（测试 / 未来内嵌到别处）时没有 Material 祖先，
    // 文字会落到 Flutter 的调试样式（红字黄下划线）并衬在黑底上。
    // 加载态同理——转圈也要转在正确的画布颜色上。
    if (!_loaded) {
      return Material(
        // 贴图模式下不能给纸色：这一层铺满整页，铺实了贴图就一点都透不上来。
        // 阅读计划（PlanSection）长在本页，用户报的「计划页没皮肤」就是这里。
        color: skinChromeOf(context).hasBackground
            ? Colors.transparent
            : cs.surface,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // 整页一个 ListView（而不是 Column + Expanded 的列表）：
    // 计划板块与笔记流要一起滚，两者不能再各占一块固定高度。
    // 笔记自己那套「按时间 / 按书」视图仍由内层 ListView 负责，
    // 用 shrinkWrap + NeverScrollableScrollPhysics 把它交给外层滚动，
    // 避免出现「列表套列表、滚动手势打架」的经典问题。
    return Material(
      // 同上：整页画布。贴图皮肤下必须透明，否则本页的所有卡片、计划板块
      // 都压在一层实心纸上，背景等于没开。
      color: skinChromeOf(context).hasBackground
          ? Colors.transparent
          : cs.surface,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // 阅读计划放在最顶上。计划是**前瞻性**的——
            // 「我今天要读什么」进门第一眼就该看见；笔记是回顾性的，
            // 翻起来没有时效压力，放在后面多滚一下无所谓。
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: PlanSection(),
            ),
            // 用一条分隔线划出边界——两块内容形态差别大（卡片 vs 流），
            // 没有界线会读成「计划卡片也是笔记」。
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Divider(height: 1),
            ),
            // 笔记的概览、视图切换与筛选跟着笔记一起滚，
            // 不再钉在页面顶部（计划移到最顶后，它们应属于笔记区）。
            _Header(
              noteCount: _items.length,
              bookCount: _distinctBookCount(),
              view: _view,
              onViewChanged: (v) => setState(() => _view = v),
              filterBookId: _bookId,
              filterBooks: _filterBooks,
              onPickBook: _pickBook,
            ),
            const SizedBox(height: 4),

            if (_items.isEmpty)
              _Empty(
                filtered: _bookId != null,
                onClearFilter: () => _pickBook(null),
              )
            else if (_view == NotesView.time)
              _TimeList(items: _items, onTap: _openBook)
            else
              _BookGroups(items: _items, onTap: _openBook),
          ],
        ),
      ),
    );
  }

  /// 覆盖了几本书。按 `bookId` 去重——同一本书写了 5 条笔记也只算 1 本，
  /// 否则「覆盖 X 本书」会退化成「写了 X 条笔记」的重复计数，一眼假。
  int _distinctBookCount() => _items.map((e) => e.note.bookId).toSet().length;
}

/// 笔记概览区：概览 + 视图切换 + 按书筛选。
///
/// 现在放在笔记列表上方、随列表一起滚：计划移到最顶之后，
/// 这一块应属于「笔记」部分，而不是钉在整页顶部压住计划。
class _Header extends StatelessWidget {
  const _Header({
    required this.noteCount,
    required this.bookCount,
    required this.view,
    required this.onViewChanged,
    required this.filterBookId,
    required this.filterBooks,
    required this.onPickBook,
  });

  final int noteCount;
  final int bookCount;
  final NotesView view;
  final ValueChanged<NotesView> onViewChanged;
  final String? filterBookId;
  final List<Book> filterBooks;
  final ValueChanged<String?> onPickBook;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final cs = Theme.of(context).colorScheme;

    // 外层用 Material 而不是 Container：下面的 DropdownButtonFormField
    // 要求祖先里有 Material 组件（它要靠 Material 画墨迹展开动效）。
    // 线上这一页是 Scaffold 的 body，Scaffold 自带 Material，所以不会报错；
    // 但「只在 Scaffold 里能用」是个潜伏的坑——一旦有人把它放进对话框
    // 或独立路由就会崩。让页面自带 Material，代价为零。
    return Material(
      color: skinChromeOf(context).hasBackground
          ? Colors.transparent
          : cs.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.notesOverview(count: noteCount, books: bookCount),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
              // SegmentedButton 自带选中态与无障碍语义，
              // 比自己拼两个 TextButton 更省事也更正确。
              SegmentedButton<NotesView>(
                segments: [
                  ButtonSegment<NotesView>(
                    value: NotesView.time,
                    icon: const Icon(Icons.schedule_outlined, size: 16),
                    label: Text(l10n.notesViewByTime),
                  ),
                  ButtonSegment<NotesView>(
                    value: NotesView.book,
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(l10n.notesViewByBook),
                  ),
                ],
                selected: <NotesView>{view},
                onSelectionChanged: (s) => onViewChanged(s.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // 按书筛选。**只列出写过笔记的书**——把 38 本一条笔记都没有的
              // 书塞进下拉，点进去全是空态，等于给用户造一个会失望的入口。
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: filterBookId,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    border: const OutlineInputBorder(),
                    labelText: l10n.notesFilterByBook,
                  ),
                  items: <DropdownMenuItem<String?>>[
                    DropdownMenuItem<String?>(
                      value: null,
                      child:
                          Text(l10n.notesAllBooks, overflow: TextOverflow.ellipsis),
                    ),
                    ...filterBooks.map(
                      (b) => DropdownMenuItem<String?>(
                        value: b.id,
                        child:
                            Text(b.title, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onPickBook,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// 按时间：一条倒序的笔记流。
///
/// `shrinkWrap` + `NeverScrollableScrollPhysics`：这一层已经嵌在外层
/// ListView 里（它下面还挂着阅读计划），自己不能再滚——
/// 否则内层吃掉手势，用户永远滚不到计划板块。
class _TimeList extends StatelessWidget {
  const _TimeList({required this.items, required this.onTap});

  final List<NoteWithBook> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) =>
          _NoteCard(item: items[i], onTap: onTap, showBook: true),
    );
  }
}

/// 按书：每本书一张卡片，卡内收该书笔记。
///
/// 分组顺序沿用 `allNotes` 的时间倒序，因此自然落在
/// 「最近动过笔的书排最上面」——与按时间视图的观感一致。
class _BookGroups extends StatelessWidget {
  const _BookGroups({required this.items, required this.onTap});

  final List<NoteWithBook> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final groups = <String, List<NoteWithBook>>{};
    final order = <String>[];
    for (final it in items) {
      final key = it.note.bookId;
      if (groups[key] == null) {
        groups[key] = <NoteWithBook>[];
        order.add(key);
      }
      groups[key]!.add(it);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      itemCount: order.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final list = groups[order[i]]!;
        final book = list.first.book;
        return _BookCard(
          title: book?.title ?? l10n.notesBookMissing,
          author: (book?.authors ?? const <String>[]).join(' · '),
          notes: list,
          onOpenBook: () => onTap(order[i]),
        );
      },
    );
  }
}

/// 每本书最多预览几条笔记，超出的折叠成一行「还有 N 条」。
///
/// 上限 3 条是按小屏估的：再多就要滑过好几屏才能看到下一本书，
/// 「按书」这个视图的意义（快速扫过多本书）就没了。
const int _previewCount = 3;

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.title,
    required this.author,
    required this.notes,
    required this.onOpenBook,
  });

  final String title;
  final String author;
  final List<NoteWithBook> notes;
  final VoidCallback onOpenBook;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final shown = notes.take(_previewCount).toList();
    final rest = notes.length - shown.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenBook,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 16),
                  const SizedBox(width: 6),
                  // Expanded 必须包住标题：书名长到一定程度时，
                  // 不参与收缩的 Text 会把整行撑爆——本项目在画像页的
                  // 区块头部真的踩过这个溢出。
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (author.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          ...shown.map(
            (n) => _NoteCard(
              item: n,
              onTap: (_) => onOpenBook(),
              showBook: false,
              embedded: true,
            ),
          ),
          if (rest > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
              child: Text(
                l10n.notesMoreCount(count: rest),
                style: TextStyle(fontSize: 12, color: cs.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// 单条笔记。
///
/// [embedded] = true 时去掉外框与阴影（已经躺在书的卡片里了），
/// 否则每本书下面会叠三层边框，视觉上糊成一团。
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.item,
    required this.onTap,
    required this.showBook,
    this.embedded = false,
  });

  final NoteWithBook item;
  final ValueChanged<String> onTap;
  final bool showBook;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final cs = Theme.of(context).colorScheme;
    final note = item.note;
    final book = item.book;

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeChip(type: note.type),
              const Spacer(),
              Text(
                _formatDate(note.createdAt),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          if (note.chapter != null && note.chapter!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note.chapter!,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
          if (showBook) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    book?.title ?? l10n.notesBookMissing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (embedded) {
      return InkWell(onTap: () => onTap(note.bookId), child: body);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () => onTap(note.bookId), child: body),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final NoteType type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (type) {
      NoteType.highlight => cs.tertiary,
      NoteType.thought => cs.primary,
      NoteType.review => cs.secondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type.label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 空态。区分两种情况：一本笔记都没有（引导去写），
/// 与筛选后没有结果（引导清除筛选）。
/// 混成一句「暂无数据」，用户就不知道下一步能做什么。
///
/// 现在它躺在可滚动的 ListView 里（下面还接着阅读计划），拿不到
/// 「整屏居中」的高度，所以改用固定上边距把它推到视觉重心附近，
/// 而不是依赖 `Center`——在无界高度里 `Center` 会退化成贴顶。
class _Empty extends StatelessWidget {
  const _Empty({required this.filtered, required this.onClearFilter});

  final bool filtered;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered
                ? Icons.filter_alt_off_outlined
                : Icons.edit_note_outlined,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            filtered ? l10n.notesEmptyFilteredTitle : l10n.notesEmptyTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            filtered ? l10n.notesEmptyFilteredDesc : l10n.notesEmptyDesc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          if (filtered) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onClearFilter,
              child: Text(l10n.notesClearFilter),
            ),
          ],
        ],
      ),
    );
  }
}

/// `createdAt` 是 ISO 8601 字符串。只取日期部分——
/// 笔记不需要精确到秒，多出来的 `T14:32:07.000Z` 只会让行尾变吵。
String _formatDate(String iso) {
  final s = iso.trim();
  if (s.length >= 10) return s.substring(0, 10);
  return s;
}
