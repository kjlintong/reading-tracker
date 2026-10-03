import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'support/png24.dart';

/// 商店**图片素材**生成器（任务 #19 的一半）。
///
/// 产出两样东西：
///
/// 1. **Feature Graphic**（Google Play「应用特色图片」）
///    1024×500，24 位 PNG、**无 alpha**，中英各一张。
///    这是 Google Play 的**必交项**——缺了它整份 listing 没法发布。
///
/// 2. **全平台应用图标**（从用户自己设计的 1024×1024 母版派生）
///    iOS 19 档 + Android 5 档 legacy + Android 自适应图标 + Play 商店 512。
///
/// ## 为什么图标是「派生」而不是「设计」
///
/// 正式图标由用户亲自设计（已确认的分工）。这里只提供**规格 + 一键派生**：
/// 用户把母版丢到 `store/assets/icon-master.png`，本文件把它缩到每个平台
/// 要求的每个像素尺寸。母版没放进来时这一步会明确跳过并打印规格，不会假装成功。
///
/// ## 为什么 Feature Graphic 走代码而不是设计软件
///
/// 本机没有 Pillow / ImageMagick（WSL 与 Windows 侧都验证过），
/// 而 Play 要求「24 位 PNG，不能有 alpha」——Flutter 自带的 PNG 导出只会给
/// RGBA。于是 `test/support/png24.dart` 里手写了一个 24 位 PNG 编码器，
/// 产物一步到位就能上传，不需要再开一次设计软件去另存为。
///
/// ## 用法
///
/// ```bash
/// bash scripts/store-assets.sh          # 内部设 STORE_ASSETS=1
/// 产物：store/assets/feature-graphic.{zh,en}.png
///       store/assets/icon-play-512.png
///       app/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png
///       app/android/app/src/main/res/mipmap-*/ic_launcher*.png
/// ```
///
/// **默认（`flutter test`）全部跳过**：本文件会改写仓库里的正式图标，
/// 日常测试绝不能顺手把图标换掉。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 改写正式图标是有副作用的操作，必须有显式开关。
  final enabled = Platform.environment['STORE_ASSETS'] == '1';

  const assetsDir = '../store/assets';
  const masterPath = '$assetsDir/icon-master.png';
  const foregroundPath = '$assetsDir/icon-foreground.png';

  setUpAll(() async {
    if (!enabled) return;
    await _loadFonts();
  });

  // ── 1. Feature Graphic ────────────────────────────────────────────────

  testWidgets('Feature Graphic（1024×500，24 位无 alpha）', (tester) async {
    if (!enabled) return;

    for (final code in const ['zh', 'en']) {
      // 渲染 + 编码 + 写盘整个放进 runAsync。
      // testWidgets 用例体跑在 FakeAsync 里，真实的文件系统 I/O 在那里
      // 永远不会完成——不是慢，是死锁（进程 CPU 0%，也不报错）。
      final int? size = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder,
            Rect.fromLTWH(0, 0, _fgWidth.toDouble(), _fgHeight.toDouble()));
        _paintFeatureGraphic(canvas, code == 'zh');
        final picture = recorder.endRecording();
        final image = await picture.toImage(_fgWidth, _fgHeight);
        final data =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        picture.dispose();
        if (data == null) {
          throw StateError('Feature Graphic 渲染失败：$code');
        }

        // 关键一步：丢掉 alpha，写成 24 位 PNG。Play 会因此不再拒收。
        final png = encodePng24(
          width: _fgWidth,
          height: _fgHeight,
          rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        final file = File('$assetsDir/feature-graphic.$code.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png, flush: true);
        return png.length;
      });

      // ignore: avoid_print
      print('  $code → $assetsDir/feature-graphic.$code.png  '
          '$_fgWidth×$_fgHeight  '
          '${(size! / 1024).toStringAsFixed(1)} KB');
    }
  });

  // ── 2. 应用图标 ───────────────────────────────────────────────────────

  testWidgets('应用图标（从母版派生全平台尺寸）', (tester) async {
    if (!enabled) return;

    final master = File(masterPath);
    if (!master.existsSync()) {
      // ignore: avoid_print
      print('''
  [跳过] 未找到图标母版：$masterPath
         正式图标由你自己设计。设计完成后：
           1. 导出一张 1024×1024 的 PNG（**不透明**，四边满幅，不要自己加圆角，
              圆角由 iOS / Android 系统各自裁切）
           2. 存为 $masterPath
           3. 重跑 bash scripts/store-assets.sh
         可选：再做一张 $foregroundPath（1024×1024，**带透明背景**），
         用于 Android 自适应图标的前景层，效果比直接拿母版当整层更好。
         规格见 store/assets/icon-spec.md
''');
      return;
    }

    final masterImage = await tester.runAsync(
        () => _decode(File(masterPath).readAsBytesSync()));
    if (masterImage == null) fail('无法解码 $masterPath（需要标准 PNG）');

    final corner = await tester.runAsync(() => _cornerColor(masterImage));
    final bgHex = corner ?? '#FFFFFF';

    // 2a. iOS：**档位表直接读 Xcode 的 Contents.json**。
    // 手写一份尺寸表迟早会跟 Contents.json 漂移，而漂移的后果是
    // Xcode 报「找不到图片」或尺寸不符——不如让 JSON 当唯一真相。
    //
    // 注意 Contents.json 有 19 条记录，但同一个 filename 会被
    // iphone / ipad 两种 idiom 复用（例如 20x20@2x 两边都要），
    // 去重后实际只有 15 个文件。按文件名去重，避免重复渲染与误导性的计数。
    final iconSetDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final contents =
        jsonDecode(File('$iconSetDir/Contents.json').readAsStringSync())
            as Map<String, dynamic>;
    final iosTargets = <String, int>{};
    for (final entry in (contents['images'] as List).cast<Map>()) {
      final filename = entry['filename'] as String?;
      if (filename == null) continue;
      final size = double.parse((entry['size'] as String).split('x').first);
      final scale = double.parse((entry['scale'] as String).replaceAll('x', ''));
      iosTargets[filename] = (size * scale).round();
    }
    for (final e in iosTargets.entries) {
      // 渲染与写盘一起进 runAsync：FakeAsync 里的真实文件 I/O 会死锁。
      await tester.runAsync(() async {
        final bytes = await _renderSquare(masterImage, e.value, opaque: true);
        await File('$iconSetDir/${e.key}').writeAsBytes(bytes, flush: true);
      });
    }
    final recordCount = (contents['images'] as List).length;
    // ignore: avoid_print
    print('  iOS  → ${iosTargets.length} 个文件'
        '（Contents.json 共 $recordCount 条记录，同名 iphone/ipad 档位已合并）'
        ' → $iconSetDir/');

    // 2b. Android legacy（5 档密度，48dp 基准）
    const densities = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final e in densities.entries) {
      await tester.runAsync(() async {
        final bytes =
            await _renderSquare(masterImage, e.value, opaque: true);
        final dir = 'android/app/src/main/res/mipmap-${e.key}';
        await Directory(dir).create(recursive: true);
        await File('$dir/ic_launcher.png').writeAsBytes(bytes, flush: true);
      });
    }
    // ignore: avoid_print
    print('  Android legacy → ${densities.length} 档 → '
        'android/app/src/main/res/mipmap-*/ic_launcher.png');

    // 2c. Android 自适应图标（API 26+）。
    // 前景层是 108dp 画布，系统按各家形状遮罩裁切，可动范围内只有中间
    // 72dp 一定可见。所以前景必须**带透明通道**，用 ImageByteFormat.png
    // 直接导出即可（这里不需要 24 位编码器）。
    final fgFile = File(foregroundPath);
    final fgSource = fgFile.existsSync()
        ? await tester
            .runAsync(() => _decode(fgFile.readAsBytesSync()))
        : masterImage;
    final fgLabel = fgFile.existsSync()
        ? '$foregroundPath（独立前景层）'
        : '母版满幅充当前景层';
    const fgDensities = {
      'mdpi': 108,
      'hdpi': 162,
      'xhdpi': 216,
      'xxhdpi': 324,
      'xxxhdpi': 432,
    };
    for (final e in fgDensities.entries) {
      await tester.runAsync(() async {
        final bytes =
            await _renderSquare(fgSource!, e.value, opaque: false);
        final dir = 'android/app/src/main/res/mipmap-${e.key}';
        await Directory(dir).create(recursive: true);
        await File('$dir/ic_launcher_foreground.png')
            .writeAsBytes(bytes, flush: true);
      });
    }

    await tester.runAsync(() async {
      final anydpi = Directory('android/app/src/main/res/mipmap-anydpi-v26');
      await anydpi.create(recursive: true);
      await File('${anydpi.path}/ic_launcher.xml').writeAsString(
          '<?xml version="1.0" encoding="utf-8"?>\n'
          '<!-- 由 app/test/store_assets_test.dart 生成，请勿手改 -->\n'
          '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
          '    <background android:drawable="@color/ic_launcher_background"/>\n'
          '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
          '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
          '</adaptive-icon>\n');
      final valuesDir = Directory('android/app/src/main/res/values');
      await valuesDir.create(recursive: true);
      await File('${valuesDir.path}/ic_launcher_background.xml')
          .writeAsString(
          '<?xml version="1.0" encoding="utf-8"?>\n'
          '<!-- 由 app/test/store_assets_test.dart 生成：母版边角取色 -->\n'
          '<resources>\n'
          '    <color name="ic_launcher_background">$bgHex</color>\n'
          '</resources>\n');
    });
    // ignore: avoid_print
    print('  Android adaptive → ${fgDensities.length} 档，前景层用 $fgLabel');
    // ignore: avoid_print
    print('                    背景色 $bgHex（取自母版边角像素）');
    // ignore: avoid_print
    print('                    mipmap-anydpi-v26/ic_launcher.xml + '
        'values/ic_launcher_background.xml');

    // 2d. Play 商店列表图标：512×512，允许带 alpha（与 iOS 的 1024 要求相反）
    await tester.runAsync(() async {
      final bytes = await _renderSquare(masterImage, 512, opaque: false);
      final playFile = File('$assetsDir/icon-play-512.png');
      await playFile.parent.create(recursive: true);
      await playFile.writeAsBytes(bytes, flush: true);
    });
    // ignore: avoid_print
    print('  Play  → 512×512 → $assetsDir/icon-play-512.png');

    // 用完记得释放，避免测试进程里挂着解码后的位图。
    masterImage.dispose();
    if (fgSource != masterImage) fgSource!.dispose();
  });
}

