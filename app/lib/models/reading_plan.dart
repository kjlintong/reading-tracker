import 'package:flutter/material.dart';

/// 阅读计划的目标类型。
///
/// 只做两种，刻意不做「每周读几本」这类复合/配额型目标：
/// 复合目标需要一套配额折算规则，用户理解成本高，而且很容易
/// 变成「为了达标而读书」。时长与截止日期是最朴素也最真实的两种。
enum PlanKind {
  /// 每天读满一定时长（分钟）
  dailyMinutes,

  /// 在某日期前读完某本书
  finishBook;

  static PlanKind fromString(String? s) => switch (s) {
        'dailyMinutes' => dailyMinutes,
        'finishBook' => finishBook,
        _ => dailyMinutes,
      };
}

/// 一条阅读计划。
///
/// 设计取舍：
///  - **不存「完成度」**，只存目标本身，完成情况在读取时按实时数据算。
///    存快照会让「昨天读到 100% 今天又改了进度」这类情况立刻失真。
///  - [done] 是**计划整体结束**的唯一持久化标记（用户手动结束一条计划）。
///  - [lastDoneOn] 是**每日型计划的「今天已完成」打点**，只记一个日期
///    （yyyy-MM-dd）。它不是「完成」——第二天看到日期不是今天，
///    计划自然回到「待完成」。这是「周期任务」与「一次性任务」的分界：
///    周期任务永远不结束，只标记「这一轮做完了」。
///
/// 为什么不复用 [done]：两者语义相反。`done` 一旦为真，计划就沉到
/// 「已结束」区不再出现；而每日计划标了「今天读完」明天必须还在。
/// 用同一个字段会让两者互相打架。
@immutable
class ReadingPlan {
  final String id;

  final PlanKind kind;

  /// 计划标题。用户可留空，空则由 UI 按类型生成。
  final String? title;

  /// [PlanKind.dailyMinutes] 用：每天目标分钟数。
  final int? dailyMinutes;

  /// [PlanKind.finishBook] 用：目标书 id。
  final String? bookId;

  /// [PlanKind.finishBook] 用：截止日期（yyyy-MM-dd）。
  final String? dueDate;

  /// 是否提醒。默认 false —— 系统通知权限弹窗在没上下文时出现极易被拒，
  /// 必须由用户在明确知道后果的前提下主动打开。
  final bool reminderEnabled;

  /// 计划已整体结束（不再出现在进行中列表）。
  final bool done;

  /// 完成时间（ISO8601）。仅 [done] 为真时有意义。
  final String? doneAt;

  /// 每日型计划的「今天已完成」打点（yyyy-MM-dd）。
  ///
  /// 只对 [PlanKind.dailyMinutes] 有意义。等于今天 = 今天不用再读了；
  /// 是昨天/更早 = 又是一轮新的开始。永远不置 null 之外的「完成态」。
  final String? lastDoneOn;

  /// 每日型计划的逐日打卡记录（yyyy-MM-dd 逗号分隔）。
  ///
  /// 只对 [PlanKind.dailyMinutes] 有意义。用于「连续打卡 N 天」统计，
  /// 也保证「当天完成 → 次日自动回到待完成」这个周期语义有据可查。
  final String? checkins;

  /// 计划创建时间，用于排序与「这个计划立了多久」的统计。
  final String createdAt;

  const ReadingPlan({
    required this.id,
    required this.kind,
    required this.createdAt,
    this.title,
    this.dailyMinutes,
    this.bookId,
    this.dueDate,
    this.reminderEnabled = false,
    this.done = false,
    this.doneAt,
    this.lastDoneOn,
    this.checkins,
  });

  /// 今天是否已经打过卡（仅每日型有意义）。
  ///
  /// 用「日期串相等」而不是「在最近 24 小时内」：用户理解的「今天」
  /// 是日历上的今天，早上 8 点打卡、第二天早上 7 点打开 App 时，
  /// 那确实已经是新的一天了。
  bool doneToday([DateTime? now]) {
    if (lastDoneOn == null) return false;
    final n = now ?? DateTime.now();
    return lastDoneOn == _isoDate(n);
  }

  /// 已打卡的日期集合（yyyy-MM-dd）。
  ///
  /// **必须是可增长的集合**：调用方会拿到它直接 `add` / `remove`
  /// （见 `plan_section.dart` 的打卡逻辑）。以前这里返回 `const {}`，
  /// 于是第一次打卡时 `const {}..add(today)` 抛 `UnsupportedError`——
  /// 异常在 async 链里没人接，表现为「点了完成毫无反应」，
  /// 而且打卡记录永远写不进库（下次点还是从零开始，永远成功不了）。
  Set<String> get markedDates {
    if (checkins == null || checkins!.isEmpty) return <String>{};
    return checkins!.split(',').where((e) => e.isNotEmpty).toSet();
  }

