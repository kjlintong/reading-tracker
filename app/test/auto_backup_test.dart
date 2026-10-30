import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/services/auto_backup.dart';

/// 自动备份的纯函数单测。
///
/// 这些函数不碰数据库、不发 I/O，单独抽出是为了能穷举边界——自动备份一旦
/// 逻辑写错（比如「每周」被判定成「从不备份」或「每次都备份」），用户很难察觉，
/// 要到丢数据那天才发现备份从来没轮到过。所以这里把「到点没」「文件名」「滚动保留」
/// 三件事都钉死。
void main() {
  final now = DateTime(2026, 10, 10, 12, 30);

  group('该不该跑', () {
    test('从未备份过（null）→ 跑', () {
      expect(AutoBackup.shouldRun(now, null, 7), isTrue);
    });

    test('时间串乱了（解析失败）→ 当没备份过，跑', () {
      expect(AutoBackup.shouldRun(now, '不是日期', 7), isTrue);
    });

    test('刚好满 7 天 → 跑（含等于）', () {
      final last = now.subtract(const Duration(days: 7));
      expect(AutoBackup.shouldRun(now, last.toIso8601String(), 7), isTrue);
    });

    test('差一天（6 天）→ 不跑', () {
      final last = now.subtract(const Duration(days: 6));
      expect(AutoBackup.shouldRun(now, last.toIso8601String(), 7), isFalse);
    });

    test('超期（10 天）→ 跑', () {
      final last = now.subtract(const Duration(days: 10));
      expect(AutoBackup.shouldRun(now, last.toIso8601String(), 7), isTrue);
    });

    test('间隔是每月（30 天），29 天前的不跑、31 天前的跑', () {
      final near = now.subtract(const Duration(days: 29));
      final far = now.subtract(const Duration(days: 31));
      expect(AutoBackup.shouldRun(now, near.toIso8601String(), 30), isFalse);
      expect(AutoBackup.shouldRun(now, far.toIso8601String(), 30), isTrue);
    });

    test('天数差用整日数算，不足一天不提前触发', () {
      // 6 天 23 小时 → inDays 仍是 6，不该触发。
      final last = now.subtract(const Duration(days: 6, hours: 23));
      expect(AutoBackup.shouldRun(now, last.toIso8601String(), 7), isFalse);
    });
  });

  group('备份文件名', () {
    test('格式 reading-tracker-auto-YYYYMMDD-HHMM.json', () {
      expect(
        AutoBackup.backupFileName(DateTime(2026, 10, 10, 12, 30)),
        'reading-tracker-auto-20261010-1230.json',
      );
    });

    test('个位数的月日时分补零', () {
      expect(
        AutoBackup.backupFileName(DateTime(2026, 1, 5, 3, 9)),
        'reading-tracker-auto-20260105-0309.json',
      );
    });
  });

  group('滚动保留', () {
    test('不超过 keep 就不删', () {
      final hist = ['a', 'b', 'c'];
      expect(AutoBackup.pruneHistory(hist, 5), isEmpty);
    });

    test('刚好等于 keep 也不删', () {
      final hist = ['a', 'b', 'c', 'd', 'e'];
      expect(AutoBackup.pruneHistory(hist, 5), isEmpty);
    });

    test('超出 keep 时，删掉最旧的那几个（文件名含时间，字典序=时间序）', () {
      final hist = [
        'reading-tracker-auto-20260101-0000.json',
        'reading-tracker-auto-20260201-0000.json',
        'reading-tracker-auto-20260301-0000.json',
        'reading-tracker-auto-20260401-0000.json',
        'reading-tracker-auto-20260501-0000.json',
        'reading-tracker-auto-20260601-0000.json',
        'reading-tracker-auto-20260701-0000.json',
      ];
      // keep=5 → 删最旧的 2 个
      final toDelete = AutoBackup.pruneHistory(hist, 5);
      expect(toDelete.length, 2);
      expect(toDelete, contains('reading-tracker-auto-20260101-0000.json'));
      expect(toDelete, contains('reading-tracker-auto-20260201-0000.json'));
      // 最新的 5 个必须留下来
      expect(toDelete, isNot(contains('reading-tracker-auto-20260701-0000.json')));
    });
  });
}
