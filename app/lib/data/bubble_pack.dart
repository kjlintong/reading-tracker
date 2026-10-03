import 'dart:math' as math;

/// 待排版的圆形
class BubbleInput {
  final String label;
  final double value;

  const BubbleInput({required this.label, required this.value});
}

/// 排版完成的圆。圆心与半径都在 `[0, size] × [0, size]` 的画布坐标系里。
class Bubble {
  final String label;
  final double value;
  final double x;
  final double y;
  final double radius;

  const Bubble({
    required this.label,
    required this.value,
    required this.x,
    required this.y,
    required this.radius,
  });

  /// 半径与「数量的平方根」成正比。
  ///
  /// 必须开方：圆的**面积**代表数量，而面积 ∝ 半径²。
  /// 直接用数量当半径，1 本与 100 本在视觉上只差 100 倍直径，
  /// 而面积差了一万倍——图会骗人。
  double get weight => radius * radius;
}

/// 圆形 packing（气泡图排版）。
///
/// 没有用 `fl_chart`：它只有折线/柱状/饼图/散点，没有气泡图。
/// 自己排是更好的选择——散点图做不出「不重叠且按数量定大小」的效果，
/// 而在散点里手动堆位置等于自己实现一遍 packing，还失去了控制权。
///
/// 算法：按半径从大到小，每个新圆都**同时与两个已放置的圆相切**
/// （两圆相切位置有解析解，两个候选点取离中心更近的那个）。
/// 这样排出来的结果像自然堆叠，而不是套圈的同心环。
///
/// 纯函数、无 Flutter 依赖，可以单测——「不重叠」「不越界」这两条
/// 是最容易在算法小改之后悄悄破掉的，必须有用例盯着。
List<Bubble> packBubbles(
  List<BubbleInput> input, {
  double size = 1.0,
  /// 圆与圆之间留的缝（缩放前坐标系）
  double padding = 0.02,
  /// 所有圆面积之和占画布面积的比例。0.62 是留白与饱满的折中，
  /// 再高就会出现「大圆贴着边、小圆挤成一点」的观感
  double fill = 0.62,
  int maxBubbles = 14,
}) {
  final items = input.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (items.isEmpty) return const [];

  final picked = items.take(maxBubbles).toList();
  final maxValue = picked.first.value;

  // 相对权重：半径 ∝ sqrt(数量)
  final weights = [for (final e in picked) math.sqrt(e.value / maxValue)];
  final sumSq = weights.fold<double>(0, (a, w) => a + w * w);
  final scale = sumSq <= 0
      ? 0.0
      : math.sqrt(fill * size * size / (math.pi * sumSq));
  final radii = [for (final w in weights) math.max(w * scale, 1e-4)];

  final centers = _place(radii, padding);

  // 打包过程中不做出界判断（那会让外侧的大圆最后被裁掉），
  // 统一在最后等比缩放平移进画布——形状不变，只是整体缩一点。
  var minX = double.infinity, maxX = -double.infinity;
  var minY = double.infinity, maxY = -double.infinity;
  for (var i = 0; i < centers.length; i++) {
    minX = math.min(minX, centers[i].x - radii[i]);
    maxX = math.max(maxX, centers[i].x + radii[i]);
    minY = math.min(minY, centers[i].y - radii[i]);
    maxY = math.max(maxY, centers[i].y + radii[i]);
  }
  final w = maxX - minX;
  final h = maxY - minY;
  final fit = math.min(size / (w <= 0 ? 1 : w), size / (h <= 0 ? 1 : h));

  return [
    for (var i = 0; i < centers.length; i++)
      Bubble(
        label: picked[i].label,
        value: picked[i].value,
        x: (centers[i].x - minX) * fit,
        y: (centers[i].y - minY) * fit,
        radius: radii[i] * fit,
      ),
  ];
}

/// 依次放置所有圆，返回圆心。第一个在原点。
List<math.Point<double>> _place(List<double> radii, double padding) {
  final centers = <math.Point<double>>[const math.Point(0, 0)];

  for (var i = 1; i < radii.length; i++) {
    final r = radii[i];
    final best = _bestTangent(r, radii, centers, padding);
    centers.add(best);
  }
  return centers;
}

math.Point<double> _bestTangent(
  double r,
  List<double> radii,
  List<math.Point<double>> centers,
  double padding,
) {
  // 只放了一个时没有「相切于两圆」可言，先沿 +x 摆开
  if (centers.length == 1) {
    return math.Point(centers[0].x + radii[0] + r + padding, centers[0].y);
  }

  math.Point<double>? best;
  var bestDist = double.infinity;

  for (var j = 0; j < centers.length; j++) {
    for (var k = j + 1; k < centers.length; k++) {
      for (final c in _tangentPoints(
          centers[j], radii[j], centers[k], radii[k], r)) {
        if (!_fits(c, r, radii, centers, padding)) continue;
        final d = c.x * c.x + c.y * c.y;
        if (d < bestDist) {
          bestDist = d;
          best = c;
        }
      }
    }
  }
  if (best != null) return best;

  // 理论上到不了这里，但算法一旦有疏漏就会变成死循环或错位，
  // 所以留一条保底的螺旋搜索：一定能找到位置，只是不够紧凑。
  final step = radii.isEmpty ? 0.05 : radii.first * 0.35;
  for (var ring = 1; ring <= 200; ring++) {
    final dist = ring * step;
    for (var a = 0; a < 120; a++) {
      final ang = a * math.pi / 60;
      final c = math.Point(dist * math.cos(ang), dist * math.sin(ang));
      if (_fits(c, r, radii, centers, padding)) return c;
    }
  }
  return math.Point(centers.last.x + radii.last + r + padding, centers.last.y);
}

/// 与两个已放置的圆同时相切的圆心位置（0 或 2 个解）
Iterable<math.Point<double>> _tangentPoints(
  math.Point<double> pj,
  double rj,
  math.Point<double> pk,
  double rk,
  double r,
) sync* {
  final dj = r + rj;
  final dk = r + rk;
  final dx = pk.x - pj.x;
  final dy = pk.y - pj.y;
  final d = math.sqrt(dx * dx + dy * dy);
  if (d < 1e-9) return;
  // 三角形不等式：两根绳子够不到彼此就没有解
  if (d > dj + dk || d < (dj - dk).abs()) return;

  final a = (dj * dj - dk * dk + d * d) / (2 * d);
  final h2 = dj * dj - a * a;
  if (h2 < 0) return;
  final h = math.sqrt(h2);

  final ux = dx / d;
  final uy = dy / d;
  final mx = pj.x + a * ux;
  final my = pj.y + a * uy;

  yield math.Point(mx - h * uy, my + h * ux);
  yield math.Point(mx + h * uy, my - h * ux);
}

bool _fits(
  math.Point<double> c,
  double r,
  List<double> radii,
  List<math.Point<double>> centers,
  double padding,
) {
  for (var m = 0; m < centers.length; m++) {
    final dx = c.x - centers[m].x;
    final dy = c.y - centers[m].y;
    final need = r + radii[m] + padding;
    // 留一点容差：相切解本身是浮点算出来的，严格 `<` 会因末位误差误判
    if (dx * dx + dy * dy < need * need - 1e-6) return false;
  }
  return true;
}
