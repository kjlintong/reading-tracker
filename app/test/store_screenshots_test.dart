import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
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
import 'package:reading_tracker/ui/book_detail_page.dart';
import 'package:reading_tracker/ui/notes_page.dart';
import 'package:reading_tracker/ui/insights_page.dart';
import 'package:reading_tracker/ui/theme.dart';

import 'support/localized_app.dart';
import 'package:reading_tracker/models/reading_plan.dart';

/// 商店截图生成器 —— 输出**符合两个平台尺寸硬性要求**的双语截图。
///
/// ## 为什么不复用 `test/goldens/`
///
/// 那 14 张基准图是 1170×2532（iPhone 14 的逻辑尺寸 × 3）。
/// 它的长边是短边的 **2.16 倍**，而 Google Play 明确规定
/// 「长边不得超过短边的 2 倍」——这批图**会被 Play Console 直接拒收**。
/// App Store 那边则是像素级精确匹配，1170×2532 只能塞进 6.1 寸档，
/// 偏偏我们 `TARGETED_DEVICE_FAMILY = "1,2"`，**6.9 寸与 13 寸 iPad 都是必交项**。
///
/// 所以商店素材必须单独出图，也就是这个文件。基准图继续留在原处做视觉回归，
/// 两者用途不同，不要互相替代。
///
/// ## 三种规格（均与真机点值精确对应）
///
/// | 键 | 物理像素 | dpr | 逻辑点 | 对应设备 |
/// |---|---|---|---|---|
/// | `play`     | 1080×1920 | 3 | 360×640 | 标准 Android 手机（16:9） |
/// | `iphone69` | 1320×2868 | 3 | 440×956 | iPhone 16 Pro Max（App Store 6.9 寸主档） |
/// | `ipad13`   | 2064×2752 | 2 | 1032×1376 | iPad Pro 13 寸（App Store iPad 必交档） |
///
/// ⚠️ 这三套**不是**互为备份，而是两边规则互斥的必然结果：
/// App Store 的 6.9 寸档按 Apple 要求必须是 1320×2868，比例 **2.17:1**，
/// 而 Google Play 明文规定长边不得超过短边的 **2 倍**。
/// 于是 `iphone69` 永远不能交给 Play，`play` 那套也不是 Apple 承认的尺寸。
/// 自检（`scripts/store-screenshots.sh`）按档位分别判定，别把规则写混。
///
/// ## 用法
///
/// ```bash
/// bash scripts/store-screenshots.sh      # 内部设 STORE_SHOTS=1
/// 产物：store/screenshots/<规格>/<语言>/NN-名称.png
/// ```
///
/// **默认（`flutter test`）完全跳过渲染**：36 张图逐张跑 settleAsync 会拖慢
/// 每一次日常测试。没有 `STORE_SHOTS=1` 时这些用例直接返回，不做任何事。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  /// 没有这个开关就什么都不做，保证 `flutter test` 的日常耗时不受影响。
  final enabled = Platform.environment['STORE_SHOTS'] == '1';



  /// 出图用哪套皮肤。默认第一套（绿意）。
  ///
  /// 商店素材不该只出一种界面——换肤是这产品的卖点之一，
  /// 不同页面/语言轮换几套皮肤，商店页和官网才能把「12 套皮肤」说出来。
  /// 传入不存在的 id **必须直接报错、不能静默回退到默认**：
  /// 静默回退会让人以为换了皮肤、实际图还是旧的。
  final skinId = Platform.environment['STORE_SKIN'] ?? appThemes.first.id;
  final skin = appThemes.firstWhere(
    (t) => t.id == skinId,
    orElse: () => throw StateError('STORE_SKIN=$skinId 不存在。可用：'
        '${appThemes.map((t) => t.id).join(", ")}'),
  );

  /// 输出根目录。带皮肤后缀时写到 `screenshots-<后缀>`，
  /// 免得换个皮肤就把上一套图覆盖掉（官网/上架素材还要用旧的）。
  final skinSuffix = Platform.environment['STORE_SKIN_SUFFIX'];

  /// 贴图字节。贴图皮肤下必须真实加载，不能走 Image.asset：
  /// 测试环境的 rootBundle 里 AssetManifest 只有条目名、没有像素，
  /// 解码失败后 errorBuilder 静默返回空 —— 出图是一张纯色纸，
  /// 看起来像「背景没生效」，实际是图根本没加载。
  // ── 逐页皮肤 / 明暗覆盖 ──────────────────────────────────────────
  //
  // 商店素材一共就这 8 张，不该为了多展示几套皮肤而多出图片。所以让
  // 「哪一页用哪套皮肤、哪个明暗」可配：
  //
  //   STORE_SKIN_MAP='01-shelf=bgStarfield:dark,02-stats=bgCat:dark'
  //
  // 一轮出图就能同时出现深色星河、深色猫屿、浅色纯色……皮肤展示得多，
  // 但**图片数量不变**，商店页与官网版式都不用改。
  //
  // 格式：`<slug>=<skinId>[:light|dark]`，多组逗号分隔。
  // 皮肤 id 不认识直接报错——静默回退会让人以为换了皮肤、实际图还是旧的。
  final skinOverrides = <String, ({String id, Brightness mode})>{};
  for (final entry
      in(Platform.environment['STORE_SKIN_MAP'] ?? '').split(',')
          .where((e) => e.trim().isNotEmpty)) {
    final parts = entry.split('=');
    if (parts.length != 2) {
      throw StateError('STORE_SKIN_MAP 条目应为 slug=skin[:mode]，收到：$entry');
    }
    final spec = parts[1].split(':');
    final id = spec.first;
    final mode = spec.length > 1 ? spec[1] : 'light';
    if (mode != 'light' && mode != 'dark') {
      throw StateError('STORE_SKIN_MAP 的明暗只能是 light/dark，收到：$mode');
    }
    if (!appThemes.any((t) => t.id == id)) {
      throw StateError('STORE_SKIN_MAP 里的皮肤 $id 不存在。可用：'
          '${appThemes.map((t) => t.id).join(', ')}');
    }
    skinOverrides[parts[0].trim()] =
        (id: id, mode: mode == 'dark' ? Brightness.dark : Brightness.light);
  }

  /// 当前这一页的皮肤与明暗。renderAll 每轮按 slug 改写，
  /// theme() / root() 都是闭包，直接读这两个变量。
  var pageSkin = skin;
  var pageBrightness = Brightness.light;

  /// 贴图字节缓存。同一张图会被多页复用（不同明暗），不必每次重读磁盘。
  final bgCache = <String, Uint8List>{};
  Uint8List bytesOf(AppTheme t) => bgCache.putIfAbsent(
      t.backgroundAsset!, () => File(t.backgroundAsset!).readAsBytesSync());
  final outRoot = (skinSuffix == null || skinSuffix.isEmpty)
      ? '../store/screenshots'
      : '../store/screenshots-$skinSuffix';

  late Database raw;
  late BookRepository repo;

  setUpAll(() async {
    if (!enabled) return;
    await _loadFonts();
  });

  setUp(() async {
    if (!enabled) return;
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  /// 按语言灌示例书库。
  ///
  /// ## 为什么必须分语言两套种子
  ///
  /// 之前无论哪种语言都灌 `library.json`，那份库的书名全是中文
  /// （三体、活着、史记……）。于是**英文截图里界面是英文、书名是中文**，
  /// 看起来就像 bug——实际上是真的 bug，只是出在素材而不是代码。
  ///
  /// 两份库的 id、状态、进度、评分与时间轴**一一对应**（同一批骨架换内容），
  /// 因此中英两版截图的图表形状完全一致，可以直接对比。
  ///
  /// 分类字段仍写中文规范值（'文学' / '历史'…）：`categoryLabel()` 在渲染时
  /// 按当前语言翻译成 Literature / History。种子库若直接写英文，
  /// 反而因为不在规范词表里而漏翻。
  Future<void> seedLibrary(String code) async {
    final file = code == 'en' ? 'assets/seed/library.en.json' : 'assets/seed/library.json';
    final payload =
        jsonDecode(await File(file).readAsString()) as Map<String, dynamic>;

    final books = (payload['books'] as List)
        .whereType<Map>()
        .map((e) => Book.fromMap(Map<String, dynamic>.from(e))
            .withNormalizedCategory())
        .toList();
    // ⚠️ skipDuplicates 必须为 false。
    //
    // insertMany 默认 skipDuplicates: true，遇到已存在的 id 直接跳过。
    // 中英两套种子库的 id 是**故意一一对应**的（同一批骨架换书名），
    // 于是第一轮灌进去的中文书会把第二轮的英文书全部挡掉——英文截图里
    // 就还是中文书。false 走 ConflictAlgorithm.replace，同 id 整行覆盖，
    // 两种语言各渲染各的，同时也就顺带实现了「每轮换语言就重灌」。
    await repo.insertMany(books, skipDuplicates: false);

    if (payload['stats'] is Map) {
      await repo.setSetting('wereadAnnualStats', jsonEncode(payload['stats']));
    }
  }

  tearDown(() async {
    if (!enabled) return;
    await raw.close();
  });

  /// 商店截图必须用**App 真实主题**，不能另起一套配色。
  ///
  /// 之前这里写的是 `ColorScheme.fromSeed(0xFF3B6D11)` —— 种子色相同，
  /// 但那只是一个裸 ThemeData：没有 surface 分层、没有排版层级、
  /// 卡片/导航栏/输入框/按钮/弹层全是 M3 默认值。于是商店图和官网图
  /// 呈现的是**用户根本看不到的界面**，主题改版后尤其明显。
  ///
  /// 现在直接走 [buildTheme]，即 `lib/ui/theme.dart` 里那一个函数——
  /// 截图与真机共用同一份主题定义，主题改了这批图自动跟着变。
  ///
  /// 字体仍然是测试环境专用的：fontFamily 是「首选」，fontFamilyFallback
  /// 是「首选缺字形时按序回退」，两者必须分属**不同 family**（见 _loadFonts）。
  ThemeData theme() {
    final base = buildTheme(pageSkin, pageBrightness);
    // ⚠️ `ThemeData.copyWith` **不接受** fontFamily / fontFamilyFallback
    // （这两个只有 ThemeData 构造器有），而 buildTheme 里已经把
    // `fontFamily: 'Roboto'` 烘进了 textTheme。所以这里必须用
    // `textTheme.apply(fontFamily:)` 逐个 TextStyle 换字体族，
    // 并显式带上 fallback —— 缺了 fallback，中文会整片变豆腐块。
    // ⚠️ AppBar 标题必须单独处理，它不走 textTheme。
    //
    // buildTheme 里 AppBarTheme.titleTextStyle 是从 textTheme.titleLarge
    // copyWith 出来的**已经烘死 `fontFamily: 'Roboto'`** 的 TextStyle。
    // 上面 apply() 只换 textTheme / primaryTextTheme 两棵树，换不到它——
    // 于是中文截图里标题「书架」整行变成豆腐块 ▯▯，而正文、按钮、
    // 列表全都有中文（它们走的是 textTheme）。只补 textTheme 是治标。
    //
    // TextStyle.copyWith 支持 fontFamily / fontFamilyFallback
    // （不支持的是 ThemeData.copyWith），所以这里逐个补一遍。
    //
    // 字段名按 Flutter 3.24 的实际签名来，别照抄新版文档：
    //   - CardTheme 没有 titleTextStyle（3.27 才加）
    //   - NavigationRailThemeData 没有 labelTextStyle
    //   - navigationBarTheme.labelTextStyle 是
    //     MaterialStateProperty<TextStyle?>，要经 fbState 包一层
    //   - chipTheme.labelStyle / tabBarTheme.labelStyle 都是纯 TextStyle?，
    //     直接用 fb（照抄新文档会把这两个搞反）
    TextStyle? fb(TextStyle? style) => style?.copyWith(
          fontFamily: _latinFamily,
          fontFamilyFallback: const <String>[_cjkFamily],
        );

    // MaterialStateProperty 版要包一层：解包 → 改 → 包回。
    MaterialStateProperty<TextStyle?>? fbState(
            MaterialStateProperty<TextStyle?>? prop) =>
        prop == null
            ? null
            : MaterialStateProperty.resolveWith<TextStyle?>(
                (states) => fb(prop.resolve(states)));

    TextTheme apply(TextTheme t) => t.apply(
          fontFamily: _latinFamily,
          fontFamilyFallback: const <String>[_cjkFamily],
        );

    return base.copyWith(
      textTheme: apply(base.textTheme),
      primaryTextTheme: apply(base.primaryTextTheme),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: fb(base.appBarTheme.titleTextStyle),
        toolbarTextStyle: fb(base.appBarTheme.toolbarTextStyle),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: fb(base.listTileTheme.titleTextStyle),
        subtitleTextStyle: fb(base.listTileTheme.subtitleTextStyle),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        labelStyle: fb(base.inputDecorationTheme.labelStyle),
        helperStyle: fb(base.inputDecorationTheme.helperStyle),
        hintStyle: fb(base.inputDecorationTheme.hintStyle),
        errorStyle: fb(base.inputDecorationTheme.errorStyle),
        prefixStyle: fb(base.inputDecorationTheme.prefixStyle),
        suffixStyle: fb(base.inputDecorationTheme.suffixStyle),
      ),
      chipTheme:
          base.chipTheme.copyWith(labelStyle: fb(base.chipTheme.labelStyle)),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        labelTextStyle: fbState(base.navigationBarTheme.labelTextStyle),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: fb(base.dialogTheme.titleTextStyle),
        contentTextStyle: fb(base.dialogTheme.contentTextStyle),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        contentTextStyle: fb(base.snackBarTheme.contentTextStyle),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelStyle: fb(base.tabBarTheme.labelStyle),
        unselectedLabelStyle: fb(base.tabBarTheme.unselectedLabelStyle),
      ),
    );
  }

  // ── 渲染外壳 ────────────────────────────────────────────────────────
  //
  // 最外层套一个带 key 的 RepaintBoundary，就能拿到「整屏」的渲染对象，
  // 再用 toImage(pixelRatio: dpr) 精确导出目标物理像素。
  // 用 golden 机制做不到这点：它只能写相对测试文件的固定路径，
  // 而这里要按 设备×语言 分目录。
  final shotKey = const ValueKey<String>('store-shot');

  /// 当前正在渲染的「规格 × 语言」组合。
  ///
  /// ⚠️ 必须拿它给 MaterialApp 加 key，见 [root] 的说明。
  int shotRound = 0;

  /// 组装一屏。
  ///
  /// ⚠️ `MaterialApp` 上的 key **不是可选的**。
  ///
  /// 大循环 6 轮共用一个 WidgetTester，每次 `pumpWidget` 送进去的都是
  /// 「RepaintBoundary → ProviderScope → MaterialApp → …」这套结构相同的
  /// widget。Element 逐层按「类型 + key」复用，于是 **MaterialApp 的
  /// Navigator 及其路由栈会跨轮存活**——上一轮 push 出去的正文页
  /// 会跟着带进下一轮，历史列表根本不在树上，finder 全打空。
  ///
  /// 给 MaterialApp 挂一个每轮不同的 key，强制整棵 App 子树重建，
  /// 路由栈自然清零。比在 draw 里手动 pop 可靠：pop 依赖「当前栈里恰好
  /// 有可弹的页」，而这里是从根上杜绝残留。
  Widget root(Locale locale, Widget home, {int round = 0}) => RepaintBoundary(
        key: shotKey,
        child: ProviderScope(
          overrides: [repoProvider.overrideWithValue(repo)],
          child: localizedApp(
            key: ValueKey<int>(round),
            theme: theme(),
            locale: locale,
            // 贴图皮肤必须把背景传进去：测试外壳的 AppBackground
            // 与生产同构（见 localized_app.dart 的注释）。
            // 漏了它就会出「贴图皮肤但不画贴图」的半透明 PNG——
            // 上传到官网就是一片透明，露出网页自己的底色。
            backgroundTheme: pageSkin.hasBackground ? pageSkin : null,
            // imageProvider 注入 MemoryImage：测试环境的rootBundle
            // 只有 AssetManifest 条目、没有图片字节，Image.asset 会解不出图。
            backgroundImage: pageSkin.hasBackground
                ? MemoryImage(bytesOf(pageSkin))
                : null,
            home: home,
          ),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    // 库里查询与页面 Future 都是真实异步，而 testWidgets 跑在 FakeAsync 里。
    // 不反复把控制权交还真实事件循环，截到的永远是「加载中」骨架屏。
    for (var i = 0; i < 25; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openTab(WidgetTester tester, Locale locale, IconData icon) async {
    await tester.pumpWidget(root(locale, const HomeShell(), round: shotRound));
    await settle(tester);
    await tester.tap(find.byIcon(icon));
    await settle(tester);
  }

  Future<void> capture(
      WidgetTester tester, _Device dev, String code, String name) async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(shotKey));
    final file = File('$outRoot/${dev.id}/$code/$name.png');

    // **渲染、编码、落盘必须整个塞进 runAsync**。
    //
    // testWidgets 的用例体跑在 FakeAsync 里，真实的文件系统 I/O（create /
    // writeAsBytes 都是真 syscall）在这个 zone 里永远不会完成——
    // 表现就是进程 CPU 0%、9 分钟一张图都没写出来，也不报错。
    // 这不是「慢」，是死锁。踩过一次，别再往里放裸 await File(...)。
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: dev.dpr);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) {
        throw StateError('导出 PNG 失败：${dev.id}/$code/$name');
      }
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    });
  }

  /// 同一页在 3 种规格 × 2 种语言下各出一张。
  Future<void> renderAll(
    WidgetTester tester,
    String name,
    Future<void> Function(WidgetTester, Locale) draw,
  ) async {
    if (!enabled) return;

    // 本页用哪套皮肤/明暗。没配就用 STORE_SIN 给的默认值。
    final ov = skinOverrides[name];
    pageSkin = ov == null ? skin : appThemes.firstWhere((t) => t.id == ov.id);
    pageBrightness = ov?.mode ?? Brightness.light;

    for (final dev in _devices) {
      for (final code in const ['zh', 'en']) {
        final locale = Locale(code);
        tester.view.physicalSize = dev.physical;
        tester.view.devicePixelRatio = dev.dpr;
        addTearDown(tester.view.reset);

        // 每轮换一个 key，逼 MaterialApp（连同它的 Navigator 与路由栈）
        // 整棵重建。否则上一轮 push 出去的正文页会跨轮残留，
        // 下一轮一开始就停在那一页上，历史列表压根不在树上。
        // 详见 [root] 的说明。
        shotRound++;
        // 每轮换语言就得换书库：同一轮要重灌，否则上一轮的语言内容会留下来
        // （英文轮里冒出中文书名，正是这个 bug 的另一面）。
        await tester.runAsync(() => seedLibrary(code));
        await draw(tester, locale);

        // 交给 flutter_test 的异常不会说明是哪一个「规格 / 语言」出的问题，
        // 而 36 张图里定位一张的成本很高（每次都要重跑 50 秒）。
        // 这里主动取出来，把设备与语言一起打进失败信息——仍然 fail，
        // 只是把「哪一张」这个信息补上，不会吞掉异常。
        final err = tester.takeException();
        if (err != null) {
          fail('$name @ ${dev.id}/$code（${dev.label}）渲染异常：\n$err');
        }

        await capture(tester, dev, code, name);
      }
    }
  }

  // ── 七个页面 ────────────────────────────────────────────────────────
  // 选页原则：覆盖「导入 → 书架 → 统计 → 画像 → 详情笔记 → AI 报告 → 笔记」
  // 这条主线，也就是商店文案里承诺的功能在界面上都能对上。少而精，不做重复角度。

  testWidgets('01 书架', (tester) async {
    await renderAll(tester, '01-shelf',
        (t, l) => openTab(t, l, Icons.menu_book_outlined));
  });

  testWidgets('02 统计', (tester) async {
    await renderAll(
        tester, '02-stats', (t, l) => openTab(t, l, Icons.insights_outlined));
  });

  testWidgets('03 阅读档案', (tester) async {
    await renderAll(tester, '03-profile', (t, l) async {
      // 这张展示画像结论（偏好分布 + 性格标签），是「阅读档案」栏的核心。
      // 原先拍的是 ProfilePage，那一页已随功能内联而删除，改拍档案栏本身。
      await t.pumpWidget(root(l, const InsightsPage(), round: shotRound));
      await settle(t);
    });
  });

  testWidgets('04 书籍详情与笔记', (tester) async {
    await renderAll(tester, '04-detail', (t, l) async {
      // 数据库调用同样是真实异步，不能在 FakeAsync 里裸 await——
      // 返回的 Future 要等真实事件循环，而 FakeAsync 不会放它过去。
      // 整段塞进 runAsync，拿到 id 再回到外面 pumpWidget。
      final targetId = await t.runAsync(() async {
        final all = await repo.all();
        final target = all.firstWhere((b) => (b.description ?? '').isNotEmpty,
            orElse: () => all.first);

        // 笔记正文是「用户自己写的东西」，属于数据而不是界面文案——
        // 它不会跟着 locale 切换。既然要出双语截图，就得按语言各写一条。
        // 固定同一个 id，配合 addNote 的 ConflictAlgorithm.replace，
        // 每渲染一次覆盖一次，不会在六轮渲染里堆出六条笔记。
        final zh = l.languageCode == 'zh';
        await repo.addNote(Note(
          id: 'store_note',
          bookId: target.id,
          type: NoteType.thought,
          content: zh
              ? '把「中央—地方」这条线理顺之后，很多政策新闻就不再是孤立事件了。'
              : 'Once the central-versus-local thread clicked, most policy stories '
                  'stopped looking like isolated events.',
          chapter: zh ? '第 3 章' : 'Chapter 3',
          createdAt: DateTime.now().toIso8601String(),
        ));
        return target.id;
      });

      await t.pumpWidget(root(l, BookDetailPage(bookId: targetId!), round: shotRound));
      await settle(t);
    });
  });

  testWidgets('06 阅读计划与笔记', (tester) async {
    await renderAll(tester, '06-plan', (t, l) async {
      final zh = l.languageCode == 'zh';
      final books = await repo.all();
      final now = DateTime.now();
      String ymd(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

      // 种两条**类型不同**的计划（每日时长 / 读完某本），让这一页展示得出
      // 两种卡片的差别 —— 只种一条就等于没展示这个功能。
      await repo.upsertPlan(ReadingPlan(
        id: 'store_plan_daily',
        kind: PlanKind.dailyMinutes,
        title: zh ? '每天读 30 分钟' : '30 minutes a day',
        dailyMinutes: 30,
        createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
        checkins: '${ymd(now.subtract(const Duration(days: 2)))},'
            '${ymd(now.subtract(const Duration(days: 1)))}',
      ));

      if (books.isNotEmpty) {
        await repo.upsertPlan(ReadingPlan(
          id: 'store_plan_book',
          kind: PlanKind.finishBook,
          title: zh ? '读完《置身事内》' : 'Finish 《置身事内》',
          bookId: books.first.id,
          dueDate: ymd(now.add(const Duration(days: 5))),
          createdAt: now.subtract(const Duration(days: 6)).toIso8601String(),
        ));

        await repo.addNote(Note(
          id: 'store_plan_note',
          bookId: books.first.id,
          type: NoteType.thought,
          content: zh
              ? '读到第三章，把「中央—地方」这条线理顺之后，'
                  '很多政策新闻就不再是孤立事件了。'
              : 'Chapter three ties it together: once the central-versus-local '
                  'thread clicks, most policy stories stop looking isolated.',
          chapter: zh ? '第 3 章' : 'Chapter 3',
          createdAt: now.toIso8601String(),
        ));
      }

      await t.pumpWidget(root(l, const NotesPage(), round: shotRound));
      await settle(t);
    });
  });

  testWidgets('05 AI 阅读报告', (tester) async {
    await renderAll(tester, '05-report', (t, l) async {
      // 商店截图要展示的是「报告本身长什么样」，而不是配置面板。
      // 种一份与语言对应的样例报告，再从历史里点开——这也是用户
      // 真实的使用路径（生成 → 历史回看），顺手当一次交互冒烟测试。
      final zh = l.languageCode == 'zh';
      await repo.saveReport(
        period: '2026-09',
        model: 'demo',
        content: zh ? _demoReportZh : _demoReportEn,
      );
      // ⚠️ 不能写 const AiReportPage()：同一用例内 zh → en 重 pump 时，
      // const 实例是同一个对象，Element 认为 widget 没变，State（含上一轮
      // 中文加载的 _history 与 _report）原样带进英文渲染，英文截图里
      // 点开的就还是中文报告。按 locale 加 key 强制每轮重建 State。
      await t.pumpWidget(root(l, AiReportPage(key: ValueKey<Locale>(l)), round: shotRound));
      await settle(t);

      // 历史瓦片在折叠线以下，且本版在配置区新增了「报告风格」一整行
      // （5 个 ChoiceChip + 说明 + 可自定义输入框），历史又被推低了一截，
      // 原来的固定拖动量已经不够。
      //
      // ⚠️ 不能直接 `scrollUntilVisible(find.byIcon(...))`：历史列表在
      // SingleChildScrollView（非 lazy）里，但**首屏没构建到时该 finder
      // 匹配数为 0**，而 `scrollUntilVisible` 内部对 0 匹配会抛
      // `Bad state: No element`——它只在「已存在但不在视口」时才有用。
      // 所以先固定往下拖一段把它带进构建范围，不够再补一段。
      //
      // ⚠️ 不能 find.byType(ListTile).first —— SwitchListTile /
      // CheckboxListTile 内部也构建 ListTile，且排在历史瓦片前面，
      // .first 点到的是自动生成开关，什么都不会发生。
      // 历史瓦片的 leading 图标（description）定位它；但同一个用例里
      // 6 轮渲染共用一个内存库，历史会累积出多条 9 月报告，
      // 所以必须 .first（reports() 按 generatedAt DESC 排，第一条
      // 恰好是本轮刚种下的当前语言那份）。
      // ⚠️ 正文页现在是**压栈**出来的新路由。同一个用例要连出 6 张图，
      // 大循环每轮都重 pump 同一个 MaterialApp，Navigator 的路由栈会
      // 跨轮残留——第二轮一开始就停在上一轮那个正文页上，
      // 于是「历史列表」根本不在树上，图标数 0、tap 找不到元素。
      // 所以每轮结束必须 pop 回列表，让下一轮从干净状态开始。
      final descIcon = find.byIcon(Icons.description_outlined);
      await t.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await settle(t);
      if (descIcon.evaluate().isEmpty) {
        await t.drag(find.byType(SingleChildScrollView), const Offset(0, -400));
        await settle(t);
      }
      await t.tap(descIcon.first);
      await settle(t);

      // 报告正文已经改到**独立正文页**（点历史即入栈一层新路由），
      // 不再是在配置面板下方展开。所以这里不再需要往下拖——
      // 正文页是从顶部渲染的，一进来就是正文开头，那才是要展示的画面。
    });
  });

  /// 添加图书：书架「+」升起的底部抽屉。
  ///
  /// 原来这一张拍的是独立的「导入」页，本版把导入整页收进了抽屉，
  /// 所以取景改成「书架 + 升起的抽屉」——正好也能让用户看到入口在哪。
  ///
  /// ⚠️ 必须 `pump()` 一帧再 `pumpAndSettle`：路由 push 之后动画控制器
  /// 要在下一帧才开始 tick，一次性跳整个时长会让抽屉停在屏幕外。
  testWidgets('06 导入', (tester) async {
    await renderAll(tester, '06-import', (t, l) async {
      await t.pumpWidget(root(l, const HomeShell(), round: shotRound));
      await settle(t);
      await t.tap(find.byIcon(Icons.menu_book_outlined));
      await settle(t);
      await t.tap(find.byIcon(Icons.add));
      await t.pump();
      await t.pumpAndSettle(const Duration(milliseconds: 50));
      await settle(t);
    });
  });

  testWidgets('07 笔记', (tester) async {
    await renderAll(tester, '07-notes', (t, l) async {
      // 商店截图不能是空态：种三条不同类型的笔记（划线 / 想法 / 书评），
      // 让「按时间」视图一屏就能看清这个栏目是干什么的。
      final zh = l.languageCode == 'zh';
      final books = await repo.all();
      String pick(int i) => books[i % books.length].id;
      await repo.addNote(Note(
        id: 'store_notes_1',
        bookId: pick(0),
        type: NoteType.highlight,
        content: zh
            ? '把「中央—地方」这条线理顺之后，很多政策新闻就不再是孤立事件了。'
            : 'Once the central-local thread clicked, most policy stories '
                'stopped looking like isolated events.',
        chapter: zh ? '第 3 章' : 'Chapter 3',
        createdAt: '2026-09-30T21:30:00',
      ));
      await repo.addNote(Note(
        id: 'store_notes_2',
        bookId: pick(1),
        type: NoteType.thought,
        content: zh
            ? '作者说地方债务是「财政幻觉」——想想身边的现象，确实如此。'
            : "The author calls local debt a 'fiscal illusion' - I can see "
                'it everywhere now.',
        chapter: zh ? '第 5 章' : 'Chapter 5',
        createdAt: '2026-09-21T08:12:00',
      ));
      await repo.addNote(Note(
        id: 'store_notes_3',
        bookId: pick(2),
        type: NoteType.review,
        content: zh
            ? '一个月读完。前三章值得重读，后面的案例翻得快。'
            : 'Finished in a month. The first three chapters deserve a reread.',
        createdAt: '2026-09-08T22:47:00',
      ));

      await t.pumpWidget(root(l, const NotesPage(), round: shotRound));
      await settle(t);
    });
  });
}

