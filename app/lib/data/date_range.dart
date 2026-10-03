import '../models/book.dart';
import '../l10n/app_loc.dart';
import '../models/enums.dart';

/// 统计时间范围。
///
/// 原来统计页只有一个隐含的「全部」口径，于是「今年读完几本」这类
/// 最常问的问题反而答不了。
///
/// 这里刻意把**口径说明**（[note]）做成模型的一部分。原因是各数据源的
/// 时间粒度根本不一样：
///   - 书目能精确到天（finishedAt / updatedAt）；
///   - 微信读书的阅读时长只有**整月**粒度（`readTimes` 是逐月秒数）；
///   - 「有阅读记录的天数」只有年度统计给得出，月区间给不出。
///
/// 如果不把这件事写在界面上，用户会以为「近 3 个月读了 12 小时」是精确值，
/// 而它其实是三个整月的数据。数字可以粗，但不能让用户误以为是细的。
class StatsRange {
  final String label;

  /// 含起点。null 表示不限
  final DateTime? from;

  /// **不含**终点（半开区间）。null 表示不限。
  /// 用半开区间是为了让「今年」= `[1/1, 明年1/1)`，
  /// 不会把 12 月 31 日 23:59 的记录漏掉，也不会把明年 1 月 1 日 00:00
  /// 的记录算进来。
  final DateTime? to;

  /// 口径说明，界面直接展示。null 表示无需说明。
  final String? note;

  const StatsRange({
    required this.label,
    this.from,
    this.to,
    this.note,
    StatsRange Function()? rebuild,
  }) : _rebuild = rebuild;

  bool get isAll => from == null && to == null;

  /// 是否恰好覆盖某个完整自然年。阅读天数这类年度统计指标只有这种
  /// 区间才拿得到准确值。
  bool coversWholeYear(int year) =>
      from == DateTime(year, 1, 1) && to == DateTime(year + 1, 1, 1);

  /// 区间覆盖的自然年列表（`isAll` 返回空）。
  List<int> get years {
    final f = from;
    final t = to;
    if (f == null || t == null) return const [];
    final out = <int>[];
    for (var y = f.year; y <= t.year; y++) {
      out.add(y);
    }
    return out;
  }

  /// 不限时间。
  ///
  /// ⚠️ 曾经是 `static final all = StatsRange(label: appLoc.s_e7a2db51)`，
  /// 这是一个只在**首次访问时**求值一次的懒初始化：label 会把当时的语言
  /// 永久钉死。用户在英文界面下点过一次统计页，之后切回中文，
  /// 这个胶囊上就一直写着 "All time"。改成 getter 后每次现取当前语言。
  /// 与 `reading_profile.dart` 的 `_rules`、`llm_protocol.dart` 的
  /// `llmPresets` 是同一类坑。
  static StatsRange get all => StatsRange(
        label: appLoc.s_e7a2db51,
        // all 没有边界可重建，配方就返回一个全新的 all。
        rebuild: () => StatsRange.all,
      );

  factory StatsRange.year(int y) => StatsRange(
        label: appLoc.s_a87cfcc9(y: y),
        from: DateTime(y, 1, 1),
        to: DateTime(y + 1, 1, 1),
        rebuild: () => StatsRange.year(y),
      );

  /// 最近 [n] 个月，含本月。
  ///
  /// 注意 from 落在「n-1 个月前的 1 号」而不是「今天减 n 个月」：
  /// 后者会让区间起点停在一月中旬，与月度粒度的阅读时长对不齐，
  /// 展示出来反而更难解释。
  factory StatsRange.lastMonths(int n, {DateTime? now}) {
    final t = now ?? DateTime.now();
    return StatsRange(
      label: appLoc.s_62654321(n: n),
      from: DateTime(t.year, t.month - (n - 1), 1),
      to: DateTime(t.year, t.month + 1, 1),
      note: appLoc.s_41f3af95,
      // 钉住已解析的 t：重算时再取一次 DateTime.now() 会让区间随
      // 时间漂移（跨月那一下，同一个选区会突然换一段）。
      rebuild: () => StatsRange.lastMonths(n, now: t),
    );
  }

