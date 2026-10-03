import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_loc.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'book_cover.dart';
import 'book_detail_page.dart';
import 'palette.dart';

/// 阅历：按月排布的阅读看板。
///
/// **为什么需要这一页**。统计页回答的是「加起来是多少」——多少本、多少分钟、
/// 各占比多少。它把一年的阅读压成了几条曲线与几个环，信息量很大，但
/// 看的人会在某个瞬间发现一件事：**书本身消失了**。90 本书变成了「90」。
///
/// 这一页补的就是那个缺口：同样是按月切，但每个月底下摆的是**具体哪几本**。
/// 它不是统计的替代品，是统计的底片——数字对不上时，用户可以在这里
/// 一眼看到「哦，三月那 7 本原来是这些」。
///
/// **为什么是竖向而不是横向的列**（2026-10-02 改）。
/// 初版照搬了 Notion board 的横向列：十二个月并排，左右划。那个形状在
/// 桌面浏览器里很自然，搬到手机上就站不住——一屏只看得到两列出头，
/// 「这一年读了多久」这件事必须靠**反复左右划**才能拼出来，而横向手势
/// 在手机上还容易和返回手势打架。竖着排则天然贴合手机：拇指上下滑，
/// 十二个月一条路走到底，顺序本身就是时间轴。
///
/// **溢出降级：每个月最多摊 4 本，剩下的进二级页**。这是竖排的代价——
/// 横排时「一个月读了 30 本」只让列变长，竖排会让这一个月的块高过整屏，
/// 把后面的月份全挤到很远的地方。所以这里做了一个取舍：
/// 4 本以内（绝大多数人的绝大多数月份）**直接摊开**，一眼看到书名；
/// 超过 4 本时把月度变成 `2×2` 的封面网格 + 一行「另有 N 本」，
/// 点进去看整月。**不丢数据，只是折叠**——想看全的那个月永远点得到。
///
/// **只展示有时间锚点的书**。「已经读完了」（[Book.finishedAt]）与
/// 「正在读」（[Book.startedAt]）都能落到某个月；「想看」和「搁置」
/// 没有锚点，硬塞进某一列只会是编的。它们仍然在统计页的「当前书架」里
/// 有位置，这一页不重复。
class ChronologyPage extends ConsumerStatefulWidget {
  const ChronologyPage({super.key});

  @override
  ConsumerState<ChronologyPage> createState() => _ChronologyPageState();
}

class _ChronologyPageState extends ConsumerState<ChronologyPage> {
  /// 一个月在概览里最多摊开几本。多出来的收进「另有 N 本」。
  ///
  /// 取 4 不是随手定的：4 本按 [ListTile] 的高度算大约 250px，
  /// 一个月 250px、十二个月 3000px——手机上滑个五六屏能看完全年，
  /// 这个量级才叫「概览」。再多就会把「回看一年」变成「翻很长的列表」。
  static const int _previewCap = 4;

