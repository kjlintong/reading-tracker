import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/date_range.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

/// 时间范围的口径回归。
///
/// 这一层的坑集中在「区间边界」与「不同数据源的粒度」两处：
/// 半开区间搞错会把 12 月 31 日的记录漏掉；月份按「包含」而不是「重叠」
/// 判断，会让 7/15–8/20 这种区间的阅读时长直接变成 0。
void main() {
  const iso = '2026-01-01T00:00:00.000Z';

  Book book(
    String id, {
    BookStatus status = BookStatus.wish,
    String? finishedAt,
    String? createdAt,
    String? updatedAt,
  }) =>
      Book(
        id: id,
        title: id,
        status: status,
        finishedAt: finishedAt,
        createdAt: createdAt ?? iso,
        updatedAt: updatedAt ?? iso,
      );

  group('区间构造', () {
    test('年份是半开区间：不漏 12/31 晚上，也不含次年 1/1', () {
      final r = StatsRange.year(2026);
      expect(r.from, DateTime(2026, 1, 1));
      expect(r.to, DateTime(2027, 1, 1));
      expect(r.contains(DateTime(2026, 12, 31, 23, 59)), isTrue);
      expect(r.contains(DateTime(2027, 1, 1)), isFalse);
      expect(r.contains(DateTime(2025, 12, 31, 23, 59)), isFalse);
    });

    test('全部时间不做任何过滤', () {
      expect(StatsRange.all.isAll, isTrue);
      expect(StatsRange.all.contains(DateTime(1999, 1, 1)), isTrue);
      expect(StatsRange.all.contains(null), isTrue);
      expect(StatsRange.all.containsIso(null), isTrue);
      expect(StatsRange.all.containsBook(book('a')), isTrue);
    });

    test('近 N 个月从整月起点算起，并带上粒度说明', () {
      final r = StatsRange.lastMonths(3, now: DateTime(2026, 9, 30));
      expect(r.from, DateTime(2026, 7, 1));
      expect(r.to, DateTime(2026, 10, 1));
      // 粒度提示必须跟着区间走：阅读时长只有月度口径，
      // 不说明的话用户会把它当成精确值
      expect(r.note, isNotNull);
    });

    test('近 N 个月可以跨年', () {
      final r = StatsRange.lastMonths(3, now: DateTime(2026, 1, 15));
      expect(r.from, DateTime(2025, 11, 1));
      expect(r.to, DateTime(2026, 2, 1));
    });

    test('自定义区间把用户选的结束日包含进来', () {
      final r = StatsRange.custom(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
      expect(r.contains(DateTime(2026, 3, 31, 20)), isTrue);
      expect(r.contains(DateTime(2026, 3, 1)), isTrue);
      expect(r.contains(DateTime(2026, 4, 1)), isFalse);
    });

    test('预置项第一个是「全部时间」', () {
      final p = StatsRange.presets(now: DateTime(2026, 9, 30));
      expect(p.first.isAll, isTrue);
      expect(p.length, 5);
      // 两个年度项 + 两个「近 N 个月」
      expect(p[1].label, '2026 年');
      expect(p[2].label, '2025 年');
    });
  });

  group('书目归属', () {
    test('读完的书只看完成日期，不看最后修改时间', () {
      final r = StatsRange.year(2026);
      // 2024 年读完、今年改过一次评分。用 updatedAt 判定的话，
      // 一本三年前读完的书会被算进「今年读完」——这正是原来连续天数虚高的成因
      final old = book('a',
          status: BookStatus.finished,
          finishedAt: '2024-05-01T00:00:00.000Z',
          updatedAt: '2026-09-30T00:00:00.000Z');
      expect(r.containsBook(old), isFalse);
    });

    test('没读完的看最后活动时间', () {
      final r = StatsRange.year(2026);
      expect(
          r.containsBook(book('a',
              status: BookStatus.reading,
              updatedAt: '2026-08-01T00:00:00.000Z')),
          isTrue);
      expect(
          r.containsBook(book('b',
              status: BookStatus.wish,
              updatedAt: '2025-08-01T00:00:00.000Z')),
          isFalse);
    });

    test('日期串损坏或为空算作不在区间内', () {
      final r = StatsRange.year(2026);
      expect(r.containsIso('不是日期'), isFalse);
      expect(r.containsIso(''), isFalse);
      expect(r.containsIso('2026-13'), isFalse, reason: '月份越界不算数');
    });

    test('粗粒度完成日期：只知道月份时按「重叠」算', () {
      // 前提事实：Dart 解析不了只有年月的串。这条断言一旦变红，
      // 说明 Dart 行为变了，下面那层补丁可以撤了
      expect(DateTime.tryParse('2026-01'), isNull);

      expect(StatsRange.year(2026).containsIso('2026-01'), isTrue);
      expect(StatsRange.year(2026).containsIso('2025-11'), isFalse);
      expect(StatsRange.year(2025).containsIso('2025-11'), isTrue);

      // 区间只覆盖半个月时，靠「1 号是否落在区间里」判会漏掉整月的数据
      final mid = StatsRange.custom(DateTime(2026, 7, 15), DateTime(2026, 8, 20));
      expect(mid.containsIso('2026-07'), isTrue);
      expect(mid.containsIso('2026-08'), isTrue);
      expect(mid.containsIso('2026-06'), isFalse);
      expect(mid.containsIso('2026-09'), isFalse);
    });

    test('只知道年份时覆盖整年', () {
      expect(StatsRange.year(2026).containsIso('2026'), isTrue);
      expect(StatsRange.year(2026).containsIso('2025'), isFalse);
      expect(StatsRange.parseSpan('2026'),
          (DateTime(2026, 1, 1), DateTime(2027, 1, 1)));
    });

    test('带时区的完整时间戳按绝对时刻判，不按自然日切分', () {
      // 2026-01-01T00:00:00Z 在 UTC 下是 1 月 1 日，在东八区是 1 月 1 日早上，
      // 但 2025-12-31T20:00:00Z 在东八区已经是 2026 年了。
      // 按自然日硬切会把它判到 2025 年去，所以这类串走时刻比较。
      final r = StatsRange.year(2026);
      expect(r.containsIso('2026-01-01T00:00:00.000Z'), isTrue);
      expect(r.containsIso('2025-12-31T00:00:00.000Z'), isFalse);
    });

    test('parseSpan 对无时区的时间按自然日处理', () {
      expect(StatsRange.parseSpan('2026-01-15'),
          (DateTime(2026, 1, 15), DateTime(2026, 1, 16)));
      expect(StatsRange.parseSpan('2026-01-15T10:30:00'),
          (DateTime(2026, 1, 15), DateTime(2026, 1, 16)));
      expect(StatsRange.parseSpan('2026-01'),
          (DateTime(2026, 1, 1), DateTime(2026, 2, 1)));
      expect(StatsRange.parseSpan('2025-11'),
          (DateTime(2025, 11, 1), DateTime(2025, 12, 1)));
      expect(StatsRange.parseSpan(null), isNull);
      expect(StatsRange.parseSpan('  '), isNull);
      expect(StatsRange.parseSpan('不是日期'), isNull);
    });

    test('粗粒度日期也能让书归入正确的年份', () {
      final r = StatsRange.year(2026);
      expect(
          r.containsBook(book('a',
              status: BookStatus.finished, finishedAt: '2026-01')),
          isTrue);
      expect(
          r.containsBook(book('b',
              status: BookStatus.finished, finishedAt: '2025-11')),
          isFalse);
    });
  });

  group('月份与粒度', () {
    test('月份序列升序且覆盖整个自然年', () {
      final m = StatsRange.year(2026).months();
      expect(m.length, 12);
      expect(m.first, DateTime(2026, 1, 1));
      expect(m.last, DateTime(2026, 12, 1));
    });

    test('全部时间截到最近 12 个月', () {
      final m = StatsRange.all.months(now: DateTime(2026, 9, 30));
      expect(m.length, 12);
      expect(m.first, DateTime(2025, 10, 1));
      expect(m.last, DateTime(2026, 9, 1));
    });

    test('月份判据是「重叠」而不是「包含」', () {
      // 用户选 7/15–8/20：7 月和 8 月的 1 号都不在区间内。
      // 按「包含」算的话这两个月的阅读时长会被整段丢掉，结果是 0
      final r = StatsRange.custom(DateTime(2026, 7, 15), DateTime(2026, 8, 20));
      expect(r.overlapsMonth(2026, 7), isTrue);
      expect(r.overlapsMonth(2026, 8), isTrue);
      expect(r.overlapsMonth(2026, 6), isFalse);
      expect(r.overlapsMonth(2026, 9), isFalse);
    });

    test('识别是否覆盖某个完整自然年', () {
      expect(StatsRange.year(2026).coversWholeYear(2026), isTrue);
      expect(StatsRange.year(2026).coversWholeYear(2025), isFalse);
      expect(StatsRange.all.coversWholeYear(2026), isFalse);
      expect(
        StatsRange.lastMonths(12, now: DateTime(2026, 6, 1))
            .coversWholeYear(2026),
        isFalse,
      );
    });

    test('自定义区间能列出覆盖的年份', () {
      final r = StatsRange.custom(DateTime(2025, 11, 1), DateTime(2026, 2, 1));
      expect(r.years, [2025, 2026]);
      expect(StatsRange.all.years, isEmpty);
    });
  });

  group('阅读活动', () {
    test('日均由时长与天数推出', () {
      expect(
        const ReadingActivity(minutes: 300, activeDays: 10).dayAvgMinutes,
        30,
      );
    });

    test('天数缺失时为 0，而不是把缺失当成「没读」', () {
      // activeDays 为 null 表示「这个区间给不出天数」，
      // 与「区间内一天都没读」是两回事
      expect(const ReadingActivity(minutes: 300).activeDays, isNull);
      expect(const ReadingActivity(minutes: 300).dayAvgMinutes, 0);
      expect(const ReadingActivity(minutes: 300, activeDays: 0).dayAvgMinutes, 0);
    });
  });
}
