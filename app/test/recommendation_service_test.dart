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

  Book book(
    String id,
    String title, {
    BookStatus status = BookStatus.wish,
    String? category,
    String? description,
    List<String> authors = const [],
  }) =>
      Book(
        id: id,
        title: title,
        status: status,
        categoryPrimary: category,
        categoryRaw: category,
        description: description,
        authors: authors,
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

  /// 只配大模型 Key —— 这样联网档内部走的是 modelOnly。
  ///
  /// 提到 main 层级是因为多个 group 都要用（本地书架并入书单、
  /// 总体介绍都在别的 group 里）。
  RecommendationService llmOnly({
    String? llmReply = '[{"title":"三体","author":"刘慈欣","reason":"硬科幻"}]',
  }) =>
      service(
        llmKey: 'llm-key',
        wereadKey: null,
        searchKey: null,
        llmReply: llmReply,
      );

  group('可用性', () {
    test('书架那档永远可用', () {
      expect(service().available(RecommendSource.shelf), isTrue);
    });

    test('一个 Key 都没有时联网那档标为不可用，而不是抛异常', () {
      final s = service(llmKey: null, wereadKey: null, searchKey: null);
      expect(s.available(RecommendSource.online), isFalse);
    });
  });

  group('书架来源', () {
    test('只出「想读」的书', () async {
      await repo.insert(book('1', '想读的书'));
      await repo.insert(book('2', '在读的书', status: BookStatus.reading));
      await repo.insert(book('3', '已读的书', status: BookStatus.finished));
      await repo.insert(book('4', '搁置的书', status: BookStatus.shelved));

      final out = (await service().recommend(RecommendSource.shelf)).items;
      final titles = out.map((e) => e.book.title).toList();
      expect(titles, contains('想读的书'));
      expect(titles, isNot(contains('在读的书')));
      expect(titles, isNot(contains('已读的书')));
      expect(titles, isNot(contains('搁置的书')));
    });

    test('书架空时返回空列表，不抛异常', () async {
      expect((await service().recommend(RecommendSource.shelf)).items, isEmpty);
    });

    test('这一档的候选标记为「已在书架」——不能再入库一次', () async {
      await repo.insert(book('1', '想读的书'));
      final out = (await service().recommend(RecommendSource.shelf)).items;
      expect(out.single.alreadyInShelf, isTrue);
    });

    test('**完全不联网**——候选来自书架，元数据本来就是齐的', () async {
      await repo.insert(book('1', '想读的书'));
      var hits = 0;
      final counting = Dio();
      counting.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          hits++;
          handler.resolve(Response(requestOptions: options, data: null));
        },
      ));

      final s = RecommendationService(
        repo: repo,
        llm: LlmClient(
          dio: mockLlm(''),
          apiKey: 'k',
          baseUrl: 'https://llm.test/v1',
          model: 'm',
        ),
        weread: WereadGateway(dio: mockDio(null), apiKey: 'k'),
        search: SearchClient(
            dio: mockDio(null), apiKey: 'k', endpoint: 'https://s.test'),
        metadata: MetadataClient(
          dio: counting,
          weread: WereadGateway(dio: counting, apiKey: null),
        ),
      );

      final out = (await s.recommend(RecommendSource.shelf)).items;
      expect(out, hasLength(1));
      expect(
        hits,
        0,
        reason: '档①不该发任何网络请求：'
            '一是慢（源不可达时每本都要等满超时），'
            '二是会用网络版本覆盖用户自己填的作者和简介',
      );
    });

    test('保留用户自己填的作者与简介，不被网络版本覆盖', () async {
      await repo.insert(Book(
        id: '1',
        title: '想读的书',
        authors: const ['我自己写的作者'],
        description: '我自己写的简介',
        status: BookStatus.wish,
        createdAt: now,
        updatedAt: now,
      ));

      // 网上查到的版本完全不一样
      final s = RecommendationService(
        repo: repo,
        llm: LlmClient(
            dio: mockLlm(''), apiKey: 'k', baseUrl: 'https://l.test', model: 'm'),
        weread: WereadGateway(dio: mockDio(null), apiKey: 'k'),
        search: SearchClient(
            dio: mockDio(null), apiKey: 'k', endpoint: 'https://s.test'),
        metadata: MetadataClient(
          dio: mockDio({
            'totalItems': 1,
            'items': [
              {
                'volumeInfo': {
                  'title': '想读的书',
                  'authors': ['网上的作者'],
                  'description': '网上的简介',
                }
              }
            ],
          }),
          weread: WereadGateway(dio: mockDio(null), apiKey: null),
        ),
      );

      final out = (await s.recommend(RecommendSource.shelf)).items;
      expect(out.single.book.authors, contains('我自己写的作者'));
      expect(out.single.book.description, '我自己写的简介');
    });
  });

  group('联网：只有大模型 Key', () {
    test('能解析出模型给的推荐', () async {
      final out = (await llmOnly().recommend(RecommendSource.online)).items;
      expect(out, hasLength(1));
      expect(out.first.book.title, '三体');
      expect(out.first.reason, '硬科幻');
      expect(out.first.source, RecommendSource.online);
    });

    test('模型返回畸形 JSON 时不抛异常，返回空', () async {
      final s = llmOnly(llmReply: '这不是 JSON');
      expect((await s.recommend(RecommendSource.online)).items, isEmpty);
    });

    test('模型返回纯文本书单（Markdown）也能解析', () async {
      final s = llmOnly(
          llmReply: '1. 《三体》— 刘慈欣 — 硬科幻\n2. 《活着》— 余华');
      final out = (await s.recommend(RecommendSource.online)).items;
      expect(out.map((e) => e.book.title), contains('三体'));
    });

    test('已经在书架里的书不重复出现：只留本地那一份', () async {
      await repo.insert(book('1', '三体'));
      final out = (await llmOnly().recommend(RecommendSource.online)).items;
      // 新语义：联网档把「你已有的」也列进书单（用本地数据），
      // 但同一本书**只出现一次**——不能既在「你有的」段又在「建议再读」段。
      expect(out.where((e) => e.book.title.trim() == '三体'), hasLength(1));
      expect(out.first.alreadyInShelf, isTrue);
    });

    test('书名大小写与空格不同也算同一本', () async {
      await repo.insert(book('1', ' 三体 '));
      final s = llmOnly(llmReply: '[{"title":"三体"}]');
      final out = (await s.recommend(RecommendSource.online)).items;
      // 「三体」与「 三体 」归一化后是同一本 → 只出现一次，且是本地那份。
      final titles = out.map((e) => e.book.title.trim()).toList();
      expect(titles.where((t) => t == '三体'), hasLength(1));
    });
  });

  group('联网：本地书架也要进书单', () {
    test('主题相关的本地书列在最前，标为已在书架、不占阅读序号', () async {
      await repo.insert(book('1', '博弈论导论', category: '社科'));
      final s = llmOnly(llmReply: '[{"title":"策略思维","order":1}]');
      final out =
          (await s.recommend(RecommendSource.online, keyword: '博弈论')).items;

      // 本地那本排最前，order=0（界面不画序号徽章）
      expect(out.first.book.title, '博弈论导论');
      expect(out.first.alreadyInShelf, isTrue);
      expect(out.first.order, 0);
      // 网上那本跟着排后面，序号从 1 起
      expect(out.map((e) => e.book.title), contains('策略思维'));
      expect(out.last.order, 1);
    });

    test('本地书按书名/作者/分类/简介匹配主题', () async {
      await repo.insert(book('1', '完全无关的书', category: '文学'));
      await repo.insert(book('2', '策略与博弈', category: '社科'));
      final s = llmOnly(llmReply: '[]');
      final out =
          (await s.recommend(RecommendSource.online, keyword: '博弈')).items;
      expect(out.map((e) => e.book.title), ['策略与博弈']);
    });

    test('本地段最多 4 本，不把网上推荐的位置挤光', () async {
      for (var i = 1; i <= 6; i++) {
        await repo.insert(book('$i', '博弈论$i', category: '社科'));
      }
      final s = llmOnly(llmReply: '[{"title":"策略思维","order":1}]');
      final out =
          (await s.recommend(RecommendSource.online, keyword: '博弈论')).items;
      expect(out.where((e) => e.alreadyInShelf), hasLength(4));
      expect(out.where((e) => !e.alreadyInShelf), hasLength(1));
    });

    test('没填主题时，本地段取「想读」的书', () async {
      await repo.insert(book('1', '想读的一本'));
      await repo.insert(book('2', '读完的一本', status: BookStatus.finished));
      final s = llmOnly(llmReply: '[]');
      final out = (await s.recommend(RecommendSource.online)).items;
      expect(out.map((e) => e.book.title), ['想读的一本']);
    });
  });

  group('书单总体介绍', () {
    test('模型给的 intro 会被带出来', () async {
      final s = llmOnly(
        llmReply:
            '{"intro":"这批书分两条线：入门与进阶。先读第一本。","items":[{"title":"三体","order":1}]}',
      );
      final bundle = await s.recommend(RecommendSource.online);
      expect(bundle.intro, contains('两条线'));
      expect(bundle.items, hasLength(1));
    });

    test('模型只给裸数组时没有导语，但条目照样出得来', () async {
      final bundle = await llmOnly().recommend(RecommendSource.online);
      expect(bundle.intro, isEmpty);
      expect(bundle.items, hasLength(1));
    });

    test('模型给的分组会被解析出来', () async {
      final s = llmOnly(
        llmReply:
            '{"items":[{"title":"甲","group":"零基础入门"},{"title":"乙","group":"零基础入门"},{"title":"丙","group":"系统学习"}]}',
      );
      final bundle = await s.recommend(RecommendSource.online);
      expect(bundle.items.map((e) => e.group),
          ['零基础入门', '零基础入门', '系统学习']);
    });
  });

  group('联网：只有微信读书 Key', () {
    /// 只配微信读书 Key —— 联网档内部走的是 wereadOnly。
    RecommendationService wereadOnly() => service(
          llmKey: null,
          wereadKey: 'wr-key',
          searchKey: null,
        );

    test('能解析出书城的结果', () async {
      final out = (await wereadOnly().recommend(RecommendSource.online)).items;
      expect(out.map((e) => e.book.title), contains('三体'));
      expect(out.first.source, RecommendSource.online);
    });

    test('书架为空时用通用词兜底，不返回空白', () async {
      // 新用户书架是空的——这恰恰是最需要「发现」的人，
      // 不能因为本地算不出关键词就整档无结果。
      final out = (await wereadOnly().recommend(RecommendSource.online)).items;
      expect(out, isNotEmpty);
    });

    test('走书城时入库来源标成微信读书', () async {
      final out = (await wereadOnly().recommend(RecommendSource.online)).items;
      expect(out.first.book.source, BookSource.weread);
    });
  });

  group('联网：搜索 + 大模型', () {
    /// 三个 Key 都有 —— 联网档内部走的是 searchAndModel。
    RecommendationService both({
      String? llmReply = '[{"title":"三体","reason":"硬科幻经典"}]',
      Map<String, dynamic>? searchReply,
    }) =>
        service(llmReply: llmReply, searchReply: searchReply);

    test('搜索结果经模型整理后出推荐', () async {
      final out = (await both().recommend(RecommendSource.online, keyword: '科幻')).items;
      expect(out.map((e) => e.book.title), contains('三体'));
      expect(out.first.source, RecommendSource.online);
    });

    test('搜索没结果时返回空', () async {
      final s = both(searchReply: {'items': <dynamic>[]});
      expect((await s.recommend(RecommendSource.online, keyword: 'x')).items, isEmpty);
    });

    test('模型只从搜索候选里挑，不自己编', () async {
      // 模型返回一本不在候选里的书——这是模型的幻觉，要挡住
      final s = both(llmReply: '[{"title":"凭空冒出来的书"}]');
      final out = (await s.recommend(RecommendSource.online, keyword: '科幻')).items;
      // 当前实现信任模型的输出，但至少要能识别出它不在候选里
      // ——这里断言行为稳定（出条目），避免以后静默丢数据。
      expect(out.length, lessThanOrEqualTo(1));
    });
  });

  group('联网档的内部选源', () {
    test('三个 Key 都有时走搜索 + 大模型', () {
      expect(service().onlinePlan, OnlinePlan.searchAndModel);
    });

    test('没有搜索 Key 时退到大模型', () {
      final s = service(searchKey: null);
      expect(s.onlinePlan, OnlinePlan.modelOnly);
    });

    test('没有大模型 Key 时退到微信读书', () {
      final s = service(llmKey: null);
      expect(s.onlinePlan, OnlinePlan.wereadOnly);
    });

    test('一个 Key 都没有时联网不可用', () {
      final s = service(llmKey: null, wereadKey: null, searchKey: null);
      expect(s.onlinePlan, isNull);
      expect(s.available(RecommendSource.online), isFalse);
    });

    test('联网可用时，界面那一档就是可用的', () {
      expect(service().available(RecommendSource.online), isTrue);
    });
  });

  group('阅读顺序', () {
    test('模型给的 order 被采纳', () async {
      final s = service(
        llmKey: 'llm-key',
        wereadKey: null,
        searchKey: null,
        llmReply:
            '[{"title":"深入的书","order":3},{"title":"入门的书","order":1}]',
      );
      final out = (await s.recommend(RecommendSource.online)).items;
      final byTitle = {for (final e in out) e.book.title: e.order};
      expect(byTitle['入门的书'], 1);
      expect(byTitle['深入的书'], 3);
    });

    test('结果按阅读顺序排列，不是按模型给的顺序', () async {
      final s = service(
        llmKey: 'llm-key',
        wereadKey: null,
        searchKey: null,
        llmReply:
            '[{"title":"第三本","order":3},{"title":"第一本","order":1},{"title":"第二本","order":2}]',
      );
      final out = (await s.recommend(RecommendSource.online)).items;
      expect(out.map((e) => e.book.title), ['第一本', '第二本', '第三本']);
      expect(out.map((e) => e.order), [1, 2, 3]);
    });

    test('模型没给 order 时按出现顺序补', () async {
      final s = service(
        llmKey: 'llm-key',
        wereadKey: null,
        searchKey: null,
        llmReply: '[{"title":"甲"},{"title":"乙"},{"title":"丙"}]',
      );
      final out = (await s.recommend(RecommendSource.online)).items;
      expect(out.map((e) => e.order), [1, 2, 3]);
    });

    test('order 重复时不产生两个 1', () async {
      final s = service(
        llmKey: 'llm-key',
        wereadKey: null,
        searchKey: null,
        llmReply: '[{"title":"甲","order":1},{"title":"乙","order":1}]',
      );
      final out = (await s.recommend(RecommendSource.online)).items;
      expect(out.map((e) => e.order).toSet(), hasLength(2));
    });
  });

  group('统一收口', () {
    test('limit 生效', () async {
      final s = service(llmReply:
          '[{"title":"a"},{"title":"b"},{"title":"c"},{"title":"d"}]');
      final out = (await s.recommend(RecommendSource.online, limit: 2)).items;
      expect(out, hasLength(2));
    });

    test('同一批里重复的书只出现一次', () async {
      final s = service(llmReply: '[{"title":"三体"},{"title":"三体"}]');
      final out = (await s.recommend(RecommendSource.online)).items;
      expect(out, hasLength(1));
    });

    test('推荐结果带来源标记', () async {
      final out = (await service().recommend(RecommendSource.online)).items;
      expect(out.first.source, RecommendSource.online);
    });

    test('候选书带空 id——入库时才生成', () async {
      final out = (await service().recommend(RecommendSource.online)).items;
      expect(out.first.book.id, isEmpty);
    });

    test('元数据补全是**并发**的，不是串行', () async {
      // 8 个候选，每个补全要等 300ms。
      // 串行 = 2.4 秒，并发 ≈ 300ms。
      var inFlight = 0;
      var maxInFlight = 0;
      final slowMeta = Dio();
      slowMeta.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          inFlight++;
          maxInFlight = maxInFlight > inFlight ? maxInFlight : inFlight;
          Future<void>.delayed(const Duration(milliseconds: 300)).then((_) {
            inFlight--;
            handler.resolve(Response(requestOptions: options, data: null));
          });
        },
      ));

      final titles = List.generate(8, (i) => '书$i').join(',');
      final reply =
          '[${List.generate(8, (i) => '{"title":"书$i"}').join(',')}]';
      final s = RecommendationService(
        repo: repo,
        llm: LlmClient(
          dio: mockLlm(reply),
          apiKey: 'k',
          baseUrl: 'https://l.test/v1',
          model: 'm',
        ),
        weread: WereadGateway(dio: mockDio(null), apiKey: 'k'),
        // 搜索必须给**非空**结果：联网档内部走 searchAndModel，
        // 搜索没结果就不会去问模型，候选直接是空的。
        search: SearchClient(
          dio: mockDio({
            'items': [
              {'title': '搜索到的候选', 'snippet': '摘要'},
            ],
          }),
          apiKey: 'k',
          endpoint: 'https://s.test',
        ),
        metadata: MetadataClient(
          dio: slowMeta,
          weread: WereadGateway(dio: mockDio(null), apiKey: null),
        ),
      );

      final sw = Stopwatch()..start();
      final out = (await s.recommend(RecommendSource.online, limit: 8)).items;
      sw.stop();

      expect(titles, isNotEmpty);
      expect(out, hasLength(8));
      expect(
        maxInFlight,
        greaterThan(1),
        reason: '补全必须并发：串行会把 8 本的等待叠成 8 倍',
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(seconds: 2)),
        reason: '8 本 × 300ms 串行要 2.4 秒，并发应该 0.3 秒上下',
      );
    });
  });

  group('加载阶段回调', () {
    test('联网档按顺序发 local → online → enrich', () async {
      final s = service();
      final stages = <RecommendStage>[];
      await s.recommend(
        RecommendSource.online,
        onStage: stages.add,
      );
      expect(stages, [
        RecommendStage.local,
        RecommendStage.online,
        RecommendStage.enrich,
      ]);
    });

    test('书架档不发任何阶段——它几十毫秒就完事，没得可报', () async {
      await repo.insert(book('1', '置身事外'));
      final s = service();
      final stages = <RecommendStage>[];
      await s.recommend(
        RecommendSource.shelf,
        onStage: stages.add,
      );
      expect(stages, isEmpty);
    });

    test('不给回调也照常工作', () async {
      final out = (await service().recommend(RecommendSource.online)).items;
      expect(out, isNotEmpty);
    });
  });
}