/// 目标规格。物理像素与 dpr 一起决定逻辑点值，三个都对应真实机型。
class _Device {
  const _Device(this.id, this.width, this.height, this.dpr, this.label);

  final String id;
  final double width;
  final double height;
  final double dpr;
  final String label;

  Size get physical => Size(width, height);

  /// 逻辑点值，用于在日志里核对是否与真机一致。
  String get logical =>
      '${(width / dpr).round()}×${(height / dpr).round()}';
}

const List<_Device> _devices = [
  _Device('play', 1080, 1920, 3.0, 'Google Play 手机（16:9）'),
  _Device('iphone69', 1320, 2868, 3.0, 'App Store iPhone 6.9 寸'),
  _Device('ipad13', 2064, 2752, 2.0, 'App Store iPad 13 寸'),
];

/// 拉丁字形用的 family 名（真 Roboto）。
const String _latinFamily = 'Roboto';

/// 中日韩字形用的 family 名（SimHei）。
///
/// **必须是独立 family**。两个字体塞进同一个 family 时 Skia 只认首个字面，
/// 中文会整片变豆腐块——这不是「回退没生效」，而是「压根没配置回退」。
const String _cjkFamily = 'SimHei';

/// 测试环境不自带任何字体：不加载中文字体，界面上的中文会渲染成空白方块；
/// 不加载 MaterialIcons，底部导航与所有图标同样变方块。
///
/// ## 为什么中英要拆成两个 family
///
/// `goldens` 那批（`screenshot_test.dart`）只把 simhei 挂到 `Roboto` 名下，
/// 靠 SimHei 自带的拉丁字形凑合。省事，但英文界面会带着黑体那种偏宽、
/// 偏等距的拉丁字形——37 张英文截图要拿去给国际市场看，这一项不能凑合。
///
/// 于是想「同一 family 先塞 Roboto 再塞 simhei」，结果**整批中文变豆腐块**：
/// Skia 在同一个 family 内**只锁定首个字面**，不做逐字符回退；
/// 逐字符回退只发生在**不同 family 之间**（即 `fontFamilyFallback`）。
/// 把两个字体 `addFont` 到同一个 family，并不等于配置了字体回退。
///
/// 正确做法就是现在这样：两个字体、两个 family，
/// 再由 `theme()` 里的 `fontFamily: 'Roboto'` +
/// `fontFamilyFallback: ['SimHei']` 把回退关系说清楚。
Future<void> _loadFonts() async {
  // FontLoader.addFont 收的是 Future<ByteData> 而不是 ByteData，
  // 直接传 ByteData.sublistView(...) 会编译失败。
  Future<ByteData> bytesOf(String path) async =>
      ByteData.view((await File(path).readAsBytes()).buffer);

  // 拉丁字形：真 Roboto，从 Flutter SDK 缓存取。
  // 取不到就跳过——此时拉丁字形由 SimHei 顶替，产物依然可用，不会失败。
  final root = Platform.environment['FLUTTER_ROOT'];
  final roboto = root == null
      ? null
      : File('$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
  if (roboto != null && roboto.existsSync()) {
    await (FontLoader(_latinFamily)..addFont(bytesOf(roboto.path))).load();
  }

  // 中日韩字形：独立 family，靠 fontFamilyFallback 生效。
  await (FontLoader(_cjkFamily)..addFont(bytesOf('test/fixtures/simhei.ttf')))
      .load();

  await (FontLoader('MaterialIcons')
        ..addFont(bytesOf('test/fixtures/MaterialIcons-Regular.otf')))
      .load();
}

/* ---------------------- 05 报告页的样例内容 ---------------------- */

/// 商店截图里的报告正文。与语言各一份；刻意覆盖渲染器支持的全部版式
/// （二级标题 / 加粗数字 / 无序列表 / 表格 / 引用 / 有序列表 / 书名高亮），
/// 让一张截图就能回答「报告长什么样」。
const String _demoReportZh = '''
## 概览

本月读完 **4 本**，累计阅读 **18 小时 20 分钟**，日均 **37 分钟**。
比上月多 **22%**，但读完率反而降了一点。

## 结构分析

- 社科占 **50%**，文学占 **25%**，其余散在三四个分类里
- 全部 6 本里有 **5 本**来自同一个平台
- 电子书与纸质书 **5:1**

## 习惯洞察

| 维度 | 本月 | 上月 |
| --- | --- | --- |
| 连续阅读 | 12 天 | 5 天 |
| 弃读率 | 22% | 31% |

> 数据不替你做决定，但它让每一点进步都有迹可循。

## 建议

1. 把《置身事内》的第三章读完，正好接上本月的社科主线
2. 翻翻《焦虑的人》的划线，把最触动的一句补进笔记
3. 下月给大部头配一本更轻的书，睡前读更不容易弃读
''';

const String _demoReportEn = '''
## Overview

**4 books** finished this month, **18h 20m** in total, **37 min** a day.
Up **22%** from last month, though the completion rate slipped a little.

## Structure

- Social science **50%**, literature **25%**, the rest spread thin
- **5 of 6** books came from a single platform
- E-books vs paper: **5:1**

## Habits

| Metric | This month | Last month |
| --- | --- | --- |
| Longest streak | 12 days | 5 days |
| Abandonment | 22% | 31% |

> The data does not decide for you; it just makes every bit of progress visible.

## Suggestions

1. Finish chapter 3 of *Lectures on China's Government* to carry the social-science thread
2. Revisit the highlights in *Anxious People* and add the one line that struck you most to your notes
3. Pair next month's heavy read with a lighter one; easier on late nights, harder to abandon
''';
