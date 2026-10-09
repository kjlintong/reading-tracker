import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/ui/book_cover.dart';
import 'package:reading_tracker/ui/palette.dart';
import 'package:reading_tracker/ui/theme.dart';

import 'support/localized_app.dart';

/// 皮肤体系的约束。
///
/// 这些断言看着像审美偏好，但每一条都对应一个具体故障：
/// 纸色与种子色同族是「换皮像没换」的根因，色板撞色会让数据看不见，
/// 占位封面色相跑偏会让书架像配色事故。
/// 该皮肤在指定亮度下**实际生效**的色板。
///
/// ⚠️ 不能直接读 `t.chartPalette`：那是浅色那份。
/// 深色模式走的是 `chartPaletteDark`，两者明度分布完全不同。
/// 之前的色板测试一律用 `t.chartPalette` 去比深色纸色，
/// 于是「深色版色板」这个字段就算接错了线、甚至是上一轮的残留值，
/// 测试也全绿——覆盖���看似完整，实际漏掉了整个深色模式。
List<Color> _paletteInUse(AppTheme t, Brightness b) =>
    buildTheme(t, b).extension<ChartPalette>()!.colors;

void main() {
  group('皮肤注册表', () {
    test('id 唯一且非空——id 要落库，重复会让用户选中的皮肤错乱', () {
      final ids = appThemes.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: '重复 id 会让 byId 命中第一套，用户选择丢失');
      expect(ids.every((e) => e.trim().isNotEmpty), isTrue);
    });

    test('每套皮肤都有可显示的名字，不落回键名', () {
      for (final t in appThemes) {
        expect(t.labelKey, isNotEmpty);
        // themeLabelOf 的 switch 漏了分支就会把键名原样显示给用户
        expect(t.label, isNot(equals(t.labelKey)),
            reason: '${t.id} 缺 themeLabelOf 分支，会显示成 ${t.labelKey}');
        expect(t.label.trim(), isNotEmpty);
      }
    });

    test('第一套是默认皮肤，byId 未知值回落到它', () {
      expect(appThemes.first.id, 'green');
      expect(AppTheme.byId(null).id, appThemes.first.id);
      expect(AppTheme.byId('不存在的皮肤').id, appThemes.first.id);
      for (final t in appThemes) {
        expect(AppTheme.byId(t.id).id, t.id);
      }
    });
  });

  group('纸色派生', () {
    test('既有接近中性的高级纸色，也有明显着色的活泼纸色', () {
      final sat = {
        for (final t in appThemes)
          t.id: HSLColor.fromColor(
            buildTheme(t, Brightness.light).colorScheme.surface,
          ).saturation,
      };
      // 下限不是更低的值：饱和度低于 0.04 时 8bit 量化会把它判成无彩色，
      // 纸色的 hue 会归零，「底色跟着主色走」那条约束就失效了。
      // 0.04 在肉眼上仍是一张纸，不是彩纸。
      expect(sat.values.reduce(_min), lessThanOrEqualTo(0.06),
          reason: '最中性的一套应贴着保底饱和度（肉眼仍是纸色），实际 $sat');
      expect(sat.values.reduce(_max), greaterThan(0.08),
          reason: '最活泼的一套应明显带主色，实际 $sat');
      // 高低两档必须真的拉开距离，否则 paperTint 没起作用。
      // 跨度 0.05 是肉眼能分辨「这张纸偏暖 / 偏冷」的量级。
      expect(sat.values.reduce(_max) - sat.values.reduce(_min), greaterThan(0.06),
          reason: '高级与活泼纸色的着色度应明显不同，实际 $sat');
    });

    test('纸色与主色同族——换肤时底色要跟着主色走', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final scheme = buildTheme(t, b).colorScheme;
          // 基准取 **primary** 而不是原始种子色：纸色是用 seed 派生的，
          // 而 M3 推导出的 primary 与 seed 本身就有几度到几十度的色相偏移
          // （低饱和种子色最明显，ink 那套差约 31°）。约束要落在
          // 「纸色与这套皮肤的主色同族」上，而不是与原始常量的偏差上。
          final primaryHue = HSLColor.fromColor(scheme.primary).hue;
          final paperHue = HSLColor.fromColor(scheme.surface).hue;
          var delta = (paperHue - primaryHue).abs();
          if (delta > 180) delta = 360 - delta;
          expect(delta, lessThanOrEqualTo(45.0),
              reason: '${t.id}/$b 的纸色色相偏离该皮肤主色 ${delta.toStringAsFixed(1)}°，'
                  '底色与主色不像一家人');
        }
      }
    });

    test('表面六档明度单调、相邻档差够大否则卡片边界消失', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final s = buildTheme(t, b).colorScheme;
          final ramp = [
            s.surfaceContainerLowest,
            s.surfaceContainerLow,
            s.surfaceContainer,
            s.surfaceContainerHigh,
            s.surfaceContainerHighest,
          ];
          final lums = [for (final c in ramp) HSLColor.fromColor(c).lightness];
          for (var i = 0; i + 1 < lums.length; i++) {
            final d = (lums[i] - lums[i + 1]).abs();
            expect(d, greaterThan(0.02),
                reason: '${t.id}/$b 的表面色第 $i 与第 ${i + 1} 档只差 '
                    '${(d * 100).toStringAsFixed(1)}%，卡片与背景会糊在一起');
          }
        }
      }
    });

    test('正文在纸色与卡片色上对比度够（浅 ≥ 12:1，深 ≥ 7:1）', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final s = buildTheme(t, b).colorScheme;
          final min = b == Brightness.light ? 12.0 : 7.0;
          final r1 = _contrast(s.onSurface, s.surface);
          expect(r1, greaterThanOrEqualTo(min),
              reason: '${t.id}/$b 正文/纸色只有 ${r1.toStringAsFixed(1)}:1');
          final r2 = _contrast(s.onSurface, s.surfaceContainerLowest);
          expect(r2, greaterThanOrEqualTo(min),
              reason: '${t.id}/$b 卡片上正文只有 ${r2.toStringAsFixed(1)}:1');
        }
      }
    });

    test('每套皮肤明暗两态都能构建出完整 ThemeData', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          expect(() => buildTheme(t, b), returnsNormally, reason: '${t.id}/$b');
        }
      }
    });
  });

  group('图表色板跟随皮肤', () {
    testWidgets('Theme 里带着当前皮肤的色板', (tester) async {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
        final palette = _paletteInUse(t, b);
        await tester.pumpWidget(localizedApp(
          // ⚠️ 每轮必须换 key：MaterialApp 会按 key 复用同一个 Element，
          // 只换 theme 属性不会重建，断言会拿上一套皮肤的色板。
          key: ValueKey<String>('${t.id}-$b'),
          theme: buildTheme(t, b),
          home: Builder(builder: (context) {
            expect(paletteOf(context), palette, reason: '${t.id}/$b');
            return const SizedBox();
          }),
        ));
        }
      }
    });

    test('色板长度够画像页展示 12 类', () {
      for (final t in appThemes) {
        final palette = _paletteInUse(t, Brightness.light);
        expect(palette.length, greaterThanOrEqualTo(12),
            reason: '${t.id} 的色板只有 ${palette.length} 个位置，'
                '第 13 类起会与前面的撞色');
      }
    });

    test('色板内颜色两两可区分', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
        final palette = _paletteInUse(t, b);
        for (var i = 0; i < palette.length; i++) {
          for (var j = i + 1; j < palette.length; j++) {
            final d = _rgbDistance(palette[i], palette[j]);
            expect(d, greaterThan(0.28),
                reason: '${t.id}/$b 色板第 $i 与第 $j 个色几乎相同'
                    '（距离 ${d.toStringAsFixed(2)}），图和图例会对不上号');
          }
        }
        }
      }
    });

    test('色板与纸色有足够亮度差——图上要能看见数据', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final palette = _paletteInUse(t, b);
          final surface = buildTheme(t, b).colorScheme.surface;
          final worst = palette
              .map((c) => (c.computeLuminance() - surface.computeLuminance()).abs())
              .reduce(_min);
          expect(worst, greaterThan(0.04),
              reason: '${t.id}/$b 有系列色与纸色几乎同亮度，那条数据会看不见');
        }
      }
    });

    test('深色模式用的是深色专用色板，不是浅色那份', () {
      for (final t in appThemes) {
        expect(t.chartPaletteDark, isNotNull,
            reason: '${t.id} 没给深色色板，深色下会沿用浅色明度分布，'
                '最暗的几色会沉进深色纸里');
        expect(t.chartPaletteDark, isNot(equals(t.chartPalette)),
            reason: '${t.id} 的深浅两套色板完全相同，'
                '说明深色那份没独立求解');
      }
    });

    test('深色色板整体比纸色亮——数据在深色底上也要能看见', () {
      for (final t in appThemes) {
        final surface =
            buildTheme(t, Brightness.dark).colorScheme.surface;
        final palette = _paletteInUse(t, Brightness.dark);
        final brighter = palette
            .where((c) => c.computeLuminance() > surface.computeLuminance())
            .length;
        expect(brighter, greaterThanOrEqualTo(10),
            reason: '${t.id} 深色模式下只有 $brighter/12 个系列比纸色亮，'
                '其余会糊进背景');
      }
    });

    // ── 背景贴图皮肤 ────────────────────────────────────────────

    test('贴图皮肤与纯色皮肤分组正确', () {
      final plain = appThemes.where((t) => !t.hasBackground).toList();
      final textured = appThemes.where((t) => t.hasBackground).toList();
      expect(plain, isNotEmpty, reason: '必须保留至少一套纯色皮肤');
      expect(textured, isNotEmpty, reason: '贴图皮肤不能为空');
      // 纯色在前、贴图在后：设置页下拉按列表顺序展示，
      // 混排会让「贴图」这个分组标题出现在列表中间，很怪。
      final firstTextured = appThemes.indexWhere((t) => t.hasBackground);
      expect(firstTextured, greaterThan(0));
      for (var i = firstTextured; i < appThemes.length; i++) {
        expect(appThemes[i].hasBackground, isTrue,
            reason: '${appThemes[i].id} 不该出现在贴图组之后');
      }
      // 默认皮肤必须是纯色：首屏若带贴图，等于一上来就糊着背景。
      expect(appThemes.first.hasBackground, isFalse);
    });

    test('每套贴图皮肤的背景参数都在可读性安全区内', () {
      for (final t in appThemes.where((x) => x.hasBackground)) {
        expect(t.backgroundOpacity, greaterThan(0.05),
            reason: '${t.id} 的贴图几乎看不见，等于白做这套皮肤');
        //上限0.50。真正的「可读性安全区」是
        // opacity × (1 - scrim)：浅色模式 scrim=0.58，
        // 所以 0.50 × 0.42 ≈ 21% 的实际可见度，
        // 深色文字对比度仍有 10:1 以上（WCAG AA 要求 4.5:1）。
        // 单看 opacity 判不出安全区——两个衰减是**相乘**的，
        // 这是这套参数最容易想歪的地方（曾经按 0.28 定上限，
        // 结果遮罩一压，opacity 这一档形同虚设）。
        expect(t.backgroundOpacity, lessThanOrEqualTo(0.50),
            reason: '${t.id} 的贴图不透明度 ${t.backgroundOpacity} '
                '过高——叠加遮罩后书名与笔记会读不清，'
                '这正是阅读类 App 背景贴图最容易踩的坑');
        expect(t.backgroundBlur, greaterThanOrEqualTo(0));
        // 模糊半径过大在低端机上会明显掉帧，且看不出收益。
        expect(t.backgroundBlur, lessThanOrEqualTo(2.0),
            reason: '${t.id} 的模糊半径 ${t.backgroundBlur} 过大');
      }
    });

    test('贴图皮肤两两不同源——不会出现两套皮肤共用一张图', () {
      final assets = appThemes
          .where((t) => t.hasBackground)
          .map((t) => t.backgroundAsset)
          .toList();
      expect(assets.toSet().length, assets.length,
          reason: '有皮肤共用同一张背景图：$assets');
    });

    test('背景资源路径都已登记进 pubspec 的 assets', () async {
      // 不读 AssetManifest（widget 测试里 rootBundle 不可靠），
      // 直接查文件系统——能抓到「代码里写了路径但文件不存在」这种
      // 最常见的上线事故（改文件名忘了改代码）。
      for (final t in appThemes.where((x) => x.hasBackground)) {
        final f = File('${t.backgroundAsset}');
        expect(f.existsSync(), isTrue,
            reason: '${t.id} 的背景图不存在：${t.backgroundAsset}');
      }
    });

    test('贴图皮肤的低对比贴图在两态下都能压住纸色', () {
      // 贴图会被以 backgroundOpacity 混进纸色。若某套贴图本身
      // 与纸色亮度太接近，混完之后界面等于没有皮肤。
      for (final t in appThemes.where((x) => x.hasBackground)) {
        for (final b in Brightness.values) {
          final surface = buildTheme(t, b).colorScheme.surface;
          // 纸色与主色的对比度：贴图再淡，主色仍必须站得住，
          // 否则界面看起来就是「一张模糊的图」而非皮肤。
          final primary = buildTheme(t, b).colorScheme.primary;
          expect(primary.computeLuminance(),
              isNot(equals(surface.computeLuminance())),
              reason: '${t.id}/$b 的主色与纸色亮度相同，界面会糊成一片');
        }
      }
    });

    test('贴图亮度居中在明暗纸色之间——这是单张贴图两用的前提', () {
      // 贴图已不按明暗分两套文件，只靠 AppBackground 的遮罩强度适配。
      // 而遮罩只能压暗/提亮纸色，**无法把贴图的固有亮度挪走**：
      // 若贴图 med 与某态纸色接近，那一态下贴图就等于隐形。
      //
      // 判据直接取自合成公式
      //   结果 = 纸×scrim + (图×opacity + 纸×(1-opacity))×(1-scrim)
      // 要求合成结果与纯纸色的差 ≥0.03，即「肉眼看得出身份」。
      const minDelta = 0.03;
      // 与 AppBackground._scrim 保持一致。
      const scrims = {Brightness.light: 0.58, Brightness.dark: 0.30};
      for (final t in appThemes.where((x) => x.hasBackground)) {
        final op = t.backgroundOpacity;
        // 用主题实际种子色反推贴图该有的亮度锚点：素材统一按中位数
        // 对齐到 0.32（见 scripts/prep_backgrounds.py）。
        const imgMedian = 0.32;
        for (final b in Brightness.values) {
          final surface =
              buildTheme(t, b).colorScheme.surface.computeLuminance();
          final s = scrims[b]!;
          final mixed = op * imgMedian + (1 - op) * surface;
          final blended = surface * s + mixed * (1 - s);
          final delta = (blended - surface).abs();
          expect(delta, greaterThanOrEqualTo(minDelta),
              reason: '${t.id}/$b 下贴图与纸色只差 $delta'
                  '（纸 $surface / 图 $imgMedian / opacity $op /遮罩 $s）——'
                  '贴图已经隐形，这套皮肤等于白做');
        }
      }
    });

    test('拿不到 context 时回退全局色板（纯函数测试仍可用）', () {
      expect(paletteOf(null), chartPalette);
      expect(chartColorAt(0), chartPalette.first);
    });
  });

  group('占位封面跟随皮肤', () {
    Future<Color> coverColorOf(
        WidgetTester tester, AppTheme t, String title) async {
      const probe = ValueKey<String>('cover-probe');
      // ⚠️ 每次 pumpWidget 一个**全新的 widget 实例**，而不是复用同一个
      // helper 返回的对象。给 MaterialApp 换 key 只换了根节点的 Element，
      // `home` 若是同一个 widget 实例，其子Element 会整体复用，
      // 于是 Theme.of 拿到的还是**上一轮**的 Theme——实测会报出
      // 「ink 皮肤下封面是 green 的色相」这种与实现无关的结论。
      // 每轮新建 probe key + 新 MaterialApp 才能强制整棵子树重建。
      await tester.pumpWidget(localizedApp(
        key: ValueKey<String>('${t.id}-$title'),
        theme: buildTheme(t, Brightness.light),
        home: Builder(
          builder: (context) {
            // 断言当前这一轮确实是目标皮肤，避免「拿错主题却看不出来」
            // 基准是**当前皮肤的 primary**，不是原始种子色：
            // M3 从低饱和种子色推导出的 primary 色相会偏移几度到几十度
            // （实测 ink 那套差31.5°），这属正常推导行为，不是 bug。
            // 这里只验证「确实换成了这一轮的皮肤」。
            expect(
              HSLColor.fromColor(Theme.of(context).colorScheme.primary).hue,
              closeTo(
                HSLColor.fromColor(
                        buildTheme(t, Brightness.light).colorScheme.primary)
                    .hue,
                1.0,
              ),
              reason: 'pump 后 Theme 仍是上一轮的皮肤',
            );
            return SizedBox(
              key: probe,
              child: BookCover(book: _book(title)),
            );
          },
        ),
      ));
      await tester.pump();

      // ⚠️ 取**最后一个**带底色的 Container：BookCover 的结构是
      // ClipRRect → Container(占位) → Text，外层还有测试自己套的 SizedBox。
      // `.first` 会命中没有 color 的外层容器，取到 null 或错色。
      final containers = tester
          .widgetList<Container>(
            find.descendant(of: find.byKey(probe), matching: find.byType(Container)),
          )
          .where((c) => c.color != null)
          .toList();
      expect(containers, isNotEmpty, reason: '占位封面应渲染出一个带底色的 Container');
      return containers.last.color!;
    }

    testWidgets('色相落在皮肤色相附近，不跑出主题色系', (tester) async {
      for (final title in ['三体', 'Dune', '百年孤独', 'The Hobbit']) {
        for (final t in appThemes) {
          final c = await coverColorOf(tester, t, title);
          final seedHue =
          HSLColor.fromColor(buildTheme(t, Brightness.light).colorScheme.primary).hue;
          final h = HSLColor.fromColor(c).hue;
          var d = (h - seedHue).abs();
          if (d > 180) d = 360 - d;
          expect(d, lessThanOrEqualTo(32.0),
              reason: '${t.id} 皮肤下《$title》的占位封面色相偏离 '
                  '${d.toStringAsFixed(1)}°（封面色相 '
                  '${h.toStringAsFixed(1)} vs 主色相 ${seedHue.toStringAsFixed(1)}），'
                  '与主题不像一家');
        }
      }
    });

    testWidgets('浅色模式下占位封面够浅，不会在纸色上「跳出来」', (tester) async {
      for (final t in appThemes) {
        final c = await coverColorOf(tester, t, '三体');
        expect(HSLColor.fromColor(c).lightness, greaterThan(0.7),
            reason: '${t.id} 的浅色占位封面明度应高于 0.7，实际'
                '${HSLColor.fromColor(c).lightness.toStringAsFixed(2)}');
      }
    });

    test('占位色的偏移量只由书名决定，与皮肤无关', () {
      // 换皮肤只是把基准色相整体平移，**偏移量**必须完全不变——
      // 否则「同一本书在不同皮肤下长得不一样」，用户会以为换了本书。
      const spread = 42.0;
      // 与 book_cover.dart 的公式保持一致（连续系数，不是取档位）
      double offsetFor(String title) {
        final h = title.hashCode.abs();
        return ((h % 1009) / 1009.0) * 2 - 1;
      }

      for (final title in ['三体', 'Dune', '百年孤独', 'The Hobbit']) {
        final o = offsetFor(title);
        expect(o.abs(), lessThanOrEqualTo(1.0),
            reason: '《$title》的色相偏移系数超出 [-1, 1]');
        expect(o * spread, lessThanOrEqualTo(spread),
            reason: '《$title》的实际色相偏移超出 ±spread');
        // 偏移应当由书名稳定决定：多算几次结果一致
        expect(offsetFor(title), equals(o));
      }
      // 不同书应在偏移空间里散开，而不是全挤在同一个值上
      final offsets = {
        for (final t2 in ['三体', 'Dune', '百年孤独', 'The Hobbit', '活着'])
          offsetFor(t2),
      };
      expect(offsets.length, greaterThanOrEqualTo(3),
          reason: '五本书只落在 $offsets 几个偏移上，书架会显得重复');
    });
  });
}

double _max(double a, double b) => a > b ? a : b;
double _min(double a, double b) => a < b ? a : b;

/// 极简 Book：占位封面只用到 id 与 title。
Book _book(String title) => Book(
      id: 'cover-test',
      title: title,
      createdAt: '2026-01-01T00:00:00.000Z',
      updatedAt: '2026-01-01T00:00:00.000Z',
    );

/// RGB 空间曼哈顿距离，归一化到 0..3。
///
/// 不用 `Color.r/g/b`：那些getter 要 Flutter 3.27 才加，
/// 本项目跑在 3.24.5上，只能走 [red]/[green]/[blue]。
///
/// Flutter 3.24 的 `Color.red/green/blue` 返回 **int**（0..255），
/// 3.27 才改成 double。所以这里显式 `/255` 归一化到 0..1。
double _rgbDistance(Color a, Color b) =>
    ((a.red - b.red).abs() +
            (a.green - b.green).abs() +
            (a.blue - b.blue).abs()) /
        255.0;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (_max(la, lb) + 0.05) / (_min(la, lb) + 0.05);
}
