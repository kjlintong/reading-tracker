/// 一行 OCR 文本 + 它的位置。
///
/// 刻意不直接依赖 ML Kit 的类型（`TextLine` / `Rect`）：解析算法必须能
/// 在纯 Dart 测试里跑，而 ML Kit 的插件在测试环境不可用。调用方负责
/// 把 `TextLine.boundingBox` 翻译成这四个数。
class OcrLine {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// 只有文本、没有几何信息时的便捷构造（退化输入）
  const OcrLine.text(this.text)
      : left = 0,
        top = 0,
        right = 0,
        bottom = 0;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  /// 几何信息是否可用。OCR 引擎偶尔不返回 boundingBox，
  /// 全为 0 的坐标会让布局聚类把整页揉成一行，必须先识别出来。
  bool get hasGeometry => right > left && bottom > top;

  OcrLine copyWith({String? text}) => OcrLine(
        text: text ?? this.text,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      );

  @override
  String toString() => 'OcrLine("$text" @$left,$top,$right,$bottom)';
}
