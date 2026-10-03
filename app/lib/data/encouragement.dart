import '../l10n/app_loc.dart';
import 'dart:math' as math;

/// 基于真实数据的鼓励语。
///
/// 三条硬约束（都是「鼓励文案」这类功能的常见死法）：
///   1. **必须有数字依据**：「继续保持！」在读完 0 本的时候出现就是讽刺；
///   2. **同一天固定同一句**：每次切 tab 都换一句，用户会意识到这是
///      随机语录，随机语录两眼就看穿；按日期播种，一天一句；
///   3. **没有数据时闭嘴**：显示一句通用但不撒谎的话，而不是硬凑。
String encouragementLine({
  required int finished,
  required int streak,
  required int minutes,
  required int total,
  required DateTime now,
}) {
  // 一天一个种子：同一天内切多少次页面都是同一句
  final daySeed = now.year * 10000 + now.month * 100 + now.day;
  final rng = math.Random(daySeed);
  String pick(List<String> list) => list[rng.nextInt(list.length)];

  if (total == 0) {
    return pick( [
      appLoc.s_e8a43314,
      appLoc.s_af03278c,
    ]);
  }

  if (streak >= 3) {
    return pick([
      appLoc.s_f53eead8(streak: streak),
      appLoc.s_ff1565a3(streak: streak),
      appLoc.s_1736f17e(streak: streak),
    ]);
  }

  if (finished >= 10) {
    return pick([
      appLoc.s_9a3fb5e5(finished: finished),
      appLoc.s_9d430ad3(finished: finished),
    ]);
  }

  if (finished >= 1) {
    return pick([
      appLoc.s_597f7c05(finished: finished),
      appLoc.s_1c87153f(finished: finished),
    ]);
  }

  if (minutes >= 30) {
    return pick([
      appLoc.s_41db17b9(minutes: minutes),
      appLoc.s_6a57c553(minutes: minutes),
    ]);
  }

  return pick( [
    appLoc.s_152a88d7,
    appLoc.s_795806c0,
    appLoc.s_aa51bf46,
  ]);
}
