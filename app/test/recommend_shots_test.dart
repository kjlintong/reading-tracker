import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/data/recommendation.dart';
import 'package:reading_tracker/data/recommendation_service.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/recommend_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_recommend_service.dart';
import 'support/localized_app.dart';

/// 「找书」推荐页的效果图生成器。
///
/// ## 为什么要单独出图
///
/// 这个页面是四档书源 + 勾选入库的新交互，纯 widget 测试断言得了
/// 「有没有这个 chip」「点得动点不动」，但**看不出排版对不对**：
/// 四个 chip 在 390 宽的屏上排不排得下、理由文字会不会把行挤爆、
/// 底部按钮压不压住列表——这些只能看图。
///
/// ## 为什么用假服务
///
/// Dio 的 mock 在 `testWidgets` 的 FakeAsync 里**永远不 resolve**
/// （FakeAsync 不交还真实事件循环，拦截器里的异步链就卡住）。
/// 真跑网络层的话截到的永远是「加载中」骨架屏。
/// 页面只认 `available()` 与 `recommend()` 两个方法，覆写它们就够了。
///
/// ## 用法
///
/// ```bash
/// SHOTS=1 flutter test test/recommend_shots_test.dart
/// 产物：store/shots/recommend-*.png
/// ```
///
/// 默认（`flutter test`）完全跳过渲染。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  final enabled = Platform.environment['SHOTS'] == '1';
  const outRoot = '../store/shots';

  late Database raw;
  late BookRepository repo;

  Future<ByteData> bytesOf(String path) async =>
      ByteData.view((await File(path).readAsBytes()).buffer);

  setUpAll(() async {
    if (!enabled) return;
    await (FontLoader('TestLatin')..addFont(bytesOf('test/fixtures/simhei.ttf')))
        .load();
    await (FontLoader('TestCJK')..addFont(bytesOf('test/fixtures/simhei.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(bytesOf('test/fixtures/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  const shotKey = ValueKey<String>('rec-shot');

  ThemeData theme() => ThemeData(
        useMaterial3: true,
        fontFamily: 'TestLatin',
        fontFamilyFallback: const <String>['TestCJK'],
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B6D11)),
      );

  /// 按 iPhone 14 的逻辑尺寸渲染。
  ///
  /// 必须在 `pumpWidget` **之前**调用：布局一旦定完，
  /// 再改 physicalSize 只会改采样密度，不会重新布局。
  void prepare(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844) * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  /// 把当前画面写成 PNG。
  ///
  /// ⚠️ 真实文件系统 I/O 与 `toImage` 必须**整个**塞进 runAsync，
  /// 否则在 FakeAsync 里死锁（表现是 CPU 0% 且永不返回，也不报错）。
  Future<void> capture(WidgetTester tester, String name) async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(shotKey));
    final file = File('$outRoot/$name.png');
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('导出 PNG 失败：$name');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    });
  }

  /// 页面在 initState 的 postFrameCallback 里发起加载，
  /// 那次加载要跨几轮微任务才能落地，所以这里多泵几轮。
  Future<void> settleAsync(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  }

  /// 四档各自的候选。
  List<Recommendation> resultsFor(RecommendSource src) => switch (src) {
        RecommendSource.shelfUnread => [
            fakeRecommendation('置身事外',
                author: '格雷厄姆·格林',
                reason: '书架里标记了想读，但一直没动',
                inShelf: true,
                source: src),
            fakeRecommendation('我与地坛',
                author: '史铁生',
                reason: '书架里标记了想读，但一直没动',
                inShelf: true,
                source: src),
          ],
        RecommendSource.llm => [
            fakeRecommendation('克拉拉与太阳',
                author: '石黑一雄',
                reason: '你偏爱文学与当代小说，诺奖作家群落里唯一还没读过的',
                source: src),
            fakeRecommendation('海边的卡夫卡',
                author: '村上春树',
                reason: '今年的阅读目标里「读完的虚构类」还差两本，这本常被推荐',
                source: src),
            fakeRecommendation('昨日的世界',
                author: '茨威格',
                reason: '最近读过两本回忆录，这本能接上同一条脉络',
                source: src),
          ],
        RecommendSource.weread => [
            fakeRecommendation('长安的荔枝',
                author: '马伯庸',
                reason: '书城榜单 · 历史小说热榜第 2',
                source: src),
            fakeRecommendation('夜晚的潜水艇',
                author: '陈春成',
                reason: '书城榜单 · 文学榜第 7',
                source: src),
          ],
        RecommendSource.search => [
            fakeRecommendation('置身事外',
                author: '格雷厄姆·格林',
                reason: '从 12 条搜索结果里挑出：与你的阅读口味最接近',
                source: src),
            fakeRecommendation('一个陌生女人的来信',
                author: '斯蒂芬·茨威格',
                reason: '从 12 条搜索结果里挑出：同作者的另一本',
                source: src),
          ],
      };

  Widget harness(RecommendationService svc) => ProviderScope(
        overrides: [
          repoProvider.overrideWithValue(repo),
          recommendationServiceProvider.overrideWithValue(svc),
        ],
        child: localizedApp(
          locale: const Locale('zh'),
          theme: theme(),
          home: const RepaintBoundary(
            key: shotKey,
            child: RecommendPage(),
          ),
        ),
      );

  RecommendationService service({
    Set<RecommendSource> available = const {},
  }) =>
      FakeRecommendService(
        repo: repo,
        available: available.isEmpty ? RecommendSource.values.toSet() : available,
        result: resultsFor,
      );

  /// 出一张图。
  ///
  /// 服务必须在**用例内部**构造：`repo` 是 `late` 局部变量，
  /// 在 `main` 顶层（注册用例时）还没初始化。
  void shot(String name, {Set<RecommendSource> available = const {}}) {
    testWidgets(name, (tester) async {
      if (!enabled) return;
      prepare(tester);
      await tester.pumpWidget(harness(service(available: available)));
      await settleAsync(tester);
      await capture(tester, name);
    });
  }

  /// 切到某个档位。
  ///
  /// 四个 chip 排在一条横向滚动条里，390 宽的屏只放得下前三个——
  /// 后面的在屏幕外。`tester.tap` 对屏幕外的 widget 不报错但**点不到**
  /// （截图会跟没切一样，悄无声息地骗人）。所以先滚过去再点。
  Future<void> switchTo(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(ChoiceChip, label);
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await settleAsync(tester);
  }

  /// 四档全可用：档位条 + 第一档列表。
  shot('recommend-01-source-and-list');

  /// 档②大模型：列表里带推荐理由。
  testWidgets('recommend-02-llm', (tester) async {
    if (!enabled) return;
    prepare(tester);
    await tester.pumpWidget(harness(service()));
    await settleAsync(tester);
    await switchTo(tester, '大模型推荐');
    await capture(tester, 'recommend-02-llm');
  });

  /// 档④搜索：书名与作者来自搜索，理由是模型从候选里挑的。
  testWidgets('recommend-03-search', (tester) async {
    if (!enabled) return;
    prepare(tester);
    await tester.pumpWidget(harness(service()));
    await settleAsync(tester);
    await switchTo(tester, '联网搜索');
    await capture(tester, 'recommend-03-search');
  });

  /// 勾选后的状态：底部出现「把 N 本加入书架」。
  testWidgets('recommend-04-selected', (tester) async {
    if (!enabled) return;
    prepare(tester);
    await tester.pumpWidget(harness(service()));
    await settleAsync(tester);
    await switchTo(tester, '大模型推荐');
    await tester.tap(find.byKey(const ValueKey('rec_title_克拉拉与太阳')));
    await settleAsync(tester);
    await capture(tester, 'recommend-04-selected');
  });

  /// 缺凭据时：其余三档置灰但**不隐藏**。
  shot(
    'recommend-05-greyed',
    available: const {RecommendSource.shelfUnread},
  );

  /// 入库之后的反馈：写在页面里的小字，不是 SnackBar。
  testWidgets('recommend-06-added', (tester) async {
    if (!enabled) return;
    prepare(tester);
    await tester.pumpWidget(harness(service()));
    await settleAsync(tester);
    await switchTo(tester, '大模型推荐');
    await tester.tap(find.byKey(const ValueKey('rec_title_克拉拉与太阳')));
    await settleAsync(tester);
    await tester.tap(find.text('把 1 本加入书架'));
    await settleAsync(tester);
    await capture(tester, 'recommend-06-added');
  });
}
