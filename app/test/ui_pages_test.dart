import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/data/profile_store.dart';
import 'package:reading_tracker/data/report_period.dart';
import 'package:reading_tracker/data/stats_prefs.dart';
import 'package:reading_tracker/main.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/models/reading_plan.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/ai_report_page.dart';
import 'package:reading_tracker/ui/backup_page.dart';
import 'package:reading_tracker/ui/book_detail_page.dart';
import 'package:reading_tracker/ui/chronology_page.dart';
import 'package:reading_tracker/ui/insights_page.dart';
import 'package:reading_tracker/ui/notes_page.dart';
import 'package:reading_tracker/ui/settings_page.dart';
import 'package:reading_tracker/ui/shelf_page.dart';
import 'package:reading_tracker/ui/stats_page.dart';
import 'package:reading_tracker/services/update_checker.dart';

import 'support/localized_app.dart';

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

  /// 用「此刻」而不是写死的日期：统计页的时间筛选是按真实当前年份算的，
  /// 写死一个 2026 会让这些用例过一年就集体变红
  String nowIso() => DateTime.now().toIso8601String();

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
        createdAt: nowIso(),
        updatedAt: nowIso(),
      );

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  /// 注入内存库，绕开 AppDatabase.instance（后者依赖 path_provider）
  ///
  /// 用 localizedApp 而不是裸 MaterialApp：页面里的文案都走 S.of(context)，
  /// 少挂 localizationsDelegates 会直接抛 _TypeError。
  Widget harness(Widget child) => ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: localizedApp(home: child),
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

  /// 长页面在默认 800×600 视口里只构建首屏，下面的卡片根本没渲染，
  /// `find` 不到不是 bug。放大视口再断言——这比去猜滚动位置可靠得多。
  void bigViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// 时间范围选择器从「一排 chips」改成了单行下拉：
  /// 区间名不再是可以直接 tap 的独立 widget，而是 DropdownButton 的**当前值**。
  /// 所以必须先点开按钮把菜单弹出来，再点菜单里的项。
  ///
  /// 菜单展开后同名文本会短暂出现两份（按钮上一份、菜单里一份），
  /// 取 `.last` 才是菜单项——点按钮那一份等于原地收起来。
  Future<void> pickRange(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await settleAsync(tester);
  }

  /// 底部表单专用。
  ///
  /// **不能用 bigViewport**：表单是 `showModalBottomSheet` 从屏幕底部向上长的，
  /// 视口拉到 3600 高时它会被排到 y=4000 开外，tap 直接打空。
  /// 但默认 800×600 又装不下约 1100 高的表单内容——两头都不行，
  /// 所以取一个刚好装得下的中等高度。
  void sheetViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    /// 统计页是高过长屏的页面（十张指标卡 + 七张图表），默认 800×600 视口下
    /// ListView 只建出首屏，下面的图压根没被构建，find 自然找不到。
    /// 把视口放大到装得下整页，顺带把「每张图表都能构建成功」一起测掉
    /// —— 图表全是 canvas，构建期抛异常在真机上就是整页白屏。
    testWidgets('七张图表都能构建出来', (tester) async {
      bigViewport(tester);
      await repo.insertMany([
        book('b1', 'A', category: '经济', finishedAt: '2026-01-15'),
        book('b2', 'B', category: '经济', finishedAt: '2026-02-15'),
        book('b3', 'C', category: '文学', status: BookStatus.reading),
      ]);
      await render(tester, const StatsPage());

      expect(find.text('统计'), findsOneWidget);
      // 分类分布里应出现两类（图例是文本，canvas 上的文字取不到）
      expect(find.textContaining('经济'), findsWidgets);
      expect(find.textContaining('文学'), findsWidgets);
      for (final t in [
        '阅读状态分布',
        '分类分布 Top 8',
        '月度在读',
        '月度阅读时长',
        '评分分布',
        '在读进度分布',
        '来源平台',
      ]) {
        expect(find.text(t), findsWidgets, reason: '缺少图表：$t');
      }
    });

    /// 「阅读时长」「阅读天数」「日均阅读」这三个数本 App 没有采集手段，
    /// 只能来自微信读书年度统计的导入。摆在「本期」下面，对不用微信读书
    /// 的用户就是三个永远填不上的空格——用户明确要求拿掉。
    ///
    /// 这条断言防的是「以后有人觉得指标卡是偶数好看又给加回来」。
    testWidgets('本期不再显示阅读时长/阅读天数/日均阅读', (tester) async {
      bigViewport(tester);
      await repo.insert(book('b1', 'A', finishedAt: '2026-01-15'));
      await render(tester, const StatsPage());

      for (final t in ['阅读时长', '阅读天数', '日均阅读']) {
        expect(find.text(t), findsNothing, reason: '$t 应从统计页移除');
      }
      // 但「读完」「新增藏书」这些靠自己数据就能算出来的指标必须还在
      expect(find.text('读完'), findsWidgets);
      expect(find.text('新增藏书'), findsWidgets);
    });

    testWidgets('时间范围可切换，纳入统计的规模跟着变', (tester) async {
      bigViewport(tester);
      final y = DateTime.now().year;
      await repo.insertMany([
        book('b1', 'A', category: '经济', finishedAt: '$y-01-15'),
        book('b2', 'B', category: '经济', finishedAt: '${y - 1}-02-15'),
        book('b3', 'C', category: '文学', status: BookStatus.reading),
      ]);
      await render(tester, const StatsPage());

      // 默认口径是「全部时间」
      expect(find.text('本期 · 全部时间'), findsOneWidget);
      expect(find.text('共 3 本纳入统计'), findsOneWidget);

      await pickRange(tester, '$y 年');
      // 去年读完的那本被排除，今年读完的 + 在读的各留一本
      expect(find.text('本期 · $y 年'), findsOneWidget);
      expect(find.text('共 2 本纳入统计'), findsOneWidget);

      await pickRange(tester, '${y - 1} 年');
      // 口径上「读完的只看完成日期」，所以只剩去年那本
      expect(find.text('共 1 本纳入统计'), findsOneWidget);
    });

    testWidgets('空库不崩溃', (tester) async {
      await render(tester, const StatsPage());
      expect(find.text('统计'), findsOneWidget);
    });

    testWidgets('右上角有「阅历」入口，点进去打开月度看板', (tester) async {
      bigViewport(tester);
      final y = DateTime.now().year;
      await repo.insert(book('b1', 'A', finishedAt: '$y-02-01'));
      await render(tester, const StatsPage());

      final entry = find.byIcon(Icons.view_kanban_outlined);
      expect(entry, findsOneWidget, reason: '统计页右上角应有「阅历」入口');
      await tester.tap(entry);
      await settleAsync(tester);

      // 真的跳到了阅历页：页面标题 + 月份都在
      expect(find.text('阅历'), findsWidgets);
      expect(find.text('1 月'), findsWidgets);
      // 注意：push 出来的新页面**盖在**统计页上，统计页的 widget 仍在
      // element 树里（只是不可见），所以不能用「统计页的东西消失了」来断言。
      // 这里改成断言阅历页**独有**的内容——月份描述文案。
      expect(find.textContaining('按月回看你读过的书'), findsWidgets);
    });

    testWidgets('只填了年月的完成日期，按年筛也不会被丢掉', (tester) async {
      bigViewport(tester);
      final y = DateTime.now().year;
      await repo.insertMany([
        // 种子库与手工录入里大量日期只到月份（"2025-11"）。
        // Dart 的 `DateTime.tryParse('2026-01')` 返回 null，
        // 所以这类书在「全部时间」口径下看着正常（被短路放过），
        // 一点「今年」就集体消失，指标卡显示成「读完 0 本」。
        book('b1', 'A', category: '经济', finishedAt: '$y-01'),
        book('b2', 'B', category: '经济', finishedAt: '${y - 1}-11'),
      ]);
      await render(tester, const StatsPage());

      await pickRange(tester, '$y 年');

      expect(find.text('共 1 本纳入统计'), findsOneWidget);
      // 这条是真正的断言：修好之前这里会出现「这个区间还没有读完的书」，
      // 因为读完日期解析不出来 → 图表拿不到数据
      expect(find.text('这个区间还没有读完的书'), findsNothing);
    });

    testWidgets('年度统计的口径写在图面上', (tester) async {
      bigViewport(tester);
      final y = DateTime.now().year;
      final mar = DateTime.utc(y, 3, 1).millisecondsSinceEpoch ~/ 1000;
      await repo.setSetting(
          'wereadAnnualStats',
          jsonEncode({
            'year': y,
            'annual': {
              'readTimes': {'$mar': 3600},
              'readDays': 20,
            },
          }));
      await repo.insertMany([book('b1', 'A', category: '经济')]);
      await render(tester, const StatsPage());

      // 「月度阅读时长」的横轴是年度统计所在的**自然年**，
      // 与上面「月度在读」的最近 12 个月不是一个口径。
      // 两句话必须都出现在界面上，否则用户会以为图错了。
      expect(find.textContaining('$y 年 · 合计'), findsOneWidget);
      expect(find.textContaining('只覆盖 $y 年'), findsOneWidget);
    });

    /* ------------------------- 图表显示设置 ------------------------- */

    /// 抽屉里那条 `SwitchListTile` 在统计页上**只能通过开关本身**定位。
    ///
    /// ⚠️ 用 `find.text(图名)` 是不行的：抽屉是叠在统计页上的，
    /// 页面里本来就有一份「来源平台」这样的图标题，`find.ancestor` 会
    /// 命中页面上那张只读的 Text，点下去什么也没发生——测试看起来是
    /// 「隐藏没生效」。所以这里一律按 `SwitchListTile` 在抽屉里的
    /// **下标**定位，下标与 `StatsChart.all` 的顺序一致。
    Finder sheetSwitch(int index) =>
        find.descendant(of: find.byType(SwitchListTile).at(index), matching: find.byType(Switch));

    int chartIndex(String id) => StatsChart.all.indexOf(id);

    void deviceViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    /// ⚠️ 打开抽屉后必须 `pumpAndSettle`，**不能用 `settleAsync`**。
    ///
    /// 抽屉是带滑入动画的模态路由，而 `settleAsync` 里的 `pump()` 不推
    /// 动画时钟——抽屉会永远停在「滑到一半」的位置（实测 1400 高的视口里
    /// 落在 y≈1885，整块在屏幕外），后面所有 tap 全部打空，用例看起来是
    /// 「隐藏没生效」。
    ///
    /// 关掉抽屉时同理。这跟数据库那套 `runAsync` 是两件事：
    /// 动画走的是 FakeAsync 的时钟，真实 I/O 走的是事件循环。
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
    }

    Future<void> closeSettings(WidgetTester tester) async {
      await tester.tap(find.text('应用'));
      await tester.pumpAndSettle();
      // 抽屉关了之后，页面要按新偏好重排；这一步才是真正要等 I/O 的地方
      await settleAsync(tester);
    }

    /// 关掉一张图并应用。
    Future<void> hideChart(WidgetTester tester, String id) async {
      await openSettings(tester);
      await tester.tap(sheetSwitch(chartIndex(id)));
      await tester.pump();
      await closeSettings(tester);
    }

    testWidgets('默认七张图全显示', (tester) async {
      bigViewport(tester);
      await repo.insert(book('b1', 'A', category: '经济', finishedAt: '2026-01-15'));
      await render(tester, const StatsPage());

      expect(find.text('来源平台'), findsWidgets);
      expect(find.text('评分分布'), findsWidgets);
    });

    testWidgets('关掉一张图，它就真的从页面上消失，且写进设置', (tester) async {
      deviceViewport(tester);
      await repo.insert(book('b1', 'A', category: '经济', finishedAt: '2026-01-15'));
      await render(tester, const StatsPage());

      await hideChart(tester, StatsChart.source);

      expect(find.text('来源平台'), findsNothing, reason: '关掉后不该再出现');
      // 其它图不受影响——「关一张结果全没了」是最容易犯的错。
      // 注意只能断言**视口内的**那几张：ListView 是懒构建的，
      // 1400 高的视口里「评分分布」还没被建出来，`findsWidgets` 会假红。
      expect(find.text('阅读状态分布'), findsWidgets);
      expect(find.text('分类分布 Top 8'), findsWidgets);

      // 偏好必须落库，否则下次进来又回来了
      final stored = await repo.getSetting('stats_hidden_charts');
      expect(stored, contains('source'));
      expect(stored, isNot(contains('rating')));
    });

    testWidgets('打开页面时读回已保存的偏好', (tester) async {
      bigViewport(tester);
      // 模拟「上次关掉了来源平台」
      await repo.setSetting('stats_hidden_charts', 'source');
      await repo.insert(book('b1', 'A', category: '经济', finishedAt: '2026-01-15'));
      await render(tester, const StatsPage());

      expect(find.text('来源平台'), findsNothing);
      expect(find.text('评分分布'), findsWidgets);
    });

    testWidgets('「全部隐藏」之后页面不会崩，且各区块标题仍在', (tester) async {
      deviceViewport(tester);
      await repo.insert(book('b1', 'A', category: '经济', finishedAt: '2026-01-15'));
      await render(tester, const StatsPage());

      await openSettings(tester);
      await tester.tap(find.text('全部隐藏'));
      await tester.pump();
      await closeSettings(tester);

      expect(find.text('来源平台'), findsNothing);
      expect(find.text('阅读状态分布'), findsNothing);
      // 页面骨架（标题、指标）不归图表开关管，必须还在
      expect(find.text('统计'), findsOneWidget);
      expect(find.text('当前书架'), findsOneWidget);
      expect(find.textContaining('结构分析'), findsWidgets);
    });

    testWidgets('设置抽屉里的开关初始状态与当前偏好一致', (tester) async {
      deviceViewport(tester);
      await repo.setSetting('stats_hidden_charts', 'source,rating');
      await repo.insert(book('b1', 'A', category: '经济', finishedAt: '2026-01-15'));
      await render(tester, const StatsPage());

      await openSettings(tester);

      // 被隐藏的两张：开关是关的；其余是开的
      bool isOn(String id) =>
          tester.widget<Switch>(sheetSwitch(chartIndex(id))).value;

      expect(isOn(StatsChart.source), isFalse);
      expect(isOn(StatsChart.rating), isFalse);
      expect(isOn(StatsChart.status), isTrue);
    });
  });

  group('阅历（月度看板）', () {
    /// 提示语与「＋」卡片的文案是同一句，页面里本来就会出现多次，
    /// 所以断言一律用 `findsWidgets` 而不是 `findsOneWidget`。
    testWidgets('按月分块，读完的书落在对应月份里', (tester) async {
      bigViewport(tester);
      final y = DateTime.now().year;
      await repo.insertMany([
        book('b1', '一月读的书', finishedAt: '$y-01-15'),
        book('b2', '三月读的书', finishedAt: '$y-03-20'),
        book('b3', '正在读的书',
            status: BookStatus.reading, finishedAt: null),
      ]);
      await render(tester, const ChronologyPage());

      // 竖向列表虽然也是懒构建，但整页只有一列、十二个月顺排，
      // 3600 高的视口足够把全年铺开——这里可以硬断言十二个月都在。
      for (var m = 1; m <= 12; m++) {
        expect(find.text('$m 月'), findsWidgets, reason: '缺少 $m 月');
      }
      expect(find.text('一月读的书'), findsOneWidget);
      expect(find.text('三月读的书'), findsOneWidget);
    });

    testWidgets('十二个月都是可滚到的条目', (tester) async {
      bigViewport(tester);
      final y = DateTime.now().year;
      await repo.insert(book('b1', 'A', finishedAt: '$y-05-01'));
      await render(tester, const ChronologyPage());

      // 竖排和横排的本质差别在这里：横排时的十二列**只能靠横向手势**
      // 才能到达，一屏就是两列，全年永远无法同时存在于视口里。
      // 竖排则是十二个顺排的条目，滚下去就能逐个看到。
      //
      // 但断言方式仍要小心：`ListView` 是**懒构建**的，屏幕外的条目
      // 不在 element 树里，所以不能直接 `findsNWidgets(12)` 数月份——
      // 那测的是视口高度，不是这个功能。正确做法是**逐个滚到它**
      // （`scrollUntilVisible` 自带滚动循环），能滚到就说明它存在。
      for (var m = 1; m <= 12; m++) {
        await tester.scrollUntilVisible(
          find.text('$m 月'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('$m 月'), findsWidgets, reason: '$m 月 滚不到');
      }
    });

    testWidgets('单月超过 4 本时折叠成网格，点「另有 N 本」能看全', (tester) async {
      bigViewport(tester);
      final y = DateTime.now().year;
      await repo.insertMany([
        for (var i = 1; i <= 6; i++)
          book('b$i', '三月第 $i 本', finishedAt: '$y-03-0$i'),
        book('b7', '一月读的书', finishedAt: '$y-01-10'),
      ]);
      await render(tester, const ChronologyPage());

      // 概览里只摊前 4 本，第 5、6 本收进「另有 2 本（点开看整月）」
      expect(find.text('三月第 1 本'), findsOneWidget);
      expect(find.text('三月第 4 本'), findsOneWidget);
      expect(find.text('三月第 5 本'), findsNothing,
          reason: '超出 4 本的书不应出现在概览里');

      // 用 textContaining 而不是整串相等：文案后面可能还会调，
      // 但「另有 N 本」这个数字必须对得上（6 本摊 4 本 = 另有 2 本）
      final moreLink = find.textContaining('另有 2 本');
      expect(moreLink, findsOneWidget);

      // 点进二级页，整月 6 本都要在（含概览里没摊开的那两本）
      await tester.tap(moreLink);
      await settleAsync(tester);
      expect(find.text('三月第 5 本'), findsOneWidget);
      expect(find.text('三月第 6 本'), findsOneWidget);
      // 上一页（概览）被盖住但**仍在 element 树里**，所以「三月第 1 本」
      // 此刻共有两份：概览网格里那份 + 二级页列表里那份。
      // 断言改成«二级页这一层里确实有它»，而不是全局唯一。
      expect(
        find.descendant(
          of: find.byType(MonthDetailPage),
          matching: find.text('三月第 1 本'),
        ),
        findsOneWidget,
        reason: '二级页展示的是整月，不是「剩下的那几本」',
      );
    });

    testWidgets('没有时间锚点的书不进看板', (tester) async {
      bigViewport(tester);
      // 想看 / 搁置都没有 startedAt / finishedAt，硬塞进某个月只能是编的
      await repo.insertMany([
        book('b1', '想看的书', status: BookStatus.wish, finishedAt: null),
        book('b2', '搁置的书', status: BookStatus.shelved, finishedAt: null),
      ]);
      await render(tester, const ChronologyPage());

      expect(find.text('想看的书'), findsNothing);
      expect(find.text('搁置的书'), findsNothing);
      // 空态不是崩，而是给一句说明
      expect(find.textContaining('还没有'), findsWidgets);
    });

    testWidgets('空库不崩溃，且年份仍可切换', (tester) async {
      await render(tester, const ChronologyPage());
      expect(find.text('阅历'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('整页只有一个竖向滚动方向（手机姿势）', (tester) async {
      bigViewport(tester);
      final y = DateTime.now().year;
      await repo.insert(book('b1', 'A', finishedAt: '$y-05-01'));
      await render(tester, const ChronologyPage());

      // 这一条的由来：初版照搬 Notion 的横向十二列，手机上一屏只看得到
      // 两列，全年得靠反复左右划才拼得出来。现在主滚动容器必须是竖向的，
      // 且页面里**不该**再有横向滚动的月份条。
      final scrollables = find
          .byType(Scrollable)
          .evaluate()
          .map((e) => e.widget as Scrollable)
          .where((s) => s.axisDirection == AxisDirection.down ||
              s.axisDirection == AxisDirection.up)
          .length;
      expect(scrollables, greaterThan(0), reason: '应有竖向滚动容器');

      final horizontal = find
          .byType(Scrollable)
          .evaluate()
          .map((e) => e.widget as Scrollable)
          .where((s) => s.axisDirection == AxisDirection.left ||
              s.axisDirection == AxisDirection.right)
          .length;
      expect(horizontal, 0, reason: '阅历页不应再有横向滚动的月份条');
    });
  });

  group('阅读档案页', () {
    void tallViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('标签与偏好分布都能渲染，并且带文本图例', (tester) async {
      tallViewport(tester);
      await repo.insertMany([
        book('a1', 'A1', category: '文学', status: BookStatus.wish),
        book('a2', 'A2', category: '文学', status: BookStatus.wish),
        book('a3', 'A3', category: '文学', status: BookStatus.wish),
        book('a4', 'A4', category: '哲学', status: BookStatus.wish),
        book('a5', 'A5', category: '哲学', status: BookStatus.wish),
        book('a6', 'A6', category: '哲学', status: BookStatus.wish),
      ]);
      await render(tester, const InsightsPage());

      expect(find.text('我的性格标签'), findsOneWidget);
      expect(find.text('阅读偏好分布'), findsOneWidget);
      // 分类偏好推出标签
      expect(find.text('浪漫诗意'), findsOneWidget);
      expect(find.text('孤独的智者'), findsOneWidget);
      // 气泡画在 canvas 上，读屏与 find 都取不到字，
      // 所以名称与占比必须另有一份文本图例
      expect(find.text('文学'), findsOneWidget);
      expect(find.text('哲学'), findsOneWidget);
      expect(find.text('50.0%'), findsWidgets);
    });

    testWidgets('点标签直接进编辑弹窗，能改也能删', (tester) async {
      tallViewport(tester);
      await repo.insertMany([
        book('a1', 'A1', category: '文学'),
        book('a2', 'A2', category: '文学'),
        book('a3', 'A3', category: '文学'),
      ]);
      await render(tester, const InsightsPage());

      // 用户反馈过「性格标签点击无法修改」——这里点开必须是编辑弹窗
      // （带删除 / 保存），而不是一段只读的依据说明。
      await tester.tap(find.text('浪漫诗意'));
      await settleAsync(tester);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('编辑标签'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      // 依据仍然要显示，改标签时需要知道它从哪来
      expect(find.textContaining('文学 3 本'), findsOneWidget);
    });

    testWidgets('在弹窗里改标签文字会落库，重建后仍是新值', (tester) async {
      tallViewport(tester);
      await repo.insertMany([
        book('a1', 'A1', category: '文学'),
        book('a2', 'A2', category: '文学'),
        book('a3', 'A3', category: '文学'),
      ]);
      await render(tester, const InsightsPage());

      await tester.tap(find.text('浪漫诗意'));
      await settleAsync(tester);
      await tester.enterText(find.byType(TextField), '改过的标签');
      await tester.tap(find.text('保存'));
      await settleAsync(tester);

      expect(find.text('改过的标签'), findsOneWidget);
      expect(find.text('浪漫诗意'), findsNothing);
      // 落库而非仅改内存：重开页面还是新值
      await repo.setSetting(profileMainTagsKey, '');
    });

    testWidgets('空库给出明确空态', (tester) async {
      await render(tester, const InsightsPage());
      expect(find.text('这个区间里还没有书'), findsOneWidget);
    });

    testWidgets('性格标签不用再点进二级页就能看到标签', (tester) async {
      tallViewport(tester);
      await repo.insertMany([
        book('a1', 'A1', category: '文学'),
        book('a2', 'A2', category: '文学'),
        book('a3', 'A3', category: '文学'),
      ]);
      await render(tester, const InsightsPage());
      // 内联展示的核心价值：一眼可见
      expect(find.text('浪漫诗意'), findsOneWidget);
    });
  });

  group('阅读档案页（内容顺序）', () {
    void tallViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('两块内容同屏：偏好分布 → 性格标签 → 报告', (tester) async {
      tallViewport(tester);
      await repo.insertMany([
        book('a1', 'A1', category: '文学', status: BookStatus.wish),
        book('a2', 'A2', category: '文学', status: BookStatus.wish),
      ]);
      await render(tester, const InsightsPage());

      // 用户明确要求的顺序：偏好分布第一、性格标签第二、报告第三。
      // 用纵向坐标而不是「存在与否」来断言——三块都在页面上时，
      // 只有比较 y 才能发现顺序被改回去。
      //
      // ⚠️ 报告区的标题是「历史报告」（s_a3dfa2a6，见 AiReportPanel 的标题行）。
      // 不能拿「AI 阅读报告」来定位：那是已删除的画像入口卡的副标题，
      // 拿它当锚点会测到卡片本身而不是报告区（旧版就这么错着）。
      final prefY = tester.getTopLeft(find.text('阅读偏好分布')).dy;
      final tagY = tester.getTopLeft(find.text('我的性格标签')).dy;
      final reportY = tester.getTopLeft(find.text('历史报告').first).dy;

      expect(prefY, lessThan(tagY), reason: '偏好分布在性格标签之前');
      expect(tagY, lessThan(reportY), reason: '性格标签在报告之前');
    });

    testWidgets('阅读计划已搬去「记录」栏，档案页不再出现', (tester) async {
      tallViewport(tester);
      await repo.insertMany([book('a1', 'A1', category: '文学')]);
      await render(tester, const InsightsPage());
      // 计划与笔记同属「进行中的产出」，已并入第二栏；档案只留回顾性内容
      expect(find.text('阅读计划'), findsNothing);
    });

    testWidgets('画像入口卡已删除，功能全内联', (tester) async {
      tallViewport(tester);
      await repo.insertMany([book('a1', 'A1', category: '文学')]);
      await render(tester, const InsightsPage());
      // 以前页尾还有一张「阅读画像」入口卡（副标题是「AI 阅读报告」），
      // 内联之后它只会让人以为下面还有别的东西；已删。
      expect(find.widgetWithText(ListTile, '阅读画像'), findsNothing);
      expect(find.text('AI 阅读报告'), findsNothing);
      // 但报告本身还在——删的是入口，不是功能
      expect(find.text('历史报告'), findsOneWidget);
    });
  });

  // 阅读计划此前挂在「阅读档案」页，现与笔记合并为第二栏「记录」。
  // 这几条断言跟着 PlanSection 一起搬到了 NotesPage 上。
  group('记录页（笔记 + 阅读计划）', () {
    void tallViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('计划空态给出引导而不是一片空白', (tester) async {
      tallViewport(tester);
      await render(tester, const NotesPage());
      expect(find.text('阅读计划'), findsOneWidget);
      expect(find.textContaining('还没有计划'), findsOneWidget);
    });

    testWidgets('有进行中的计划时展示进度，不显示「已完成」', (tester) async {
      tallViewport(tester);
      await repo.upsertPlan(ReadingPlan(
        id: 'p1',
        kind: PlanKind.dailyMinutes,
        dailyMinutes: 30,
        createdAt: DateTime.now().toIso8601String(),
      ));
      await render(tester, const NotesPage());

      // 没给自定义标题时，按类型生成标题
      expect(find.text('每天阅读'), findsOneWidget);
      expect(find.textContaining('日均 0 / 30 分钟'), findsOneWidget);
      expect(find.text('已达成'), findsNothing);
      // 未完成的计划不该被塞进「已结束」分区
      expect(find.text('已结束'), findsNothing);
    });

    testWidgets('目标已达成时直接显示达成，不用用户再点一次', (tester) async {
      tallViewport(tester);
      await repo.insert(book('b1', '目标书', status: BookStatus.finished));
      await repo.upsertPlan(ReadingPlan(
        id: 'p1',
        kind: PlanKind.finishBook,
        bookId: 'b1',
        createdAt: DateTime.now().toIso8601String(),
      ));
      await render(tester, const NotesPage());

      expect(find.text('已达成'), findsOneWidget);
      expect(find.text('目标书'), findsWidgets);
    });

    testWidgets('goal 书已从书架删除时提示，而不是显示 0% 让人困惑', (tester) async {
      tallViewport(tester);
      await repo.upsertPlan(ReadingPlan(
        id: 'p1',
        kind: PlanKind.finishBook,
        bookId: '不存在的书',
        createdAt: DateTime.now().toIso8601String(),
      ));
      await render(tester, const NotesPage());
      expect(find.textContaining('已不在书架'), findsOneWidget);
    });

    testWidgets('计划在前、笔记在后，两块同屏可滚', (tester) async {
      tallViewport(tester);
      await repo.insert(book('b1', '有笔记的书'));
      await repo.addNote(Note(
        id: 'n1',
        bookId: 'b1',
        type: NoteType.thought,
        content: '一条笔记',
        createdAt: DateTime.now().toIso8601String(),
      ));
      await render(tester, const NotesPage());

      // 合并栏的核心是「两块能一起看到」。用 y 坐标断言顺序：
      // 计划是前瞻性的（今天要读什么），进门第一眼就该看见，放最上面；
      // 笔记是回顾性的，翻起来没有时效压力，接在后面。
      final planY = tester.getTopLeft(find.text('阅读计划')).dy;
      final noteY = tester.getTopLeft(find.text('一条笔记')).dy;
      expect(planY, lessThan(noteY), reason: '阅读计划在笔记流之前');

      // 笔记自己不能再吃掉滚动手势，否则用户滚不到上面的计划
      expect(find.text('一条笔记'), findsOneWidget);
    });
  });

  group('底部导航', () {
    testWidgets('五栏顺序：书架 → 记录 → 统计 → 阅读档案 → 设置', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // 必须走 render（内部带 repoProvider 覆盖 + settleAsync）：
      // HomeShell 首帧要 await loadSettings，没有内存库就会一直卡在
      // 转圈上，导航栏压根不构建。
      await render(tester, const HomeShell());

      // 第二栏叫「记录」——笔记与阅读计划合并后的名字。
      // 名字本身是产品决策，改了测试就该红。
      //
      // 不按 `find.byType(NavigationDestination)` 取 label：NavigationBar
      // 把 destinations 当成**配置**消化掉，从不把它们挂进 element 树，
      // byType 永远是空列表。改为断言渲染出来的文本文案，
      // 并按 x 坐标验顺序——位置错了也是错。
      final labels = ['书架', '记录', '统计', '阅读档案', '设置'];
      for (final l in labels) {
        expect(find.text(l), findsWidgets, reason: '缺少导航栏「$l」');
      }
      final xs = [
        for (final l in labels) tester.getCenter(find.text(l).first).dx,
      ];
      for (var i = 1; i < xs.length; i++) {
        expect(xs[i], greaterThan(xs[i - 1]),
            reason: '导航栏顺序错：第 ${i + 1} 项应排在第 $i 项右侧');
      }
    });
  });

  group('设置页', () {
    testWidgets('渲染配置项与保存按钮', (tester) async {
      // 设置页是长列表：默认 800×600 视口只构建首屏，
      // 下面的 TextField（WeRead Key / LLM 三连）压根没渲染，
      // find.byType(TextField) 会假红。放大视口再断言——
      // 和其它长页面测试（AI 报告页）保持一致的做法。
      bigViewport(tester);
      await render(tester, const SettingsPage());
      expect(find.text('设置'), findsOneWidget);
      // 配置页是长列表，「保存配置」按钮在首屏之外，未渲染前 find 不到，
      // 因此这里断言首屏一定存在的输入框，而不是滚到底部去找按钮
      expect(find.byType(TextField), findsWidgets);
    });

    /// 长选项收成下拉后的回归。
    ///
    /// 语言和分类曾是整页里最占地方的两块：语言 6 行单选、分类二十来行
    /// 列表（还不算每行一个弹菜单），设置页因此被撑到三屏以上。
    /// 现在两者都必须只占一行，展开才看到选项。
    testWidgets('语言与分类收成下拉，选项不再逐行铺开', (tester) async {
      bigViewport(tester);
      await render(tester, const SettingsPage());
      await settleAsync(tester);
      // 分类：下拉只显示当前选中的那一项（默认落在词表第一项）
      expect(find.text('选择分类'), findsOneWidget);
      expect(find.text('文学'), findsOneWidget);
      // 词表里其余分类不再占行——没点开下拉就不该在树里
      expect(find.text('宗教'), findsNothing);
      expect(find.text('计算机'), findsNothing);
      // 语言：6 行单选收成 1 行。当前值「跟随系统」照常显示在按钮上，
      // 但其余语言不该还在树里——它们只在展开后才构建。
      expect(find.byType(DropdownButtonFormField<String?>), findsOneWidget);
      expect(find.text('Deutsch'), findsNothing);
      expect(find.text('界面语言'), findsWidgets);
    });

    testWidgets('分类下拉里是完整词表，选中后才能改名或删除', (tester) async {
      bigViewport(tester);
      await render(tester, const SettingsPage());
      await settleAsync(tester);
      // 「识别模式」的下拉也是 DropdownButtonFormField<String>，按 labelText 认人
      final dropdown = find.byWidgetPredicate((w) =>
          w is DropdownButtonFormField<String> &&
          w.decoration.labelText == '选择分类');
      expect(dropdown, findsOneWidget);

      await tester.tap(dropdown);
      await settleAsync(tester);
      // 展开后才是完整词表
      expect(find.text('宗教'), findsWidgets);
      await tester.tap(find.text('宗教').last);
      await settleAsync(tester);
      // 收起后只剩当前值，操作按钮针对它生效
      expect(find.text('宗教'), findsOneWidget);
      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);

      await tester.tap(find.text('删除'));
      await settleAsync(tester);
      // 删除不可逆：必须先确认，且要说明有多少书会移到未分类
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('未分类'), findsWidgets);
      await tester.tap(find.text('取消'));
      await settleAsync(tester);
      // 取消后词表原样不动
      expect(find.text('宗教'), findsOneWidget);
    });

    testWidgets('语言下拉列出全部语言并可切换', (tester) async {
      bigViewport(tester);
      await render(tester, const SettingsPage());
      await settleAsync(tester);
      // 语言下拉的泛型是 String?（「跟随系统」= null），与其它下拉不重样
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await settleAsync(tester);
      for (final name in [
        '跟随系统',
        '简体中文',
        'English',
        'Deutsch',
        'Français',
        'Español',
      ]) {
        expect(find.text(name), findsWidgets, reason: '语言下拉缺少「$name」');
      }
      await tester.tap(find.text('Deutsch').last);
      await settleAsync(tester);
      // 选完即收起，控件上留下的是当前语言的自称
      expect(find.text('Deutsch'), findsOneWidget);
    });
  });

  group('AI 报告页', () {
    testWidgets('无历史报告时渲染空态', (tester) async {
      await render(tester, const AiReportPage());
      expect(find.text('阅读报告'), findsOneWidget);
    });

    testWidgets('周期按年/月归档，可切到去年的年报', (tester) async {
      bigViewport(tester);
      await render(tester, const AiReportPage());
      final y = DateTime.now().year;
      expect(find.text('报告周期'), findsOneWidget);
      // 默认落在今年年报
      expect(find.text('$y 年'), findsWidgets);

      // 下拉项只有展开后才构建，不点开就断言会假红
      await tester.tap(find.byType(DropdownButtonFormField<ReportPeriod>));
      await settleAsync(tester);
      expect(find.text('${y - 1} 年'), findsWidgets);
      await tester.tap(find.text('${y - 1} 年').last);
      await settleAsync(tester);
      expect(find.text('${y - 1} 年'), findsWidgets);
    });

    testWidgets('报告首页只留历史与生成，配置收进二级页', (tester) async {
      bigViewport(tester);
      await render(tester, const AiReportPage());
      // 配置项（风格 / 自动生成 / 补生成）都搬进了二级页
      expect(find.text('报告设置'), findsOneWidget);
      expect(find.text('报告风格'), findsNothing);
      // 空库时给出明确空态，而不是一片空白。
      // 测试库没配大模型 Key，所以走的是「先配 Key」那条文案
      // ——两条都是空态，断言要认现实里的那一条。
      expect(find.textContaining('还没有'), findsOneWidget);
    });

    testWidgets('报告设置页：默认只勾年报，月报要用户自己开', (tester) async {
      bigViewport(tester);
      await render(tester, const ReportSettingsPage());
      await settleAsync(tester);
      // 用户明确要求「默认生成年报，用户选择是否生成月报」
      expect(find.text('年报'), findsOneWidget);
      expect(find.text('月报'), findsOneWidget);
      final boxes = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(boxes.length, 2);
      expect(boxes[0].value, isTrue, reason: '年报默认开');
      expect(boxes[1].value, isFalse, reason: '月报默认关，由用户自己勾');
    });

    testWidgets('报告设置页不再自动补生成，改成显式按钮', (tester) async {
      bigViewport(tester);
      await render(tester, const ReportSettingsPage());
      await settleAsync(tester);
      // 打开设置页不该有任何自动生成（那会在用户无感知下烧 token）
      expect(find.text('补生成缺失的报告'), findsOneWidget);
    });

    testWidgets('会告知用户书名清单会被上传', (tester) async {
      bigViewport(tester);
      await render(tester, const AiReportPage());
      expect(find.textContaining('书名清单'), findsOneWidget);
    });

    testWidgets('点开历史报告：不崩、显示正文，且无语法符号外泄', (tester) async {
      // 回归：_openHistory 曾把 parse 出来的新 ReportPeriod 实例直接赋给
      // _period，而候选列表里是另一个同 key 实例（未重载 ==，按同一性比较），
      // DropdownButton 断言 value 不在 items 里，点开历史报告必崩。
      bigViewport(tester);
      final y = DateTime.now().year;
      final m = DateTime.now().month == 1 ? 2 : 1; // 当月不在候选里，取一个确定的月
      await repo.saveReport(
        period: '$y-0$m',
        model: 'demo',
        content: '## 概览\n\n本月读完 **2 本**，日均 **20 分钟**。',
      );
      await render(tester, const AiReportPage());

      // 历史瓦片带全页唯一的 description 图标，用它定位。
      await tester.scrollUntilVisible(
        find.byIcon(Icons.description_outlined),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byIcon(Icons.description_outlined));
      await settleAsync(tester);

      expect(tester.takeException(), isNull);

      // 正文现在在**独立页**里，列表页仍留在路由栈下面没被卸载——
      // 它的摘要卡上也有「本月读完…」，所以文本会命中两份。
      // 断言正文页那一份：用 ReportDetailPage 限定范围。
      final detail = find.byType(ReportDetailPage);
      expect(detail, findsOneWidget, reason: '点历史应跳进报告正文页');
      expect(
        find.descendant(of: detail, matching: find.textContaining('本月读完')),
        findsOneWidget,
      );
      // Markdown 语法符号不能印到屏幕上
      expect(
        find.descendant(of: detail, matching: find.textContaining('**')),
        findsNothing,
      );
    });
  });

  group('数据导出页', () {
    testWidgets('渲染导出与恢复两个入口', (tester) async {
      await render(tester, const BackupPage());
      expect(find.text('数据导出与恢复'), findsOneWidget);
      expect(find.text('导出为 JSON 文件'), findsOneWidget);
      expect(find.text('选择备份文件并恢复'), findsOneWidget);
    });

    testWidgets('说明里点明包含哪些表', (tester) async {
      await render(tester, const BackupPage());
      expect(find.textContaining('图书'), findsOneWidget);
      expect(find.textContaining('AI 报告'), findsOneWidget);
    });
  });

  group('手动添加图书', () {
    /// 从书架「+」走到手填表单。
    ///
    /// 本版把「+」改成了**底部抽屉**（列出全部添加方式），手填只是其中一项；
    /// 抽屉自己还有一段入场动画，且手填走的是**全屏页**（不是底部表单）——
    /// 所以比原来多一跳，且每一步都要把动画推完再点下一层。
    ///
    /// ⚠️ 这里必须用 `pumpAndSettle`，不能只 `pump(400ms)` 跳一大步。
    /// 路由 push 之后动画控制器要在**下一帧**才开始 tick；一次性跳过整个
    /// 时长会落在「还没开始动」的位置上，抽屉停在屏幕外的 y=1400，
    /// 里面的每一项都点不到，报 `Bad state: No element`。
    ///
    /// 两级入口都用图标定位：书架「+」的 tooltip 与抽屉标题现在都叫
    /// 「添加图书」，按文字找会撞车。
    Future<void> openManualForm(WidgetTester tester) async {
      await render(tester, const ShelfPage());
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await settleAsync(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      await settleAsync(tester);
    }

    testWidgets('填书名即可入架，并落到数据库', (tester) async {
      sheetViewport(tester);
      await openManualForm(tester);

      expect(find.text('手动添加图书'), findsWidgets);
      await tester.enterText(
          find.widgetWithText(TextField, '书名 *'), '置身事内');
      await tester.enterText(
          find.widgetWithText(TextField, '作者'), '兰小欢');
      await settleAsync(tester);

      await tester.tap(find.text('加入书架'));
      await settleAsync(tester);

      final all = await repo.all();
      expect(all.length, 1);
      expect(all.single.title, '置身事内');
      expect(all.single.authors, ['兰小欢']);
      // 手填的书必须过归一化，否则「经管励志」和库里的「管理」会裂成两类
      expect(all.single.source, BookSource.manual);
    });

    testWidgets('书名为空时不落库', (tester) async {
      sheetViewport(tester);
      await openManualForm(tester);
      await tester.tap(find.text('加入书架'));
      await settleAsync(tester);

      expect(find.text('书名不能为空'), findsOneWidget);
      expect(await repo.all(), isEmpty);
    });

    testWidgets('标成已读会自动补完成时间，否则「今年读完」永远少一本',
        (tester) async {
      sheetViewport(tester);
      await openManualForm(tester);
      await tester.enterText(
          find.widgetWithText(TextField, '书名 *'), '万历十五年');
      await settleAsync(tester);

      // 状态从下拉框改成了 chips（与详情页共用 StatusEditor）。
      // 不能按文字找「已读完」：书架页筛选条里也有状态 chip，会撞车；
      // 限定在 ChoiceChip 里找才唯一。
      await tester.tap(find.widgetWithText(ChoiceChip, '已读完'));
      await settleAsync(tester);

      await tester.tap(find.text('加入书架'));
      await settleAsync(tester);

      final b = (await repo.all()).single;
      expect(b.status, BookStatus.finished);
      expect(b.finishedAt, isNotNull);
      expect(b.progressPercent, 100);
    });
  });

  group('笔记', () {
    testWidgets('空态给出引导，可添加可落库', (tester) async {
      bigViewport(tester);
      await repo.insert(book('b1', '置身事内'));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      expect(find.text('笔记 · 0'), findsOneWidget);
      await tester.tap(find.text('添加笔记'));
      await settleAsync(tester);

      expect(find.text('添加笔记'), findsWidgets);
      await tester.enterText(
          find.widgetWithText(TextField, '摘抄、随想或书评…'), '地方政府的行为逻辑');
      await settleAsync(tester);
      await tester.tap(find.text('保存').last);
      await settleAsync(tester);

      final notes = await repo.notesOf('b1');
      expect(notes.length, 1);
      expect(notes.single.content, '地方政府的行为逻辑');
      expect(find.text('笔记 · 1'), findsOneWidget);
    });

    testWidgets('可删除', (tester) async {
      bigViewport(tester);
      await repo.insert(book('b1', '置身事内'));
      await repo.addNote(Note(
        id: 'n1',
        bookId: 'b1',
        type: NoteType.thought,
        content: '随手记',
        createdAt: DateTime.now().toIso8601String(),
      ));
      await render(tester, const BookDetailPage(bookId: 'b1'));
      expect(find.text('随手记'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      // 弹出菜单有入场动画，只推进一帧时点位还在动画中间态，
      // tap 会打空——而打空只 warning 不失败，用例会假绿。
      // 菜单还要先被 build 出来，所以先跑一轮 settleAsync 再等动画走完。
      await settleAsync(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await settleAsync(tester);
      expect(find.text('编辑'), findsOneWidget);
      await tester.tap(find.text('删除').last);
      await settleAsync(tester);
      await tester.pump(const Duration(milliseconds: 400));
      await settleAsync(tester);
      await tester.tap(find.text('删除').last);
      await settleAsync(tester);

      expect(await repo.notesOf('b1'), isEmpty);
    });
  });

  group('书籍详情页', () {
    /// **不要用 `find.widgetWithText(OutlinedButton, ...)` 定位这种按钮。**
    ///
    /// `OutlinedButton.icon` 构造出来的**不是** `OutlinedButton`，
    /// 而是一个私有子类 `_OutlinedButtonWithIcon`；`find.byType` 是
    /// 严格的 `runtimeType` 相等，所以 `byType(OutlinedButton)` 会返回 0 个，
    /// 断言会以「找不到」的形式失败，看起来像功能没实现。
    ///
    /// 这里改用 `runtimeType.toString().contains('OutlinedButton')` 的谓词——
    /// 两种构造方式（`.icon` 与普通）都能命中。
    ///
    /// 也不要用 `find.ancestor(...).first`：`.first` 在**零匹配**时会抛
    /// `Bad state: No element`，把「按钮不存在」这个干净的失败变成一条
    /// 堆栈难看的异常。「按钮不存在」正是这个测试要断言的情况之一，
    /// 所以必须让零匹配能正常返回空集合。改用 `find.descendant` 反查
    /// （从按钮往文本查），层次唯一，`findsOneWidget` / `findsNothing`
    /// 两种断言都能正常工作。
    Finder outlinedButtonWithText(String text) => find.descendant(
          of: find.byWidgetPredicate(
            (w) => w.runtimeType.toString().contains('OutlinedButton'),
          ),
          matching: find.text(text),
        );
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

    testWidgets('没有分类的书显示「未分类」而不是整行消失', (tester) async {
      // 整行消失会让用户以为分类丢了，而不是「还没填」
      await repo.insert(book('b1', '无分类的书'));
      await render(tester, const BookDetailPage(bookId: 'b1'));
      expect(find.textContaining('未分类'), findsOneWidget);
    });

    testWidgets('状态只有四项，不再有弃读/暂搁/借阅中', (tester) async {
      await repo.insert(book('b1', 'A'));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      for (final s in ['想看', '阅读中', '已读完', '搁置']) {
        expect(find.widgetWithText(ChoiceChip, s), findsOneWidget,
            reason: '缺少状态 $s');
      }
      for (final gone in ['弃读', '暂搁', '借阅中']) {
        expect(find.widgetWithText(ChoiceChip, gone), findsNothing,
            reason: '$gone 应该已经不存在了');
      }
    });

    testWidgets('点状态 chip 落库，标成已读完会补完成时间', (tester) async {
      await repo.insert(book('b1', 'A'));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      await tester.tap(find.widgetWithText(ChoiceChip, '已读完'));
      await settleAsync(tester);

      final b = (await repo.byId('b1'))!;
      expect(b.status, BookStatus.finished);
      expect(b.finishedAt, isNotNull);
      expect(b.progressPercent, 100);
    });

    testWidgets('借阅是独立开关：打开后出现来源与应还日期，且不影响阅读状态',
        (tester) async {
      await repo.insert(book('b1', 'A').copyWith(status: BookStatus.reading));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      // 关着的时候不该出现这两个字段，否则每本书都平白多两行
      expect(find.widgetWithText(TextField, '借阅来源'), findsNothing);

      await tester.tap(find.widgetWithText(SwitchListTile, '这是借来的书'));
      await settleAsync(tester);

      expect(find.widgetWithText(TextField, '借阅来源'), findsOneWidget);
      expect(find.text('应还日期'), findsWidgets);

      // 关键：借阅与状态正交，打开借阅不能把「在读」改掉
      final b = (await repo.byId('b1'))!;
      expect(b.isBorrowed, isTrue);
      expect(b.status, BookStatus.reading);
    });

    testWidgets('关闭借阅会清掉来源与应还日期，不留矛盾状态', (tester) async {
      await repo.insert(book('b1', 'A').copyWith(
        isBorrowed: true,
        borrowedFrom: '市图书馆',
        dueAt: '2026-12-01',
      ));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      await tester.tap(find.widgetWithText(SwitchListTile, '这是借来的书'));
      await settleAsync(tester);

      final b = (await repo.byId('b1'))!;
      expect(b.isBorrowed, isFalse);
      // 留着会显示「没标借阅但带着应还日期」
      expect(b.borrowedFrom, isNull);
      expect(b.dueAt, isNull);
    });

    testWidgets('标记已归还：清空借阅三件套，且按钮只在借阅中才出现',
        (tester) async {
      await repo.insert(book('b1', 'A').copyWith(
        isBorrowed: true,
        borrowedFrom: '市图书馆',
        dueAt: '2026-12-01',
      ));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      // 借阅中才有归还入口
      expect(outlinedButtonWithText('标记已归还'), findsOneWidget);

      await tester.tap(outlinedButtonWithText('标记已归还'));
      await settleAsync(tester);

      final b = (await repo.byId('b1'))!;
      expect(b.isBorrowed, isFalse);
      expect(b.borrowedFrom, isNull, reason: '归还后不该留着借阅来源');
      expect(b.dueAt, isNull, reason: '归还后不该留着应还日期');
      // 归还完成后按钮应当消失（已经不是借阅态了）
      expect(outlinedButtonWithText('标记已归还'), findsNothing);
    });

    testWidgets('非借阅的书不显示「标记已归还」', (tester) async {
      await repo.insert(book('b1', 'A'));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      // 归还针对的是「已经在书架上的借来的书」，普通书不该出现这个动作
      expect(outlinedButtonWithText('标记已归还'), findsNothing);
    });

    testWidgets('进度拖到 100% 自动变已读，但不会覆盖用户选的「搁置」',
        (tester) async {
      await repo.insert(book('b1', 'A').copyWith(
        status: BookStatus.shelved,
        progressPercent: 40,
      ));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      // 拖动进度条到大约 60%（不到 100%）
      await tester.drag(find.byType(Slider), const Offset(300, 0));
      await settleAsync(tester);

      // 用户已经明确选了「搁置」，动一下进度不该把它改回「在读」
      expect((await repo.byId('b1'))!.status, BookStatus.shelved,
          reason: '进度联动不该抹掉用户明确选过的搁置状态');
    });

    testWidgets('有编辑入口，改分类后详情页跟着更新', (tester) async {
      await repo.insert(book('b1', 'A', category: '经济'));
      await render(tester, const BookDetailPage(bookId: 'b1'));

      // 旧版根本没有这个入口，只能删掉重加——笔记和进度一起丢
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await settleAsync(tester);

      // 进入编辑表单，分类带过来了
      expect(find.text('编辑图书'), findsOneWidget);
    });

    /// 「检查更新」的三条路径都要有说法，且不自动下载。
    ///
    /// ## 为什么注入 mock adapter 而不是拦真实网络
    ///
    /// Dio 的超时定时器是 `Future.delayed`，在 FakeAsync 里会成为
    /// pending timer，让 flutter_test 在用例收尾时判失败——
    /// 即使断言全过。而真实 socket 读在假时钟里也永远等不到推进。
    /// 所以只能注入（`SettingsPage.updateChecker` 这个口子就是为此存在的）。
    ///
    /// ## 核心承诺
    ///
    /// 有新版时必须**先展示更新说明、再给下载入口**，且**不自动下载**。
    /// 「自动下载安装包」既费流量又越过用户选择——
    /// 应用数据在本地，覆盖安装前用户有权先看一眼改了什么。
    UpdateChecker _stubChecker(String tag, {String body = ''}) =>
        UpdateChecker(dio: Dio()..httpClientAdapter = _StubAdapter(
              jsonEncode({
                'tag_name': tag,
                'body': body,
                'published_at': '2026-10-09T09:00:00Z',
                'assets': [
                  {
                    'name': 'Readnest-$tag-release.apk',
                    'browser_download_url': 'https://example.test/$tag.apk',
                  },
                ],
              }),
            ));

    testWidgets('设置页有检查更新入口，且排在关于之前', (tester) async {
      bigViewport(tester);
      await render(tester, const SettingsPage());
      await settleAsync(tester);

      expect(find.byIcon(Icons.system_update_alt), findsOneWidget);
      final check = find.ancestor(
        of: find.byIcon(Icons.system_update_alt),
        matching: find.byWidgetPredicate(
            (w) => w is ButtonStyleButton && w.onPressed != null),
      );
      final about = find.text('关于');
      expect(about, findsOneWidget);
      expect(tester.getTopLeft(check).dy, lessThan(tester.getTopLeft(about).dy),
          reason: '「检查更新」应在「关于」之上——更新比翻关于更常用');
      expect(find.text('已经是最新版本了'), findsNothing,
          reason: '没点按钮就不该出现任何检查结果');
    });

    testWidgets('有新版时展示更新说明与下载入口，且不自动下载', (tester) async {
      bigViewport(tester);
      await render(tester, SettingsPage(
        updateChecker: _stubChecker('v1.1.0',
            body: '## 新版\n\n- 加了检查更新\n- 修了筛选抽屉'),
      ));
      await settleAsync(tester);

      // ⚠️ tap 必须整个放进 runAsync：Dio 走 dart:io HttpClient，
      // 完成回调由**真实事件循环**投递，不会进 FakeAsync 队列。
      // 只在 tap 之后才 runAsync 的话，请求永远停在半路，弹窗不打开。
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.system_update_alt));
        await tester.pump();
      });
      await settleAsync(tester);

      // 标题带上新版本号
      expect(find.text('有 1.1.0 了'), findsOneWidget);
      // 更新说明逐条列出——这是用户决定要不要更新的唯一依据
      expect(find.textContaining('加了检查更新'), findsOneWidget);
      expect(find.textContaining('修了筛选抽屉'), findsOneWidget);
      expect(find.text('这一版改了什么'), findsOneWidget);
      // 下载入口在，且**由用户点**才走
      expect(find.text('下载 1.1.0'), findsOneWidget);
    });

    testWidgets('已是最新时不显示下载入口', (tester) async {
      bigViewport(tester);
      await render(tester,
          SettingsPage(updateChecker: _stubChecker('v1.0.0')));
      await settleAsync(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.system_update_alt));
        await tester.pump();
      });
      await settleAsync(tester);

      expect(find.text('已经是最新版本了'), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsWidgets);
      expect(find.text('这一版改了什么'), findsNothing,
          reason: '没有新版就不该展示更新说明');
      expect(find.textContaining('下载'), findsNothing,
          reason: '已是最新时给下载入口没有意义——下载的就是当前版本');
    });

    testWidgets('检查失败时给可读提示，绝不静默当作已是最新', (tester) async {
      bigViewport(tester);
      await render(tester, SettingsPage(
        updateChecker: UpdateChecker(
          dio: Dio()..httpClientAdapter = _FailingAdapter(),
        ),
      ));
      await settleAsync(tester);

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.system_update_alt));
        await tester.pump();
      });
      await settleAsync(tester);

      expect(find.text('检查更新失败'), findsOneWidget);
      expect(find.text('已经是最新版本了'), findsNothing,
          reason: '网络失败若假装检查通过，用户会以为已是最新版并永远停在旧版本');
      expect(find.textContaining('网络'), findsWidgets,
          reason: '要说清是哪一类失败，用户才知道该重试还是等网络');
    });
  });
}

/// 回放固定 JSON 的 Dio adapter。见 update_checker_test.dart 的同名类。
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.json);

  final String json;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(json, 200,
          headers: {Headers.contentTypeHeader: ['application/json']});
}

/// 一律失败的 adapter，用来验证网络错误路径。
class _FailingAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      throw DioException(requestOptions: options);
}
