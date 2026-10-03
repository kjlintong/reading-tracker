import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/data/date_range.dart';
import 'package:reading_tracker/data/stats_aggregate.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 内存聚合的正确性，以及与 SQL 实现的一致性。
///
/// 为什么要有第二组：时间筛选要求「先按区间筛书，再在筛出来的集合上算分布」，
/// 于是同一套口径存在两份实现——`BookRepository` 里的 SQL 版（给不需要
/// 区间筛选的调用方用）和这里的 Dart 版。两份实现漂移之后，
/// 同一个「分类分布」在统计页和阅读报告里会给出不同的数字，
/// 而这种错很难被发现。所以这里拿同一批数据把两边都跑一遍并比对。
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database raw;
  late BookRepository repo;

  const iso = '2026-01-01T00:00:00.000Z';

  Book book(
    String id, {
    String? category,
    BookStatus status = BookStatus.wish,
    BookSource source = BookSource.manual,
    double rating = 0,
    double progress = 0,
    String? finishedAt,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic> extra = const {},
  }) =>
      Book(
        id: id,
        title: id,
        categoryPrimary: category,
        status: status,
        source: source,
        rating: rating,
        progressPercent: progress,
        finishedAt: finishedAt,
        createdAt: createdAt ?? iso,
        updatedAt: updatedAt ?? iso,
        extra: extra,
      );

  List<Book> sample() => [
        book('a',
            category: '文学',
            status: BookStatus.finished,
            source: BookSource.weread,
            rating: 5,
            finishedAt: '2026-01-15'),
        book('b',
            category: '文学',
            status: BookStatus.finished,
            source: BookSource.weread,
            rating: 4.5,
            finishedAt: '2026-02-20'),
        book('c',
            category: '经济',
            status: BookStatus.finished,
            source: BookSource.manual,
            rating: 4,
            finishedAt: '2026-02-28'),
        book('d',
            category: '经济',
            status: BookStatus.reading,
            source: BookSource.manual,
            progress: 25),
        book('e',
            category: '哲学',
            status: BookStatus.reading,
            source: BookSource.notion,
            progress: 90),
        book('f', category: '哲学', source: BookSource.notion),
        book('g', source: BookSource.manual),
      ];

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  group('与 SQL 实现保持一致', () {
    test('状态分布', () async {
      await repo.insertMany(sample());
      final all = await repo.all();
      expect(statusCountsOf(all), await repo.statusCounts());
    });

    test('分类与来源分布（按 name+count 比对，顺序允许不同）', () async {
      await repo.insertMany(sample());
      final all = await repo.all();

      Set<String> packs(List<Map<String, dynamic>> rows) => rows
          .map((r) => '${r['name']}|${r['c']}')
          .toSet();

      expect(packs(categoryDistributionOf(all)),
          packs(await repo.categoryDistribution()));
      expect(packs(sourceDistributionOf(all)),
          packs(await repo.sourceDistribution()));
    });

    test('评分分布与平均分', () async {
      await repo.insertMany(sample());
      final all = await repo.all();

      final mine = ratingBucketsOf(all);
      final theirs = await repo.ratingBuckets();
      expect(mine.length, theirs.length);
      for (var i = 0; i < mine.length; i++) {
        expect(mine[i]['count'], theirs[i]['count'], reason: '第 $i 桶不一致');
        expect(mine[i]['stars'], theirs[i]['stars']);
      }
      expect(averageRatingOf(all), await repo.averageRating());
    });

    test('在读进度分布', () async {
      await repo.insertMany(sample());
      final all = await repo.all();
      final mine = progressBucketsOf(all);
      final theirs = await repo.progressBuckets();
      for (var i = 0; i < mine.length; i++) {
        expect(mine[i]['count'], theirs[i]['count'], reason: '第 $i 桶不一致');
      }
    });

    test('某年月度读完', () async {
      await repo.insertMany(sample());
      final all = await repo.all();
      final year = 2026;
      final months = [for (var m = 1; m <= 12; m++) DateTime(year, m, 1)];

      Map<String, int> mine = {
        for (final t in monthlyFinishedOf(all, months))
          t['month'] as String: t['c'] as int
      };
      Map<String, int> theirs = {
        for (final t in await repo.monthlyFinishedTrend(year))
          t['month'] as String: t['c'] as int
      };
      expect(mine, theirs);
      expect(mine, {'2026-01': 1, '2026-02': 2});
    });
  });

  group('分桶边界', () {
    test('评分四舍五入进位：4.5 进 5 星桶、0.5 进 1 星桶', () {
      final buckets = ratingBucketsOf([
        book('a', rating: 4.5),
        book('b', rating: 4.0),
        book('c', rating: 0.5),
        book('d'),
      ]);
      expect(buckets[0]['count'], 1); // 未评分
      expect(buckets[1]['count'], 1); // 0.5 → 1 星
      expect(buckets[4]['count'], 1); // 4.0 → 4 星
      expect(buckets[5]['count'], 1); // 4.5 → 5 星
    });

    test('进度边界落在高的一档，且只有在读的书参与', () {
      final buckets = progressBucketsOf([
        book('a', status: BookStatus.reading, progress: 0),
        book('b', status: BookStatus.reading, progress: 25),
        book('c', status: BookStatus.reading, progress: 99),
        book('d', status: BookStatus.finished, progress: 100),
      ]);
      expect(buckets[0]['count'], 1);
      expect(buckets[1]['count'], 1);
      expect(buckets[2]['count'], 0);
      expect(buckets[3]['count'], 1);
    });

    test('平均分只统计有评分的书', () {
      expect(
        averageRatingOf([book('a', rating: 5), book('b', rating: 3), book('c')]),
        4.0,
      );
      expect(averageRatingOf([book('a')]), 0);
      expect(averageRatingOf(const []), 0);
    });

    test('评分标准差把「一律四星」和「两极分化」分开', () {
      final even = [for (var i = 0; i < 5; i++) book('e$i', rating: 4)];
      expect(ratingStdDevOf(even), 0);

      final split = [
        book('a', rating: 5),
        book('b', rating: 5),
        book('c', rating: 1),
        book('d', rating: 1),
      ];
      expect(ratingStdDevOf(split), closeTo(2.0, 1e-9));
      // 只有一个评分时谈不上离散
      expect(ratingStdDevOf([book('x', rating: 5)]), 0);
    });
  });

  group('区间筛选下的聚合', () {
    test('先筛书再算分布：区间外的书不参与', () {
      final all = [
        book('a',
            category: '文学',
            status: BookStatus.finished,
            finishedAt: '2026-01-15'),
        book('b',
            category: '文学',
            status: BookStatus.finished,
            finishedAt: '2024-01-15'),
        book('c',
            category: '经济',
            status: BookStatus.finished,
            finishedAt: '2026-05-15'),
      ];
      final r = StatsRange.year(2026);
      final inRange = all.where(r.containsBook).toList();
      expect(inRange.map((b) => b.id).toList(), ['a', 'c']);

      final dist = categoryDistributionOf(inRange);
      expect(dist.length, 2);
      expect(dist.first['name'], anyOf('文学', '经济'));
      expect(dist.first['c'], 1);
    });

    test('分类集中度', () {
      final books = [
        book('a', category: '文学'),
        book('b', category: '文学'),
        book('c', category: '文学'),
        book('d', category: '经济'),
      ];
      final c = categoryConcentration(books);
      expect(c.kinds, 2);
      expect(c.topShare, closeTo(0.75, 1e-9));
      expect(categoryConcentration(const []).kinds, 0);
    });

    test('开坑没填 = 在读且进度低于 15%', () {
      expect(
        stalledCountOf([
          book('a', status: BookStatus.reading, progress: 5),
          book('b', status: BookStatus.reading, progress: 14.9),
          book('c', status: BookStatus.reading, progress: 15),
          book('d', status: BookStatus.wish, progress: 0),
        ]),
        2,
      );
    });
  });

  group('区间内的阅读活动（数据库层）', () {
    test('手工日志按天精确筛，天数也给得出', () async {
      await repo.insertMany([book('a')]);
      await repo.addLog(ReadingLog(
          id: 'l1', bookId: 'a', date: '2026-03-10', durationMin: 30));
      await repo.addLog(ReadingLog(
          id: 'l2', bookId: 'a', date: '2026-03-11', durationMin: 20));
      await repo.addLog(ReadingLog(
          id: 'l3', bookId: 'a', date: '2025-03-11', durationMin: 99));

      // 没有年度统计时天数退回「手工记录的阅读日」，并必须说明这一点
      final r = await repo.readingActivity(StatsRange.year(2026));
      expect(r.minutes, 50);
      expect(r.activeDays, 2);
      expect(r.note, contains('手工记录'));
    });

    test('年度统计只有月度粒度：区间落在哪几个月就算哪几个月', () async {
      await repo.insertMany([book('a')]);
      await repo.setSetting(
          'wereadAnnualStats',
          jsonEncode({
            'year': 2026,
            'annual': {
              'readTimes': {
                '1767225600': 3600, // 2026-01
                '1769904000': 7200, // 2026-02
                '1772323200': 1800, // 2026-03
              },
              'readDays': 30,
            },
          }));

      final q1 = await repo.readingActivity(
          StatsRange.custom(DateTime(2026, 1, 1), DateTime(2026, 3, 31)));
      expect(q1.minutes, 210); // (3600+7200+1800)/60

      final feb = await repo.readingActivity(
          StatsRange.custom(DateTime(2026, 2, 1), DateTime(2026, 2, 28)));
      expect(feb.minutes, 120);
    });

    test('整年区间才给得出阅读天数', () async {
      await repo.insertMany([book('a')]);
      await repo.setSetting(
          'wereadAnnualStats',
          jsonEncode({
            'year': 2026,
            'annual': {
              'readTimes': {'1769904000': 7200},
              'readDays': 42,
            },
          }));

      final whole =
          await repo.readingActivity(StatsRange.year(2026));
      expect(whole.activeDays, 42);

      // 半年区间拿不到天数——塞 0 会让「没法统计」和「一天没读」长得一样
      final half = await repo.readingActivity(
          StatsRange.custom(DateTime(2026, 1, 1), DateTime(2026, 6, 30)));
      expect(half.activeDays, isNull);
      expect(half.note, contains('整月'));
    });

    test('每本累计时长没有日期，只在「全部时间」口径里生效', () async {
      await repo.insertMany([
        book('a', extra: {'wereadReadingTimeSec': 6000}),
      ]);
      await repo.setSetting(
          'wereadAnnualStats',
          jsonEncode({
            'year': 2026,
            'annual': {
              'readTimes': {'1769904000': 600},
            },
          }));

      // 全部时间：6000 秒的每本累计比年度统计里的 600 秒大，取 6000
      final all = await repo.readingActivity(StatsRange.all);
      expect(all.minutes, 100);

      // 指定年份：每本累计用不上（没有日期），只有年度统计那一笔
      final y = await repo.readingActivity(StatsRange.year(2026));
      expect(y.minutes, 10);
    });

    test('空库不会除零，也不会抛出', () async {
      final r = await repo.readingActivity(StatsRange.all);
      expect(r.minutes, 0);
      expect(r.dayAvgMinutes, 0);
    });
  });
}
