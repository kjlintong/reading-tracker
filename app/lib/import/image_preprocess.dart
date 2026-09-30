import 'dart:io';

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
      debugPrint('图像预处理失败，改用原图：$e');
      return srcPath;
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
