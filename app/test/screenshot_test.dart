import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/main.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/ai_report_page.dart';
import 'package:reading_tracker/ui/backup_page.dart';
import 'package:reading_tracker/ui/book_detail_page.dart';
import 'package:reading_tracker/ui/book_form_page.dart';

import 'support/localized_app.dart';

/// 界面截图生成器。
///
/// 为什么走测试渲染而不是 `flutter run -d linux`：
/// 本机 WSL 缺 GTK 开发库（clang / cmake / ninja / pkg-config / libgtk-3-dev），
/// 安装需要 sudo 密码；Web 端也不可行（sqflite 没有 web 实现）。
/// flutter_test 自带完整的 Skia 软件渲染管线，能在离线、免权限的前提下
/// 把真实界面渲染成 PNG，用来验收视觉效果足够了。
///
/// 生成/更新基准图：
///   bash scripts/screenshot.sh          # 内部就是 --update-goldens
/// 产物落在 test/goldens/*.png。
///
/// 本文件只负责出图，不参与断言回归。为了让代码和这句话一致，
/// **像素比对默认关闭**：`flutter test` 全量跑时这几张图不会被拿来对比，
/// 否则每次调个间距、改句文案都会变红，几轮之后所有人就学会无视红色了。
///
/// 但**渲染照常进行**——页面构建期抛异常（图表 canvas 尤其容易）依然会让
/// 测试失败，冒烟价值一分没少。只有 scripts/screenshot.sh 会设 GOLDEN=1，
/// 那时才真正比对/写盘。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database raw;
  late BookRepository repo;

  Future<ByteData> bytesOf(String path) async =>
      ByteData.view((await File(path).readAsBytes()).buffer);

  // 测试环境不带任何字体：不加载中文字体，界面上的中文会渲染成空白方块；
  // 不加载 MaterialIcons，底部导航与所有图标同样变方块。
  //
  // ⚠️ 两个字体必须落在**不同 family**：Skia 在同一个 family 内只锁定
  // 首个字面，逐字符回退只发生在不同 family 之间。所以这里造两个 family——
  // `TestLatin` 给拉丁字形、`TestCJK` 只装汉字——再由 theme() 的
  // `fontFamily` + `fontFamilyFallback` 把回退关系说清楚。
  // 都塞进 'Roboto' 一个 family 也行得通（本文件历史上就是这么干的），
  // 但只要有任何 widget 自带不带 fontFamily 的裸 TextStyle，字族就会丢，
  // 于是那条路径上的汉字变豆腐块（DropdownButton 就踩过这个坑）。
  setUpAll(() async {
    // 两个 family 用的是**同一份** SimHei 字体文件：它在测试环境里同时
    // 提供拉丁与汉字字形，注册两遍只是为了让 fontFamily /
    // fontFamilyFallback 指向两个不同的族名，回退链条才能成立。
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

    // 灌入随包发布的示例书库（38 本合成数据），
    // 截图里看到的就是用户首次打开 App 时会看到的形态。
    final payload = jsonDecode(
            await File('assets/seed/library.json').readAsString())
        as Map<String, dynamic>;

    final books = (payload['books'] as List)
        .whereType<Map>()
        .map((e) => Book.fromMap(Map<String, dynamic>.from(e))
            .withNormalizedCategory())
        .toList();
    await repo.insertMany(books);

    if (payload['stats'] is Map) {
      await repo.setSetting('wereadAnnualStats', jsonEncode(payload['stats']));
    }
  });

  tearDown(() async => raw.close());

  ThemeData theme() => ThemeData(
        useMaterial3: true,
        // 首选拉丁字族（测试环境没装 Roboto，缺字形时按 fallback 逐字符回退）
        fontFamily: 'TestLatin',
        fontFamilyFallback: const <String>['TestCJK'],
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B6D11)),
      );

  Widget app() => ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: localizedApp(theme: theme(), home: const HomeShell()),
      );

  Widget page(Widget child) => ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: localizedApp(theme: theme(), home: child),
      );

  /// 数据库查询与页面 Future 都是真实异步，而 testWidgets 跑在 FakeAsync 里；
  /// 不反复把控制权交还真实事件循环，截到的就永远是「加载中」骨架屏。
  Future<void> settleAsync(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// 按 iPhone 14 的逻辑尺寸（390x844 @3x）渲染
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  /// 是否比对/写盘基准图。由 scripts/screenshot.sh 设 GOLDEN=1 打开。
  final compareGoldens = Platform.environment['GOLDEN'] == '1';

  Future<void> shoot(WidgetTester tester, String name) async {
    if (!compareGoldens) return;
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  /// 打开 App 并切到指定 tab（图标定位，避免和页面正文里的同名文字撞车）
  Future<void> openTab(WidgetTester tester, IconData icon) async {
    await tester.pumpWidget(app());
    await settleAsync(tester);
    await tester.tap(find.byIcon(icon));
    await settleAsync(tester);
  }

  /// 阅读档案：第 4 栏。偏好分布 / 性格标签 / 报告全部内联，
  /// 原来那张「阅读画像」入口卡已删除，所以不再需要点进二级页——
  /// 直接切 tab 就是完整内容。
  Future<void> openArchive(WidgetTester tester) async {
    await openTab(tester, Icons.auto_stories_outlined);
  }

  testWidgets('01 书架', (tester) async {
    phone(tester);
    await openTab(tester, Icons.menu_book_outlined);
    await shoot(tester, '01-shelf');
  });

  testWidgets('02 添加图书抽屉', (tester) async {
    phone(tester);
    await openTab(tester, Icons.menu_book_outlined);
    // 导入不再单独占一栏，全部方式收在书架「+」的底部抽屉里。
    //
    // ⚠️ 必须 `pump()` 一帧再 `pumpAndSettle`：路由 push 之后动画控制器
    // 要在下一帧才开始 tick，一次性跳整个时长会让抽屉停在屏幕外。
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await settleAsync(tester);
    await shoot(tester, '02-import');
  });

  testWidgets('03 统计', (tester) async {
    phone(tester);
    await openTab(tester, Icons.insights_outlined);
    await shoot(tester, '03-stats');
  });

  // 报告面板现在挂在第 4 栏「阅读档案」页里（画像在上、报告在下）。
  // 这里直接渲染该页，取景对准报告部分。
  testWidgets('04 报告', (tester) async {
    phone(tester);
    await tester.pumpWidget(page(const AiReportPage()));
    await settleAsync(tester);
    await shoot(tester, '04-report');
  });

  testWidgets('05 设置', (tester) async {
    phone(tester);
    await openTab(tester, Icons.settings_outlined);
    await shoot(tester, '05-settings');
  });

  /// 统计页是高过长屏的长页：首屏只有指标卡，七张图表全在下面。
  /// 只拍首屏等于什么都没验收，所以专门滚到图表区再拍一张。
  ///
  /// 取景落在「分类图例 → 月度读完 → 月度阅读时长」这三张上：
  /// 后两张的横轴不是一个口径（一个是最近 12 个月，一个是年度统计所在
  /// 的自然年），副标题就是用来讲清楚这件事的，所以必须同时入镜。
  ///
  /// **别指望把拖动量加大就能多看到一点**：一次拖 -1500 和一次拖 -1700
  /// 出图完全一样（Scrollable 的拖动阈值会把超出部分吃掉），
  /// 分两次拖又会滚过头。想验证卡片底部那句脚注，去 ui_pages_test 里
  /// 用文本断言——canvas 上的东西取不到，但脚注是真正的 Text widget，
  /// 断言比像素比对可靠得多。
  testWidgets('07 统计图表', (tester) async {
    phone(tester);
    await openTab(tester, Icons.insights_outlined);
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await settleAsync(tester);
    await shoot(tester, '07-stats-charts');
  });

  /// 时间范围筛选：同一个页面换一个区间，指标与图表都要跟着变
  testWidgets('10 统计-按年', (tester) async {
    phone(tester);
    await openTab(tester, Icons.insights_outlined);
    // 选择器已改成单行下拉：区间名是按钮的当前值，不是可点控件。
    // 先点开按钮，再点菜单项。
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year} 年').last);
    await settleAsync(tester);
    await shoot(tester, '10-stats-year');
  });

  /// 阅读档案：性格标签 + 偏好气泡图。
  testWidgets('09 阅读档案', (tester) async {
    phone(tester);
    await openArchive(tester);
    await shoot(tester, '09-profile');
  });

  /// 档案页的下半段：偏好分布图与图例。
  testWidgets('11 偏好分布', (tester) async {
    phone(tester);
    await openArchive(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await settleAsync(tester);
    await shoot(tester, '11-profile-bubbles');
  });

  /// 书架列表视图：网格看封面，列表看分类/平台/状态徽章与进度条。
  testWidgets('08 书架列表', (tester) async {
    phone(tester);
    await openTab(tester, Icons.menu_book_outlined);
    await tester.tap(find.byTooltip('切换为列表'));
    await settleAsync(tester);
    await shoot(tester, '08-shelf-list');
  });

  testWidgets('06 书籍详情', (tester) async {
    phone(tester);
    final all = await repo.all();
    final target = all.firstWhere((b) => (b.description ?? '').isNotEmpty,
        orElse: () => all.first);

    await tester.pumpWidget(page(BookDetailPage(bookId: target.id)));
    await settleAsync(tester);
    await shoot(tester, '06-detail');
  });

  /// 详情页下半部分的笔记区。首屏只有元数据，笔记在「读后感」下面，
  /// 不滚下去等于没验收——这是本轮新加的功能，必须有图。
  testWidgets('12 书籍笔记', (tester) async {
    phone(tester);
    final all = await repo.all();
    final target = all.first;
    await repo.addNote(Note(
      id: 'shot_n1',
      bookId: target.id,
      type: NoteType.thought,
      content: '把「中央—地方」这条线理顺之后，很多政策新闻就不再是孤立事件了。',
      chapter: '第 3 章',
      createdAt: DateTime.now().toIso8601String(),
    ));

    await tester.pumpWidget(page(BookDetailPage(bookId: target.id)));
    await settleAsync(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await settleAsync(tester);
    await shoot(tester, '12-detail-notes');
  });

  /// 手动添加图书：本轮新增的入口，六字段表单 + 固定底栏提交。
  testWidgets('13 手动添加图书', (tester) async {
    phone(tester);
    await tester.pumpWidget(page(const BookFormPage()));
    await settleAsync(tester);
    await shoot(tester, '13-add-book');
  });

  /// 数据导出页：跨平台迁移的唯一保障，值得单独留一张。
  testWidgets('14 数据导出', (tester) async {
    phone(tester);
    await tester.pumpWidget(page(const BackupPage()));
    await settleAsync(tester);
    await shoot(tester, '14-backup');
  });
}
