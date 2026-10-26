import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// 品牌标记（分享图角标）。
///
/// 素材在 `assets/brand/mark.png`：从应用图标母版裁出的圆角小方图，
/// 主体是中间那本金色的书——缩到小尺寸仍然是一根明确的高亮竖条，
/// 而整枚图标缩到 24px 就只是三根亮线加一片暗木纹，看不出是什么。
///
/// ## 为什么用 [ui.Image] 而不是 [Image.asset]
///
/// 分享卡是**离屏渲染**的：`ScreenshotController.captureFromWidget` 把
/// widget 挂到一棵独立的渲染树上，截图流程是
///
/// ```
/// build → 首次 toImage → 等 delay → 若 isDirty 则重建重截
/// ```
///
/// 而 `isDirty` 只在**调度了 build** 时置位。`Image.asset` 解析图片走的是
/// `ImageStream`，解码完成只触发 `markNeedsPaint`（重绘），**不触发 build**——
/// 于是第一帧截图里根本没有这张图，之后也不会重截。
///
/// 结论：角标必须在截图**之前**就解码成 [ui.Image]，再用 [RawImage] 画。
/// `RawImage` 直接贴一张已解码的图，是同步绘制，第一帧就在。
const String kBrandMarkAsset = 'assets/brand/mark.png';

/// 读取并解码品牌标记。
///
/// 失败（资源缺失、格式损坏）返回 null 而不是抛异常——角标是锦上添花，
/// 缺了不该让「分享」这个动作整个失败。
Future<ui.Image?> loadBrandMark() async {
  try {
    final data = await rootBundle.load(kBrandMarkAsset);
    final bytes = _exactBytes(data);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

/// 把 [ByteData] 精确切成字节数组。
///
/// `ByteData.buffer` 可能比数据本身长（view 带 offset），
/// 直接 `asUint8List()` 会把前后的空字节也带进去，解码时行为诡异。
Uint8List _exactBytes(ByteData data) => data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
