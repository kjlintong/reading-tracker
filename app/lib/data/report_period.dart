import 'date_range.dart';
import '../l10n/app_loc.dart';

/// 报告周期：年报 / 月报。
///
/// 之前报告页的周期是「2026年至今 / 近30天 / 近90天 / 全部时间」这类
/// 相对区间，问题在于**它们不可归档**：每次点开「近30天」指的是不同的
/// 30 天，生成的报告存下来也不知道该叫什么。用户要的是「年报」「月报」——
/// 一个能对得上日历、能回看、能自动补的周期。
///
/// key 即归档键：`2026` / `2026-09`。历史报告表用 period 列存这个串，
/// 所以 key 的格式一旦发布就不能改，否则老报告认不出来。
class ReportPeriod {
  final String key;
  final String label;

  /// 年报为 true，月报为 false
  final bool isYear;

  final StatsRange range;

  const ReportPeriod({
    required this.key,
    required this.label,
    required this.isYear,
    required this.range,
  });

  factory ReportPeriod.year(int y) => ReportPeriod(
        key: '$y',
        label: appLoc.s_a87cfcc9(y: y),
        isYear: true,
        range: StatsRange.year(y),
      );

  factory ReportPeriod.month(int y, int m) => ReportPeriod(
        key: '$y-${m.toString().padLeft(2, '0')}',
        label: appLoc.s_0e59d960(y: y, m: m),
        isYear: false,
        // 月份区间必须走「自然月」而不是「最近 30 天」：
        // 月报要能和今年其他月份横向比，起点不统一就没法比。
        range: StatsRange.custom(
          DateTime(y, m, 1),
          DateTime(y, m + 1, 1).subtract(const Duration(days: 1)),
        ),
      );

  /// 可选周期列表：年份（近 3 年，新的在前）+ 月份（近 12 个自然月）。
  ///
  /// 月份只给到**已结束的月份**（不含当月）：当月的月报数据还在长，
  /// 生成出来第二天就过期了，属于诱导用户反复生成。
  static List<ReportPeriod> candidates({DateTime? now}) {
    final t = now ?? DateTime.now();
    final out = <ReportPeriod>[];
    for (var i = 0; i < 3; i++) {
      out.add(ReportPeriod.year(t.year - i));
    }
    for (var i = 1; i <= 12; i++) {
      var y = t.year;
      var m = t.month - i;
      while (m <= 0) {
        m += 12;
        y -= 1;
      }
      out.add(ReportPeriod.month(y, m));
    }
    return out;
  }

  /// 默认周期：今年年报
  static ReportPeriod current({DateTime? now}) =>
      ReportPeriod.year((now ?? DateTime.now()).year);

  static ReportPeriod? parse(String? key) {
    if (key == null || key.isEmpty) return null;
    final ym = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(key);
    if (ym != null) {
      return ReportPeriod.month(
        int.parse(ym.group(1)!),
        int.parse(ym.group(2)!),
      );
    }
    final y = int.tryParse(key);
    if (y != null && y > 1900 && y < 3000) return ReportPeriod.year(y);
    return null;
  }

  /// 自动补生成的候选：今年年报 + 上一个自然月的月报。
  ///
  /// 只补「已经结束的周期」——当月月报要等下个月才生成，
  /// 否则用户每开一次页面就多一份只差几天的重复报告。
  static List<ReportPeriod> autoTargets({DateTime? now}) {
    final t = now ?? DateTime.now();
    var y = t.year;
    var m = t.month - 1;
    if (m == 0) {
      m = 12;
      y -= 1;
    }
    return [ReportPeriod.month(y, m), ReportPeriod.year(t.year)];
  }
}
