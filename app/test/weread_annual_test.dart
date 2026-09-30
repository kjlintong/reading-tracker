import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/weread_annual.dart';

/// 微信读书年度统计的解包。
///
/// 这份报文整包存在 settings 里，字段名随版本变过
/// （`totalReadTime` / `readTimes` / `readStat`），而且嵌套三层。
/// 解析器一旦写错，症状是统计页安静地少一张图、少两个数字，
/// 不报错、不崩溃——最容易被忽略的那类问题，所以用真实结构钉住。
///
/// 这里的样例直接取自 assets/seed/library.json 的真实形状。
void main() {
  /// readTimes 的键是「该月 1 号的 epoch 秒」
  int epochOf(int year, int month) =>
      DateTime.utc(year, month, 1).millisecondsSinceEpoch ~/ 1000;

  String blob({
    int? totalReadTime,
    Map<int, int> months = const {},
    int? readDays,
    int? dayAvg,
    int? year = 2026,
  }) =>
      jsonEncode({
        'year': year,
        'annual': {
          if (totalReadTime != null) 'totalReadTime': totalReadTime,
          'readTimes': {
            for (final e in months.entries)
              '${epochOf(year ?? 2026, e.key)}': e.value,
          },
          if (readDays != null) 'readDays': readDays,
          if (dayAvg != null) 'dayAverageReadTime': dayAvg,
        },
        'overall': {'readTimes': {}},
      });

  group('解析', () {
    test('读出全年秒数、天数与日均', () {
      final s = WereadAnnualStats.parse(blob(
        totalReadTime: 389553,
        readDays: 73,
        dayAvg: 1432,
        months: {1: 734, 7: 119136, 8: 255879},
      ))!;

      expect(s.year, 2026);
      expect(s.totalReadSec, 389553);
      expect(s.readDays, 73);
      expect(s.dayAvgReadSec, 1432);
      expect(s.totalReadMinutes, 6493); // 389553 / 60
      expect(s.dayAvgMinutes, 24); // 1432 / 60
      expect(s.isEmpty, isFalse);
    });

    test('逐月数据按时间升序，月份不被时区挪位', () {
      // 越界月在前也能排回来
      final s = WereadAnnualStats.parse(blob(
        months: {12: 60, 1: 120, 3: 180},
      ))!;

      expect(s.monthly.map((m) => m.month).toList(), [1, 3, 12]);
      expect(s.monthly.first.label, '1 月');
      expect(s.monthly.first.minutes, 2);
      expect(s.monthly.first.hours, closeTo(0.0333, 0.001));
    });

    test('totalReadTime 缺失时用逐月累加兜底', () {
      final s = WereadAnnualStats.parse(blob(months: {1: 600, 2: 600}))!;
      expect(s.totalReadSec, 1200);
    });

    test('只额外给 readTimes 却给了 totalReadTime 时以 total 为准', () {
      // 服务端的 total 口径可能包含逐月没覆盖的部分
      final s = WereadAnnualStats.parse(blob(
        totalReadTime: 9999,
        months: {1: 600},
      ))!;
      expect(s.totalReadSec, 9999);
    });

    test('没给日均就按总时长/天数估算', () {
      final s = WereadAnnualStats.parse(
          blob(totalReadTime: 7200, readDays: 10))!;
      expect(s.dayAvgReadSec, 720);
      expect(s.dayAvgMinutes, 12);
    });

    test('没给日均也没给天数时日均为 0，而不是拿 365 去凑', () {
      // 拿总时长除以 365 会把「只用了三个月」的重度用户压成一个假数字
      final s = WereadAnnualStats.parse(blob(totalReadTime: 7200))!;
      expect(s.readDays, 0);
      expect(s.dayAvgReadSec, 0);
    });

    test('数值以字符串给出也能读', () {
      final s = WereadAnnualStats.parse(jsonEncode({
        'year': '2026',
        'annual': {'totalReadTime': '3600', 'readDays': '5'},
      }))!;
      expect(s.totalReadSec, 3600);
      expect(s.readDays, 5);
    });

    test('没有 year 字段时取最早那个月所属年', () {
      final s = WereadAnnualStats.parse(jsonEncode({
        'annual': {
          'readTimes': {'${epochOf(2025, 11)}': 60, '${epochOf(2026, 1)}': 60},
        },
      }))!;
      expect(s.year, 2025);
    });

    test('直接给 annual 体（没有外层包裹）也能解析', () {
      final s = WereadAnnualStats.parse(jsonEncode({
        'totalReadTime': 3600,
        'readDays': 3,
      }))!;
      expect(s.totalReadSec, 3600);
      expect(s.readDays, 3);
    });
  });

  group('容错：宁可少一张图，也不能让统计页崩掉', () {
    test('null / 空串 / 非 JSON / 顶层不是对象，一律返回 null', () {
      expect(WereadAnnualStats.parse(null), isNull);
      expect(WereadAnnualStats.parse(''), isNull);
      expect(WereadAnnualStats.parse('   '), isNull);
      expect(WereadAnnualStats.parse('{不是 JSON'), isNull);
      expect(WereadAnnualStats.parse('[1,2,3]'), isNull);
    });

    test('解析成功但全是零 → 视为没有数据（否则会画出一张全是 0 的图）', () {
      expect(WereadAnnualStats.parse(jsonEncode({})), isNull);
      expect(
        WereadAnnualStats.parse(jsonEncode({
          'annual': {'readTimes': {}},
        })),
        isNull,
      );
    });

    test('readTimes 里混入坏键或坏值时跳过它们，不整包丢弃', () {
      final s = WereadAnnualStats.parse(jsonEncode({
        'year': 2026,
        'annual': {
          'totalReadTime': 600,
          'readTimes': {
            'not-a-number': 60,
            '${epochOf(2026, 3)}': 600,
            '${epochOf(2026, 4)}': 'oops',
          },
        },
      }))!;
      expect(s.monthly.length, 1);
      expect(s.monthly.single.month, 3);
    });
  });

  group('示例种子库', () {
    test('整包解析后总时长与逐月累加一致', () {
      final s = WereadAnnualStats.parse(_seedAnnualBlob())!;

      expect(s.year, 2026);
      final months = s.monthly.map((m) => m.month).toSet();
      expect(s.monthly.length, months.length, reason: '逐月数据不能出现重复月份');
      final sum = s.monthly.fold<int>(0, (a, b) => a + b.seconds);
      expect(s.totalReadSec, sum);
      expect(s.readDays, greaterThan(0));
      expect(s.totalReadSec, greaterThan(0));
      // 日均应当是个正常人能读出来的数（几十分钟量级），量级错了说明单位搞混
      expect(s.dayAvgMinutes, inInclusiveRange(1, 600));
    });
  });
}

/// 随包发布的种子库里那段年度统计原文。
///
/// 用真实报文而不是手写样例：字段名或嵌套层级一变，这里立刻变红。
/// 测试的工作目录是 app/，`flutter test` 与 `dart test` 都是。
String _seedAnnualBlob() {
  final payload =
      jsonDecode(File('assets/seed/library.json').readAsStringSync())
          as Map<String, dynamic>;
  return jsonEncode(payload['stats']);
}
