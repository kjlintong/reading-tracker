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
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/book_detail_page.dart';

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
  setUpAll(() async {
    await (FontLoader('Roboto')..addFont(bytesOf('test/fixtures/simhei.ttf')))
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
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B6D11)),
      );

  Widget app() => ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme(),
          home: const HomeShell(),
        ),
      );

  Widget page(Widget child) => ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme(),
          home: child,
        ),
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

  testWidgets('01 书架', (tester) async {
    phone(tester);
    await openTab(tester, Icons.menu_book_outlined);
    await shoot(tester, '01-shelf');
  });

  testWidgets('02 导入', (tester) async {
    phone(tester);
    await openTab(tester, Icons.file_upload_outlined);
    await shoot(tester, '02-import');
  });

  testWidgets('03 统计', (tester) async {
    phone(tester);
    await openTab(tester, Icons.insights_outlined);
    await shoot(tester, '03-stats');
  });

  testWidgets('04 报告', (tester) async {
    phone(tester);
    await openTab(tester, Icons.auto_awesome_outlined);
    await shoot(tester, '04-report');
  });

  testWidgets('05 设置', (tester) async {
    phone(tester);
    await openTab(tester, Icons.settings_outlined);
    await shoot(tester, '05-settings');
  });

  /// 统计页是高过长屏的长页：首屏只有指标卡，六张图表全在下面。
  /// 只拍首屏等于什么都没验收，所以专门滚到图表区再拍一张。
  testWidgets('07 统计图表', (tester) async {
    phone(tester);
    await openTab(tester, Icons.insights_outlined);
    await tester.drag(find.byType(ListView).first, const Offset(0, -980));
    await settleAsync(tester);
    await shoot(tester, '07-stats-charts');
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
}
