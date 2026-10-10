import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/models/reading_plan.dart';

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

  group('v2 → v3 状态迁移', () {
    /// 直接往表里塞旧状态值，模拟升级前的库。
    ///
    /// 不能走 repo.insert：Dart 侧 BookStatus 已经没有 borrowed/paused 了，
    /// 构造不出这样的 Book。而升级的真实场景正是「库里躺着旧值」，
    /// 所以必须绕过模型直接写 SQL。
    Future<void> legacy(
      String id,
      String status, {
      String? borrowedFrom,
      String? dueAt,
    }) =>
        raw.insert('books', {
          'id': id,
          'title': id,
          'status': status,
          'isBorrowed': 0,
          'borrowedFrom': borrowedFrom,
          'dueAt': dueAt,
          'createdAt': now,
          'updatedAt': now,
        });

    test('借阅中 → 在读 + 借阅标记，并保留原册摘要', () async {
      await legacy('b1', 'borrowed', borrowedFrom: '市图书馆', dueAt: '2026-10-10');
      await appDb.migrateBorrowedStatus(raw);

      final b = (await repo.byId('b1'))!;
      expect(b.status, BookStatus.reading);
      expect(b.isBorrowed, isTrue);
      // 迁移只动 status / isBorrowed，借阅的附属信息必须原样留着
      expect(b.borrowedFrom, '市图书馆');
      expect(b.dueAt, '2026-10-10');
    });

    test('弃读与暂搁都归到搁置', () async {
      await legacy('b1', 'abandoned');
      await legacy('b2', 'paused');
      await legacy('b3', 'reading');
      await appDb.migrateBorrowedStatus(raw);

      expect((await repo.byId('b1'))!.status, BookStatus.shelved);
      expect((await repo.byId('b2'))!.status, BookStatus.shelved);
      // 没被迁移波及的状态不能被动
      expect((await repo.byId('b3'))!.status, BookStatus.reading);
    });

    test('只填了借阅来源/应还日期的行也认作借阅', () async {
      await legacy('b1', 'reading', dueAt: '2026-11-01');
      await legacy('b2', 'finished', borrowedFrom: '同事');
      await legacy('b3', 'wish');
      await appDb.migrateBorrowedStatus(raw);

      expect((await repo.byId('b1'))!.isBorrowed, isTrue);
      expect((await repo.byId('b2'))!.isBorrowed, isTrue);
      // 没有任何借阅信息的书不该被误标
      expect((await repo.byId('b3'))!.isBorrowed, isFalse);
    });

    test('迁移后按状态查询能查到原「借阅中」的书', () async {
      // 这是迁移存在的根本理由：统计走的是 SQL 而不是 fromString，
      // 留在库里的 'borrowed' 会在所有按状态聚合的地方静默消失。
      await legacy('b1', 'borrowed');
      await appDb.migrateBorrowedStatus(raw);

      final reading = await repo.all(status: BookStatus.reading);
      expect(reading.map((b) => b.id), contains('b1'));
      // 状态分布统计（后台报表用 SQL group by）也要能对上
      expect((await repo.statusCounts())[BookStatus.reading], 1);
      // 旧值不该再统计出任何一类
      expect((await repo.statusCounts())[BookStatus.shelved], isNull);
    });
  });
  group('版本迁移', () {
    /// 造一个 v1 时代的库：books 没有 categoryRaw / isBorrowed，
    /// 也不存在 reading_plans 表。
    ///
    /// 只建迁移真正会碰到的列，够用即可——照抄最新表结构的话，
    /// 「这一代的库到底缺哪些列」就再也分不出来了。
    /// 用**临时文件**而不是 inMemoryDatabasePath：sqflite 的内存库是按路径
    /// 共享实例的（`:memory:` 永远指同一份），这里要的是一份全新的旧库，
    /// 否则会直接复用 setUp 已经建好的最新版本 schema，测试等于没测。
    Future<Database> openLegacy() async {
      final dir = await Directory.systemTemp.createTemp('rn_migration_test');
      final db = await databaseFactory.openDatabase('${dir.path}/legacy.db');
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      await db.execute('''
        CREATE TABLE books (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          authors TEXT,
          categoryPrimary TEXT,
          status TEXT,
          borrowedFrom TEXT,
          dueAt TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      await db.insert('books', {
        'id': 'b1',
        'title': '置身事内',
        'authors': '兰小欢',
        'categoryPrimary': '经济理财',
        'status': 'finished',
        'createdAt': now,
        'updatedAt': now,
      });
      return db;
    }

    Future<List<String>> columns(Database db, String table) async {
      final rows = await db.rawQuery('PRAGMA table_info($table)');
      return [for (final r in rows) r['name'] as String];
    }

    test('v1 → v6 不会重复加列（历史致命缺陷）', () async {
      final legacy = await openLegacy();

      // 历史上这一句会抛 duplicate column name：
      // oldV<4 的 CREATE 里带了 lastDoneOn，紧接着 oldV<5 又 ALTER 一次。
      // 异常把整段迁移连同 PRAGMA user_version 一起回滚，
      // 用户覆盖安装后再也打不开 App，而且版本号没写上、重装也没用。
      await expectLater(appDb.upgradeForTest(legacy, 1, 6), completes);

      final books = await columns(legacy, 'books');
      expect(books, contains('categoryRaw'));
      expect(books, contains('isBorrowed'));

      final plans = await columns(legacy, 'reading_plans');
      expect(plans, contains('lastDoneOn'));
      expect(plans, contains('checkins'));
      // 同名列必须只有一份——重复加列当年就是因为这里裂开而炸的
      expect(plans.where((c) => c == 'lastDoneOn'), hasLength(1));
      expect(plans.where((c) => c == 'checkins'), hasLength(1));
    });

    test('任一旧版本升级到 v6 都能跑完，且列不重不漏', () async {
      final legacy = await openLegacy();

      // 反复在同一个库上跑：真实设备只会走一条路径，但一列对这些路径
      // 全都成立，才说明加列是真的幂等，而不是碰巧这次没撞上。
      for (final from in const [1, 2, 3, 4, 5]) {
        await expectLater(
          appDb.upgradeForTest(legacy, from, 6),
          completes,
          reason: '从 v$from 升级应当顺利完成',
        );
      }

      final plans = await columns(legacy, 'reading_plans');
      expect(plans.where((c) => c == 'lastDoneOn'), hasLength(1),
          reason: 'lastDoneOn 跑了五轮迁移也只应存在一份');
      expect(plans.where((c) => c == 'checkins'), hasLength(1));
    });

    test('迁移后仍可向 reading_plans 写入打卡字段', () async {
      final legacy = await openLegacy();
      await appDb.upgradeForTest(legacy, 1, 6);

      await legacy.insert('reading_plans', {
        'id': 'p1',
        'kind': 'dailyMinutes',
        'title': '每天 20 分钟',
        'dailyMinutes': 20,
        'createdAt': now,
        'lastDoneOn': '2026-10-10',
        'checkins': '2026-10-08,2026-10-09,2026-10-10',
      });

      final rows = await legacy.query('reading_plans');
      expect(rows, hasLength(1));
      expect(rows.first['checkins'], '2026-10-08,2026-10-09,2026-10-10');
    });
  });

  group('阅读计划', () {
    /// 造一条时长型计划。createdAt 由调用方给，好控制「从哪天开始算」。
    ReadingPlan daily({
      required String id,
      required int minutes,
      required String createdAt,
      bool done = false,
    }) =>
        ReadingPlan(
          id: id,
          kind: PlanKind.dailyMinutes,
          dailyMinutes: minutes,
          createdAt: createdAt,
          done: done,
        );

    ReadingPlan finish({
      required String id,
      required String bookId,
      String? dueDate,
      String createdAt = '2026-09-01T00:00:00.000Z',
    }) =>
        ReadingPlan(
          id: id,
          kind: PlanKind.finishBook,
          bookId: bookId,
          dueDate: dueDate,
          createdAt: createdAt,
        );

    Future<void> log(String id, String date, int min) =>
        repo.addLog(ReadingLog(id: id, bookId: 'b1', date: date, durationMin: min));

    String iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}T00:00:00.000Z';

    test('存取往返不丢字段', () async {
      final p = ReadingPlan(
        id: 'p1',
        kind: PlanKind.finishBook,
        title: '本月读完这本书',
        bookId: 'b1',
        dueDate: '2026-10-31',
        reminderEnabled: true,
        createdAt: now,
      );
      await repo.upsertPlan(p);
      final got = (await repo.plans()).single;
      expect(got.id, 'p1');
      expect(got.kind, PlanKind.finishBook);
      expect(got.title, '本月读完这本书');
      expect(got.bookId, 'b1');
      expect(got.dueDate, '2026-10-31');
      expect(got.reminderEnabled, isTrue);
      expect(got.done, isFalse);
    });

    test('upsert 同 id 是更新而不是插两条', () async {
      await repo.upsertPlan(daily(id: 'p1', minutes: 30, createdAt: now));
      await repo.upsertPlan(daily(id: 'p1', minutes: 45, createdAt: now));
      final all = await repo.plans();
      expect(all.length, 1);
      expect(all.single.dailyMinutes, 45);
    });

    test('已完成的计划排在进行中的后面', () async {
      // 用户每天要看的是「还没做完的」，完成的不该占着首屏
      await repo.upsertPlan(daily(id: 'done1', minutes: 10, createdAt: now, done: true));
      await repo.upsertPlan(daily(id: 'live1', minutes: 10, createdAt: now));
      final all = await repo.plans();
      expect(all.first.id, 'live1');
      expect(all.last.id, 'done1');
    });

    test('activePlans 只返回未完成的', () async {
      await repo.upsertPlan(daily(id: 'a', minutes: 10, createdAt: now));
      await repo.upsertPlan(daily(id: 'b', minutes: 10, createdAt: now, done: true));
      final active = await repo.activePlans();
      expect(active.map((p) => p.id), ['a']);
    });

    test('durations 型：日均达到目标才算达成', () async {
      final created = DateTime.now().subtract(const Duration(days: 2));
      // 从创建日到今天共 3 天（含今天），每天 30 分钟 → 日均 30
      await log('l1', iso(created), 30);
      await log('l2', iso(created.add(const Duration(days: 1))), 30);
      await log('l3', '${DateTime.now().year.toString().padLeft(4, '0')}-'
          '${DateTime.now().month.toString().padLeft(2, '0')}-'
          '${DateTime.now().day.toString().padLeft(2, '0')}', 30);

      final p = daily(id: 'p1', minutes: 30, createdAt: iso(created));
      final pr = await repo.planProgress(p);
      expect(pr.achieved, isTrue);
      expect(pr.ratio, closeTo(1.0, 0.001));
    });

    test('durations 型：日均不够就不算达成，且比率反映真实差距', () async {
      final created = DateTime.now().subtract(const Duration(days: 3));
      // 4 天只读了 60 分钟 → 日均 15，目标 30 → 50%
      await log('l1', iso(created), 60);
      final p = daily(id: 'p1', minutes: 30, createdAt: iso(created));
      final pr = await repo.planProgress(p);
      expect(pr.achieved, isFalse);
      expect(pr.ratio, closeTo(0.5, 0.02));
    });

    test('计划创建之前的日志不计入，否则老账会把新目标撑成已完成', () async {
      final created = DateTime.now();
      // 去年读了一大堆，跟今天立的目标无关
      final old = DateTime.now().subtract(const Duration(days: 200));
      await log('old', iso(old), 6000);
      final p = daily(id: 'p1', minutes: 20, createdAt: iso(created));
      final pr = await repo.planProgress(p);
      expect(pr.current, 0);
      expect(pr.achieved, isFalse);
    });

    test('finishBook 型：状态为已读完即达成，不看进度条', () async {
      // 用户可能勾了「已读完」却没把进度条拖到底，此时以状态为准
      await repo.insert(book(
        id: 'b1',
        title: '目标书',
        status: BookStatus.finished,
      ));
      final pr = await repo.planProgress(finish(id: 'p1', bookId: 'b1'));
      expect(pr.achieved, isTrue);
      expect(pr.current, 100);
    });

    test('finishBook 型：在读但没读完，按实际进度算比率', () async {
      await repo.insert(Book(
        id: 'b1',
        title: '目标书',
        authors: const ['佚名'],
        status: BookStatus.reading,
        progressPercent: 40,
        createdAt: now,
        updatedAt: now,
      ));
      final pr = await repo.planProgress(finish(id: 'p1', bookId: 'b1'));
      expect(pr.achieved, isFalse);
      expect(pr.ratio, closeTo(0.4, 0.001));
    });

    test('目标书被删掉：不判达成也不崩，界面交给用户处理', () async {
      final pr = await repo.planProgress(finish(id: 'p1', bookId: '不存在'));
      expect(pr.achieved, isFalse);
      expect(pr.current, 0);
    });

    test('倒计时：逾期是负数，今天到期是 0', () async {
      final today = DateTime.now();
      String pad(int n) => n.toString().padLeft(2, '0');
      String fmt(DateTime d) => '${d.year}-${pad(d.month)}-${pad(d.day)}';

      final overdue = finish(
        id: 'p1',
        bookId: 'b1',
        dueDate: fmt(today.subtract(const Duration(days: 3))),
      );
      final dueToday = finish(
        id: 'p2',
        bookId: 'b1',
        dueDate: fmt(today),
      );
      expect(overdue.daysUntilDue, -3);
      expect(dueToday.daysUntilDue, 0);
    });

    test('报告载荷带达成情况，且口径与计划卡片同源', () async {
      await repo.insert(book(
        id: 'b1',
        title: '目标书',
        status: BookStatus.finished,
      ));
      final created = DateTime.now().subtract(const Duration(days: 1));
      await repo.upsertPlan(finish(id: 'p1', bookId: 'b1', createdAt: iso(created)));
      await repo.upsertPlan(daily(id: 'p2', minutes: 30, createdAt: iso(created)));

      final snaps = await repo.activePlanProgress();
      expect(snaps.length, 2);
      final byId = {for (final s in snaps) s.plan.id: s};

      // 这是一个**行为契约**：报告里的数字必须和卡片上看到的一致，
      // 否则用户会看到「卡片说达成、报告说没达成」这种打脸的情况。
      final js = byId['p1']!.toReportJson();
      expect(js['achieved'], isTrue);
      expect(js['kind'], 'finishBook');
      expect(js['dueDate'], isNull);
      expect(js['target'], 100);
      expect(js['current'], 100);

      final js2 = byId['p2']!.toReportJson();
      expect(js2['achieved'], isFalse);
      expect(js2['kind'], 'dailyMinutes');
      expect(js2['targetMinutesPerDay'], 30);
    });

    test('已完成的计划不进报告载荷：复盘的是「还在追的」', () async {
      await repo.upsertPlan(daily(id: 'p1', minutes: 10, createdAt: now, done: true));
      final snaps = await repo.activePlanProgress();
      expect(snaps, isEmpty);
    });

    test('删计划会连带清掉', () async {
      await repo.upsertPlan(daily(id: 'p1', minutes: 10, createdAt: now));
      await repo.deletePlan('p1');
      expect(await repo.plans(), isEmpty);
    });
  });

}
