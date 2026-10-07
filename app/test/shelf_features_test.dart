import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/category_prefs.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/models/reading_plan.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 删除书 / 标签筛选 / 分类可编辑 三件事的回归。
///
/// 共同点：都是「用户以为有、实际没有或会出错」的地方。
/// 删除不是删一行（孤儿笔记会一直躺在库里），标签筛选不是 LIKE 一下
/// （tags 是 JSON 数组），分类可编辑也不是改一份常量（改完还要管存量书）。
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database raw;
  late BookRepository repo;
  const now = '2026-10-07T10:00:00.000Z';

  Book book(
    String id, {
    String title = '书',
    String? category,
    List<String> tags = const [],
  }) =>
      Book(
        id: id,
        title: title,
        categoryPrimary: category,
        tags: tags,
        status: BookStatus.wish,
        createdAt: now,
        updatedAt: now,
      );

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
    // 词表是全局单例，测试之间必须复位，否则上一个用例的自定义分类
    // 会漏到下一个用例里（表现为「莫名其妙多出一个分类」）。
    restoreDefaultCategories();
  });

  tearDown(() async {
    restoreDefaultCategories();
    await raw.close();
  });

  group('删除书：派生态跟着走，笔记留下', () {
    test('书、阅读记录、计划一起消失', () async {
      await repo.insertMany([book('a', title: '待删'), book('b', title: '留着')]);
      await repo.addLog(ReadingLog(
          id: 'l1', bookId: 'a', date: '2026-10-01', durationMin: 30));
      await repo.upsertPlan(ReadingPlan(
        id: 'p1',
        kind: PlanKind.finishBook,
        bookId: 'a',
        createdAt: now,
      ));

      await repo.delete('a');

      expect((await repo.all()).map((b) => b.id), ['b']);
      // 留着的话，「总阅读时长」会继续统计一本已经不存在的书
      expect(await raw.query('reading_logs'), isEmpty);
      // 目标书都没了的计划永远无法达成
      expect(await raw.query('reading_plans'), isEmpty);
    });

    test('笔记不跟着删：它们是用户手打的内容', () async {
      await repo.insertMany([book('a', title: '待删')]);
      await repo.addNote(
          Note(id: 'n1', bookId: 'a', content: '我的想法', createdAt: now));

      await repo.delete('a');

      // 书可以是误导入的重复条目，写在它下面的想法不能跟着蒸发。
      // 于是必然出现孤儿笔记，界面用占位书名顶住（见 notes_page_test）。
      final items = await repo.allNotes();
      expect(items, hasLength(1));
      expect(items.first.book, isNull);
    });
  });

  group('标签筛选', () {
    test('按 JSON 数组里的标签计数，不是全文匹配', () async {
      await repo.insertMany([
        book('a', tags: ['想读', '哲学']),
        book('b', tags: ['哲学']),
        book('c', tags: ['想读']),
        book('d'),
      ]);

      final dist = await repo.tagDistribution();
      final byName = {for (final t in dist) t['name'] as String: t['c'] as int};
      expect(byName['想读'], 2);
      expect(byName['哲学'], 2);
      // 没有标签的书不产生计数项
      expect(byName.containsKey(''), isFalse);

      // 子串不能误命中：'想' 不该匹配到「想读」
      expect((await repo.all(tag: '想读')).map((b) => b.id), ['a', 'c']);
      expect((await repo.all(tag: '哲学')).map((b) => b.id), ['a', 'b']);
    });

    test('标签与其它筛选条件叠加', () async {
      await repo.insertMany([
        book('a', category: '哲学', tags: ['长篇']),
        book('b', category: '文学', tags: ['长篇']),
      ]);
      expect(
        (await repo.all(category: '哲学', tag: '长篇')).map((b) => b.id),
        ['a'],
      );
    });
  });

  group('分类筛选', () {
    test('「未分类」同时接住 NULL 和字面值，与分布计数对得上', () async {
      // 分布把 categoryPrimary 为 NULL 的书 COALESCE 成「未分类」，
      // 筛选若只做等值匹配，这拨书就永远筛不出来——分布说 39 本、
      // 筛出来十几本，用户看到的就是「筛选没生效」。
      await repo.insertMany([
        book('a'), // category 为 NULL
        book('b', category: kUncategorized),
        book('c', category: '哲学'),
      ]);

      final dist = await repo.categoryDistribution();
      final byName = {for (final c in dist) c['name'] as String: c['c'] as int};
      expect(byName[kUncategorized], 2);

      expect(
        (await repo.all(category: kUncategorized)).map((b) => b.id),
        ['a', 'b'],
      );
      expect((await repo.all(category: '哲学')).map((b) => b.id), ['c']);
    });
  });

  group('分类可编辑', () {
    test('新增的分类进生效词表，默认分类不受影响', () {
      expect(categoryVocabulary.active, defaultCategories);
      expect(addCategory('烹饪'), isTrue);
      expect(categoryVocabulary.active, [...defaultCategories, '烹饪']);
      expect(categoryVocabulary.isCustom('烹饪'), isTrue);
      // 重名拒绝：下拉框里出现两个一样的值，用户没法分辨该选哪个
      expect(addCategory('烹饪'), isFalse);
      expect(addCategory(''), isFalse);
      expect(addCategory(kUncategorized), isFalse);
    });

    test('删除默认分类后它不再生效，加回来还在原来的位置', () {
      final idx = defaultCategories.indexOf('宗教');
      removeCategory('宗教');
      expect(categoryVocabulary.active.contains('宗教'), isFalse);
      expect(categoryVocabulary.hidden, ['宗教']);

      addCategory('宗教');
      // 重新加回的是默认分类，应该回到默认词表里原来的位置，
      // 而不是被当成自定义分类追加到末尾
      expect(categoryVocabulary.active.indexOf('宗教'), idx);
      expect(categoryVocabulary.isCustom('宗教'), isFalse);
    });

    test('默认分类改名后不会和旧名字同时出现', () {
      renameCategory('宗教', '信仰');
      final active = categoryVocabulary.active;
      // 少了这步就会同时出现「宗教」和「信仰」——用户只想留一个
      expect(active.contains('宗教'), isFalse);
      expect(active.contains('信仰'), isTrue);
      expect(active.where((c) => c == '信仰'), hasLength(1));
    });

    test('归一化认用户新增的分类，不把它折进「其他」', () {
      // 「烹饪」在别名表里是映射到「其他」的；用户显式加了这个分类之后
      // 就该直接归到它，否则「新增分类」等于没生效
      expect(normalizeCategory('烹饪'), '其他');
      addCategory('烹饪');
      expect(normalizeCategory('烹饪'), '烹饪');
    });

    test('删掉的分类不会被新导入的书带回来', () {
      expect(normalizeCategory('哲学宗教'), '哲学');
      removeCategory('哲学');
      // 别名表是按语义写死的，它不知道用户已经不要这个分类了
      expect(normalizeCategory('哲学宗教'), '其他');
    });

    test('删除分类时把书迁到「未分类」', () async {
      await repo.insertMany([
        book('a', category: '宗教'),
        book('b', category: '宗教'),
        book('c', category: '文学'),
      ]);
      expect(await repo.categoryCount('宗教'), 2);

      final moved = await repo.recategorize('宗教', kUncategorized);
      expect(moved, 2);

      expect(await repo.categoryCount('宗教'), 0);
      expect(await repo.categoryCount(kUncategorized), 2);
      expect((await repo.all(category: '文学')).map((b) => b.id), ['c']);
    });

    test('改分类名时存量书跟着走', () async {
      await repo.insertMany([
        book('a', category: '宗教'),
        book('b', category: '文学'),
      ]);
      renameCategory('宗教', '信仰');
      expect(await repo.recategorize('宗教', '信仰'), 1);
      expect((await repo.all(category: '信仰')).map((b) => b.id), ['a']);
      expect((await repo.all(category: '文学')).map((b) => b.id), ['b']);
    });

    test('存坏的 JSON 不会让词表崩掉', () {
      applyCategoryVocabulary(custom: '这不是 JSON', hidden: null);
      // 一个损坏的偏好值只能退化成「用户没改过」，不该让书架打不开
      expect(categoryVocabulary.active, defaultCategories);
    });

    test('两个名单能原样存取', () {
      addCategory('烹饪');
      removeCategory('宗教');
      final custom = encodeCategoryList(categoryVocabulary.custom);
      final hidden = encodeCategoryList(categoryVocabulary.hidden);

      restoreDefaultCategories();
      expect(categoryVocabulary.isEmpty, isTrue);

      applyCategoryVocabulary(custom: custom, hidden: hidden);
      expect(categoryVocabulary.custom, ['烹饪']);
      expect(categoryVocabulary.hidden, ['宗教']);
    });
  });
}
