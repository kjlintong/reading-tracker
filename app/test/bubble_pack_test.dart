import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/bubble_pack.dart';

/// 气泡排版的不变量。
///
/// 「不重叠」和「不越界」是这类算法最容易在后续小改中悄悄破掉的两条——
/// 破掉之后画面上不会报错，只会有一两个圆叠在一起，肉眼未必一眼看出来，
/// 而且只有某些数量组合才触发。所以两条都用暴力两两检查钉住。
void main() {
  List<BubbleInput> inputs(List<num> counts) => [
        for (var i = 0; i < counts.length; i++)
          BubbleInput(label: 'C$i', value: counts[i].toDouble()),
      ];

  double gap(Bubble a, Bubble b) => math.sqrt(
      math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2)) -
      a.radius -
      b.radius;

  group('基本行为', () {
    test('空输入或全零返回空', () {
      expect(packBubbles(const []), isEmpty);
      expect(packBubbles(inputs([0, 0])), isEmpty);
      expect(packBubbles(inputs([-3])), isEmpty);
    });

    test('半径按数量的平方根缩放，面积才与数量成正比', () {
      // 100 : 25 → 半径比 2 : 1（面积比 4 : 1 = 数量比）。
      // 直接拿数量当半径的话，比值会变成 4 : 1，视觉差距被平方放大
      final b = packBubbles(inputs([100, 25]));
      expect(b.length, 2);
      expect(b[1].radius / b[0].radius, closeTo(0.5, 1e-6));
    });

    test('按数量降序，标签跟着数量走', () {
      final b = packBubbles([
        const BubbleInput(label: '小', value: 1),
        const BubbleInput(label: '大', value: 9),
        const BubbleInput(label: '中', value: 4),
      ]);
      expect(b.map((e) => e.label).toList(), ['大', '中', '小']);
      expect(b.first.radius, greaterThan(b.last.radius));
    });

    test('单个圆居中', () {
      final b = packBubbles(inputs([10]), size: 100);
      expect(b.length, 1);
      expect(b.single.x, closeTo(50, 1e-6));
      expect(b.single.y, closeTo(50, 1e-6));
    });

    test('超出上限时只保留最大的若干个', () {
      final b = packBubbles(inputs([for (var i = 1; i <= 20; i++) i]),
          maxBubbles: 5);
      expect(b.length, 5);
      expect(b.first.value, 20);
      expect(b.last.value, 16);
    });

    test('相同输入结果可复现', () {
      final a = packBubbles(inputs([9, 9, 9, 9]));
      final c = packBubbles(inputs([9, 9, 9, 9]));
      for (var i = 0; i < a.length; i++) {
        expect(a[i].x, closeTo(c[i].x, 1e-9));
        expect(a[i].y, closeTo(c[i].y, 1e-9));
      }
    });
  });

  group('不变量', () {
    test('任何两个圆都不重叠', () {
      final b = packBubbles(inputs([30, 22, 17, 12, 9, 7, 5, 4, 3, 3, 2, 1]));
      expect(b.length, 12);
      for (var i = 0; i < b.length; i++) {
        for (var j = i + 1; j < b.length; j++) {
          expect(gap(b[i], b[j]), greaterThanOrEqualTo(-1e-6),
              reason: '$i 与 $j 重叠了');
        }
      }
    });

    test('数量都相同时也不重叠（相切解最紧的情况）', () {
      final b = packBubbles(inputs(List.filled(10, 5)));
      for (var i = 0; i < b.length; i++) {
        for (var j = i + 1; j < b.length; j++) {
          expect(gap(b[i], b[j]), greaterThanOrEqualTo(-1e-6),
              reason: '$i 与 $j 重叠了');
        }
      }
    });

    test('数量差距悬殊时也不重叠', () {
      final b = packBubbles(inputs([1000, 1, 1, 1]));
      for (var i = 0; i < b.length; i++) {
        for (var j = i + 1; j < b.length; j++) {
          expect(gap(b[i], b[j]), greaterThanOrEqualTo(-1e-6),
              reason: '$i 与 $j 重叠了');
        }
      }
    });

    test('全部落在画布内', () {
      const size = 200.0;
      final b = packBubbles(inputs([40, 30, 20, 15, 10, 5]), size: size);
      for (final x in b) {
        expect(x.x - x.radius, greaterThanOrEqualTo(-1e-6));
        expect(x.x + x.radius, lessThanOrEqualTo(size + 1e-6));
        expect(x.y - x.radius, greaterThanOrEqualTo(-1e-6));
        expect(x.y + x.radius, lessThanOrEqualTo(size + 1e-6));
      }
    });

    test('画布至少有一个方向被填满，不会缩成一小团', () {
      const size = 200.0;
      final b = packBubbles(inputs([50, 25, 12, 6, 3]), size: size);
      var w = 0.0;
      var h = 0.0;
      for (final x in b) {
        w = math.max(w, x.x + x.radius);
        h = math.max(h, x.y + x.radius);
      }
      final minX = b.map((e) => e.x - e.radius).reduce(math.min);
      final minY = b.map((e) => e.y - e.radius).reduce(math.min);
      expect(math.max(w - minX, h - minY), closeTo(size, 1e-6));
    });
  });
}
