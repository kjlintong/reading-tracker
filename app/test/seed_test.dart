import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/data/date_range.dart';
import 'package:reading_tracker/data/seed_import.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

/// 首启动灌库是用户对 App 的第一印象：从 Notion 迁过来的人打开就应看到
/// 自己的真实书库，而不是空列表。这里验证随包种子数据的完整性与幂等性。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database raw;
  late BookRepository repo;

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  Future<List<Book>> loadSeed() async {
    final raw = await rootBundle.loadString('assets/seed/library.json');
    final payload = jsonDecode(raw) as Map<String, dynamic>;
    final list = (payload['books'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((m) => Book.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  group('种子数据完整性', () {
    test('共 38 本，必填字段无缺失', () async {
      final books = await loadSeed();
      expect(books.length, 38);
      expect(books.where((b) => b.title.trim().isEmpty), isEmpty);
      expect(books.where((b) => b.id.isEmpty), isEmpty);
    });

    test('分类与简介覆盖率 100%', () async {
      final books = await loadSeed();
      expect(
        books.where((b) => b.categoryPrimary != null && b.categoryPrimary!.isNotEmpty).length,
        books.length,
      );
      expect(
        books.where((b) => b.description != null && b.description!.isNotEmpty).length,
        books.length,
      );
    });

    test('作者覆盖率高于 90%（LLM 补全结果已由权威源复核）', () async {
      final books = await loadSeed();
      final withAuthor = books.where((b) => b.authors.isNotEmpty).length;
      expect(withAuthor / books.length, greaterThan(0.9));
    });

    test('分类全部落在受控词表内', () async {
      final books = await loadSeed();
      final cats = books.map((b) => b.categoryPrimary).whereType<String>().toSet();
      for (final c in cats) {
        expect(defaultCategories, contains(c), reason: '分类 $c 不在受控词表');
      }
    });

    test('评分与进度在合法区间', () async {
      final books = await loadSeed();
      expect(books.where((b) => b.rating < 0 || b.rating > 5), isEmpty);
      expect(books.where((b) => b.progressPercent < 0 || b.progressPercent > 100), isEmpty);
    });

    test('同时含已读/在读/想读三种状态', () async {
      final books = await loadSeed();
      final statuses = books.map((b) => b.status).toSet();
      expect(statuses, contains(BookStatus.finished));
      expect(statuses, contains(BookStatus.reading));
      expect(statuses, contains(BookStatus.wish));
    });

    test('完成日期可解析，且按年筛选不会把它们丢掉', () async {
      final books = await loadSeed();
      final finished =
          books.where((b) => b.status == BookStatus.finished).toList();
      expect(finished, isNotEmpty);

      for (final b in finished) {
        expect(StatsRange.parseSpan(b.finishedAt), isNotNull,
            reason: '${b.title} 的完成日期 ${b.finishedAt} 解析不出来');
      }

      // 回归用例：种子里的完成日期只到月份（"2026-01"），
      // 而 `DateTime.tryParse('2026-01')` 在 Dart 里返回 null。
      // 统计页原先的 containsIso 因此把 11 本读完的书全部判成「不在区间内」，
      // 「全部时间」口径因为短路看不出来，一点「2026 年」就变成「读完 0 本」。
      final y2026 = finished.where(StatsRange.year(2026).containsBook).length;
      final y2025 = finished.where(StatsRange.year(2025).containsBook).length;
      expect(y2026, greaterThan(0), reason: '按年筛不能把读完的书全丢掉');
      expect(y2025, greaterThan(0));
      expect(y2026 + y2025, finished.length,
          reason: '种子里的完成日期只落在 2025/2026 两年，两边加起来应等于总数');
    });
  });

  group('种子数据脱敏', () {
    // 仓库是公开的，种子数据不能带着某个具体人的痕迹：
    // 封面外链、平台内部 bookId、deepLink 都能反查出私人书单。
    test('不含任何真实外部标识', () async {
      final books = await loadSeed();
      expect(books.where((b) => b.coverUrl != null), isEmpty,
          reason: '封面外链可反查真实书单');
      expect(books.where((b) => b.sourceBookId != null), isEmpty,
          reason: '平台内部 bookId 属于私人数据');
      expect(books.where((b) => b.sourceUrl != null), isEmpty,
          reason: 'deepLink 指向具体账号的阅读记录');
      for (final b in books) {
        expect(b.id, startsWith('sample-'), reason: 'id 必须是合成前缀');
      }
    });

    test('不含私人借阅与私密字段', () async {
      final books = await loadSeed();
      expect(books.where((b) => b.borrowedFrom != null), isEmpty);
      expect(books.where((b) => b.dueAt != null), isEmpty);
      final secret = books.where((b) =>
          (b.extra['wereadSecret'] as bool?) == true);
      expect(secret, isEmpty, reason: '私密书籍不能出现在示例书库');
    });
  });

  group('SeedImporter', () {
    test('首次导入 38 本，重复调用返回 0（幂等）', () async {
      final importer = SeedImporter(repo);
      final first = await importer.importIfNeeded();
      final second = await importer.importIfNeeded();

      expect(first, 38);
      expect(second, 0);
      expect((await repo.all()).length, 38);
    });

    test('导入后写入 seedVersion，标记完成', () async {
      await SeedImporter(repo).importIfNeeded();
      expect(await repo.getSetting('seedVersion'), isNotNull);
    });

    test('forceImport 可重新灌库', () async {
      final importer = SeedImporter(repo);
      await importer.importIfNeeded();
      await repo.delete((await repo.all()).first.id);
      final again = await importer.forceImport();
      expect(again, greaterThan(0));
    });
  });
}