// ── Feature Graphic 绘制 ──────────────────────────────────────────────────

const int _fgWidth = 1024;
const int _fgHeight = 500;

/// 品牌绿。与 App 主题种子色（`0xFF3B6D11`）同源，
/// 保证商店图和应用界面看起来是同一个产品。
const Color _deep = Color(0xFF1F4708);
const Color _mid = Color(0xFF3B6D11);
const Color _light = Color(0xFF7AB534);

/// 画一张 Feature Graphic。
///
/// 版式（从左到右）：品牌渐变底 → 右侧同心弧线（呼应产品名 nest「巢」）
/// → 左侧文字区：产品名 / 一句话定位 / 三个功能胶囊。
///
/// 文字全部落在左侧 60% 宽度内：Play 会在不同位置对这张图做裁切与叠加，
/// 把信息压在中间偏左比铺满四角更安全。
void _paintFeatureGraphic(Canvas canvas, bool zh) {
  final w = _fgWidth.toDouble();
  final h = _fgHeight.toDouble();
  final bounds = Rect.fromLTWH(0, 0, w, h);

  // 底色：对角渐变
  canvas.drawRect(
    bounds,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(w, h),
        const [_deep, _mid, _light],
        const [0.0, 0.55, 1.0],
      ),
  );

  // 右侧柔光，避免整张图平得像色卡
  canvas.drawRect(
    bounds,
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(w * 0.86, h * 0.12),
        h * 0.95,
        const [Color(0x33FFFFFF), Color(0x00FFFFFF)],
      ),
  );

  // 同心弧线：nest（巢）的意象。圆心放在右下角外侧，
  // 只露出左上四分之一，形成不抢戏的图形底纹。
  final center = Offset(w * 0.97, h * 1.42);
  for (var i = 0; i < 4; i++) {
    final r = h * (0.62 + i * 0.19);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      math.pi,
      math.pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..color = Color.fromRGBO(255, 255, 255, 0.055 + i * 0.022),
    );
  }

  // ── 文字区 ──
  const left = 84.0;

  final title = _para(
    'Readnest',
    size: 108,
    weight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -2.5,
  )..layout(ui.ParagraphConstraints(width: w * 0.62));
  canvas.drawParagraph(title, const Offset(left, 96));

  // 产品名下的小横线
  canvas.drawRRect(
    RRect.fromRectAndRadius(
        const Rect.fromLTWH(left + 2, 232, 96, 6), const Radius.circular(3)),
    Paint()..color = const Color(0xE6FFFFFF),
  );

  final tagline = _para(
    zh ? '把散落各处的书，收进同一个书架' : 'Every book you own, in one quiet place',
    size: 34,
    weight: FontWeight.w500,
    color: const Color(0xF2FFFFFF),
    letterSpacing: 0.2,
  )..layout(ui.ParagraphConstraints(width: w * 0.62));
  canvas.drawParagraph(tagline, const Offset(left, 268));

  // 功能胶囊
  final labels = zh
      ? const ['本地优先', '无需账号', '拍照导入', '阅读统计']
      : const ['On-device', 'No account', 'Shelf scanning', 'Reading stats'];

  var x = left;
  const pillY = 376.0;
  const pillH = 48.0;
  const gap = 12.0;
  const padX = 22.0;

  for (final label in labels) {
    final p = _para(label,
        size: 25, weight: FontWeight.w600, color: const Color(0xF2FFFFFF))
      ..layout(const ui.ParagraphConstraints(width: 400));
    final pillW = p.longestLine + padX * 2;
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, pillY, pillW, pillH), const Radius.circular(pillH / 2));
    canvas.drawRRect(rect, Paint()..color = const Color(0x26FFFFFF));
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x4DFFFFFF),
    );
    canvas.drawParagraph(
      p,
      Offset(x + padX, pillY + (pillH - p.height) / 2),
    );
    x += pillW + gap;
  }
}

