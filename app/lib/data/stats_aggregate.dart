import 'dart:math' as math;

import '../models/book.dart';
import '../l10n/app_loc.dart';
import '../models/enums.dart';

// 纯 Dart 的统计聚合。
//
// 为什么不全走 SQL：时间筛选要求「先按区间筛书，再在筛出来的集合上算分布」，
// 把区间条件塞进每一条 GROUP BY 既啰嗦又容易漏。书籍量级是几千本，
// 一次 all() 之后在内存里算完全够用，而且可以单测。
//
// BookRepository 里那套 SQL 版本保留给不需要区间筛选的调用方
// （阅读报告、种子导入等）。两套实现存在漂移风险，所以
// test/stats_aggregate_test.dart 里有一条用例专门拿全库数据
// 交叉验证它们结果一致。

/// 状态分布
Map<BookStatus, int> statusCountsOf(List<Book> books) {
  final out = <BookStatus, int>{};
  for (final b in books) {
    out[b.status] = (out[b.status] ?? 0) + 1;
  }
  return out;
}

/// 分类分布，数量降序。同名时按名称升序，保证结果稳定
/// （SQL 的 `ORDER BY c DESC` 在并列时顺序是不确定的，界面上会跳）。
List<Map<String, dynamic>> categoryDistributionOf(List<Book> books) {
  final counts = <String, int>{};
  for (final b in books) {
    // 与 SQL 的 COALESCE(categoryPrimary,'未分类') 保持一致的写法，
    // 否则两套实现的结果对不上
    final key = b.categoryPrimary ?? kUncategorized;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return _sortedPairs(counts);
}

/// 来源平台分布
List<Map<String, dynamic>> sourceDistributionOf(List<Book> books) {
  final counts = <String, int>{};
  for (final b in books) {
    counts[b.source.name] = (counts[b.source.name] ?? 0) + 1;
  }
  return _sortedPairs(counts);
}

/// 评分分布：未评分 + 1~5 星。
///
/// 在 Dart 侧分桶而不是写 SQL：`rating` 是 REAL，4.5 星该进 5 星桶、
/// 0.5 星该进 1 星桶，这种取整规则用 SQL 表达既难读也容易写错。
List<Map<String, dynamic>> ratingBucketsOf(List<Book> books) {
  final counts = List<int>.filled(6, 0);
  for (final b in books) {
    final r = b.rating;
    final idx = r <= 0 ? 0 : r.ceil().clamp(1, 5);
    counts[idx]++;
  }
  return [
    for (var i = 0; i < 6; i++)
      {'label': i == 0 ? appLoc.s_06225788 : appLoc.s_89cfaca8(i: i), 'count': counts[i], 'stars': i},
  ];
}

/// 在读图书的进度分布，看「开了多少坑没填」
List<Map<String, dynamic>> progressBucketsOf(List<Book> books) {
  const labels = ['0-25%', '25-50%', '50-75%', '75-100%'];
  final counts = List<int>.filled(4, 0);
  for (final b in books) {
    if (b.status != BookStatus.reading) continue;
    final i = (b.progressPercent / 25).floor().clamp(0, 3);
    counts[i]++;
  }
  return [
    for (var i = 0; i < labels.length; i++)
      {'label': labels[i], 'count': counts[i]},
  ];
}

/// 已读书目的平均分（无评分时返回 0）
double averageRatingOf(List<Book> books) {
  var sum = 0.0;
  var n = 0;
  for (final b in books) {
    if (b.rating <= 0) continue;
    sum += b.rating;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

/// 按月统计读完数量，键为 `YYYY-MM`。只统计 [from] ~ [to]（含）之间的月份。
List<Map<String, dynamic>> monthlyFinishedOf(
  List<Book> books,
  List<DateTime> months,
) {
  final byMonth = <String, int>{};
  for (final b in books) {
    if (b.status != BookStatus.finished) continue;
    final iso = b.finishedAt;
    if (iso == null || iso.length < 7) continue;
    final key = iso.substring(0, 7);
    byMonth[key] = (byMonth[key] ?? 0) + 1;
  }
  final out = <Map<String, dynamic>>[];
  for (final m in months) {
    final key = monthKey(m);
    final c = byMonth[key] ?? 0;
    if (c == 0) continue;
    out.add({'month': key, 'c': c});
  }
  return out;
}

/// 区间内新增藏书数（按 createdAt）
int addedInRange(List<Book> books) => books.length;

/// 开了坑没填：在读但进度极低
int stalledCountOf(List<Book> books) =>
    books.where((b) => b.status == BookStatus.reading && b.progressPercent < 15).length;

/// 分类集中度：出现过的分类数与最大一类占比
({int kinds, double topShare}) categoryConcentration(List<Book> books) {
  final dist = categoryDistributionOf(books);
  if (dist.isEmpty) return (kinds: 0, topShare: 0);
  final total = dist.fold<int>(0, (a, b) => a + (b['c'] as int));
  final top = dist.first['c'] as int;
  return (kinds: dist.length, topShare: total == 0 ? 0 : top / total);
}

/// 评分标准差。用来区分「一律四星」和「要么五星要么一星」这两种读者。
double ratingStdDevOf(List<Book> books) {
  final rated = books.where((b) => b.rating > 0).map((b) => b.rating).toList();
  if (rated.length < 2) return 0;
  final mean = rated.reduce((a, b) => a + b) / rated.length;
  final variance =
      rated.map((r) => math.pow(r - mean, 2).toDouble()).reduce((a, b) => a + b) /
          rated.length;
  return math.sqrt(variance);
}

List<Map<String, dynamic>> _sortedPairs(Map<String, int> counts) {
  final out = counts.entries
      .map((e) => <String, dynamic>{'name': e.key, 'c': e.value})
      .toList();
  out.sort((a, b) {
    final byCount = (b['c'] as int).compareTo(a['c'] as int);
    if (byCount != 0) return byCount;
    return (a['name'] as String).compareTo(b['name'] as String);
  });
  return out;
}

/// `YYYY-MM`，与 SQL 里 `substr(finishedAt,1,7)` 的结果一致
String monthKey(DateTime m) =>
    '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';

/// 轴标签：只跨一年时用「3 月」，跨年时用「26/3」——
/// 后者写上月份也分不清是哪一年。
String monthAxisLabel(DateTime m, {required bool sameYear}) =>
    sameYear ? appLoc.s_1a2e873e(month: m.month) : '${m.year % 100}/${m.month}';

