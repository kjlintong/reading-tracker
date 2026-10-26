import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/data/recommendation.dart';
import 'package:reading_tracker/data/recommendation_service.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/discover_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_recommend_service.dart';
import 'support/localized_app.dart';

/// 「发现」页的交互行为。
///
/// ## 这一组测试要钉住什么
///
/// 服务层已经测过「出什么」，这里钉的是**页面这一层的产品承诺**：
///
/// 1. 只有两个来源——**我的书架** 与 **联网**。
///    早先是四档（书架/大模型/微信读书/搜索），等于让用户替 App 选技术方案。
/// 2. 两个都显示，联网缺凭据时**置灰但不隐藏**，并说清楚缺什么 + 给「去设置」。
/// 3. 顶部有**一句说明**——页面叫「发现」，光看名字不知道能干什么。
/// 4. 「先看列表，勾选后再入库」——勾选前不写库，勾选后才写。
/// 5. 入库后条目**从列表消失**——否则用户能再勾一次、插一条重复记录。
/// 6. 入库反馈写在**页面里**，不是 SnackBar（SnackBar 跨页留存、2 秒就消失）。
/// 7. 已在书架的书**不可勾选**——再入库就是重复记录。
/// 8. 联网档给出**阅读顺序**（序号徽章 + 「按这个顺序读」提示）；
///    书架档不给——那只是「最近加入的」，说成阅读顺序是误导。
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
    int order = 0,
    bool inShelf = false,
    RecommendSource source = RecommendSource.online,
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
        order: order,
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
          home: const DiscoverPage(),
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

  group('来源分段', () {
    testWidgets('只有两个来源：我的书架 与 联网', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf, RecommendSource.online},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.text('我的书架'), findsOneWidget);
      expect(find.text('联网'), findsOneWidget);

      // 早先的四档不许再出现——用户不该替 App 选技术方案。
      expect(find.text('大模型推荐'), findsNothing);
      expect(find.text('微信读书书城'), findsNothing);
      expect(find.text('联网搜索'), findsNothing);
      expect(find.byType(ChoiceChip), findsNWidgets(2));
    });

    testWidgets('联网缺凭据时置灰但不隐藏', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.text('联网'), findsOneWidget);

      double opacityOf(String label) {
        final chip = find.widgetWithText(ChoiceChip, label);
        final op = tester.widget<Opacity>(
          find.ancestor(of: chip, matching: find.byType(Opacity)).first,
        );
        return op.opacity;
      }

      expect(opacityOf('我的书架'), 1.0);
      expect(opacityOf('联网'), lessThan(1.0));
    });

    testWidgets('联网不可用时说清楚缺什么，并给「去设置」', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.textContaining('联网推荐需要先配置'), findsOneWidget);
      expect(find.text('去设置'), findsOneWidget);
    });

    testWidgets('点「去设置」把底部导航切到设置栏', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      await tester.tap(find.text('去设置'));
      await settleAsync(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(DiscoverPage)),
      );
      expect(container.read(homeTabProvider), HomeTabs.settings);
    });

    testWidgets('缺凭据的联网点不动', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, '联网'));
      await settleAsync(tester);

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '联网'),
      );
      expect(chip.selected, isFalse);
    });

    testWidgets('可用的联网能切过去，并按新来源重新出结果', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf, RecommendSource.online},
        result: (src) => src == RecommendSource.online
            ? [rec('联网给的书')]
            : [rec('书架给的书')],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(titleOf('书架给的书'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '联网'));
      await settleAsync(tester);

      expect(titleOf('联网给的书'), findsOneWidget);
      expect(titleOf('书架给的书'), findsNothing);
    });
  });

  group('功能说明', () {
    testWidgets('顶部有说明文字，讲清这个功能能干什么', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.text('发现'), findsOneWidget);
      expect(find.textContaining('感兴趣'), findsOneWidget);
    });

    testWidgets('输入框提示用户可以填主题', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('想读点什么'), findsOneWidget);
    });
  });

  group('阅读顺序', () {
    testWidgets('联网档显示序号徽章与「按这个顺序读」提示', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf, RecommendSource.online},
        result: (_) => [
          rec('第一本', reason: '入门', order: 1),
          rec('第二本', reason: '进阶', order: 2),
        ],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, '联网'));
      await settleAsync(tester);

      expect(find.text('建议按这个顺序读'), findsOneWidget);
      // 序号徽章
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('书架档不给「阅读顺序」提示——那是最近加入，不是阅读顺序',
        (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => [rec('想读的书', source: RecommendSource.shelf)],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.text('建议按这个顺序读'), findsNothing);
    });

    testWidgets('书架那档的条目标注「来自你的书架」', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => [
          rec('想读的书', inShelf: true, source: RecommendSource.shelf),
        ],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.text('来自你的书架'), findsOneWidget);
    });
  });

  group('列表与入库', () {
    testWidgets('结果渲染出来', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
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
        available: const {RecommendSource.shelf},
        result: (_) => const [],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      expect(find.textContaining('没找到合适的书'), findsOneWidget);
    });

    testWidgets('已在书架的条目不可勾选', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
        result: (_) => [
          rec('想读的书', inShelf: true, source: RecommendSource.shelf),
        ],
      );
      await tester.pumpWidget(harness(s));
      await settleAsync(tester);

      // 书架那档的条目显示的是静态对勾，不是可勾的加号
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
        available: const {RecommendSource.shelf},
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
      expect(find.text('已加入 1 本'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('入库的书状态是「想读」', (tester) async {
      final s = FakeRecommendService(
        repo: repo,
        available: const {RecommendSource.shelf},
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
        available: const {RecommendSource.shelf},
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
