import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/stats_prefs.dart';

/// 图表可见性偏好的编解码。
///
/// 这层唯一值得测的东西是「坏数据不能把统计页搞崩」和
/// 「新增的图默认可见」——两条都是那种上线后才发现就太晚的问题。
void main() {
  group('decodeHiddenCharts', () {
    test('null / 空串 = 一张都不隐藏', () {
      expect(decodeHiddenCharts(null), isEmpty);
      expect(decodeHiddenCharts(''), isEmpty);
      expect(decodeHiddenCharts('   '), isEmpty);
    });

    test('正常解码', () {
      final h = decodeHiddenCharts('status,rating');
      expect(h, {'status', 'rating'});
    });

    test('容忍多余空白与空段', () {
      expect(decodeHiddenCharts(' status , , rating ,'), {'status', 'rating'});
    });

    test('丢掉不认识的 id', () {
      // 版本回退 / 手工改库都可能出现这种情况。留着会让「已隐藏 N 张」
      // 的数字大于实际能被隐藏的张数，界面上就成了一个解释不清的错觉。
      expect(decodeHiddenCharts('status,ghost_chart'), {'status'});
      expect(decodeHiddenCharts('nonsense'), isEmpty);
    });
  });

  group('encodeHiddenCharts', () {
    test('空集合编码成空串', () {
      expect(encodeHiddenCharts(<String>{}), '');
    });

    test('顺序稳定：按 StatsChart.all 的声明序，不按 Set 的插入序', () {
      // 这个断言防的是「同一份偏好，两次编码出两个字符串」——
      // 那样每次进设置页都会被判定成「有改动」而回写一次 KV。
      final a = encodeHiddenCharts({'source', 'status'});
      final b = encodeHiddenCharts({'status', 'source'});
      expect(a, 'status,source');
      expect(a, b);
    });

    test('未知 id 不写进去', () {
      expect(encodeHiddenCharts({'status', 'ghost'}), 'status');
    });

    test('编码 → 解码是恒等变换', () {
      final s = {StatsChart.trend, StatsChart.progress};
      expect(decodeHiddenCharts(encodeHiddenCharts(s)), s);
    });
  });

  group('StatsChart.all', () {
    test('七个 id 且互不重复', () {
      // 重复会让「全部隐藏」的按钮点下去只隐藏六张，
      // 而「已隐藏 7 张」的提示还在。
      expect(StatsChart.all.length, 7);
      expect(StatsChart.all.toSet().length, 7);
    });
  });
}
