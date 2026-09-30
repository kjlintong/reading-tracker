import 'dart:convert';

/// 微信读书「年度统计」的解包。
///
/// 这份原始报文在导入微信读书数据时就整包存进了 settings（键名
/// `wereadAnnualStats`），但一直没有被统计页消费——于是界面上
/// 「阅读时长 0 分钟、连续阅读 0 天」，而数据其实躺在库里：
/// `annual.totalReadTime` 秒、`readDays` 天、`readTimes` 逐月秒数。
///
/// 刻意做成不依赖 sqflite 的纯解析器：微信读书的字段命名改过几轮
/// （`totalReadTime` / `readTimes` / `readStat`），这类兼容逻辑最需要
/// 单测盯着，而解析器一旦碰数据库就没法在纯 Dart 环境里跑。
class WereadAnnualStats {
  /// 统计所属年份。报文里没有就取 `readTimes` 里最早那个月。
  final int year;

  /// 全年累计阅读秒数。
  final int totalReadSec;

  /// 全年有阅读记录的天数。
  final int readDays;

  /// 日均阅读秒数（服务端给的，没有就按 [totalReadSec] / [readDays] 估算）。
  final int dayAvgReadSec;

  /// 逐月阅读量，按时间升序。
  final List<MonthlyReading> monthly;

  const WereadAnnualStats({
    required this.year,
    required this.totalReadSec,
    required this.readDays,
    required this.dayAvgReadSec,
    required this.monthly,
  });

  int get totalReadMinutes => (totalReadSec / 60).round();

  int get dayAvgMinutes => (dayAvgReadSec / 60).round();

  bool get isEmpty => totalReadSec == 0 && monthly.isEmpty && readDays == 0;

  /// 解析存的原始 JSON。任何异常都返回 null——
  /// 统计页少一张图不能变成整页崩掉。
  static WereadAnnualStats? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;

    // 正常是 {year, annual:{...}, overall:{...}}；但也兼容直接给 annual 体
    final root = Map<Object?, Object?>.from(decoded);
    final annualRaw = root['annual'];
    final a = annualRaw is Map
        ? Map<Object?, Object?>.from(annualRaw)
        : root;

    final monthly = <MonthlyReading>[];
    final readTimes = a['readTimes'];
    if (readTimes is Map) {
      for (final e in readTimes.entries) {
        final epoch = int.tryParse('${e.key}');
        final sec = _asInt(e.value);
        if (epoch == null || sec == null) continue;
        // 键是「该月 1 号的 epoch 秒」（服务端按 UTC 给），
        // 用 UTC 解析才不会在时区偏移下把月份挪错一格
        final d = DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true);
        monthly.add(MonthlyReading(year: d.year, month: d.month, seconds: sec));
      }
    }
    monthly.sort((x, y) => x.year == y.year
        ? x.month.compareTo(y.month)
        : x.year.compareTo(y.year));

    final monthSum = monthly.fold<int>(0, (s, m) => s + m.seconds);
    // totalReadTime 缺失就用逐月累加兜底——两者本应是同一个数
    final total = _asInt(a['totalReadTime']) ?? monthSum;

    final readDays = _asInt(a['readDays']) ?? 0;
    var dayAvg = _asInt(a['dayAverageReadTime']) ?? 0;
    if (dayAvg == 0 && readDays > 0 && total > 0) {
      dayAvg = (total / readDays).round();
    }

    final year = _asInt(root['year']) ??
        (monthly.isNotEmpty ? monthly.first.year : DateTime.now().year);

    final stats = WereadAnnualStats(
      year: year,
      totalReadSec: total == 0 ? monthSum : total,
      readDays: readDays,
      dayAvgReadSec: dayAvg,
      monthly: monthly,
    );
    return stats.isEmpty ? null : stats;
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) {
      final t = v.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t) ?? double.tryParse(t)?.round();
    }
    return null;
  }
}

/// 单月阅读量
class MonthlyReading {
  final int year;
  final int month;
  final int seconds;

  const MonthlyReading({
    required this.year,
    required this.month,
    required this.seconds,
  });

  int get minutes => (seconds / 60).round();

  double get hours => seconds / 3600;

  /// 「1 月」这样的轴标签
  String get label => '$month 月';
}