  List<Book> _books = const [];
  int _year = DateTime.now().year;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ref.read(repoProvider).all();
    if (!mounted) return;
    setState(() {
      _books = all;
      _loading = false;
    });
  }

  /// 这一年出现过的年份，降序。用来决定左右箭头能不能按。
  List<int> get _years {
    final ys = <int>{};
    for (final b in _books) {
      final y = _anchorYear(b);
      if (y != null) ys.add(y);
    }
    // 当前年份永远可选：用户可能刚装好应用还没读任何书，
    // 此时年份列表为空会让页面看起来像坏了
    ys.add(DateTime.now().year);
    final out = ys.toList()..sort((a, b) => b.compareTo(a));
    return out;
  }

  void _shiftYear(int delta) {
    final ys = _years;
    final i = ys.indexOf(_year);
    final next = i < 0 ? 0 : i - delta; // ys 是降序，所以 delta 取反
    if (next < 0 || next >= ys.length) return;
    setState(() => _year = ys[next]);
  }

  /// 一本书在「阅历」里的时间锚点。
  ///
  /// 已读完的用完成日；否则用开始日。两者都没有就不进看板。
  static DateTime? _anchor(Book b) {
    final raw = b.status == BookStatus.finished
        ? (b.finishedAt ?? b.startedAt)
        : b.startedAt;
    if (raw == null || raw.length < 7) return null;
    // 只取到月：这一页的分辨率就是「月」
    return DateTime.tryParse('${raw.substring(0, 7)}-01');
  }

  static int? _anchorYear(Book b) => _anchor(b)?.year;

  /// 把某一年的书按月份分桶。下标 0 = 一月。
  List<List<Book>> _byMonth(int year) {
    final buckets = List.generate(12, (_) => <Book>[]);
    for (final b in _books) {
      final a = _anchor(b);
      if (a == null || a.year != year) continue;
      buckets[a.month - 1].add(b);
    }
    // 每个月内部：读完的排前面（那才是这个月的「成果」），
    // 同状态按评分降序，最后按书名，保证顺序稳定不跳
    for (final list in buckets) {
      list.sort((a, b) {
        final byStatus = a.status.index.compareTo(b.status.index);
        if (byStatus != 0) return byStatus;
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
        return a.title.compareTo(b.title);
      });
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = S.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final months = _byMonth(_year);
    final total = months.fold<int>(0, (a, m) => a + m.length);
    final years = _years;
    final canPrev = years.isNotEmpty && _year < years.first;
    final canNext = years.isNotEmpty && _year > years.last;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chronology),
        actions: [
          IconButton(
            tooltip: '${_year - 1}',
            icon: const Icon(Icons.chevron_left),
            onPressed: canNext ? () => _shiftYear(-1) : null,
          ),
          Text('$_year',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          IconButton(
            tooltip: '${_year + 1}',
            icon: const Icon(Icons.chevron_right),
            onPressed: canPrev ? () => _shiftYear(1) : null,
          ),
        ],
      ),
      // 竖向滚动的十二个月。整页只有一个滚动方向，拇指一路向下就是一年。
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            total == 0 ? l10n.chronologyEmpty : l10n.chronologyDesc,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < 12; i++) ...[
            const SizedBox(height: 12),
            _monthBlock(context, i, months[i]),
          ],
        ],
      ),
    );
  }