/// 构造一段可测量的文字。测试环境没有字体，必须由 `_loadFonts()` 先喂进去，
/// 否则量出来的宽度是 0、画出来是豆腐块。
///
/// ## 字体回退为什么两个参数都得给
///
/// `ui.ParagraphStyle` 在 Flutter 3.24 **没有** `fontFamilyFallback`，
/// 只有 `ui.TextStyle` 有——所以回退必须写在 pushStyle 的 TextStyle 上。
///
/// 但**只给 fallback 而把 fontFamily 留空**会得到一屏方块：
/// `ui.TextStyle` 内部是 `_fontFamily = fontFamily ?? ''`，
/// 空字符串会被原样当作字族名交给原生层，查不到就落到
/// flutter_test 那个「所有字形都是方框」的兜底字体上。
/// 结论：`fontFamily` 与 `fontFamilyFallback` 要成对出现。
ui.Paragraph _para(
  String text, {
  required double size,
  required FontWeight weight,
  required Color color,
  double letterSpacing = 0,
}) {
  final style = ui.ParagraphStyle(
    textAlign: TextAlign.left,
    fontFamily: _latinFamily,
    fontSize: size,
    fontWeight: weight,
  );
  // 级联（..）返回的是 ParagraphBuilder 自己，不是 Paragraph——
  // 必须显式 build()，否则返回类型对不上直接编译失败。
  final builder = ui.ParagraphBuilder(style)
    ..pushStyle(ui.TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      fontFamily: _latinFamily,
      fontFamilyFallback: const <String>[_cjkFamily],
    ))
    ..addText(text);
  return builder.build();
}

