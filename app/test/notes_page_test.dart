import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/book_detail_page.dart';
import 'package:reading_tracker/ui/notes_page.dart';

import 'support/localized_app.dart';

/// 笔记页的行为测试。
///
/// 这一页是新增的第五个主栏目，覆盖三件最容易出错的事：
/// 1. 跨书聚合是否正确（此前笔记只能按 `bookId` 单本查，没有全库入口）；
/// 2. 「按时间 / 按书」两种分组是否真的换了分组方式，而不是换个标题；
/// 3. 点笔记能不能跳回它的书——这是本页唯一的动作出口。
void main() {
  // UI 测试必须用 NoIsolate 版本：默认的 databaseFactoryFfi 把 SQL 放到独立
  // isolate，而 testWidgets 跑在 FakeAsync zone 内，回信永远等不到。
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database raw;
  late BookRepository repo;

  String nowIso() => DateTime.now().toIso8601String();

  Book book(String id, String title, {String author = '佚名'}) => Book(
        id: id,
        title: title,
        authors: [author],
        status: BookStatus.finished,
        createdAt: nowIso(),
        updatedAt: nowIso(),
      );

  Note note(String id, String bookId, String content,
          {NoteType type = NoteType.thought}) =>
      Note(
        id: id,
        bookId: bookId,
        type: type,
        content: content,
        createdAt: nowIso(),
      );

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  Widget harness(Widget child) => ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: localizedApp(home: child),
      );

  /// 数据库查询是真实异步，而 testWidgets 跑在 FakeAsync 里。
  /// 不先把控制权交还真实事件循环，Future 永远不 resolve。
  Future<void> settleAsync(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  Future<void> pumpNotes(WidgetTester tester) async {
    await tester.pumpWidget(harness(const NotesPage()));
    await settleAsync(tester);
  }

  testWidgets('无笔记时给出引导，而不是空白页', (tester) async {
    await pumpNotes(tester);
    expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);
    // 空态必须说清「下一步能做什么」，只写「暂无数据」等于没写。
    expect(find.textContaining('打开任意一本书'), findsOneWidget);
  });

  testWidgets('按时间视图列出全库笔记，并带上所属书名', (tester) async {
    await repo.insertMany([book('b1', '沉思录'), book('b2', '百年孤独')]);
    await repo.addNote(note('n1', 'b1', '未加思索的行动不是行动，而是习惯。'));
    await repo.addNote(note('n2', 'b2', '过去都是假的，回忆没有归路。'));

    await pumpNotes(tester);

    expect(find.text('未加思索的行动不是行动，而是习惯。'), findsOneWidget);
    expect(find.text('过去都是假的，回忆没有归路。'), findsOneWidget);
    // 「按时间」视图每条都要标出来自哪本书，否则脱离了上下文没法读。
    expect(find.text('沉思录'), findsWidgets);
    expect(find.text('百年孤独'), findsWidgets);
  });

  testWidgets('概览按书去重，不是把笔记数抄一遍', (tester) async {
    await repo.insertMany([book('b1', '沉思录')]);
    // 同一本书写 3 条：笔记数是 3，覆盖的书仍是 1 本。
    await repo.addNote(note('n1', 'b1', '第一条'));
    await repo.addNote(note('n2', 'b1', '第二条'));
    await repo.addNote(note('n3', 'b1', '第三条'));

    await pumpNotes(tester);

    expect(find.text('共 3 条 · 覆盖 1 本书'), findsOneWidget);
  });

  testWidgets('切到「按书」后按书分组，同一本书只出现一个卡片头', (tester) async {
    await repo.insertMany([book('b1', '沉思录'), book('b2', '百年孤独')]);
    await repo.addNote(note('n1', 'b1', '沉思录笔记一'));
    await repo.addNote(note('n2', 'b1', '沉思录笔记二'));
    await repo.addNote(note('n3', 'b2', '百年孤独笔记一'));

    await pumpNotes(tester);
    await tester.tap(find.text('按书'));
    await settleAsync(tester);

    // 分组视图的关键不是「显示了笔记」，而是「同一本书的笔记被归到一处」。
    // 3 条笔记分 2 组：分组数为 2，而不是 3。
    final cards = tester.widgetList<Card>(find.byType(Card));
    expect(cards.length, 2);
    expect(find.text('沉思录笔记一'), findsOneWidget);
    expect(find.text('沉思录笔记二'), findsOneWidget);
    expect(find.text('百年孤独笔记一'), findsOneWidget);
  });

  testWidgets('点笔记跳到它所属书籍的详情页', (tester) async {
    await repo.insertMany([book('b1', '沉思录'), book('b2', '百年孤独')]);
    await repo.addNote(note('n1', 'b2', '过去都是假的，回忆没有归路。'));

    await pumpNotes(tester);
    await tester.tap(find.text('过去都是假的，回忆没有归路。'));
    await tester.pumpAndSettle();
    await settleAsync(tester);

    expect(find.byType(BookDetailPage), findsOneWidget);
    // 必须跳到笔记所属的那本书，而不是跳到列表第一本。
    expect(find.text('百年孤独'), findsWidgets);
  });

  test('allNotes 按 bookId 过滤，且按时间倒序', () async {
    await repo.insertMany([book('b1', '沉思录'), book('b2', '百年孤独')]);
    await repo.addNote(Note(
      id: 'old',
      bookId: 'b1',
      content: '旧的',
      createdAt: '2026-01-01T00:00:00.000Z',
    ));
    await repo.addNote(Note(
      id: 'new',
      bookId: 'b1',
      content: '新的',
      createdAt: '2026-06-01T00:00:00.000Z',
    ));
    await repo.addNote(Note(
      id: 'other',
      bookId: 'b2',
      content: '别的书',
      createdAt: '2026-05-01T00:00:00.000Z',
    ));

    final filtered = await repo.allNotes(bookId: 'b1');
    expect(filtered.length, 2);
    // 新的在前：笔记页是「最近记了什么」的入口，顺序错了整页就没意义。
    expect(filtered.first.note.id, 'new');
    expect(filtered.first.book?.title, '沉思录');

    final all = await repo.allNotes();
    expect(all.length, 3);
  });

  test('booksWithNotes 只返回写过笔记的书', () async {
    await repo.insertMany([
      book('b1', '有笔记的书'),
      book('b2', '没笔记的书'),
    ]);
    await repo.addNote(note('n1', 'b1', '一条'));

    final books = await repo.booksWithNotes();
    expect(books.map((b) => b.title).toList(), ['有笔记的书']);
  });

  test('笔记所属的书被删除后仍能显示，不崩', () async {
    await repo.insertMany([book('b1', '会被删的书')]);
    await repo.addNote(note('n1', 'b1', '书没了但笔记还在'));
    // 删书不级联删笔记：笔记是用户手打的内容，比书籍记录更不该被顺手清掉。
    // 于是必然出现「笔记还在、书没了」的数据，界面必须能扛住。
    await repo.delete('b1');

    final items = await repo.allNotes();
    expect(items.length, 1);
    expect(items.first.book, isNull);
    // 界面走的就是这条分支：书名缺失时给占位文案而不是 book!.title。
    expect(items.first.title('书籍已不存在'), '书籍已不存在');
  });
}
