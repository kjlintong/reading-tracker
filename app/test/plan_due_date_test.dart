import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ui/plan_due_date.dart';

/// 截止日选择器的边界计算（对应 issue：编辑已逾期计划时日期打不开）。
///
/// ## 为什么这个测试必须存在
///
/// 旧实现的 `firstDate` 固定为「昨天」，`initialDate` 却是已存的截止日。
/// 计划逾期后，`initialDate < firstDate`：
///
///  - debug 下 `showDatePicker` 断言失败 → 点开日期选择器直接崩；
///  - release 下不报错，日历翻到没有那一天的月份，
///    **存着的截止日从界面上消失，保存后被静默改成别的日期**。
///
/// 后者比崩溃更难发现：没有报错、没有异常，数据却悄悄变了。
/// 所以这里用穷举（而不是一两个例子）钉住三条不变式。
void main() {
  final now = DateTime(2026, 10, 26, 14, 30);

  group('dueDateBounds', () {
    test('新建计划：下限是昨天，初始日是两周后', () {
      final b = dueDateBounds(now);
      expect(b.first, DateTime(2026, 10, 25));
      expect(b.initial, DateTime(2026, 11, 9));
    });

    test('已逾期计划：下限退到已存截止日，初始日就是那个截止日', () {
      // 截止日是 40 天前 —— 远早于「昨天」。
      final b = dueDateBounds(now, existing: DateTime(2026, 9, 16));
      expect(b.first, DateTime(2026, 9, 16));
      expect(b.initial, DateTime(2026, 9, 16));
    });

    test('已逾期一天的计划：下限取「昨天」与截止日里更早的那个', () {
      // 截止日 = 昨天。两者同一天，取更早者即可 —— 仍是昨天。
      final b = dueDateBounds(now, existing: DateTime(2026, 10, 25));
      expect(b.first, DateTime(2026, 10, 25));
      expect(b.initial, DateTime(2026, 10, 25));
    });

    test('未逾期计划：下限仍是昨天，初始日是已存截止日', () {
      final b = dueDateBounds(now, existing: DateTime(2026, 11, 9));
      expect(b.first, DateTime(2026, 10, 25));
      expect(b.initial, DateTime(2026, 11, 9));
    });

    test('今天到期：不能被「昨天」的下限误判成过去', () {
      // 截止日就是今天。下限是昨天，所以今天仍然可选。
      final b = dueDateBounds(now, existing: DateTime(2026, 10, 26));
      expect(b.initial, DateTime(2026, 10, 26));
      expect(b.first, DateTime(2026, 10, 25));
      expect(b.initial.isBefore(b.first), isFalse,
          reason: '初始日绝不能早于下限，否则 showDatePicker 断言失败');
    });

    test('不变式：initial 永不早于 first（showDatePicker 的断言条件）', () {
      // 穷举：从 90 天前到 90 天后，每天都试一遍。
      // 这条不变式一旦破了，debug 下就是断言崩溃，release 下是静默改数据。
      for (var d = -90; d <= 90; d++) {
        final existing = DateTime(2026, 10, 26).add(Duration(days: d));
        final b = dueDateBounds(now, existing: existing);
        expect(b.initial.isBefore(b.first), isFalse,
            reason: '偏移 $d 天时 initial(${b.initial}) < first(${b.first})');
        expect(b.first.isAfter(DateTime(2026, 10, 26)), isFalse,
            reason: '偏移 $d 天时下限跑到了今天之后');
      }
    });

    test('不变式：新建计划的下限不晚于今天', () {
      for (var d = -90; d <= 90; d++) {
        final when = DateTime(2026, 10, 26).add(Duration(days: d));
        final b = dueDateBounds(when);
        expect(b.first.isAfter(dateOnlyOf(when)), isFalse,
            reason: '$when 的下限跑到了当天之后');
        expect(b.initial.isBefore(b.first), isFalse);
      }
    });

    test('跨月跨年边界不串日期', () {
      // 2 月末 → 3 月初
      final feb = DateTime(2026, 2, 27, 23, 59);
      final b1 = dueDateBounds(feb, existing: DateTime(2026, 2, 27));
      expect(b1.initial, DateTime(2026, 2, 27));
      // 12 月末 → 1 月初
      final dec = DateTime(2026, 12, 31, 8, 0);
      final b2 = dueDateBounds(dec, existing: DateTime(2027, 1, 5));
      expect(b2.initial, DateTime(2027, 1, 5));
      expect(b2.first, DateTime(2026, 12, 30));
    });
  });

  group('formatDueDate', () {
    test('补零到 yyyy-MM-dd', () {
      expect(formatDueDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(formatDueDate(DateTime(2026, 10, 26)), '2026-10-26');
      expect(formatDueDate(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('格式与 DateTime.parse 能互转（数据库里存的就是这个串）', () {
      final d = DateTime(2026, 3, 9);
      expect(DateTime.parse(formatDueDate(d)), d);
    });
  });

  group('dateOnlyOf', () {
    test('抹掉时分秒', () {
      final d = dateOnlyOf(DateTime(2026, 10, 26, 23, 59, 59));
      expect(d, DateTime(2026, 10, 26));
      expect(d.hour, 0);
      expect(d.minute, 0);
    });
  });
}
