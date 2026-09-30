import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/ai_report_page.dart';
import 'package:reading_tracker/ui/book_detail_page.dart';
import 'package:reading_tracker/ui/settings_page.dart';
import 'package:reading_tracker/ui/shelf_page.dart';
import 'package:reading_tracker/ui/stats_page.dart';

/// 页面级冒烟：静态分析查不出运行时崩溃（空数据、异步竞态、provider 未注入），
/// 这里用内存库把每个主页面真正渲染一遍，确保打开即能看到内容。
void main() {
  // 关键：UI 测试必须用 NoIsolate 版本的 factory。
  // 默认的 databaseFactoryFfi 把 SQL 执行放到独立 isolate，而 testWidgets 运行在
  // FakeAsync zone 内，isolate 回信永远等不到 → 页面 Future 永不完成 →
  // pumpWidget 挂死，随后报 "Guarded function conflict"。
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database raw;
  late BookRepository repo;

  const now = '2026-09-29T10:00:00.000Z';

  Book book(String id, String title,
          {String author = '佚名',
          BookStatus status = BookStatus.finished,
          String? category,
          String? finishedAt}) =>
      Book(
        id: id,
        title: title,
        authors: [author],
        status: status,
        categoryPrimary: category,
        finishedAt: finishedAt,
        createdAt: now,
        updatedAt: now,
      );

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  /// 注入内存库，绕开 AppDatabase.instance（后者依赖 path_provider）
  Widget harness(Widget child) => ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: MaterialApp(home: child),
      );

  /// 数据库查询是真实异步，而 testWidgets 跑在 FakeAsync 里；
  /// 不先用 runAsync 把控制权交还真实事件循环，Future 永远不 resolve，
  /// 页面就会一直停留在上一次的数据快照上。
  ///
  /// 这里刻意不用 pumpAndSettle：它的超时是第三个位置参数，
  /// 一旦漏传就会挂满默认 10 分钟，而 EnginePhase 在 Dart 侧没有稳定的
  /// 公开导出路径。自建「交还事件循环 + 泵一帧」的循环更可控。
  Future<void> settleAsync(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  Future<void> render(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(harness(page));
    await settleAsync(tester);
  }

  group('书架页', () {
    testWidgets('空库显示引导文案', (tester) async {
      await render(tester, const ShelfPage());
      expect(find.text('还没有书，去「导入」页添加吧'), findsOneWidget);
    });

    testWidgets('列出书名与作者', (tester) async {
      await repo.insertMany([
        book('b1', '置身事内', author: '兰小欢', category: '经济'),
        book('b2', '三体', author: '刘慈欣', category: '文学',
            status: BookStatus.reading),
      ]);
      await render(tester, const ShelfPage());

      // 默认是封面网格：占位封面上会印书名前两字，正文里再印一次全名，
      // 所以「三体」会命中两个 Text。用 findsWidgets 而不是 findsOneWidget。
      expect(find.text('置身事内'), findsWidgets);
      expect(find.text('三体'), findsWidgets);
      // 每格下方那行是作者；书架必须能不点进去就看到作者
      expect(find.text('兰小欢'), findsOneWidget);
      expect(find.text('刘慈欣'), findsOneWidget);
    });

    testWidgets('网格与列表可以切换，列表里作者与分类都露出来', (tester) async {
      await repo.insertMany([
        book('b1', '置身事内', author: '兰小欢', category: '经济'),
      ]);
      await render(tester, const ShelfPage());
      expect(find.byType(GridView), findsOneWidget);

      await tester.tap(find.byTooltip('切换为列表'));
      await settleAsync(tester);

      expect(find.byType(GridView), findsNothing);
      expect(find.text('兰小欢'), findsOneWidget);
      expect(find.text('经济'), findsOneWidget);
    });

    testWidgets('排序菜单可切换且不丢数据', (tester) async {
      await repo.insertMany([
        book('b1', 'A书', author: '甲'),
        book('b2', 'B书', author: '乙'),
      ]);
      await render(tester, const ShelfPage());

      await tester.tap(find.byTooltip('排序'));
      // 弹出菜单是带入场动画的 overlay。settleAsync 只泵「一帧 + 交还事件循环」，
      // 动画停在中间态时菜单项的位置还是旧的，tap 会打空——而且因为是
      // warnIfMissed 警告而非失败，测试会「假绿」。这里显式把动画推到底。
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 菜单里是 ShelfSort.values 的 label；选中后同一个 label 还会出现在
      // 顶部的当前排序提示里，所以取 last 命中菜单项
      await tester.tap(find.text('书名升序').last);
      await settleAsync(tester);
      // 再推一帧把菜单的退场动画走完，否则菜单项还在树上，
      // 和顶部提示条的同名文本撞成两个
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('A书'), findsWidgets);
      expect(find.text('B书'), findsWidgets);
      // 真正证明排序生效：顶部提示条上的当前排序变了
      expect(find.text('书名升序'), findsOneWidget);
    });

    testWidgets('搜索按书名过滤', (tester) async {
      await repo.insertMany([
        book('b1', '置身事内', author: '兰小欢'),
        book('b2', '三体', author: '刘慈欣'),
      ]);
      await render(tester, const ShelfPage());

      await tester.enterText(find.byType(TextField), '三体');
      await settleAsync(tester);

      expect(find.text('三体'), findsWidgets);
      expect(find.text('置身事内'), findsNothing);
    });
  });

  group('统计页', () {
    testWidgets('渲染分类分布', (tester) async {
      // 统计页现在是长页面（8 张指标卡 + 6 张图表），默认 800×600 视口下
      // ListView 只建出首屏，分类图压根没被构建，find 自然找不到。
      // 把视口放大到装得下整页，顺带把「六张图表都能构建成功」一起测掉
      // —— 图表全是 canvas，构建期抛异常在真机上就是整页白屏。
      tester.view.physicalSize = const Size(1000, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await repo.insertMany([
        book('b1', 'A', category: '经济', finishedAt: '2026-01-15'),
        book('b2', 'B', category: '经济', finishedAt: '2026-02-15'),
        book('b3', 'C', category: '文学', status: BookStatus.reading),
      ]);
      await render(tester, const StatsPage());

      expect(find.text('统计'), findsOneWidget);
      // 分类分布里应出现两类
      expect(find.textContaining('经济'), findsWidgets);
      expect(find.textContaining('文学'), findsWidgets);
      // 六张图表标题都在，说明每张图都真的构建过
      for (final t in [
        '阅读状态分布',
        '分类分布 Top 8',
        '评分分布',
        '在读进度分布',
        '来源平台',
      ]) {
        expect(find.text(t), findsWidgets, reason: '缺少图表：$t');
      }
    });

    testWidgets('空库不崩溃', (tester) async {
      await render(tester, const StatsPage());
      expect(find.text('统计'), findsOneWidget);
    });
  });

  group('设置页', () {
    testWidgets('渲染配置项与保存按钮', (tester) async {
      await render(tester, const SettingsPage());
      expect(find.text('设置'), findsOneWidget);
      // 配置页是长列表，「保存配置」按钮在首屏之外，未渲染前 find 不到，
      // 因此这里断言首屏一定存在的输入框，而不是滚到底部去找按钮
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('AI 报告页', () {
    testWidgets('无历史报告时渲染空态', (tester) async {
      await render(tester, const AiReportPage());
      expect(find.text('阅读报告'), findsOneWidget);
    });
  });

  group('书籍详情页', () {
    testWidgets('展示书名、作者与分类', (tester) async {
      await repo.insert(book('b1', '置身事内', author: '兰小欢', category: '经济')
          .copyWith(description: '一本讲中国经济的书'));

      await render(tester, const BookDetailPage(bookId: 'b1'));

      expect(find.text('置身事内'), findsWidgets);
      expect(find.text('作者：兰小欢'), findsOneWidget);
      expect(find.text('分类：经济'), findsOneWidget);
    });

    testWidgets('书不存在时给出明确提示，而不是一直转圈', (tester) async {
      await render(tester, const BookDetailPage(bookId: 'missing'));
      expect(find.text('这本书不存在或已被删除'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
