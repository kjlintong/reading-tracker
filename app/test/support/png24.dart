/// 极小的 **24 位 PNG**（truecolor，无 alpha 通道）编码器。
///
/// ## 为什么需要它
///
/// Google Play 对「应用特色图片 / Feature Graphic」的硬性要求是
/// **JPEG 或 24 位 PNG，且不能带 alpha 通道**。
/// 而 Flutter 的 `ui.Image.toByteData(format: ImageByteFormat.png)` 只会产出
/// **RGBA（color type 6）**，alpha 通道必然存在——即便画布填满了不透明像素，
/// 通道本身仍在文件里。Play Console 对此一向严格。
///
/// 本机也没有任何可用的图像库（WSL 与 Windows 侧均无 Pillow / ImageMagick），
/// 而 Dart 侧 `dart:io` 自带 `ZLibEncoder`，写 PNG 的剩余工作
/// —— 分块、CRC32、扫描线过滤 —— 加起来不到 100 行，且零外部依赖。
/// 于是就有了这个文件。
///
/// ## 为什么不用「先出 RGBA 再用工具剥掉 alpha」
///
/// 那需要额外一步人工操作，而且换台机器就又得重来一遍。让产物一步到位，
/// 脚本跑完的文件就能直接上传，才不会再出现「本地看着没问题、上传被拒」。
///
/// 注意：`library;` 必须写在整个文件的最前面（在所有 import 之前），
/// 否则报 "The library directive must appear before all other directives"。
library;

import 'dart:io';
import 'dart:typed_data';

/// 把「紧密排列的 RGBA 字节」写成 24 位 PNG（丢弃 alpha，其余按原样输出）。
///
/// [rgba] 长度必须是 `width * height * 4`。
/// 调用方需自行保证画布已被完整绘制（不要留透明区域）——
/// 本函数只负责丢弃 alpha，不会把透明像素合成到任何背景上。
Uint8List encodePng24({
  required int width,
  required int height,
  required Uint8List rgba,
}) {
  final expected = width * height * 4;
  if (rgba.length != expected) {
    throw ArgumentError(
        'RGBA 长度 ${rgba.length} 与 $width×$height 不匹配（应为 $expected）');
  }

  // 扫描线：每行前面加一个 filter 字节。这里统一用 0（None）——
  // 图片是纯色渐变加少量文字，压缩率本来就够高，不值得为每行挑最优 filter
  // 写一堆试算代码。
  final raw = Uint8List(height * (1 + width * 3));
  var w = 0;
  for (var y = 0; y < height; y++) {
    raw[w++] = 0;
    var src = y * width * 4;
    for (var x = 0; x < width; x++) {
      raw[w++] = rgba[src]; // R
      raw[w++] = rgba[src + 1]; // G
      raw[w++] = rgba[src + 2]; // B
      // rgba[src + 3]（alpha）直接丢弃
      src += 4;
    }
  }

  final idat = Uint8List.fromList(ZLibEncoder(level: 9).convert(raw));

  final out = BytesBuilder(copy: false)
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  final ihdr = BytesBuilder(copy: false)
    ..add(_u32(width))
    ..add(_u32(height))
    ..add(const [
      8, // bit depth
      2, // color type 2 = truecolor RGB（关键：无 alpha）
      0, // compression: deflate
      0, // filter method
      0, // interlace: none
    ]);
  out.add(_chunk('IHDR', ihdr.takeBytes()));
  out.add(_chunk('IDAT', idat));
  out.add(_chunk('IEND', Uint8List(0)));

  return out.takeBytes();
}

/// 组装一个 PNG 分块：长度(4) + 类型(4) + 数据 + CRC32(4)。
Uint8List _chunk(String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final crcInput = BytesBuilder(copy: false)
    ..add(typeBytes)
    ..add(data);

  return (BytesBuilder(copy: false)
        ..add(_u32(data.length))
        ..add(typeBytes)
        ..add(data)
        ..add(_u32(_crc32(crcInput.takeBytes()))))
      .takeBytes();
}

/// PNG 与 zip 共用的 CRC-32（IEEE 802.3，多项式 0xEDB88320 反射形式）。
int _crc32(Uint8List bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var i = 0; i < 8; i++) {
      // 等价于「最低位为 1 时先右移再异或多项式」
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}

Uint8List _u32(int v) {
  final b = Uint8List(4);
  b.buffer.asByteData().setUint32(0, v, Endian.big);
  return b;
}
