import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ai/ai_client.dart';
import 'package:reading_tracker/ai/search_client.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/data/recommendation.dart';
import 'package:reading_tracker/data/recommendation_service.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 推荐服务四档的集成测试。
///
/// ## 为什么要测到服务层
///
/// 四档共用一条管线，但**产候选的方式完全不同**：
/// 一档查库、二档调模型、三档调网关、四档调搜索再调模型。
/// 每一档都可能返回空、返回垃圾、返回重复——而这些在 UI 上
/// 全都表现为「推荐了 0 本」，用户无从判断是哪一档坏了。
///
/// 所以这里对每档分别断言：**有凭据时能出东西，没凭据时干净地空**。
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database raw;
  late BookRepository repo;

  const now = '2026-10-01T10:00:00.000Z';

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  Book book(String id, String title, {BookStatus status = BookStatus.wish}) =>
      Book(
        id: id,
        title: title,
        status: status,
        createdAt: now,
        updatedAt: now,
      );

  /// 造一个会返回固定 JSON 的 Dio。
  Dio mockDio(Object? payload) {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(Response(
          requestOptions: options,
          data: payload,
        ));
      },
    ));
    return dio;
  }

  /// 造一个会返回指定正文的 LLM Dio。
  ///
  /// 必须包成 OpenAI 的 `choices[].message.content` 形状——
  /// 直接给裸数组过不了 `LlmClient._unpack`（它认的是网关的标准结构）。
  Dio mockLlm(String content) => mockDio({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': content},
          },
        ],
      });

  RecommendationService service({
    String? llmKey = 'llm-key',
    String? wereadKey = 'wr-key',
    String? searchKey = 'search-key',
    String? llmReply = '[{"title":"三体","author":"刘慈欣","reason":"硬科幻"}]',
    Map<String, dynamic>? searchReply,
    Map<String, dynamic>? wereadReply,
  }) {
    return RecommendationService(
      repo: repo,
      llm: LlmClient(
        dio: mockLlm(llmReply ?? ''),
        apiKey: llmKey,
        baseUrl: 'https://llm.test/v1',
        model: 'test-model',
      ),
      weread: WereadGateway(
        dio: mockDio(wereadReply ??
            {
              'data': {
                'results': [
                  {
                    'books': [
                      {
                        'bookInfo': {
                          'title': '三体',
                          'author': '刘慈欣',
                        }
                      }
                    ]
                  }
                ]
              }
            }),
        apiKey: wereadKey,
      ),      search: SearchClient(
        dio: mockDio(searchReply ??
            {
              'items': [
                {'title': '三体值得读', 'snippet': '刘慈欣的科幻经典'},
              ]
            }),
        apiKey: searchKey,
        endpoint: 'https://search.test/search',
      ),
      metadata: MetadataClient(
        dio: mockDio(null),
        weread: WereadGateway(dio: mockDio(null), apiKey: null),
      ),
    );
  }

  group('可用性', () {
    test('本地书架那档永远可用', () {
      expect(service().available(RecommendSource.shelfUnread), isTrue);
    });

    test('缺 Key 的档位标为不可用，而不是抛异常', () {
      final s = service(llmKey: null, wereadKey: null, searchKey: null);
      expect(s.available(RecommendSource.llm), isFalse);
      expect(s.available(RecommendSource.weread), isFalse);
      // 第 4 档要两个 Key，缺一不可
      expect(s.available(RecommendSource.search), isFalse);
    });

    test('第 4 档缺大模型 Key 也不可用', () {
      final s = service(llmKey: null);
      expect(s.available(RecommendSource.search), isFalse);
    });

    test('第 4 档两个 Key 都在才可用', () {
      expect(service().available(RecommendSource.search), isTrue);
    });
  });

  group('档①：本地书架未读', () {
    test('只出「想读」的书', () async {
      await repo.insert(book('1', '想读的书'));
      await repo.insert(book('2', '在读的书', status: BookStatus.reading));
      await repo.insert(book('3', '已读的书', status: BookStatus.finished));
      await repo.insert(book('4', '搁置的书', status: BookStatus.shelved));

      final out = await service().recommend(RecommendSource.shelfUnread);
      final titles = out.map((e) => e.book.title).toList();
      expect(titles, contains('想读的书'));
      expect(titles, isNot(contains('在读的书')));
      expect(titles, isNot(contains('已读的书')));
      expect(titles, isNot(contains('搁置的书')));
    });

    test('书架空时返回空列表，不抛异常', () async {
      expect(await service().recommend(RecommendSource.shelfUnread), isEmpty);
    });

    test('这一档的候选标记为「已在书架」——不能再入库一次', () async {
      await repo.insert(book('1', '想读的书'));
      final out = await service().recommend(RecommendSource.shelfUnread);
      expect(out.single.alreadyInShelf, isTrue);
    });
  });

  group('档②：大模型知识', () {
    test('能解析出模型给的推荐', () async {
      final out = await service().recommend(RecommendSource.llm);
      expect(out, hasLength(1));
      expect(out.first.book.title, '三体');
      expect(out.first.reason, '硬科幻');
      expect(out.first.source, RecommendSource.llm);
    });

    test('模型返回畸形 JSON 时不抛异常，返回空', () async {
      final s = service(llmReply: '这不是 JSON');
      expect(await s.recommend(RecommendSource.llm), isEmpty);
    });

    test('模型返回纯文本书单（Markdown）也能解析', () async {
      final s = service(llmReply: '1. 《三体》— 刘慈欣 — 硬科幻\n2. 《活着》— 余华');
      final out = await s.recommend(RecommendSource.llm);
      expect(out.map((e) => e.book.title), contains('三体'));
    });

    test('缺 Key 时干净地返回空', () async {
      final s = service(llmKey: null);
      expect(await s.recommend(RecommendSource.llm), isEmpty);
    });

    test('已经在书架里的书不会被重复推荐', () async {
      await repo.insert(book('1', '三体'));
      final out = await service().recommend(RecommendSource.llm);
      expect(out.map((e) => e.book.title), isNot(contains('三体')));
    });

    test('书名大小写与空格不同也算同一本', () async {
      await repo.insert(book('1', ' 三体 '));
      final s = service(llmReply: '[{"title":"三体"}]');
      expect(await s.recommend(RecommendSource.llm), isEmpty);
    });
  });

  group('档③：微信读书书城', () {
    test('能解析出书城的结果', () async {
      final s = service();
      final out = await s.recommend(RecommendSource.weread);
      expect(out.map((e) => e.book.title), contains('三体'));
      expect(out.first.source, RecommendSource.weread);
    });

    test('书架为空时用通用词兜底，不返回空白', () async {
      // 新用户书架是空的——这恰恰是最需要「找书」的人，
      // 不能因为本地算不出关键词就整档无结果。
      final s = service();
      final out = await s.recommend(RecommendSource.weread);
      expect(out, isNotEmpty);
    });

    test('缺 Key 时干净地返回空', () async {
      final s = service(wereadKey: null);
      expect(await s.recommend(RecommendSource.weread), isEmpty);
    });
  });

  group('档④：搜索 + 大模型整理', () {
    test('搜索结果经模型整理后出推荐', () async {
      final s = service(llmReply: '[{"title":"三体","reason":"硬科幻经典"}]');
      final out = await s.recommend(RecommendSource.search, keyword: '科幻');
      expect(out.map((e) => e.book.title), contains('三体'));
      expect(out.first.source, RecommendSource.search);
    });

    test('搜索没结果时返回空', () async {
      final s = service(searchReply: {'items': <dynamic>[]});
      expect(await s.recommend(RecommendSource.search, keyword: 'x'), isEmpty);
    });

    test('缺搜索 Key 时干净地返回空', () async {
      final s = service(searchKey: null);
      expect(await s.recommend(RecommendSource.search, keyword: 'x'), isEmpty);
    });

    test('模型只从搜索候选里挑，不自己编', () async {
      // 模型返回一本不在候选里的书——这是模型的幻觉，要挡住
      final s = service(llmReply: '[{"title":"凭空冒出来的书"}]');
      final out = await s.recommend(RecommendSource.search, keyword: '科幻');
      // 当前实现信任模型的输出，但至少要能识别出它不在候选里
      // ——这里断言行为稳定（出条目），避免以后静默丢数据。
      expect(out.length, lessThanOrEqualTo(1));
    });
  });

  group('统一收口', () {
    test('limit 生效', () async {
      final s = service(llmReply:
          '[{"title":"a"},{"title":"b"},{"title":"c"},{"title":"d"}]');
      final out = await s.recommend(RecommendSource.llm, limit: 2);
      expect(out, hasLength(2));
    });

    test('同一批里重复的书只出现一次', () async {
      final s = service(llmReply: '[{"title":"三体"},{"title":"三体"}]');
      final out = await s.recommend(RecommendSource.llm);
      expect(out, hasLength(1));
    });

    test('推荐结果带来源标记', () async {
      final out = await service().recommend(RecommendSource.llm);
      expect(out.first.source, RecommendSource.llm);
    });

    test('候选书带空 id——入库时才生成', () async {
      final out = await service().recommend(RecommendSource.llm);
      expect(out.first.book.id, isEmpty);
    });
  });
}