  /// 自定义区间。用户选的是自然日，[to] 加一天转成半开区间。
  ///
  /// label 是纯数字、与语言无关，只有 [note] 需要跟随语言。
  factory StatsRange.custom(DateTime a, DateTime b) {
    final start = DateTime(a.year, a.month, a.day);
    final end = DateTime(b.year, b.month, b.day).add(const Duration(days: 1));
    return StatsRange(
      label: '${start.year}/${start.month}/${start.day}'
          ' - ${end.subtract(const Duration(days: 1)).month}/'
          '${end.subtract(const Duration(days: 1)).day}',
      from: start,
      to: end,
      note: appLoc.s_41f3af95,
      rebuild: () => StatsRange.custom(a, b),
    );
  }

  /// 预置选项。第一个是默认值。
  static List<StatsRange> presets({DateTime? now}) {
    final t = now ?? DateTime.now();
    return [
      all,
      StatsRange.year(t.year),
      StatsRange.year(t.year - 1),
      StatsRange.lastMonths(12, now: t),
      StatsRange.lastMonths(3, now: t),
    ];
  }

  /// 按当前语言重建 [label] / [note]，边界不变。
  ///
  /// 为什么需要它：`StatsPage` 是 `HomeShell._pages` 里的 `const` 实例，
  /// 它的 State 会跨越语言切换一直存活——区间对象在构造时算好 label，
  /// 切语言后不会重算，于是「全部时间」在中文界面下显示成 "All time"。
  /// UI 每次 build 拿它过一遍即可，不必给整个页面加重建 key。
  ///
  /// 实现上不「反推」这个区间是哪种预置，而是让每个工厂函数留下
  /// [_rebuild] 配方——从 label 字符串倒推区间类型是脆的：
  /// 用户自定义一段恰好是 1/1~次年 1/1 的区间，就会被误判成「2026 年」。
  StatsRange relabeled() {
    final make = _rebuild;
    return make == null ? this : make();
  }

  /// 重建配方：用**当前**语言重新构造一个边界相同的区间。
  /// 由 [year] / [lastMonths] 等工厂函数在创建时填入。
  final StatsRange Function()? _rebuild;

  /// [d] 是否落在区间内。
  ///
  /// 传入 null（日期缺失）时：只有「全部时间」算数——它的语义就是不过滤，
  /// 一本没有完成日期的书在全部时间口径里本来就该被算进去。
  /// 有限区间则一律算不在：日期缺失时无法判断归属，宁可少算也不要瞎归。
  /// 这一点必须与 [containsIso] / [containsBook] 保持一致，
  /// 否则同一个「全部时间」在三处会给出三种答案。
  bool contains(DateTime? d) {
    if (d == null) return isAll;
    final f = from;
    if (f != null && d.isBefore(f)) return false;
    final e = to;
    if (e != null && !d.isBefore(e)) return false;
    return true;
  }

  /// 把一个日期串解析成它**覆盖的时间段**（半开区间）。
  ///
  /// 支持三种精度，因为真实数据里三种都有：
  ///   - `2026-01-15` / 完整 ISO → `[当天, 次日)`
  ///   - `2026-01`（只有年月）   → `[1 号, 下月 1 号)`
  ///   - `2026`（只有年份）      → `[1/1, 次年 1/1)`
  ///
  /// 为什么非做不可：Dart 的 `DateTime.tryParse('2026-01')` 返回 **null**，
  /// 而种子库和手工录入里大量日期只到月份（`"2025-11"`）。
  /// 「全部时间」口径会短路掉日期解析，所以这个坑在这个口径下完全看不出来
  /// ——一旦按年筛选，读完的书会集体消失、显示成 0 本。
  ///
  /// 解析不出来返回 null，由调用方按「不在区间内」处理。
  static (DateTime, DateTime)? parseSpan(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    final full = DateTime.tryParse(s);
    if (full != null) {
      final d = DateTime(full.year, full.month, full.day);
      return (d, DateTime(full.year, full.month, full.day + 1));
    }
    final ym = _yearMonth.firstMatch(s);
    if (ym != null) {
      final y = int.parse(ym.group(1)!);
      final m = int.parse(ym.group(2)!);
      if (m < 1 || m > 12) return null;
      return (DateTime(y, m, 1), DateTime(y, m + 1, 1));
    }
    final yOnly = _yearOnly.firstMatch(s);
    if (yOnly != null) {
      final y = int.parse(yOnly.group(1)!);
      return (DateTime(y, 1, 1), DateTime(y + 1, 1, 1));
    }
    return null;
  }

  static final _yearMonth = RegExp(r'^(\d{4})[-/.](\d{1,2})$');
  static final _yearOnly = RegExp(r'^(\d{4})$');
  static final _tzSuffix = RegExp(r'([Zz]|[+-]\d\d:?\d\d)$');

