import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ai/ai_client.dart';
import 'package:reading_tracker/ai/search_client.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/data/recommendation.dart';
import 'package:reading_tracker/data/recommendation_service.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/recommend_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/localized_app.dart';

/// 假的推荐服务：直接给结果，不碰网络。
///
/// ## 为什么页面测试要自己造服务
///
/// Dio 的拦截器 mock 在 `testWidgets` 的 FakeAsync 里**永远不 resolve**
/// （FakeAsync 不交还真实事件循环，拦截器里的异步链就卡住了）。
/// 服务层的测试因此用普通 `test()` 跑，页面测试就不能再用真服务——
/// 否则测的其实不是页面，而是「Dio 能不能在 FakeAsync 里 resolve」。
///
/// 所以这里把 [RecommendationService] 的两个对外方法覆写掉：
/// 页面只认这两个方法，覆写了它就与网络无关了。
class FakeRecommendService extends RecommendationService {
  FakeRecommendService({
    required List<Recommendation> Function(RecommendSource source) result,
    Set<RecommendSource> available = const {},
    required super.repo,
  })  : _result = result,
        _available = available,
        super(
          llm: LlmClient(
            dio: Dio(),
            apiKey: null,
            baseUrl: 'https://llm.test/v1',
            model: 'test',
          ),
          weread: WereadGateway(dio: Dio(), apiKey: null),
          search: SearchClient(
            dio: Dio(),
            apiKey: null,
            endpoint: 'https://search.test/s',
          ),
          metadata: MetadataClient(
            dio: Dio(),
            weread: WereadGateway(dio: Dio(), apiKey: null),
          ),
        );

  final List<Recommendation> Function(RecommendSource source) _result;
  final Set<RecommendSource> _available;

  @override
  bool available(RecommendSource source) => _available.contains(source);

  @override
  Future<List<Recommendation>> recommend(
    RecommendSource source, {
    String? keyword,
    int limit = 8,
  }) async =>
      _result(source);
}

