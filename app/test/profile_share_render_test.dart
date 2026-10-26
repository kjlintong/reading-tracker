import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/profile_store.dart';
import 'package:reading_tracker/data/reading_profile.dart';
import 'package:reading_tracker/ui/brand_mark.dart';
import 'package:reading_tracker/ui/profile_share_card.dart';
import 'package:reading_tracker/ui/profile_share_style.dart';
import 'package:reading_tracker/ui/theme.dart';
import 'package:screenshot/screenshot.dart';

import 'support/localized_app.dart';

/// 真跑一次离屏截图，确认品牌角标**真的出现在 PNG 里**。
///
/// ## 为什么非要真截图
///
/// 离屏渲染有个反直觉的坑：截图流程只等「调度了 build」才重截，
/// 而 `Image.asset` 的异步解码只触发重绘（`markNeedsPaint`），
/// **不触发 build**——于是第一帧截图里根本没有那张图，
/// 之后也不会重截。代码看起来完全正常，角标却不见了。
///
/// 这个坑只有真截图才暴露得出来：普通 widget 测试里图片照样会显示，
/// 测试全绿而线上丢图。所以这条用例守的是**离屏渲染特有的失败模式**，
/// 不能省。
///
/// ## 为什么整段包在 runAsync 里
///
/// 截图流程内部有 `Future.delayed`（等重绘），在 FakeAsync 里会死锁。
/// 项目铁律：真实 I/O 必须走 `tester.runAsync`。
void main() {
  testWidgets('离屏截图的右上角有品牌角标（不是一张空图）', (tester) async {
    late BuildContext hostCtx;
    await tester.pumpWidget(localizedApp(
      home: Builder(builder: (ctx) {
        hostCtx = ctx;
        return const Scaffold(body: SizedBox.shrink());
      }),
    ));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final mark = await loadBrandMark();
      expect(mark, isNotNull, reason: '品牌角标解码失败，资源路径或格式不对');

      final berry = appThemes.firstWhere((t) => t.id == 'berry');
      final style = ProfileShareStyle.of(berry, Brightness.light);

      final bytes = await ScreenshotController().captureFromWidget(
        ProfileShareCard(
          profile: const ReadingProfile(
            preferences: [
              PreferenceSlice(label: 'literature', count: 12, share: 0.3),
            ],
          ),
          tags: const [ProfileTagItem(text: '夜读型')],
          rangeLabel: '近 30 天',
          bookCount: 38,
          style: style,
          mark: mark,
        ),
        pixelRatio: 2.0,
        context: hostCtx,
      );

      expect(bytes.length, greaterThan(1000), reason: '截图太小，可能是空图');

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);
      final w = img.width, h = img.height;
      expect(w, greaterThan(100));
      expect(h, greaterThan(100));

      final px = data!.buffer.asUint8List();

      // 角标在卡片右上角：找那块区域饱和度最高的点——应该是金书。
      var bestSat = -1.0;
      var bestAt = Offset.zero;
      for (var y = 0; y < (h / 5).round(); y++) {
        for (var x = (w * 5 / 6).round(); x < w; x++) {
          final o = (y * w + x) * 4;
          final r = px[o], g = px[o + 1], b = px[o + 2];
          final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
          final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
          final sat = mx == 0 ? 0.0 : (mx - mn) / mx;
          if (sat > bestSat) {
            bestSat = sat;
            bestAt = Offset(x.toDouble(), y.toDouble());
          }
        }
      }
      // 纸色本身饱和度很低（<0.2），金书明显更高。
      expect(bestSat, greaterThan(0.35),
          reason: '右上角找不到金色书脊（最高饱和度 $bestSat @ $bestAt）'
              '——角标可能没被画进截图');

      img.dispose();
      codec.dispose();
      mark?.dispose();
    });
  });
}
