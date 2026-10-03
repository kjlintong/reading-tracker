import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/bubble_pack.dart';
import '../l10n/app_loc.dart';
import 'palette.dart';

/// 气泡图。用 CustomPaint 自绘——
/// `fl_chart` 没有气泡图，而散点图做不到「不重叠 + 按数量定大小」。
///
/// 从 `profile_page.dart` 提出来公开，因为「阅读档案」首页也要内联
/// 展示同一张图。两处必须逐像素一致，否则用户在档案页和画像页
/// 看到的「偏好分布」会长得不一样。
class PreferenceBubbleChart extends StatelessWidget {
  final List<Bubble> bubbles;

  /// 规范值 → 当前语言的显示名。
  ///
  /// [Bubble] 里的 label 是规范值（取色用），但气泡中心要画的是给人看的字，
  /// 所以二者必须分开传，不能让 painter 直接画 `b.label`。
  final Map<String, String> displayNames;

  /// 分类名 → 颜色。由外面按**图例的顺序**生成后传进来。
  ///
  /// 不能在这里用 `bubbles[i]` 的下标取色：气泡是按半径降序重排过的，
  /// 同数量的分类之间顺序不保证稳定，一旦漂移就会出现
  /// 「图上两个圆同色、图例里却是两行」这种很难查的错。
  final Map<String, Color> colors;

  const PreferenceBubbleChart({
    super.key,
    required this.bubbles,
    required this.displayNames,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (bubbles.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(appLoc.s_9fe34cff,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }
    // 画布必须是正方形：packing 是在单位正方形里算的，
    // 拉成矩形会让圆变成椭圆。
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    return LayoutBuilder(
      builder: (context, c) {
        final side = c.maxWidth < 230 ? c.maxWidth : 230.0;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: CustomPaint(
              painter: _BubblePainter(
                bubbles: bubbles,
                displayNames: displayNames,
                colors: colors,
                labelStyle: labelStyle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final Map<String, String> displayNames;
  final Map<String, Color> colors;
  final TextStyle? labelStyle;

  const _BubblePainter({
    required this.bubbles,
    required this.displayNames,
    required this.colors,
    this.labelStyle,
  });

  /// 把标签塞进半径 [r] 的圆里，塞不下就缩字号，缩到底还塞不下就不画。
  ///
  /// 判据是勾股定理：居中放置的文字块能放进圆里，当且仅当
  /// `(w/2)² + (h/2)² ≤ r²`。**只限宽（`maxWidth: r * 1.6`）是不够的**——
  /// 那等于假设文字只有一行；两行的标签高度会把四个角顶到圆外，
  /// 截图里就会出现「字比圆宽」的观感。
  ///
  /// 不画也不要紧：名称与数量另有文本图例兜底，信息不会丢。
  TextPainter? _fitLabel(String text, double r) {
    // 留 12% 边距，避免文字刚好贴到圆边上
    final limit = r * 0.88;
    for (final size in const [11.0, 10.0, 9.0, 8.0]) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: (labelStyle ?? const TextStyle()).copyWith(
            fontSize: size,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: r * 1.7);
      final w = tp.width / 2;
      final h = tp.height / 2;
      if (math.sqrt(w * w + h * h) <= limit) return tp;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 半径太小的圆里放不下字，连试都不用试
    const minLabelRadius = 12.0;

    for (var i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      final center = Offset(b.x * size.width, b.y * size.height);
      final r = b.radius * size.width;

      canvas.drawCircle(
        center,
        r,
        Paint()..color = colors[b.label] ?? chartColorAt(i),
      );

      if (r < minLabelRadius) continue;

      // 画的是本地化显示名，不是取色用的规范值
      final tp = _fitLabel(displayNames[b.label] ?? b.label, r);
      if (tp == null) continue;
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) =>
      old.bubbles != bubbles ||
      old.displayNames != displayNames ||
      old.colors != colors ||
      old.labelStyle != labelStyle;
}