/// 推荐书单页的交互行为。
///
/// ## 这一组测试要钉住什么
///
/// 服务层已经测过「每档出什么」，这里钉的是**页面这一层的产品承诺**：
///
/// 1. 四个档位**都显示**——不可用的置灰但不隐藏。
///    隐藏的话用户根本不知道 App 还有这个功能，只会觉得「怎么只有三种推荐」。
/// 2. 「先看列表，勾选后再入库」——勾选前不写库，勾选后才写。
/// 3. 入库后条目**从列表消失**——否则用户能再勾一次、插一条重复记录。
/// 4. 入库反馈写在**页面里**，不是 SnackBar（SnackBar 跨页留存、2 秒就消失）。
/// 5. 已在书架的书（档①的推荐）**不可勾选**——再入库就是重复记录。
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

  Recommendation rec(
    String title, {
    String? reason,
    bool inShelf = false,
    RecommendSource source = RecommendSource.llm,
  }) =>
      Recommendation(
        book: Book(
          id: '',
          title: title,
          authors: const ['刘慈欣'],
          status: BookStatus.wish,
          createdAt: now,
          updatedAt: now,
        ),
        reason: reason ?? '',
        source: source,
        alreadyInShelf: inShelf,
      );

  /// 标题的精确 finder。
  ///
  /// 不能直接用 `find.text('三体')`：封面占位块里也会画一遍书名，
  /// 同一个书名在页面里出现两次，tap 会报「ambiguously found multiple」。
  Finder titleOf(String t) => find.byKey(ValueKey('rec_title_$t'));

  Widget harness(RecommendationService svc) => ProviderScope(
        overrides: [
          repoProvider.overrideWithValue(repo),
          recommendationServiceProvider.overrideWithValue(svc),
        ],
        child: localizedApp(
          locale: const Locale('zh'),
          home: const RecommendPage(),
        ),
      );

  /// 页面在 initState 的 postFrameCallback 里发起加载，
  /// 那次加载要跨几轮微任务才能落地，所以这里多泵几轮。
  Future<void> settleAsync(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  }

  group('档位分段', () {
    testWidgets('四个档位都显示，缺凭据的置灰但不隐藏', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelfUnread},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      // 四个都在
      expect(find.text('书架里的'), findsOneWidget);
      expect(find.text('大模型推荐'), findsOneWidget);
      expect(find.text('微信读书书城'), findsOneWidget);
      expect(find.text('联网搜索'), findsOneWidget);

      // 缺凭据的那三个置灰（半透明 0.45），第一档不透明
      double opacityOf(String label) {
        final chip = find.widgetWithText(ChoiceChip, label);
        final op = tester.widget<Opacity>(
          find.ancestor(of: chip, matching: find.byType(Opacity)).first,
        );
        return op.opacity;
      }

      expect(opacityOf('书架里的'), 1.0);
      expect(opacityOf('大模型推荐'), lessThan(1.0));
      expect(opacityOf('微信读书书城'), lessThan(1.0));
      expect(opacityOf('联网搜索'), lessThan(1.0));
    });

    testWidgets('缺凭据的档位点不动', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelfUnread},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, '大模型推荐'));
      await settleAsync(tester);

      // 切不过去——大模型那一档的 chip 仍是未选中
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '大模型推荐'),
      );
      expect(chip.selected, isFalse);
    });

    testWidgets('可用的档位能切过去，并按新档位重新出结果', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {
          RecommendSource.shelfUnread,
          RecommendSource.llm,
        },
        result: (src) => src == RecommendSource.llm
            ? [rec('大模型给的书')]
            : [rec('书架给的书')],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(titleOf('书架给的书'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '大模型推荐'));
      await settleAsync(tester);

      expect(titleOf('大模型给的书'), findsOneWidget);
      expect(titleOf('书架给的书'), findsNothing);
    });
  });

  group('列表与入库', () {
    testWidgets('结果渲染出来', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelfUnread},
        result: (_) => [rec('三体', reason: '硬科幻经典')],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(titleOf('三体'), findsOneWidget);
      expect(find.text('硬科幻经典'), findsOneWidget);
      expect(find.text('刘慈欣'), findsOneWidget);
    });

    testWidgets('空结果显示空态提示，不是白屏', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelfUnread},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.textContaining('这里暂时没有结果'), findsOneWidget);
    });

    testWidgets('已在书架的条目不可勾选', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelfUnread},
        result: (_) => [
          rec('想读的书', inShelf: true, source: RecommendSource.shelfUnread),
        ],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      // 档①的条目显示的是静态对勾，不是可勾的加号
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // 点它也不会出入库按钮
      await tester.tap(titleOf('想读的书'));
      await settleAsync(tester);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('勾选前不写库，勾选并入库后才写', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelfUnread},
        result: (_) => [rec('三体')],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      // 勾选前不入库按钮不出现
      expect(find.byType(FilledButton), findsNothing);

      await tester.tap(titleOf('三体'));
      await settleAsync(tester);

      // 勾选后底部出现「把 1 本加入书架」
      expect(find.text('把 1 本加入书架'), findsOneWidget);
      // 此时还没写库
      expect(await repo.all(), isEmpty);

      await tester.tap(find.text('把 1 本加入书架'));
      await settleAsync(tester);

      // 写库了
      final saved = await repo.all();
      expect(saved.map((b) => b.title), contains('三体'));
      // 条目从列表消失，不会被再勾一次
      expect(titleOf('三体'), findsNothing);
      // 反馈写在页面里，不是 SnackBar
      expect(find.text('已把 1 本书加入书架'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('入库的书状态是「想读」', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelfUnread},
        result: (_) => [rec('三体')],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      await tester.tap(titleOf('三体'));
      await settleAsync(tester);
      await tester.tap(find.text('把 1 本加入书架'));
      await settleAsync(tester);

      final saved = await repo.all();
      expect(saved.single.status, BookStatus.wish);
    });

    testWidgets('入库后剩的条目仍能继续勾选', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelfUnread},
        result: (_) => [rec('第一本'), rec('第二本')],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      await tester.tap(titleOf('第一本'));
      await settleAsync(tester);
      await tester.tap(find.text('把 1 本加入书架'));
      await settleAsync(tester);

      // 剩下一本，勾它还能正常入库
      expect(titleOf('第二本'), findsOneWidget);
      await tester.tap(titleOf('第二本'));
      await settleAsync(tester);
      expect(find.text('把 1 本加入书架'), findsOneWidget);

      await tester.tap(find.text('把 1 本加入书架'));
      await settleAsync(tester);
      expect((await repo.all()).length, 2);
    });
  });
}
