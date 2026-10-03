import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ui/palette.dart';

/// 图表配色的可辨识性约束。
///
/// 配色看起来是纯审美问题，但这里的每一条都对应一个具体的显示故障：
/// 颜色不够多会有两个分类同色（图和图例对不上号），
/// 用取模取色会把「同色」这件事藏到第 N 个分类才暴露。
void main() {
  group('图表配色', () {
    test('前 12 个分类颜色互不相同', () {
      final colors = [for (var i = 0; i < 12; i++) chartColorAt(i)];
      expect(colors.toSet().length, 12,
          reason: '画像页最多展示 12 类，撞色会让图和图例对不上号');
    });

    test('超出调色板长度也能给出颜色，不回绕复用', () {
      expect(chartColorAt(chartPalette.length), isNot(chartColorAt(0)));
      // 越界下标不能抛异常
      expect(chartColorAt(50), isNotNull);
      expect(chartColorAt(-1), isNotNull);
    });

    test('按展示顺序生成「分类名 → 颜色」映射', () {
      final m = chartColorsFor(['文学', '哲学', '历史']);
      expect(m['文学'], chartColorAt(0));
      expect(m['哲学'], chartColorAt(1));
      expect(m['历史'], chartColorAt(2));
      expect(m.length, 3);
    });
  });
}
