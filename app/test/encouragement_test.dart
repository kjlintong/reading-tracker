import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/encouragement.dart';

void main() {
  String line({
    int finished = 0,
    int streak = 0,
    int minutes = 0,
    int total = 0,
    required DateTime now,
  }) =>
      encouragementLine(
        finished: finished,
        streak: streak,
        minutes: minutes,
        total: total,
        now: now,
      );

  final d1 = DateTime(2026, 9, 30);

  test('同一天固定同一句，跨天才换', () {
    // 每次切 tab 都换一句的话，用户两眼就看出这是随机语录
    final a = line(now: d1, finished: 3, total: 10);
    final b = line(now: d1, finished: 3, total: 10);
    expect(a, b);

    var differs = false;
    for (var day = 2; day <= 28; day++) {
      if (line(now: DateTime(2026, 9, day), finished: 3, total: 10) != a) {
        differs = true;
        break;
      }
    }
    expect(differs, isTrue, reason: '一个月里至少该换过一次');
  });

  test('空书架说的是起步，不是空泛打气', () {
    final s = line(now: d1, total: 0);
    expect(s, isNotEmpty);
    // 一句「加油」在读完 0 本的时候出现就是讽刺
    expect(s, isNot(contains('继续保持')));
  });

  test('有连续天数优先讲节奏', () {
    final s = line(now: d1, streak: 5, finished: 2, total: 10);
    expect(s, contains('5'));
  });

  test('读完本数多的那档会点出本数', () {
    final s = line(now: d1, finished: 12, total: 40);
    expect(s, contains('12'));
  });

  test('只有时长时讲时长', () {
    final s = line(now: d1, minutes: 90, total: 20);
    expect(s, contains('90'));
  });

  test('什么都没有时不硬凑，也不撒谎', () {
    final s = line(now: d1, total: 5);
    expect(s, isNotEmpty);
    // 没有数据就不能出现具体数字——「你读了 0 本，很棒」是嘲讽
    expect(s, isNot(contains('0 本')));
  });
}
