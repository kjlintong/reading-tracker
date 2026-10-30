import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/services/auto_backup.dart';

/// 自动备份的纯函数单测。
///
/// 这些函数不碰数据库、不发 I/O，单独抽出是为了能穷举边界——自动备份一旦
/// 逻辑写错（比如「每周」被判定成「从不备份」或「每次都备份」），用户很难察觉，
/// 要到丢数据那天才发现备份从来没轮到过。所以这里把「到点没」「文件名」「槽位轮转」
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

  group('备份文件名（固定槽位）', () {
    test('按槽位号生成固定名', () {
      expect(AutoBackup.backupFileName(1), 'readnest-backup-1.json');
      expect(AutoBackup.backupFileName(2), 'readnest-backup-2.json');
    });

    test('文件名不含时间戳——这是占用恒定的关键', () {
      for (final n in AutoBackup.slotFileNames) {
        expect(n, isNot(contains('20'))); // 不含年份
      }
      expect(AutoBackup.slotFileNames.length, AutoBackup.keepCount);
    });

    test('越界槽位号收敛到有效范围', () {
      expect(AutoBackup.backupFileName(0), 'readnest-backup-1.json');
      expect(AutoBackup.backupFileName(99), 'readnest-backup-4.json');
      expect(AutoBackup.backupFileName(-3), 'readnest-backup-1.json');
    });
  });

  group('槽位轮转（挑该覆盖哪一份）', () {
    final s1 = 'readnest-backup-1.json';
    final s2 = 'readnest-backup-2.json';
    final s3 = 'readnest-backup-3.json';
    final s4 = 'readnest-backup-4.json';

    test('一个都没有 → 从 1 号槽开始写', () {
      expect(AutoBackup.pickOverwriteSlot([], []), 1);
    });

    test('只有 1 号存在 → 写 2 号（不动已有的那份）', () {
      expect(AutoBackup.pickOverwriteSlot([s1], [s1]), 2);
    });

    test('有缺口时填缺口，而不是覆盖已存在的', () {
      // 3 号缺失 → 应该写 3 号
      expect(AutoBackup.pickOverwriteSlot([s1, s2, s4], [s1, s2, s4]), 3);
    });

    test('四个都在 → 覆盖最旧的那个（order 第一个）', () {
      final existing = [s1, s2, s3, s4];
      expect(AutoBackup.pickOverwriteSlot(existing, [s2, s1, s4, s3]), 2);
      expect(AutoBackup.pickOverwriteSlot(existing, [s3, s4, s1, s2]), 3);
    });

    test('order 为空时退化为覆盖编号最小的（仍是固定集合，不增生）', () {
      final existing = [s1, s2, s3, s4];
      expect(AutoBackup.pickOverwriteSlot(existing, []), 1);
    });

    test('认不出的文件名不参与判断（用户自己的文件不碰）', () {
      // 目录里有个不认识的文件，不该被当成槽位
      final existing = [s1, 'my-own-file.json', 'reading-tracker-20261010.json'];
      final slot = AutoBackup.pickOverwriteSlot(existing, [s1]);
      expect(slot, 2);
      expect(AutoBackup.backupFileName(slot), isNot(contains('my-own')));
    });

    test('轮转不会产生第 5 个文件名——占用上限恒为 keepCount', () {
      // 模拟连续备份 20 次，文件名集合始终不变
      final set = <String>{};
      var existing = <String>[];
      for (var i = 0; i < 20; i++) {
        final slot = AutoBackup.pickOverwriteSlot(existing, existing);
        final name = AutoBackup.backupFileName(slot);
        set.add(name);
        if (!existing.contains(name)) existing = [...existing, name];
      }
      expect(set.length, lessThanOrEqualTo(AutoBackup.keepCount));
      expect(set.length, AutoBackup.keepCount);
    });
  });

  group('旧格式文件清理', () {
    test('认得出旧版自动备份命名', () {
      expect(
        AutoBackup.legacyAutoBackupNames([
          'reading-tracker-auto-20261010-1230.json',
          'reading-tracker-auto-20260101-0000.json',
        ]),
        hasLength(2),
      );
    });

    test('用户手动导出的文件不算旧垃圾（不能删）', () {
      final legacy = AutoBackup.legacyAutoBackupNames([
        'reading-tracker-20261010.json',
        'readnest-backup-1.json',
        '我的笔记.json',
        'notes.json',
      ]);
      expect(legacy, isEmpty);
    });

    test('只清理带 auto 的旧自动备份，不动同名前缀的手动导出', () {
      final legacy = AutoBackup.legacyAutoBackupNames([
        'reading-tracker-auto-20261010-1230.json',
        'reading-tracker-20261010.json',
      ]);
      expect(legacy, ['reading-tracker-auto-20261010-1230.json']);
    });
  });
}
