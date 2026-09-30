import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

/// 本地优先架构下，SQLite 是唯一数据源，没有服务端兜底。
/// 这里用内存库跑真实 SQL，覆盖 CRUD、去重、统计与设置读写——
/// 统计口径出错的话，AI 报告会基于错误数字生成一本正经的错误结论。
void main() {
  // sqflite_common_ffi 需要先初始化，并显式接管全局 factory
  // （AppDatabase.init 在桌面端做同样的事，但测试不经过 init）
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database raw;
  late AppDatabase appDb;
  late BookRepository repo;

  const now = '2026-09-29T10:00:00.000Z';

  Book book({
    required String id,
    required String title,
    String author = '佚名',
    String? isbn,
    BookStatus status = BookStatus.wish,
    String? category,
    String? finishedAt,
    List<String> tags = const [],
  }) =>
      Book(
        id: id,
        title: title,
        authors: [author],
        isbn13: isbn,
        status: status,
        categoryPrimary: category,
        tags: tags,
        finishedAt: finishedAt,
        createdAt: now,
        updatedAt: now,
      );

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  group('写入与读取', () {
    test('插入后可按 id 读回，字段类型不退化', () async {
      await repo.insert(book(
        id: 'b1',
        title: '置身事内',
        author: '兰小欢',
        isbn: '9787553681380',
        status: BookStatus.finished,
        category: '经济',
        tags: ['经济'],
      ).copyWith(rating: 4.5, progressPercent: 100));

      final got = await repo.byId('b1');
      expect(got, isNotNull);
      expect(got!.title, '置身事内');
      expect(got.authors, ['兰小欢']);
      expect(got.rating, 4.5);
      expect(got.progressPercent, 100.0);
      expect(got.tags, ['经济']);
      expect(got.status, BookStatus.finished);
    });

    test('更新只改动目标记录', () async {
      await repo.insert(book(id: 'b1', title: 'A'));
      await repo.insert(book(id: 'b2', title: 'B'));
      await repo.update((await repo.byId('b1'))!.copyWith(title: 'A2'));

      expect((await repo.byId('b1'))!.title, 'A2');
      expect((await repo.byId('b2'))!.title, 'B');
    });

    test('删除', () async {
      await repo.insert(book(id: 'b1', title: 'A'));
      await repo.delete('b1');
      expect(await repo.byId('b1'), isNull);
    });

    test('批量写入跳过已存在，返回真实新增数', () async {
      await repo.insert(book(id: 'b1', title: 'A'));
      final added = await repo.insertMany([
        book(id: 'b1', title: 'A'),
        book(id: 'b2', title: 'B'),
        book(id: 'b3', title: 'C'),
      ]);
      expect(added, 2);
      expect((await repo.all()).length, 3);
    });
  });

  group('去重', () {
    test('ISBN 命中即判重', () async {
      await repo.insert(book(id: 'b1', title: '置身事内', isbn: '9787'));
      final dup = await repo.findDuplicate(book(id: 'b2', title: '另一书名', isbn: '9787'));
      expect(dup?.id, 'b1');
    });

    test('无 ISBN 时按书名+作者判重', () async {
      await repo.insert(book(id: 'b1', title: '置身事内', author: '兰小欢'));
      final dup = await repo.findDuplicate(book(id: 'b2', title: '置身事内', author: '兰小欢'));
      expect(dup?.id, 'b1');
    });

    test('同书名不同作者不算重复', () async {
      await repo.insert(book(id: 'b1', title: '置身事内', author: '兰小欢'));
      final dup = await repo.findDuplicate(book(id: 'b2', title: '置身事内', author: '他人'));
      expect(dup, isNull);
    });
  });

  group('筛选', () {
    setUp(() async {
      await repo.insertMany([
        book(id: 'b1', title: '置身事内', status: BookStatus.finished, category: '经济'),
        book(id: 'b2', title: '三体', status: BookStatus.reading, category: '文学'),
        book(id: 'b3', title: '万历十五年', status: BookStatus.wish, category: '历史'),
      ]);
    });

    test('按状态', () async {
      expect((await repo.all(status: BookStatus.finished)).length, 1);
      expect((await repo.all(status: BookStatus.reading)).length, 1);
    });

    test('按分类', () async {
      final r = await repo.all(category: '文学');
      expect(r.single.title, '三体');
    });

    test('按关键词命中书名', () async {
      expect((await repo.all(keyword: '三体')).length, 1);
      expect((await repo.all(keyword: '不存在的书')).length, 0);
    });
  });

  group('统计', () {
    setUp(() async {
      await repo.insertMany([
        book(id: 'b1', title: 'A', status: BookStatus.finished, category: '经济',
            finishedAt: '2026-01-15'),
        book(id: 'b2', title: 'B', status: BookStatus.finished, category: '经济',
            finishedAt: '2026-03-20'),
        book(id: 'b3', title: 'C', status: BookStatus.reading, category: '文学'),
      ]);
      await repo.addLog(const ReadingLog(id: 'l1', bookId: 'b1', date: '2026-01-15', durationMin: 30));
      await repo.addLog(const ReadingLog(id: 'l2', bookId: 'b2', date: '2026-03-20', durationMin: 45));
    });

    test('状态分布', () async {
      final c = await repo.statusCounts();
      expect(c[BookStatus.finished], 2);
      expect(c[BookStatus.reading], 1);
    });

    test('分类分布按数量降序', () async {
      final d = await repo.categoryDistribution();
      expect(d.first['name'], '经济');
      expect(d.first['c'], 2);
    });

    test('年度读完与月度趋势', () async {
      expect((await repo.finishedInYear(2026)).length, 2);
      expect((await repo.finishedInYear(2025)).length, 0);

      final trend = await repo.monthlyFinishedTrend(2026);
      expect(trend.length, 2);
      expect(trend.first['month'], '2026-01');
      expect(trend.last['month'], '2026-03');
    });

    test('总阅读时长', () async {
      expect(await repo.totalReadingMinutes(), 75);
    });

    test('笔记按书归属', () async {
      await repo.addNote(Note(
        id: 'n1', bookId: 'b1', type: NoteType.highlight,
        content: '金句', createdAt: now,
      ));
      final notes = await repo.notesOf('b1');
      expect(notes.single.content, '金句');
      expect(await repo.notesOf('b2'), isEmpty);
    });
  });

  group('设置读写', () {
    test('写入后可覆盖读取，未设置返回 null', () async {
      expect(await repo.getSetting('seedVersion'), isNull);
      await repo.setSetting('seedVersion', '2026-09-29');
      expect(await repo.getSetting('seedVersion'), '2026-09-29');
      await repo.setSetting('seedVersion', '2026-10-01');
      expect(await repo.getSetting('seedVersion'), '2026-10-01');
    });
  });
}
