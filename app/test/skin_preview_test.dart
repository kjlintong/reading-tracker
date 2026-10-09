import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/ui/book_cover.dart';
import 'package:reading_tracker/ui/palette.dart';
import 'package:reading_tracker/ui/theme.dart';

import 'support/localized_app.dart';

/// 皮肤样张生成器 —— 输出一张 10 套皮肤的总览图 + 每套一张详情图。
///
/// ## 为什么要单独出图，而不是靠肉眼 review 代码
///
/// 这次换肤改了三个互相独立、又必须同时成立的东西：
///  1. **纸色**（`paperTint` 派生六档 surface）——「高级 / 活泼」的分级
///     全在这里，肉眼几乎看不出 0.04 与 0.05 的差别；
///  2. **占位封面**——必须跟着皮肤色相走，不能再冒出粉/蓝/紫方块；
///  3. **图表色板**——12 色两两必须能分辨，且与纸色有亮度差。
///
/// `theme_system_test.dart` 用断言守住了这三条的**数值**，但断言说不出
/// 「这套皮肤好不好看」。好看不好看只能看图，所以这里把每套皮肤的
/// 纸色梯、占位封面、图表色板摊在一张图上直接对比。
///
/// ## 为什么详情图要画真实的 [BookCover]
///
/// 占位封面的取色逻辑在 `book_cover.dart` 里，与本文件无关——但正因为
/// 无关，才必须在**真实组件**上看：如果测试里自己拼一个 ColoredBox，
/// 那看到的颜色跟用户见到的封面不是一回事，等于没测。
///
/// ## 用法
///
/// ```bash
/// SKIN_PREVIEW=1 flutter test test/skin_preview_test.dart
/// 产物：store/skin-preview/00-all-{light,dark}.png + <id>-{light,dark}.png
/// ```
///
/// 默认（`flutter test`）完全跳过渲染。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final enabled = Platform.environment['SKIN_PREVIEW'] == '1';
  const outRoot = '../store/skin-preview';

  setUpAll(() async {
    if (!enabled) return;
    await _loadFonts();
  });

  const shotKey = ValueKey<String>('skin-shot');

  ThemeData themeOf(AppTheme t, Brightness b) {
    final base = buildTheme(t, b);
    TextStyle? fb(TextStyle? s) => s?.copyWith(
          fontFamily: _latinFamily,
          fontFamilyFallback: const <String>[_cjkFamily],
        );
    // ⚠️ 按钮的label 走组件主题自带样式，不是 textTheme。
    // 只补 textTheme / appBarTheme / listTileTheme 时，「主要按钮」四个字
    // 会整排变成豆腐块 ▯▯▯▯。
    //
    // 按钮主题的层级与别的组件不同，**两层都要解**：
    //   FilledButtonThemeData.style 是 **ButtonStyle**（不是 TextStyle），
    //   而ButtonStyle.textStyle 才是 **MaterialStateProperty<TextStyle?>**
    //   （也不是裸 TextStyle）。所以先 copyWith 出新的 ButtonStyle，
    //   再把 textStyle 这一层用 resolveWith 包起来逐状态解包。
    // 直接把 theme.style 丢给处理 TextStyle 的 fb() 会编译不过。
    ButtonStyle fbBtn(ButtonStyle? st) => (st ?? const ButtonStyle()).copyWith(
          textStyle: MaterialStateProperty.resolveWith<TextStyle?>(
              (states) => fb(st?.textStyle?.resolve(states))),
        );

    TextTheme apply(TextTheme tt) => tt.apply(
          fontFamily: _latinFamily,
          fontFamilyFallback: const <String>[_cjkFamily],
        );

    // 与商店截图同一套理由：buildTheme 里 AppBarTheme.titleTextStyle
    // 是已烘死 fontFamily 的 TextStyle，textTheme.apply() 换不到它，
    // 漏补就是中文标题整行豆腐块。
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
      chipTheme:
          base.chipTheme.copyWith(labelStyle: fb(base.chipTheme.labelStyle)),
      // 按钮主题要解两层，见顶部 fbBtn 的注释。
      filledButtonTheme:
          FilledButtonThemeData(style: fbBtn(base.filledButtonTheme.style)),
      outlinedButtonTheme:
          OutlinedButtonThemeData(style: fbBtn(base.outlinedButtonTheme.style)),
      textButtonTheme:
          TextButtonThemeData(style: fbBtn(base.textButtonTheme.style)),
      elevatedButtonTheme:
          ElevatedButtonThemeData(style: fbBtn(base.elevatedButtonTheme.style)),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        linearTrackColor: base.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget root(AppTheme t, Brightness b, Widget home, {int round = 0}) =>
      RepaintBoundary(
        key: shotKey,
        child: localizedApp(
          key: ValueKey<String>('${t.id}-$b-$round'),
          theme: themeOf(t, b),
          locale: const Locale('zh'),
          home: home,
        ),
      );

  /// 必须在 `pumpWidget` **之前**调用。
  ///
  /// 踩过的坑：一开始把`tester.view.physicalSize` 写在 [capture] 里，
  /// 而capture 是在 pumpWidget 之后才调的——那时候布局已经按默认的
  /// 800x600 定完了，改physicalSize 只会改采样密度，不会重新布局。
  /// 于是无论传什么尺寸，产物一律 800x600，总览图被裁掉一半皮肤。
  void prepare(WidgetTester tester, Size size, double dpr) {
    tester.view.physicalSize = size * dpr;
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
  }

  Future<void> capture(
    WidgetTester tester,
    String name, {
    double dpr = 1.0,
  }) async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(shotKey));
    final file = File('$outRoot/$name.png');

    // 真实文件系统 I/O 必须整个塞进 runAsync，否则在 FakeAsync 里死锁
    //（表现是 CPU 0% 且永不返回，也不报错）。踩过一次，别再放裸 await。
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: dpr);
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

  // ── 详情图 ────────────────────────────────────────────────────────

  for (final t in appThemes) {
    for (final b in Brightness.values) {
      final suffix = b == Brightness.light ? 'light' : 'dark';
      testWidgets('皮肤样张 ${t.id}-$suffix', (tester) async {
        if (!enabled) return;
        prepare(tester, const Size(900, 1180), 1.0);
        await tester.pumpWidget(root(t, b, _SkinSheet(t, b)));
        await tester.pumpAndSettle();
        final err = tester.takeException();
        if (err != null) fail('${t.id}-$suffix 渲染异常：\n$err');
        await capture(tester, '${t.id}-$suffix');
      });
    }
  }

  // ── 总览图：浅色 + 深色各一张，一眼比完 10 套 ─────────────────────

  for (final b in Brightness.values) {
    final suffix = b == Brightness.light ? 'light' : 'dark';
    testWidgets('总览 $suffix', (tester) async {
      if (!enabled) return;
      prepare(tester, const Size(1360, 1280), 1.0);
      await tester.pumpWidget(root(appThemes.first, b, _Overview(b)));
      await tester.pumpAndSettle();
      final err = tester.takeException();
      if (err != null) fail('总览 $suffix 渲染异常：\n$err');
      await capture(tester, '00-all-$suffix');
    });
  }
}