  /// 日期串是否落在区间内。
  ///
  /// 粗粒度串（只到月/年）按**重叠**判定：`"2026-01"` 的真实含义是
  /// 「2026 年 1 月里的某一天」，用户筛 1/15–1/20 时不能断言它不在里面，
  /// 所以按「1 月与区间有交集」算入。这里宁可多召回——漏掉的书用户
  /// 不会察觉，多算的会以「本期读完」变多的形式被看见。
  ///
  /// 带时区的完整时间戳按绝对时刻判，不按自然日切分：
  /// `2025-12-31T16:00:00Z` 到底算 12 月还是 1 月，取决于用户所在时区。
  ///
  /// 解析不了的串一律算不在——宁可少算，不要把脏数据当成「今天」混进统计。
  bool containsIso(String? iso) {
    if (isAll) return true;
    if (iso == null) return false;
    final s = iso.trim();
    if (s.isEmpty) return false;

    final full = DateTime.tryParse(s);
    if (full != null && (full.isUtc || _tzSuffix.hasMatch(s))) {
      return contains(full);
    }

    final span = parseSpan(s);
    if (span == null) return false;
    final (a, b) = span;
    final e = to;
    if (e != null && !a.isBefore(e)) return false;
    final f = from;
    if (f != null && !b.isAfter(f)) return false;
    return true;
  }

  /// 这本书是否计入本区间。
  ///
  /// 口径与「阅读报告」页保持一致：**先看完成日期**，读完的书只认
  /// 完成日期；没读完的再看最后活动时间。
  ///
  /// 为什么不统一用 updatedAt：那是记录被修改的时间，改一次评分就会
  /// 把一本三年前读完的书算进「本月读完」。
  bool containsBook(Book b) {
    if (isAll) return true;
    if (containsIso(b.finishedAt)) return true;
    if (b.status == BookStatus.finished) return false;
    return containsIso(b.updatedAt);
  }

  /// 区间覆盖的月份序列（升序，元素为该月 1 号）。
  ///
  /// 上限 12 个月：轴上铺几十根柱子谁也看不清，所以超长区间只保留
  /// **最近** 12 个月。用户选了跨年区间时图上只画最后一年这件事，
  /// 由调用方在图表标题里说明——不能默默截断。
  ///
  /// 「全部时间」没有起点可言，以 [now] 为锚往回取 12 个月。
  List<DateTime> months({int maxMonths = 12, DateTime? now}) {
    final t = now ?? DateTime.now();
    final f = from;
    final e = to;

    if (f == null || e == null) {
      return [
        for (var i = maxMonths - 1; i >= 0; i--)
          DateTime(t.year, t.month - i, 1),
      ];
    }
    final out = <DateTime>[];
    var cursor = DateTime(f.year, f.month, 1);
    while (cursor.isBefore(e) && out.length < 400) {
      out.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    if (out.length > maxMonths) {
      return out.sublist(out.length - maxMonths);
    }
    return out;
  }

  /// 该月与区间是否有**交集**。
  ///
  /// 判据必须是「重叠」而不是「月 1 号落在区间里」：阅读时长只有月度粒度，
  /// 用户选 7/15–8/20 时，7 月和 8 月的 1 号都不在区间内，
  /// 按后者算出来的时长会莫名其妙变成 0。
  bool overlapsMonth(int year, int month) {
    if (isAll) return true;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final e = to;
    if (e != null && !start.isBefore(e)) return false;
    final f = from;
    if (f != null && !end.isAfter(f)) return false;
    return true;
  }

  @override
  String toString() => label;
}

/// 区间内的阅读活动汇总。
///
/// 几个字段都是「能算就算，算不出就给 null」，而不是塞 0。
/// 塞 0 会让「这三个月没读过」和「这三个月的天数无从统计」长得一模一样。
class ReadingActivity {
  /// 手工日志 + 微信读书的合计分钟数
  final int minutes;

  /// 有阅读记录的天数。null = 该区间给不出这个数
  final int? activeDays;

  /// 口径说明
  final String? note;

  const ReadingActivity({
    required this.minutes,
    this.activeDays,
    this.note,
  });

  static const empty = ReadingActivity(minutes: 0);

  int get dayAvgMinutes {
    final d = activeDays;
    if (d == null || d <= 0) return 0;
    return (minutes / d).round();
  }
}
