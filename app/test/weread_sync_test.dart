import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/ai/ai_client.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/import/import_manager.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

/// 微信读书同步的字段语义校验。
///
/// 这里的所有期望值都来自对官方网关的**真实抓包**
/// （见 `tools/samples/weread-shelf-raw-live.json`），不是推测：
///
/// - `/shelf/sync` 每本书只有 10 个字段，**没有** readingProgress、
///   也**没有** markedStatus，所以状态只能从 finishReading 与
///   updateTime/readUpdateTime 的关系推。
/// - `readUpdateTime` **恒大于 0**，哪怕从没读过的书也有值
///   （实测某本从未阅读的书 readUpdateTime 早于 updateTime），
///   因此 `readUpdateTime > 0` 是个会误判的判据，必须比时间先后。
class _FakeGateway extends WereadGateway {
  final List<Map<String, dynamic>> shelfRows;
  final Map<String, ReadingProgress> progresses;
  final List<String> progressCalls = [];

  _FakeGateway(this.shelfRows, {this.progresses = const {}});

  @override
  bool get available => true;

  @override
  Future<List<Map<String, dynamic>>> shelf() async => shelfRows;

  @override
  Future<ReadingProgress> progressOf(String bookId) async {
    progressCalls.add(bookId);
    final p = progresses[bookId];
    if (p == null) throw StateError('no progress for $bookId');
    return p;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 实测样本：加入书架 1789017454，之后读到 1790664442 → 在读
  const readBook = {
    'bookId': '3300062053',
    'deepLink': 'https://weread.qq.com/book-detail?type=1&v=8c332830813ab7ebdg013f1c',
    'title': '经济学的思维方式：第13版',
    'author': '[美]保罗·海恩 [美]彼得·勃特克 [美]大卫·普雷契特科',
    'updateTime': 1789017454,
    'cover': 'https://cdn.weread.qq.com/weread/cover/80/x.jpg',
    'finishReading': 0,
    'readUpdateTime': 1790664442,
    'secret': 1,
    'category': '经济理财-财经',
  };

  // 实测样本：readUpdateTime(1616718207) 早于 updateTime(1760179191)
  // —— 加入书架之前就没再碰过，属于想读
  const unreadBook = {
    'bookId': '908796',
    'deepLink': 'https://weread.qq.com/book-detail?type=1&v=aaa',
    'title': '黑马波段操盘术（升级版）',
    'author': '凌波',
    'updateTime': 1760179191,
    'cover': 'https://cdn.weread.qq.com/weread/cover/1/y.jpg',
    'finishReading': 0,
    'readUpdateTime': 1616718207,
    'secret': 1,
    'category': '经济理财',
  };

  const finishedBook = {
    'bookId': '777',
    'title': '读完的书',
    'author': '某作者',
    'updateTime': 1700000000,
    'finishReading': 1,
    'readUpdateTime': 1750000000,
    'category': '个人成长',
  };

  group('deriveStatus（基于实测字段）', () {
    test('读过之后没读完 → 在读', () {
      expect(WereadGateway.deriveStatus(readBook), BookStatus.reading);
    });

    test('从未读过（readUpdateTime 早于入架时间）→ 想读', () {
      expect(WereadGateway.deriveStatus(unreadBook), BookStatus.wish);
    });

    test('finishReading=1 → 已读，优先于时间判断', () {
      expect(WereadGateway.deriveStatus(finishedBook), BookStatus.finished);
    });

    test('readUpdateTime 有值但为 0 也不当作已读', () {
      expect(
        WereadGateway.deriveStatus({'updateTime': 100, 'readUpdateTime': 0}),
        BookStatus.wish,
      );
    });

    test('字段缺失时安全回落到想读，不抛异常', () {
      expect(WereadGateway.deriveStatus({}), BookStatus.wish);
    });

    test('字符串数字也能解析（网关偶有返回字符串）', () {
      expect(
        WereadGateway.deriveStatus(
            {'updateTime': '100', 'readUpdateTime': '200'}),
        BookStatus.reading,
      );
    });
  });

  group('toMeta 字段映射', () {
    test('分类落到 categoryRaw 而不是 categoryPrimary', () {
      final m = WereadGateway.toMeta(readBook);
      expect(m['categoryRaw'], '经济理财-财经');
      expect(m.containsKey('categoryPrimary'), isFalse,
          reason: '未归一化的源站分类不能直接当 categoryPrimary');
    });

    test('deepLink 成为 sourceUrl', () {
      expect(WereadGateway.toMeta(readBook)['sourceUrl'], readBook['deepLink']);
    });

    test('秒级时间戳转成 ISO8601', () {
      final m = WereadGateway.toMeta(readBook);
      expect(m['addedAt'], isNotNull);
      expect(DateTime.parse(m['addedAt'] as String).year, 2026);
      expect(DateTime.parse(m['lastReadAt'] as String).year, 2026);
    });

    test('时间戳为 0 或缺失时不编造时间', () {
      final m = WereadGateway.toMeta({'title': 'x'});
      expect(m['addedAt'], isNull);
      expect(m['lastReadAt'], isNull);
    });
  });

  group('ReadingProgress 解析（实测响应结构）', () {
    test('progress 是 0-100 整数，直接当百分比', () {
      final p = ReadingProgress.fromResponse('b1', {
        'bookId': 'b1',
        'book': {
          'chapterUid': 296,
          'chapterIdx': 2,
          'updateTime': 1790664442,
          'readingTime': 64,
          'progress': 37,
          'isStartReading': 1,
          'recordReadingTime': 0,
        },
      });
      expect(p.progressPercent, 37);
      expect(p.isStartReading, isTrue);
      expect(p.chapterIdx, 2);
    });

    test('累计时长优先取 recordReadingTime，为空才回退 readingTime', () {
      final withTotal = ReadingProgress.fromResponse('b', {
        'book': {'recordReadingTime': 3600, 'readingTime': 64},
      });
      expect(withTotal.readingTimeSec, 3600);

      // 实测里出现过 recordReadingTime=0 而 readingTime=64
      final onlySession = ReadingProgress.fromResponse('b', {
        'book': {'recordReadingTime': 0, 'readingTime': 64},
      });
      expect(onlySession.readingTimeSec, 64);
    });

    test('book 字段缺失时也不崩', () {
      final p = ReadingProgress.fromResponse('b2', {'bookId': 'b2'});
      expect(p.progress, 0);
      expect(p.readingTimeSec, 0);
    });
  });

  group('ImportManager 同步链路', () {
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

    ImportManager manager() => ImportManager(
          repo: repo,
          metadata: MetadataClient(weread: WereadGateway(apiKey: null)),
          llm: LlmClient(apiKey: null),
        );

    test('书架同步带上状态、深链与归一化分类', () async {
      final books = await manager().fetchWereadShelf(
        _FakeGateway([readBook, unreadBook, finishedBook]),
      );

      expect(books.length, 3);
      final read = books.firstWhere((b) => b.title.contains('经济学'));
      expect(read.status, BookStatus.reading);
      expect(read.categoryPrimary, '经济');
      expect(read.categoryRaw, '经济理财-财经');
      expect(read.sourceUrl, readBook['deepLink']);
      expect(read.sourceBookId, '3300062053');

      final unread = books.firstWhere((b) => b.title.contains('黑马'));
      expect(unread.status, BookStatus.wish);
      expect(unread.startedAt, isNull, reason: '没读过的书不该有开始时间');
      expect(unread.categoryPrimary, '经济');

      expect(books.last.status, BookStatus.finished);
      expect(books.last.categoryPrimary, '成长');
    });

    test('作者字段按分隔符拆开', () async {
      final books = await manager().fetchWereadShelf(_FakeGateway([readBook]));
      // 实测微信读书把多个作者塞在一个字符串里，以空格分隔
      expect(books.first.authors.length, greaterThanOrEqualTo(1));
      expect(books.first.authors.first, isNotEmpty);
    });

    test('落库后分类是归一化值，原始值仍在', () async {
      final books = await manager().fetchWereadShelf(_FakeGateway([readBook]));
      await repo.insertMany(books);

      final saved = await repo.bySourceBookId('3300062053', BookSource.weread);
      expect(saved, isNotNull);
      expect(saved!.categoryPrimary, '经济');
      expect(saved.categoryRaw, '经济理财-财经');
      expect(saved.status, BookStatus.reading);
    });

    test('进度同步回写百分比与时长', () async {
      final books = await manager().fetchWereadShelf(_FakeGateway([readBook]));
      await repo.insertMany(books);

      final gateway = _FakeGateway([readBook], progresses: {
        '3300062053': const ReadingProgress(
          bookId: '3300062053',
          progress: 42,
          chapterIdx: 5,
          readingTimeSec: 7200,
          isStartReading: true,
        ),
      });

      final n = await manager().syncProgress(
        ['3300062053'],
        gateway: gateway,
      );
      expect(n, 1);
      expect(gateway.progressCalls, ['3300062053']);

      final saved = await repo.bySourceBookId('3300062053', BookSource.weread);
      expect(saved!.progressPercent, 42);
      expect(saved.status, BookStatus.reading);
      expect(saved.extra['wereadReadingTimeSec'], 7200);
    });

    test('进度同步不把「已读」状态覆盖回去', () async {
      final books = await manager().fetchWereadShelf(_FakeGateway([finishedBook]));
      await repo.insertMany(books);

      await manager().syncProgress(['777'], gateway: _FakeGateway([], progresses: {
        '777': const ReadingProgress(bookId: '777', progress: 100),
      }));

      final saved = await repo.bySourceBookId('777', BookSource.weread);
      expect(saved!.status, BookStatus.finished,
          reason: '已读是用户的判断，进度接口无权改写');
    });

    test('单本进度失败不中断整批', () async {
      final books = await manager().fetchWereadShelf(
        _FakeGateway([readBook, unreadBook]),
      );
      await repo.insertMany(books);

      final gateway = _FakeGateway([], progresses: {
        // 只给其中一本，另一本会抛异常
        '908796': const ReadingProgress(bookId: '908796', progress: 10),
      });
      final n = await manager().syncProgress(
        ['3300062053', '908796'],
        gateway: gateway,
      );
      expect(n, 1);
      expect(gateway.progressCalls.length, 2, reason: '失败的那本也要走到');
    });

    test('本地没有对应记录时跳过而不是崩', () async {
      final n = await manager().syncProgress(
        ['does-not-exist'],
        gateway: _FakeGateway([], progresses: {
          'does-not-exist': const ReadingProgress(bookId: 'x', progress: 5),
        }),
      );
      expect(n, 0);
    });
  });

  group('导入进度与失败留痕', () {
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

    test('onProgress 覆盖 0..total', () async {
      final m = ImportManager(
        repo: repo,
        metadata: MetadataClient(weread: WereadGateway(apiKey: null)),
        llm: LlmClient(apiKey: null),
      );
      final seen = <int>[];
      await m.commit(
        [
          Book(id: '1', title: 'a', createdAt: 'now', updatedAt: 'now'),
          Book(id: '2', title: 'b', createdAt: 'now', updatedAt: 'now'),
        ],
        enrichMetadata: false,
        onProgress: (done, total) => seen.add(done),
      );
      expect(seen.first, 0);
      expect(seen.last, 2);
    });

    test('导入时分类被归一化（收口在这一层，各条链路都不会漏）', () async {
      final m = ImportManager(
        repo: repo,
        metadata: MetadataClient(weread: WereadGateway(apiKey: null)),
        llm: LlmClient(apiKey: null),
      );
      await m.commit(
        [
          Book(
            id: '1', title: '书',
            categoryPrimary: '经济理财-财经',
            createdAt: 'now', updatedAt: 'now',
          ),
        ],
        enrichMetadata: false,
      );
      final got = await repo.byId('1');
      expect(got!.categoryPrimary, '经济');
      expect(got.categoryRaw, '经济理财-财经');
    });
  });
}