  /// 连续打卡天数。从今天往前数连续出现的日期；
  /// 今天还没打但不算中断——只要昨天打了，今天仍算续上。
  int get streak {
    final set = markedDates;
    if (set.isEmpty) return 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    if (!set.contains(_isoDate(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!set.contains(_isoDate(cursor))) return 0;
    }
    var count = 0;
    while (set.contains(_isoDate(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// 今天的 yyyy-MM-dd。写字面量给 UI 层用，避免各调用点自己拼日期
  /// 格式（拼错一个补零就会让 [doneToday] 永远判 false）。
  static String todayIso([DateTime? now]) => _isoDate(now ?? DateTime.now());

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'dailyMinutes': dailyMinutes,
        'bookId': bookId,
        'dueDate': dueDate,
        'reminderEnabled': reminderEnabled ? 1 : 0,
        'done': done ? 1 : 0,
        'doneAt': doneAt,
        'lastDoneOn': lastDoneOn,
        'checkins': checkins,
        'createdAt': createdAt,
      };

  factory ReadingPlan.fromMap(Map<String, dynamic> m) => ReadingPlan(
        id: m['id'] as String,
        kind: PlanKind.fromString(m['kind'] as String?),
        title: m['title'] as String?,
        dailyMinutes: m['dailyMinutes'] as int?,
        bookId: m['bookId'] as String?,
        dueDate: m['dueDate'] as String?,
        reminderEnabled: (m['reminderEnabled'] as int? ?? 0) == 1,
        done: (m['done'] as int? ?? 0) == 1,
        doneAt: m['doneAt'] as String?,
        lastDoneOn: m['lastDoneOn'] as String?,
        checkins: m['checkins'] as String?,
        createdAt: m['createdAt'] as String? ?? '',
      );

  ReadingPlan copyWith({
    String? title,
    int? dailyMinutes,
    String? bookId,
    String? dueDate,
    bool? reminderEnabled,
    bool? done,
    String? doneAt,
    String? lastDoneOn,
    // 这几个字段需要能被显式清空，nullable 参数表达不了「清空」，
    // 所以用独立开关——与 Book.copyWith 里 isBorrowed 的处理同理。
    bool clearTitle = false,
    bool clearDailyMinutes = false,
    bool clearBookId = false,
    bool clearDueDate = false,
    bool clearDoneAt = false,
    bool clearLastDoneOn = false,
    String? checkins,
    bool clearCheckins = false,
  }) =>
      ReadingPlan(
        id: id,
        kind: kind,
        createdAt: createdAt,
        title: clearTitle ? null : (title ?? this.title),
        dailyMinutes:
            clearDailyMinutes ? null : (dailyMinutes ?? this.dailyMinutes),
        bookId: clearBookId ? null : (bookId ?? this.bookId),
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        done: done ?? this.done,
        doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
        lastDoneOn: clearLastDoneOn ? null : (lastDoneOn ?? this.lastDoneOn),
        checkins: clearCheckins ? null : (checkins ?? this.checkins),
      );

  /// 倒计时天数（仅 [PlanKind.finishBook] 有意义）。负数表示已逾期。
  int? get daysUntilDue {
    final d = dueDate;
    if (d == null) return null;
    final parsed = DateTime.tryParse(d);
    if (parsed == null) return null;
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(parsed.year, parsed.month, parsed.day);
    return b.difference(a).inDays;
  }
}

/// 一条计划的完成情况快照。**由实时数据算出来，不落库。**
///
/// 报告生成与计划卡片都消费它，保证两处口径完全一致——
/// 否则很容易出现「卡片说达成、报告说没达成」这种打脸的情况。
@immutable
class PlanProgress {
  final ReadingPlan plan;

  /// 目标值：时长型=分钟数；书本型=100（百分比）。
  final double target;

  /// 当前值，同口径。
  final double current;

  /// 是否已达成。
  final bool achieved;

  const PlanProgress({
    required this.plan,
    required this.target,
    required this.current,
    required this.achieved,
  });

  /// 达成率，0~1。用于进度条。
  double get ratio => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  /// 报告里用的可读摘要，例如「每天 30 分钟 · 日均 22 分钟（达成 73%）」。
  Map<String, dynamic> toReportJson() => {
        'kind': plan.kind.name,
        if (plan.title != null && plan.title!.isNotEmpty) 'title': plan.title,
        'target': target,
        'current': double.parse(current.toStringAsFixed(1)),
        'achieved': achieved,
        'ratio': double.parse(ratio.toStringAsFixed(2)),
        if (plan.dailyMinutes != null) 'targetMinutesPerDay': plan.dailyMinutes,
        if (plan.dueDate != null) 'dueDate': plan.dueDate,
        if (plan.daysUntilDue != null) 'daysUntilDue': plan.daysUntilDue,
        if (plan.doneAt != null) 'doneAt': plan.doneAt,
      };
}