// ── 图标派生 ──────────────────────────────────────────────────────────────

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// 把母版等比缩放成 [size]×[size]。
///
/// [opaque] = true  → 24 位 PNG，无 alpha（iOS 全档 + Android legacy 要求）
/// [opaque] = false → 普通 RGBA PNG，保留透明（Android 自适应前景层、
///                    Play 商店 512 图标都允许甚至需要 alpha）
Future<Uint8List> _renderSquare(ui.Image src, int size,
    {required bool opaque}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

  // 母版带透明时直接丢 alpha 会变黑边，所以先铺一层白底再叠图。
  if (opaque) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  canvas.drawImageRect(
    src,
    Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Paint()
      ..isAntiAlias = true
      // 缩小图像时 high 明显更干净；下采样到 20px 全靠这个。
      ..filterQuality = FilterQuality.high,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);

  if (opaque) {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    if (data == null) return Uint8List(0);
    return encodePng24(
      width: size,
      height: size,
      rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return png!.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
}

/// 取母版左上角的颜色，作为 Android 自适应图标的背景色。
/// 母版是满幅设计时，这样能让被系统遮罩裁掉的部分与背景无缝衔接。
/// 边角像素是透明的（母版有 alpha）就返回 null，交给调用方回退到白色。
Future<String?> _cornerColor(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;
  final b = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final a = b[3];
  if (a < 250) return null;
  String hx(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '#${hx(b[0])}${hx(b[1])}${hx(b[2])}';
}

// ── 字体 ──────────────────────────────────────────────────────────────────

/// 拉丁字形用的 family 名（真 Roboto）。
const String _latinFamily = 'Roboto';

/// 中日韩字形用的 family 名（SimHei）。
///
/// **必须是独立 family**，不能跟 Roboto 混在同一个名下。
/// 踩过的坑：一开始把 Roboto 与 simhei 依次 `addFont` 到同一个 `'Roboto'`
/// family，结果整幅 Feature Graphic 的汉字全变成空心方框——
/// Skia 在**同一个 family 内只锁定首个字面**，不做逐字符回退；
/// 逐字符回退只发生在**不同 family 之间**（`fontFamilyFallback`）。
/// 也就是说 `FontLoader` 注册多个字面并不等于「字体回退」。
const String _cjkFamily = 'SimHei';

/// 测试环境不自带字体，必须自己喂，分三个 family：
///
/// - `Roboto`：真 Roboto，只管拉丁。从 Flutter SDK 缓存取
///   （`FLUTTER_ROOT` 由 `flutter test` 注入）；取不到就跳过，
///   此时拉丁字形由 [SimHei] 顶替，产物依然可用，不会失败。
/// - `SimHei`：simhei.ttf，管中日韩。挂在独立 family 下，
///   靠 `fontFamilyFallback` 生效，而不是跟 Roboto 抢同一个 family。
/// - `MaterialIcons`：本文件用不到图标，但保持与截图脚本一致，顺手加载。
Future<void> _loadFonts() async {
  Future<ByteData> bytesOf(String path) async =>
      ByteData.view((await File(path).readAsBytes()).buffer);

  final root = Platform.environment['FLUTTER_ROOT'];
  final roboto =
      root == null ? null : File('$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
  if (roboto != null && roboto.existsSync()) {
    await (FontLoader(_latinFamily)..addFont(bytesOf(roboto.path))).load();
  }

  await (FontLoader(_cjkFamily)..addFont(bytesOf('test/fixtures/simhei.ttf')))
      .load();
}
