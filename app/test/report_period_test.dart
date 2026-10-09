import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/report_period.dart';

void main() {
  group('构造', () {
    test('年报 key 是四位年份', () {
      final p = ReportPeriod.year(2026);
      expect(p.key, '2026');
      expect(p.label, '2026 年');
      expect(p.isYear, isTrue);
      expect(p.range.coversWholeYear(2026), isTrue);
    });

    test('月报 key 补零，区间是自然月', () {
      final p = ReportPeriod.month(2026, 9);
      expect(p.key, '2026-09');
      expect(p.label, '2026 年 9 月');
      expect(p.isYear, isFalse);
      // 9 月区间必须整月覆盖：既含 9/1 也含 9/30
      expect(p.range.contains(DateTime(2026, 9, 1)), isTrue);
      expect(p.range.contains(DateTime(2026, 9, 30)), isTrue);
      expect(p.range.contains(DateTime(2026, 8, 31)), isFalse);
      expect(p.range.contains(DateTime(2026, 10, 1)), isFalse);
    });

    test('12 月跨界不能写成年份+13', () {
      final p = ReportPeriod.month(2026, 12);
      expect(p.key, '2026-12');
      expect(p.range.contains(DateTime(2026, 12, 31)), isTrue);
      expect(p.range.contains(DateTime(2027, 1, 1)), isFalse);
    });
  });

  group('解析', () {
    test('从归档 key 还原', () {
      expect(ReportPeriod.parse('2026')!.isYear, isTrue);
      expect(ReportPeriod.parse('2026-09')!.key, '2026-09');
    });

    test('认不出返回 null', () {
      expect(ReportPeriod.parse('近30天'), isNull);
      expect(ReportPeriod.parse(''), isNull);
      expect(ReportPeriod.parse(null), isNull);
      expect(ReportPeriod.parse('0001'), isNull);
    });
  });

  group('候选与自动补生成', () {
    test('候选含近 4 年与近 12 个已结束月份', () {
      final list = ReportPeriod.candidates(now: DateTime(2026, 9, 30));
      expect(list.where((p) => p.isYear).length, 4);
      expect(list.where((p) => !p.isYear).length, 12);
      // 当月不在候选里：当月月报数据还在长，生成出来第二天就过期
      expect(list.any((p) => p.key == '2026-09'), isFalse);
      expect(list.any((p) => p.key == '2026-08'), isTrue);
    });

    test('1 月时回退到去年 12 月', () {
      final list = ReportPeriod.candidates(now: DateTime(2026, 1, 15));
      expect(list.any((p) => p.key == '2025-12'), isTrue);
      expect(list.any((p) => p.key == '2026-01'), isFalse);
    });

    test('自动目标是「上月月报 + 去年年报」', () {
      // 年报取去年而非今年：今年的 12 个月还没走完，
      // 现在就出「今年年报」等于把残缺的一年当全年结论。
      final t = ReportPeriod.autoTargets(now: DateTime(2026, 9, 30));
      expect(t.map((p) => p.key).toList(), ['2026-08', '2025']);
    });

    test('自动目标跨年正确', () {
      final t = ReportPeriod.autoTargets(now: DateTime(2026, 1, 10));
      expect(t.map((p) => p.key).toList(), ['2025-12', '2025']);
    });
  });
}
