import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/enums.dart';

/// 闲置的在读书，自动挪到「搁置」。
///
/// **这套规则为什么存在**：「在读」是一个**状态**，不是一次动作。一本三年前
/// 翻开就再没碰过的书，状态栏至今写着「在读」——它年年出现在年报的在读清单
/// 里，也年年被算进「今年在读 N 本」。用户不手动改，它就永远挂在那儿。
///
/// 有了 `Book.lastReadAt` 之后才量得出闲置时长。闲置超过 [idleDays] 天的挪到
/// 「搁置」——不是删除，也不是惩罚，状态随时能改回来，而改回「在读」时会顺手
/// 刷新最后一次阅读时间，不会刚恢复又被挪走。
///
/// **判定必须抽成纯函数**：这条规则会批量改动用户数据，改错一次很难察觉，
/// 而且跨月跨年的边界靠肉眼读代码看不出来。穷举测试是唯一能钉死它的办法。
class AutoShelve {
  AutoShelve._();

  /// 闲置满这么多天，认为读者已经放下了。
  ///
  /// 两个月对多数人的阅读节奏是个安全值：既不太可能误伤出差、考试这类短期
  /// 中断，也不至于等太久让清单里堆满僵尸书。
  static const int idleDays = 60;

  /// 设置键：是否启用自动搁置。默认见 settings 初始化，用户可在设置页关掉。
  static const String enabledKey = 'auto_shelve_enabled';

  /// 设置键：上次执行的日期（yyyy-MM-dd）。用来做到一天最多跑一次，
  /// 免得每次进 App 都对整座书架做一遍判断。
  static const String lastRunKey = 'auto_shelve_last_run';

  /// 这本书最后一次被读者动了的时间。
  ///
  /// 依次取 `lastReadAt` → `startedAt` → `createdAt`。前两个是明确的阅读行为，
  /// 第三个只是入架。兜底到入架日期是**有意往乐观方向估**：真实的下一次阅读
  /// 行为一定发生在这之后，估早了只会让闲置天数算少一点，于是少搁置；
  /// 反过来估晚则会错杀用户还在读的书。这条规则不可逆，宁漏不杀。
  ///
  /// 算不出来（日期全空或全是非法字符串）返回 null，调用方按「没闲置」处理。
  @visibleForTesting
  static DateTime? lastActivity(Book b) {
    for (final s in <String?>[b.lastReadAt, b.startedAt, b.createdAt]) {
      if (s == null || s.isEmpty) continue;
      final t = DateTime.tryParse(s);
      if (t != null) return t;
    }
    return null;
  }

  /// 闲置了多少天。
  ///
  /// 算不出活动时间的返回 0（当作今天刚动过），结果为负（日期在未来，比如用户
  /// 改过系统时间）也夹到 0——负天数会让后面「满 60 天」的判断失效。
  @visibleForTesting
  static int idleDaysOf(Book b, DateTime now) {
    final last = lastActivity(b);
    if (last == null) return 0;
    final d = now.difference(last).inDays;
    return d < 0 ? 0 : d;
  }

  /// 这本书最后一次「进度变化」的时间。
  ///
  /// 与 [lastActivity]（阅读行为）同源但看另一件事：你在书里推进了多少。
  /// 一本你每天翻几页但从没点过「今天读了」的书，阅读行为是空的，进度却是
  /// 新鲜的——它显然还在读，不该被搁置。所以进度变化本身是一个独立的活跃
  /// 信号，和「今天读了」互相不替代。
  ///
  /// 兜底顺序同样是 `startedAt` → `createdAt`：开了头就是有过进度，没开头
  /// 就当入架那天。算不出来返回 null，调用方按「没闲置」处理。
  @visibleForTesting
  static DateTime? lastProgressActivity(Book b) {
    for (final s in <String?>[b.lastProgressAt, b.startedAt, b.createdAt]) {
      if (s == null || s.isEmpty) continue;
      final t = DateTime.tryParse(s);
      if (t != null) return t;
    }
    return null;
  }

  /// 进度闲置了多少天（基于 [lastProgressActivity]）。
  @visibleForTesting
  static int progressIdleDaysOf(Book b, DateTime now) {
    final last = lastProgressActivity(b);
    if (last == null) return 0;
    final d = now.difference(last).inDays;
    return d < 0 ? 0 : d;
  }

  /// 这本书该不该被挪到搁置。
  ///
  /// **两个「活跃信号」必须同时失效才挪**：
  ///  1) [idleDaysOf] ≥ [idleDays]——60 天没「读过」（没点过「今天读了」，
  ///     也没标过在读）；
  ///  2) [progressIdleDaysOf] ≥ [idleDays]——60 天进度没变（没推进过页码）。
  ///
  /// 只读不推进（比如重读已读完的书）和只推进不点「读过」都不算放下，
  /// 两个信号互相独立，任一新鲜就留住这本书。这样就不会出现「我明明每天
  /// 都在翻，却因为从没点过那个按钮而被挪到搁置」的误杀。
  ///
  /// [busyBookIds] 传「有未完成阅读计划的书」的 id 集合：这些书读者明确排了
  /// 期，哪怕很久没动，什么时候放弃也该由他自己说了算，系统不能替他决定。
  @visibleForTesting
  static bool shouldShelve(
    Book b,
    DateTime now, {
    Set<String> busyBookIds = const <String>{},
  }) {
    // 只对「在读」生效：想读的书本来就没开始，不存在「放下了」的说法
    if (b.status != BookStatus.reading) return false;

    // 借来的书有应还日期，读不读完到期都得还。把它标成搁置既没意义，
    // 还会让读者以为这本书不用管了，结果忘了还。
    if (b.isBorrowed) return false;
    if (b.dueAt != null && b.dueAt!.isNotEmpty) return false;

    if (busyBookIds.contains(b.id)) return false;

    return idleDaysOf(b, now) >= idleDays &&
        progressIdleDaysOf(b, now) >= idleDays;
  }

  /// 日期键（yyyy-MM-dd），用于「一天只跑一次」的节流。
  static String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 整座书架里，这一刻应当被挪到「搁置」的书。
  ///
  /// 只是把 [shouldShelve] 套到每本书上。抽成独立方法是为了能在测试里
  /// 直接穷举判定结果，而不用伪造一整套书架数据库去驱动执行器。
  static List<Book> pendingShelve(
    List<Book> shelf,
    DateTime now, {
    Set<String> busyBookIds = const <String>{},
  }) =>
      shelf.where((b) => shouldShelve(b, now, busyBookIds: busyBookIds)).toList();
}
