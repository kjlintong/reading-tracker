import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/services/auto_shelve.dart';

/// 一本用于判定的书。
///
/// 三个时间字段给的是三件事：[lastReadAt] 是最后一次阅读行为，[startedAt] 是
/// 开读，[createdAt] 是入架。判定按这个优先级回退，所以下面的用例常常只填其中
/// 一个，看它有没有正确落到该用的那个上——而不是被更旧的日期带偏。
Book _book({
  String id = 'b1',
  BookStatus status = BookStatus.reading,
  String? lastReadAt,
  String? lastProgressAt,
  String? startedAt,
  String? createdAt,
  bool isBorrowed = false,
  String? dueAt,
}) =>
    Book(
      id: id,
      title: '某本书',
      status: status,
      createdAt: createdAt ?? '2026-01-01T00:00:00.000',
      updatedAt: createdAt ?? '2026-01-01T00:00:00.000',
      startedAt: startedAt,
      lastReadAt: lastReadAt,
      lastProgressAt: lastProgressAt,
      isBorrowed: isBorrowed,
      dueAt: dueAt,
    );

String _iso(DateTime d) => d.toIso8601String();

void main() {
  final now = DateTime(2026, 10, 10, 12);

  group('最后一次活动时间', () {
    test('有 lastReadAt 就以它为准', () {
      final b = _book(
        lastReadAt: '2026-10-01T00:00:00.000',
        startedAt: '2020-01-01T00:00:00.000',
        createdAt: '2019-01-01T00:00:00.000',
      );
      expect(AutoShelve.lastActivity(b), DateTime(2026, 10, 1));
    });

    test('没有 lastReadAt 就回落到开读日期', () {
      final b = _book(
        startedAt: '2020-01-01T00:00:00.000',
        createdAt: '2019-01-01T00:00:00.000',
      );
      expect(AutoShelve.lastActivity(b), DateTime(2020, 1, 1));
    });

    test('两个都没有回落到入架日期', () {
      final b = _book(createdAt: '2019-01-01T00:00:00.000');
      expect(AutoShelve.lastActivity(b), DateTime(2019, 1, 1));
    });

    test('日期非法就跳过去看下一个', () {
      final b = _book(
        lastReadAt: '不是日期',
        startedAt: '2020-01-01T00:00:00.000',
      );
      expect(AutoShelve.lastActivity(b), DateTime(2020, 1, 1));
    });

    test('全都算不出来时返回空值（调用方按「没闲置」处理）', () {
      final b = _book(lastReadAt: 'x', startedAt: 'y', createdAt: 'z');
      expect(AutoShelve.lastActivity(b), isNull);
    });
  });

  group('闲置天数', () {
    test('正好 60 天', () {
      final b = _book(lastReadAt: _iso(now.subtract(const Duration(days: 60))));
      expect(AutoShelve.idleDaysOf(b, now), 60);
    });

    test('差一天就是 59', () {
      final b = _book(lastReadAt: _iso(now.subtract(const Duration(days: 59))));
      expect(AutoShelve.idleDaysOf(b, now), 59);
    });

    test('跨年也能算对', () {
      final b = _book(lastReadAt: '2025-12-25T00:00:00.000');
      expect(AutoShelve.idleDaysOf(b, DateTime(2026, 3, 1)), 66);
    });

    test('算不出活动时间就当今天刚动过', () {
      expect(AutoShelve.idleDaysOf(_book(createdAt: 'z'), now), 0);
    });

    test('未来的日期夹到 0，不会算出负数', () {
      final b = _book(lastReadAt: _iso(now.add(const Duration(days: 5))));
      expect(AutoShelve.idleDaysOf(b, now), 0);
    });
  });

  group('进度变化的活动时间', () {
    test('有 lastProgressAt 就以它为准', () {
      final b = _book(
        lastProgressAt: '2026-10-01T00:00:00.000',
        startedAt: '2020-01-01T00:00:00.000',
      );
      expect(AutoShelve.lastProgressActivity(b), DateTime(2026, 10, 1));
    });

    test('没有 lastProgressAt 就回落到开读日期', () {
      final b = _book(
        startedAt: '2020-01-01T00:00:00.000',
        createdAt: '2019-01-01T00:00:00.000',
      );
      expect(AutoShelve.lastProgressActivity(b), DateTime(2020, 1, 1));
    });

    test('进度刚好停了 60 天', () {
      final b = _book(
          lastProgressAt: _iso(now.subtract(const Duration(days: 60))));
      expect(AutoShelve.progressIdleDaysOf(b, now), 60);
    });

    test('进度还新鲜着就不算闲置', () {
      final b = _book(
          lastProgressAt: _iso(now.subtract(const Duration(days: 10))));
      expect(AutoShelve.progressIdleDaysOf(b, now), 10);
    });
  });

  group('该不该挪到搁置', () {
    test('闲置刚好满 60 天就挪', () {
      final b = _book(lastReadAt: _iso(now.subtract(const Duration(days: 60))));
      expect(AutoShelve.shouldShelve(b, now), isTrue);
    });

    test('差一天就先留着', () {
      final b = _book(lastReadAt: _iso(now.subtract(const Duration(days: 59))));
      expect(AutoShelve.shouldShelve(b, now), isFalse);
    });

    test('刚读过的绝不动', () {
      expect(AutoShelve.shouldShelve(_book(lastReadAt: _iso(now)), now), isFalse);
    });

    test('只管在读的书，其余状态一律不动', () {
      for (final s in [
        BookStatus.wish,
        BookStatus.finished,
        BookStatus.shelved,
      ]) {
        final b = _book(
          status: s,
          lastReadAt: _iso(now.subtract(const Duration(days: 500))),
        );
        expect(AutoShelve.shouldShelve(b, now), isFalse, reason: '$s 不该被挪');
      }
    });

    test('借来的书不挪', () {
      // 有还期，读不读到时候都得还。标成搁置会让人以为这本不用管了，然后忘还。
      final b = _book(
        isBorrowed: true,
        lastReadAt: _iso(now.subtract(const Duration(days: 500))),
      );
      expect(AutoShelve.shouldShelve(b, now), isFalse);
    });

    test('有应还日期的不挪', () {
      final b = _book(
        dueAt: '2026-11-01T00:00:00.000',
        lastReadAt: _iso(now.subtract(const Duration(days: 500))),
      );
      expect(AutoShelve.shouldShelve(b, now), isFalse);
    });

    test('排了计划的书不挪，没排的照挪', () {
      // 用户明确排了期，什么时候放弃该他自己定，系统不能替他决定。
      final b = _book(lastReadAt: _iso(now.subtract(const Duration(days: 500))));
      expect(AutoShelve.shouldShelve(b, now, busyBookIds: {b.id}), isFalse);
      expect(AutoShelve.shouldShelve(b, now, busyBookIds: {'别的书'}), isTrue);
    });

    test('时间全空的书不会被误杀', () {
      expect(AutoShelve.shouldShelve(_book(createdAt: 'zzz'), now), isFalse);
    });
  });

    test('很久没读但进度还新鲜 → 不挪（只推进不点读过也留住）', () {
      // 模拟「每天翻几页却从没点过『今天读了』」：阅读行为停在 200 天前，
      // 但进度三天前刚推进过。两个信号任一新鲜就留住，所以不该挪。
      final b = _book(
        lastReadAt: _iso(now.subtract(const Duration(days: 200))),
        lastProgressAt: _iso(now.subtract(const Duration(days: 3))),
      );
      expect(AutoShelve.shouldShelve(b, now), isFalse);
    });

    test('进度也停在三年前 → 两个信号都失效 → 挪', () {
      final b = _book(
        lastReadAt: _iso(now.subtract(const Duration(days: 200))),
        lastProgressAt: _iso(now.subtract(const Duration(days: 1100))),
      );
      expect(AutoShelve.shouldShelve(b, now), isTrue);
    });

    test('两个信号都无记录且入架已久 → 挪', () {
      final b = _book(createdAt: '2020-01-01T00:00:00.000');
      expect(AutoShelve.shouldShelve(b, now), isTrue);
    });

  group('节流用的日期键', () {
    test('月和日都要补零', () {
      expect(AutoShelve.dayKey(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('两位数不用补', () {
      expect(AutoShelve.dayKey(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('整批待搁置', () {
    test('空书架返回空', () {
      expect(AutoShelve.pendingShelve([], now), isEmpty);
    });

    test('只捞出闲置满期的在读书，其余状态原样留下', () {
      final fresh = _book(id: 'fresh', lastReadAt: _iso(now));
      final stale = _book(id: 'stale', lastReadAt: _iso(now.subtract(const Duration(days: 200))));
      final wish = _book(id: 'wish', status: BookStatus.wish, lastReadAt: _iso(now.subtract(const Duration(days: 200))));
      final out = AutoShelve.pendingShelve([fresh, stale, wish], now);
      expect(out.map((b) => b.id).toList(), ['stale']);
    });

    test('有计划的书即使闲置也不在结果里', () {
      final stale = _book(id: 'stale', lastReadAt: _iso(now.subtract(const Duration(days: 200))));
      final out = AutoShelve.pendingShelve([stale], now, busyBookIds: {'stale'});
      expect(out, isEmpty);
    });

    test('借来的书即使闲置也不在结果里', () {
      final borrowed = _book(
        id: 'borrowed',
        isBorrowed: true,
        lastReadAt: _iso(now.subtract(const Duration(days: 200))),
      );
      expect(AutoShelve.pendingShelve([borrowed], now), isEmpty);
    });
  });
}