/// 一套皮肤的样张。
///
/// 刻意把这四样东西放在同一张图里，因为它们必须**同时**成立才算这套皮肤成立：
/// 纸色梯（底色对不对）、主色与点缀色（点睛色够不够克制）、
/// 真实占位封面（会不会冒出跑飞的色块）、图表色板（12 色能不能分辨）。
class _SkinSheet extends StatelessWidget {
  const _SkinSheet(this.theme, this.brightness);

  final AppTheme theme;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = paletteOf(context);
    final seed = brightness == Brightness.light ? theme.lightSeed : theme.darkSeed;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    theme.label.substring(0, 1),
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      fontFamily: _latinFamily,
                      fontFamilyFallback: const <String>[_cjkFamily],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(theme.label,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                        'paperTint ${theme.paperTint.toStringAsFixed(3)}'
                        ' · ${brightness == Brightness.light ? "浅色" : "深色"}'
                        ' · seed #${hexOf(seed)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _section(context, '纸色梯 surface（低 → 高）'),
            _ramp(scheme),
            const SizedBox(height: 22),
            _section(context, '主色系'),
            _row(<Color>[
              scheme.primary,
              scheme.onPrimary,
              scheme.secondary,
              scheme.tertiary,
              scheme.error,
              scheme.surfaceContainerHighest,
              scheme.outline,
            ]),
            const SizedBox(height: 22),
            _section(context, '占位封面（真实 BookCover 组件）'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final title in const [
                  '三体',
                  'Dune',
                  '百年孤独',
                  '活着',
                  'The Hobbit',
                  '置身事内',
                ])
                  SizedBox(
                    width: 96,
                    height: 138,
                    child: BookCover(
                      book: _book(title),
                      radius: 8,
                      placeholderFontSize: 13,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            _section(context, '图表色板 ${palette.length} 色（两两须可分辨）'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < palette.length; i++)
                  Container(
                    width: 62,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette[i],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$i',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette[i].computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white70,
                        fontFamily: _latinFamily,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _section(context, '真实组件'),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.menu_book_outlined),
                      title: Text('正在阅读'),
                      subtitle: Text('三体 · 刘慈欣 · 进度 62%'),
                    ),
                    LinearProgressIndicator(
                      value: 0.62,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text('文学')),
                        Chip(label: Text('历史')),
                        FilterChip(
                          label: const Text('已读'),
                          selected: brightness == Brightness.light,
                          onSelected: (_) {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton(
                            onPressed: () {}, child: const Text('主要按钮')),
                        const SizedBox(width: 10),
                        OutlinedButton(
                            onPressed: () {}, child: const Text('次要按钮')),
                        const SizedBox(width: 10),
                        TextButton(
                            onPressed: () {}, child: const Text('文字按钮')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 10 套皮肤总览。每套一格：色板条 + 3 张真实占位封面 + 名字。
///
/// 这是给用户「挑皮肤」用的一张图——比逐张翻 10 个文件快得多。
class _Overview extends StatelessWidget {
  const _Overview(this.brightness);

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Readnest 皮肤总览 · ${brightness == Brightness.light ? "浅色" : "深色"}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text('共 ${appThemes.length} 套',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3.1,
              children: [
                for (final t in appThemes) _SkinCell(t, brightness),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 总览里的一格。必须自带 [Theme]，因为它渲染的是**别的**皮肤——
/// 外层 Theme.of(context) 拿到的是网格页自己的皮肤，不是这一格的。
class _SkinCell extends StatelessWidget {
  const _SkinCell(this.theme, this.brightness);

  final AppTheme theme;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final base = buildTheme(theme, brightness);
    final scheme = base.colorScheme;
    final palette = base.extension<ChartPalette>()?.colors ?? chartPalette;

    TextStyle tt(double size, {Color? c, FontWeight? w}) => TextStyle(
          fontSize: size,
          color: c,
          fontWeight: w,
          fontFamily: _latinFamily,
          fontFamilyFallback: const <String>[_cjkFamily],
        );

    return Theme(
      data: base,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: scheme.primary, shape: BoxShape.circle),
                        child: Text(
                          theme.label.substring(0, 1),
                          style: tt(13,
                              c: scheme.onPrimary, w: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(theme.label,
                            style: tt(15, w: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        theme.paperTint.toStringAsFixed(3),
                        style: tt(11, c: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 12 色板压成一条，比排成方阵省地方，也更能看出是否同一色系。
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 14,
                      // stretch 的理由见 _row() 的注释：无 child 的 ColoredBox
                      // 在 Row 里必须靠 stretch 才有高度，否则整条不可见。
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final c in palette)
                            Expanded(child: ColoredBox(color: c)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            for (final title in const ['三体', 'Dune', '百年孤独'])
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SizedBox(
                  width: 40,
                  height: 58,
                  child: BookCover(
                      book: _book(title), radius: 5, placeholderFontSize: 9),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _section(BuildContext context, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );

/// 六档纸色梯。名字直接标出来——「哪一档是卡片、哪一档是背景」
/// 是换肤最容易搞错的地方，写在图上比记在脑子里可靠。
Widget _ramp(ColorScheme s) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            for (final e in _rampEntries(s))
              Expanded(
                child: Container(
                  color: e.color,
                  alignment: Alignment.center,
                  child: Text(
                    e.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: e.color.computeLuminance() > 0.5
                          ? Colors.black54
                          : Colors.white54,
                      fontFamily: _latinFamily,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

Widget _row(List<Color> colors) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 48,
        // ⚠️ crossAxisAlignment: stretch 不能少。
        // 无 child 的 ColoredBox 取constraints.smallest，而 Row 给子项的
        // 高度约束是 0..48（center 对齐），smallest 就是 0——色块会被压成
        // 零高度，整行看起来就是「什么都没画」。stretch 把高度约束收紧成
        // tight 48，色块才真的占满。
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in colors) Expanded(child: ColoredBox(color: c)),
          ],
        ),
      ),
    );

List<({String name, Color color})> _rampEntries(ColorScheme s) => [
      (name: 'lowest', color: s.surfaceContainerLowest),
      (name: 'low', color: s.surfaceContainerLow),
      (name: 'base', color: s.surfaceContainer),
      (name: 'high', color: s.surfaceContainerHigh),
      (name: 'highest', color: s.surfaceContainerHighest),
      (name: 'outline', color: s.outline),
    ];

String hexOf(Color c) =>
    c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

const String _latinFamily = 'Roboto';
const String _cjkFamily = 'SimHei';

Book _book(String title) => Book(
      id: 'skin-preview-$title',
      title: title,
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
    );

Future<void> _loadFonts() async {
  Future<ByteData> bytesOf(String path) async =>
      ByteData.view((await File(path).readAsBytes()).buffer);

  final root = Platform.environment['FLUTTER_ROOT'];
  final roboto = root == null
      ? null
      : File('$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
  if (roboto != null && roboto.existsSync()) {
    await (FontLoader(_latinFamily)..addFont(bytesOf(roboto.path))).load();
  }
  await (FontLoader(_cjkFamily)..addFont(bytesOf('test/fixtures/simhei.ttf')))
      .load();
  await (FontLoader('MaterialIcons')
        ..addFont(bytesOf('test/fixtures/MaterialIcons-Regular.otf')))
      .load();
}
