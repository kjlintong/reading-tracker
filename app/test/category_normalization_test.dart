import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

/// 分类归一化落在 App 侧的完整性校验。
///
/// 背景：Node 数据工具链一直在做归一化，但 App 的导入链路曾整条漏掉——
/// `normalizeCategory` 定义了却从没被调用，导致同步进来的书带着
/// 「经济理财」「个人成长」这类源站分类直接入库，与种子里已归一化的
/// 「经济」「成长」并存，统计图凭空多出一堆同义分类。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database raw;
  late AppDatabase appDb;
  late BookRepository repo;

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  Book make(String id, {String? primary, String? rawCategory, String title = '书'}) =>
      Book(
        id: id,
        title: title,
        categoryPrimary: primary,
        categoryRaw: rawCategory,
        createdAt: '2026-09-29T00:00:00.000Z',
        updatedAt: '2026-09-29T00:00:00.000Z',
      );

  group('Book.withNormalizedCategory', () {
    test('源站分类被归口，原始值原样保留', () {
      final b = make('1', primary: '经济理财-财经').withNormalizedCategory();
      expect(b.categoryPrimary, '经济');
      expect(b.categoryRaw, '经济理财-财经');
    });

    test('受控词表内的值原样不动', () {
      final b = make('1', primary: '哲学').withNormalizedCategory();
      expect(b.categoryPrimary, '哲学');
    });

    test('幂等：跑两次结果一致，且不产生额外写入', () {
      final once = make('1', primary: '个人成长').withNormalizedCategory();
      final twice = once.withNormalizedCategory();
      // 已经是归一化态，第二次应直接返回同一实例（不 bump updatedAt）
      expect(identical(once, twice), isTrue);
      expect(twice.categoryPrimary, '成长');
      expect(twice.categoryRaw, '个人成长');
    });

    test('已有的 categoryRaw 优先于 categoryPrimary', () {
      final b = make('1', primary: '别的', rawCategory: '哲学宗教')
          .withNormalizedCategory();
      expect(b.categoryPrimary, '哲学');
      expect(b.categoryRaw, '哲学宗教');
    });

    test('空分类不报错', () {
      expect(make('1').withNormalizedCategory().categoryPrimary, isNull);
      expect(make('1', primary: '  ').withNormalizedCategory().categoryPrimary, isNull);
    });
  });

  group('categoryRaw 持久化', () {
    test('toMap/fromMap 往返保留 categoryRaw', () async {
      await repo.insert(
        make('1', primary: '经济理财', title: '置身事内').withNormalizedCategory(),
      );
      final got = await repo.byId('1');
      expect(got!.categoryPrimary, '经济');
      expect(got.categoryRaw, '经济理财');
    });
  });

  group('renormalizeCategories 迁移', () {
    /// 模拟 v1 数据：导入链路没归一化，categoryPrimary 里是源站分类，
    /// 且没有 categoryRaw 这一列的值
    Future<void> seedV1Rows() async {
      for (final r in [
        ('a', '经济理财'),
        ('b', '个人成长'),
        ('c', '哲学宗教'),
      ]) {
        await raw.insert('books', {
          'id': r.$1,
          'title': r.$1,
          'categoryPrimary': r.$2,
          'categoryRaw': null,
        });
      }
    }

    test('把未归一化的历史数据修好，并留下原始值', () async {
      await seedV1Rows();
      final n = await appDb.renormalizeCategories();
      expect(n, 3);

      expect((await repo.byId('a'))!.categoryPrimary, '经济');
      expect((await repo.byId('a'))!.categoryRaw, '经济理财');
      expect((await repo.byId('b'))!.categoryPrimary, '成长');
      expect((await repo.byId('c'))!.categoryPrimary, '哲学');
    });

    test('已经是受控值的不动', () async {
      await raw.insert('books', {'id': 'x', 'title': 'x', 'categoryPrimary': '经济'});
      final n = await appDb.renormalizeCategories();
      expect(n, 0, reason: '受控值不应被改写（可能来自种子数据或用户手改）');
      final got = await repo.byId('x');
      expect(got!.categoryPrimary, '经济');
      expect(got.categoryRaw, isNull, reason: '不该凭空写一个伪原始分类');
    });

    test('重复执行不再改动任何行（幂等）', () async {
      await seedV1Rows();
      expect(await appDb.renormalizeCategories(), 3);
      expect(await appDb.renormalizeCategories(), 0);
    });

    test('force 模式可基于 categoryRaw 重算全部', () async {
      await raw.insert('books', {
        'id': 'y', 'title': 'y',
        'categoryPrimary': '其他',       // 归一化错了
        'categoryRaw': '经济理财',        // 原始值还在，可以纠正
      });
      expect(await appDb.renormalizeCategories(), 0, reason: '默认模式跳过已受控值');
      expect(await appDb.renormalizeCategories(force: true), 1);
      expect((await repo.byId('y'))!.categoryPrimary, '经济');
    });

    test('空分类与无分类的行安全跳过', () async {
      await raw.insert('books', {'id': 'z', 'title': 'z'});
      await raw.insert('books', {'id': 'w', 'title': 'w', 'categoryPrimary': ''});
      expect(await appDb.renormalizeCategories(), 0);
    });
  });

  group('统计口径一致性', () {
    test('迁移后同一语义只占一个分类位', () async {
      // 源站分两次给出「经济理财」与「经济」，历史上会分裂成两类
      await raw.insert('books', {
        'id': 'p1', 'title': 'p1', 'categoryPrimary': '经济理财',
        'status': BookStatus.finished.name, 'source': BookSource.weread.name,
      });
      await raw.insert('books', {
        'id': 'p2', 'title': 'p2', 'categoryPrimary': '经济',
        'status': BookStatus.finished.name, 'source': BookSource.weread.name,
      });

      await appDb.renormalizeCategories();

      // rawQuery 返回的列名是 name / c
      final dist = await repo.categoryDistribution();
      final economics = dist.where((e) => e['name'] == '经济').toList();
      expect(economics.length, 1, reason: '不应出现两个「经济」同义分类');
      expect(economics.first['c'], 2);
    });
  });
}
