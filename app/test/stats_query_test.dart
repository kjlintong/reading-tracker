import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 统计口径的回归。
///
/// 这里的项都是「看起来有数、实际算错」的高危区：
/// 阅读时长漏算了微信读书同步回来的累计时长（一直显示 0.0 小时），
/// 连续天数用 updatedAt 当阅读日（改一次评分就算读过一天）。
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database raw;
  late BookRepository repo;

  const now = '2026-09-29T10:00:00.000Z';

  Book book(
    String id, {
    String title = '书',
    BookStatus status = BookStatus.wish,
    double rating = 0,
    double progress = 0,
    Map<String, dynamic> extra = const {},
  }) =>
      Book(
        id: id,
        title: title,
        status: status,
        rating: rating,
        progressPercent: progress,
        extra: extra,
        createdAt: now,
        updatedAt: now,
      );

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  String today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  String daysAgo(int d) {
    final n = DateTime.now().subtract(Duration(days: d));
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  group('阅读时长', () {
    test('把微信读书同步回来的每本累计时长算进去', () async {
      // 恰恰是没有 reading_logs 时最容易漏的一环：
      // 只查 reading_logs 会永远得到 0，统计页就一直是「0.0 小时」
      await repo.insertMany([
        book('a', extra: {'wereadReadingTimeSec': 3600}),
        book('b', extra: {'wereadReadingTimeSec': 1800}),
        book('c'),
      ]);
      expect(await repo.totalReadingMinutes(), 90);
    });

    test('手工阅读日志与同步时长相加', () async {
      await repo.insert(book('a', extra: {'wereadReadingTimeSec': 600}));
      await repo.addLog(ReadingLog(
        id: 'l1',
        bookId: 'a',
        date: today(),
        durationMin: 20,
      ));
      expect(await repo.totalReadingMinutes(), 30);
    });

    test('没有任何每本时长时，取年度统计的 totalReadTime', () async {
      // 合成示例库的 38 本书都没有 wereadReadingTimeSec，
      // 但整包的年度统计里有 totalReadTime = 389553 秒。
      // 不接这一段，统计页会一直显示「阅读时长 0 分钟」。
      await repo.insertMany([book('a'), book('b')]);
      await repo.setSetting(
          'wereadAnnualStats',
          jsonEncode({
            'year': 2026,
            'annual': {'totalReadTime': 7200, 'readDays': 12},
          }));

      expect(await repo.totalReadingMinutes(), 120);
    });

    test('年度统计与每本时长重叠，取较大值而不是相加', () async {
      // 两者都源自微信读书、覆盖范围重叠，相加等于重复计时：
      // 每本 3600s（合计 60 分钟）对本年 7200s（120 分钟），
      // 合理答案是一个，不是 180。
      await repo.insert(book('a', extra: {'wereadReadingTimeSec': 3600}));
      await repo.setSetting(
          'wereadAnnualStats',
          jsonEncode({
            'year': 2026,
            'annual': {'totalReadTime': 7200},
          }));

      expect(await repo.totalReadingMinutes(), 120);
    });

    test('每本时长比年度统计更全时以每本为准', () async {
      await repo.insert(book('a', extra: {'wereadReadingTimeSec': 36000}));
      await repo.setSetting(
          'wereadAnnualStats',
          jsonEncode({
            'year': 2026,
            'annual': {'totalReadTime': 7200},
          }));

      expect(await repo.totalReadingMinutes(), 600);
    });

    test('年度统计损坏时不崩，退回每本时长', () async {
      await repo.insert(book('a', extra: {'wereadReadingTimeSec': 3600}));
      await repo.setSetting('wereadAnnualStats', '{不是 JSON');

      expect(await repo.wereadAnnualStats(), isNull);
      expect(await repo.totalReadingMinutes(), 60);
    });
  });

  group('连续阅读天数', () {
    test('连续三天读到，含今天', () async {
      await repo.insertMany([
        book('a', extra: {'wereadLastReadAt': '${today()}T09:00:00.000Z'}),
        book('b', extra: {'wereadProgressUpdatedAt': '${daysAgo(1)}T09:00:00.000Z'}),
        book('c', extra: {'wereadLastReadAt': '${daysAgo(2)}T09:00:00.000Z'}),
      ]);
      expect(await repo.readingStreakDays(), 3);
    });

    test('今天还没读也算连续（从昨天回溯）', () async {
      await repo.insertMany([
        book('a', extra: {'wereadLastReadAt': '${daysAgo(1)}T09:00:00.000Z'}),
        book('b', extra: {'wereadLastReadAt': '${daysAgo(2)}T09:00:00.000Z'}),
      ]);
      expect(await repo.readingStreakDays(), 2);
    });

    test('中间断了就截断，不会把整年算成连续', () async {
      await repo.insertMany([
        book('a', extra: {'wereadLastReadAt': '${today()}T09:00:00.000Z'}),
        book('b', extra: {'wereadLastReadAt': '${daysAgo(5)}T09:00:00.000Z'}),
      ]);
      expect(await repo.readingStreakDays(), 1);
    });

    test('完全没读过就是 0', () async {
      await repo.insert(book('a'));
      expect(await repo.readingStreakDays(), 0);
    });
  });

  group('评分分布', () {
    test('4.0 进 4 星桶、4.5 进 5 星桶、无评分单独一桶', () async {
      await repo.insertMany([
        book('a', rating: 5),
        book('b', rating: 4.5),
        book('c', rating: 4.0),
        book('d', rating: 1),
        book('e'),
      ]);
      final buckets = await repo.ratingBuckets();
      expect(buckets.length, 6);
      expect(buckets[0]['count'], 1); // 未评分
      expect(buckets[4]['count'], 1); // 4 星
      expect(buckets[5]['count'], 2); // 5 星（含 4.5）
      expect(buckets[1]['count'], 1); // 1 星
    });

    test('平均分只统计有评分的书', () async {
      await repo.insertMany([
        book('a', rating: 5),
        book('b', rating: 3),
        book('c'),
      ]);
      expect(await repo.averageRating(), 4.0);
    });
  });

  group('在读进度分布', () {
    test('只在读的书参与分桶，边界值落在高的一档', () async {
      await repo.insertMany([
        book('a', status: BookStatus.reading, progress: 0),
        book('b', status: BookStatus.reading, progress: 25),
        book('c', status: BookStatus.reading, progress: 99),
        book('d', status: BookStatus.finished, progress: 100),
      ]);
      final buckets = await repo.progressBuckets();
      expect(buckets[0]['count'], 1); // 0-25%
      expect(buckets[1]['count'], 1); // 25-50%
      expect(buckets[3]['count'], 1); // 75-100%
      expect(buckets[2]['count'], 0);
    });
  });

  group('extra 解析容错', () {
    test('单行 extra 损坏不影响整体统计', () async {
      await repo.insert(book('good', extra: {'wereadReadingTimeSec': 600}));
      await raw.insert('books', {
        'id': 'bad',
        'title': '坏数据',
        'status': 'wish',
        'extra': '{不是合法 JSON',
        'createdAt': now,
        'updatedAt': now,
        'progressPercent': 0,
        'rating': 0,
        'rereadCount': 0,
      });
      expect(await repo.totalReadingMinutes(), 10);
    });

    test('extra 可正常往返编解码', () {
      final b = book('a', extra: {'wereadReadingTimeSec': 42, 'nested': {'x': 1}});
      final back = Book.fromMap(b.toMap());
      expect(jsonEncode(back.extra), jsonEncode(b.extra));
    });
  });
}
