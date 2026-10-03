import 'dart:io';
import '../l10n/app_loc.dart';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// 截图 OCR 前的图像增强。
///
/// 端侧 ML Kit 对小字号、彩色背景上的文字识别率会明显下降，而手机截图
/// 恰好两样都占：书名是 12px 的小字，进度文字还压在彩色封面上。
/// 放大到 1200px 宽再把彩色压成灰度，是收益最直接的两步。
///
/// 全程 fail-safe：任何一步出问题都返回原图路径，
/// 宁可识别率差一点，也不能因为预处理失败而让整个导入流程崩掉。
class ImagePreprocessor {
  ImagePreprocessor._();

  /// 增强并落盘到一个新文件，返回可直接喂给 OCR 的路径
  static Future<String> enhanceToFile(String srcPath, {String? outDir}) async {
    try {
      final bytes = await File(srcPath).readAsBytes();
      // 解码 + 缩放 + 编码都是 CPU 密集操作，1080×2400 的截图在主线程上
      // 会把界面卡住几百毫秒，所以丢到独立 isolate。
      final out = await compute(enhanceForOcr, bytes);
      if (out == null) return srcPath;

      final dir = outDir ?? p.dirname(srcPath);
      final dst = p.join(
          dir, 'ocr_${DateTime.now().microsecondsSinceEpoch}.png');
      await File(dst).writeAsBytes(out, flush: true);
      return dst;
    } catch (e) {
      debugPrint(appLoc.s_5583162a(e: e));
      return srcPath;
    }
  }

  /// 转成可直接发给多模态模型的 JPEG 字节。
  ///
  /// 与 OCR 那条路的需求**相反**：OCR 要大而清晰（放大到 1200px），
  /// 视觉模型要小而省 token（长边 1280、质量 85 足够读出书名，
  /// 再大只是白烧钱并且更容易触发网关的体积上限）。
  ///
  /// 还必须统一成 JPEG：模型网关只认 image/jpeg / png / webp 少数几种，
  /// 相册里选出来的可能是 HEIC，直接把原始字节发出去必被拒。
  static Future<Uint8List?> toJpegBytes(
    String srcPath, {
    int maxSide = 1280,
    int quality = 85,
  }) async {
    try {
      final bytes = await File(srcPath).readAsBytes();
      return await compute(_toJpeg, _JpegJob(bytes, maxSide, quality));
    } catch (e) {
      debugPrint(appLoc.s_628c2132(e: e));
      return null;
    }
  }

  /// 用完即删，别让临时图占着手机存储
  static Future<void> cleanup(String? path, {required String original}) async {
    if (path == null || path == original) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // 清理失败无关紧要
    }
  }
}

/// 顶层函数，供 compute 在独立 isolate 中调用。
///
/// 返回 null 表示解码失败或已有足够质量，调用方会用原图。
@visibleForTesting
Uint8List? enhanceForOcr(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) return null;

  var im = decoded;

  // 太小的图直接放大。ML Kit 内部会把大图缩到 ~1024，
  // 但放大能让细小笔画先变得可分辨，识别率是净收益。
  const targetWidth = 1200;
  if (im.width < targetWidth) {
    im = img.copyResize(
      im,
      width: targetWidth,
      interpolation: img.Interpolation.cubic,
    );
  }

  // 去色 + 轻度提对比。刻意保守（1.25 而不是 2.0）：
  // 过度提对比会把浅色小字直接抹成背景。
  im = img.adjustColor(im, saturation: 0, contrast: 1.25, brightness: 1.03);

  return img.encodePng(im);
}

class _JpegJob {
  final Uint8List bytes;
  final int maxSide;
  final int quality;

  const _JpegJob(this.bytes, this.maxSide, this.quality);
}

/// 顶层函数，供 compute 在独立 isolate 中调用。
Uint8List? _toJpeg(_JpegJob job) {
  final decoded = img.decodeImage(job.bytes);
  if (decoded == null) return null;
  var im = decoded;
  final longSide = im.width > im.height ? im.width : im.height;
  if (longSide > job.maxSide) {
    final ratio = job.maxSide / longSide;
    im = img.copyResize(
      im,
      width: (im.width * ratio).round(),
      height: (im.height * ratio).round(),
      interpolation: img.Interpolation.average,
    );
  }
  return Uint8List.fromList(img.encodeJpg(im, quality: job.quality));
}