/// 一个月（一块）。
///
/// 块头是「N 月 + 本数」，底下按本数走两种形态：≤ [ChronologyPage._previewCap] 本
/// 一栏一栏摊开（看到书名），超过则降级成封面网格 + 「另有 N 本」。
///
/// 月度的识别色取自共享调色板 [chartColorAt]：同一套色相在统计页、
/// 画像页已经用过，这里复用能让「三月是金色」这件事在不同页面里一致。
  Widget _monthBlock(BuildContext context, int index, List<Book> books) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = chartColorAt(index);
    final monthLabel = appLoc.s_1a2e873e(month: index + 1);

    if (books.isEmpty) {
      // 空月份**不整块消失**，留一行淡淡的占位。
      // 去掉它看着更干净，但十二个月会变成「几个月」，用户没法确认
      // 「三月确实是空的」还是「三月被吞了」——这一页的价值就在完整性。
      return Row(
        children: [
          _MonthDot(accent: accent),
          const SizedBox(width: 8),
          SizedBox(
            width: 52,
            child: Text(
              monthLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Text('—',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      );
    }

    final overflowing = books.length > _previewCap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* --------------------------- 月份表头 --------------------------- */
        Row(
          children: [
            _MonthDot(accent: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                monthLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            Text(
              '${books.length}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        /* ------------------------- 书（两种形态） ------------------------- */
        if (!overflowing)
          for (final b in books)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _BookTile(book: b, accent: accent),
            )
        else
          _MonthGrid(
            books: books.take(_previewCap).toList(),
            all: books,
            accent: accent,
            monthLabel: monthLabel,
          ),
      ],
    );
  }
}

/// 月份前的小圆点：把「这个月是金色」这件事压到一个点上。
///
/// 横排时整列有底色和左边框，识别色铺得开；竖排没有「列」这个概念了，
/// 再用色块会把页面刷成十二道横条，所以只保留一个月色圆点。
class _MonthDot extends StatelessWidget {
  final Color accent;

  const _MonthDot({required this.accent});

  @override
  Widget build(BuildContext context) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      );
}

/// 一本书一行：小封面 + 书名 + 作者 + 状态。
///
/// 点击直接进详情页——看板的用途是「回看 + 顺手改」，如果只能看不能点，
/// 用户看到某本书的评分记错了还得自己回书架找一遍。
class _BookTile extends StatelessWidget {
  final Book book;
  final Color accent;

  const _BookTile({required this.book, required this.accent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.45),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookDetailPage(bookId: book.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 45,
                child:
                    BookCover(book: book, radius: 3, placeholderFontSize: 11),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, height: 1.3, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // 竖排一行有整屏宽，作者放得下；横排的 168px 列里放不下。
                      // 作者为空时不留一串空白，退化成只显示状态。
                      book.authors.isEmpty
                          ? _statusLabel(book.status)
                          : '${book.authors.first} · ${_statusLabel(book.status)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: accent),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: cs.onSurfaceVariant.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  /// 用本页自己的短词，而不是 [BookStatus.label]。
  ///
  /// 这不是改词表——词表（枚举）只有一份，这里只是同一含义在这个
  /// 尺寸下的短写法。状态后面还要跟作者，全称会把一行撑满。
  static String _statusLabel(BookStatus s) => switch (s) {
        BookStatus.finished => appLoc.chronologyFinished,
        BookStatus.reading => appLoc.chronologyReading,
        BookStatus.shelved => appLoc.chronologyShelved,
        BookStatus.wish => appLoc.chronologyWish,
      };
}

/// 一个月超过 [_previewCap] 本时的折叠形态：`2×2` 封面网格 + 「另有 N 本」。
///
/// **为什么是网格而不是继续往下排**：这个分支存在的唯一理由就是「别让它太长」，
/// 再一栏一栏排下去等于没有折叠。换成封面网格后，无论这个月是 5 本还是 30 本，
/// 块高都是固定的那一点——想知道全部是哪几本，点「另有 N 本」进二级页。
///
/// [all] 是**整月**（不只是 [books] 那 4 本），原样交给二级页。
class _MonthGrid extends StatelessWidget {
  final List<Book> books;
  final List<Book> all;
  final Color accent;
  final String monthLabel;

  const _MonthGrid({
    required this.books,
    required this.all,
    required this.accent,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final extra = all.length - books.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, c) {
            // 两列，间距 10。不写 GridView：只有 4 格，用 Wrap 更省事，
            // 也不用再套一层滚动。
            final cell = (c.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final b in books)
                  SizedBox(
                    width: cell,
                    child: _BookCell(book: b, accent: accent),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MonthDetailPage(
                monthLabel: monthLabel,
                books: all,
                accent: accent,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appLoc.chronologyMore(n: extra),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 15, color: accent),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 网格里的一格：封面 + 书名两行。
class _BookCell extends StatelessWidget {
  final Book book;
  final Color accent;

  const _BookCell({required this.book, required this.accent});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BookDetailPage(bookId: book.id)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 42,
            child:
                BookCover(book: book, radius: 3, placeholderFontSize: 11),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5, height: 1.25, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// 某个月的完整列表（二级页）。
///
/// 概览里一个月只摊 [_previewCap] 本，剩下的在这里补全——入口就是那块
/// 「另有 N 本」。**它展示的是整月，不是「剩下的那几本」**：用户点进来的
/// 心理是「看看这个月到底读了什么」，给他一份缺了前四本的清单是错的。
///
/// [books] 由概览页整月传入（已排好序）。不在这里重新查库：查库要重新
/// 解析时间锚点、重新分桶，等于把「哪本书属于这个月」算两遍，
/// 两处一旦有分歧，用户就会看到两个不一样的月份。
class MonthDetailPage extends StatelessWidget {
  final String monthLabel;
  final List<Book> books;
  final Color accent;

  const MonthDetailPage({
    super.key,
    required this.monthLabel,
    required this.books,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(monthLabel),
        // 副标题给出本数，免得用户自己去数
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                '${books.length}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final b in books)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _BookTile(book: b, accent: accent),
            ),
        ],
      ),
    );
  }
}
