/// 计划截止日的日期选择器边界（纯函数，可穷举测试）。
///
/// ## 为什么把它抽出来
///
/// 之前 `showDatePicker` 的 `firstDate` 固定为「昨天」，而 `initialDate`
/// 是**已存的截止日**。编辑一条**已逾期**的计划时，`initialDate`
/// 落在 `firstDate` 之前：
///
///  - debug 下 Flutter 直接断言失败 → 用户根本点不开日期选择器；
///  - release 下不报错，而是把日历翻到没有那一天的月份，
///    **用户存着的截止日在界面上消失，保存后被静默改成别的日期**。
///
/// 后者更糟：没有报错、没有崩溃，只是数据被悄悄改掉了。
///
/// ## 规则
///
///  - **下限** = 「已存截止日」与「昨天」中更早的那个。
///    已逾期的计划仍能改回原来的截止日；
///    新建计划没有历史截止日，仍然只能选今天及以后。
///  - **初始日** = 已存截止日；没有则默认两周后。
///
/// ## 为什么按「日期」而不是「时刻」比较
///
/// [showDatePicker] 内部先 `DateUtils.dateOnly` 归一化三个参数，
/// 再断言 `initialDate >= firstDate`：
///
/// ```dart
/// initialDate = DateUtils.dateOnly(initialDate);
/// firstDate = DateUtils.dateOnly(firstDate);
/// assert(initialDate == null || !initialDate.isBefore(firstDate));
/// ```
///
/// 所以这里也按 y/m/d 三元组比较，与组件内部口径一致。
/// 实测两种口径在现有数据下结果相同（数据库里存的截止日恒为午夜），
/// 但统一成日期口径后，「下限不晚于已存截止日」这条不变式
/// 读起来就是字面意思，不会因为将来截止日带上时分秒而悄悄失效。
library;

/// 把时刻归一到「当天 00:00」。
DateTime dateOnlyOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// 日期选择器可选范围。
class DueDateBounds {
  /// 可选的最早日期。
  final DateTime first;

  /// 日历打开时默认落在的那一天。
  final DateTime initial;

  const DueDateBounds({required this.first, required this.initial});
}

/// 计算截止日选择器的边界。
///
/// [existing] 是已存的截止日（可为 null，表示新建计划），
/// [now] 是「当前时刻」（默认取系统时间，测试里显式传入以便穷举）。
///
/// 返回值保证：
///  - `initial` 不早于 `first`（否则 [showDatePicker] 断言失败）；
///  - `first` 不晚于今天 + 一天（即新建计划仍只能选今天及以后）。
DueDateBounds dueDateBounds(DateTime now, {DateTime? existing}) {
  final today = dateOnlyOf(now);
  final floor = today.subtract(const Duration(days: 1));
  final first = (existing != null && dateOnlyOf(existing).isBefore(floor))
      ? dateOnlyOf(existing)
      : floor;
  final raw = existing ?? now.add(const Duration(days: 14));
  final initial = dateOnlyOf(raw);
  return DueDateBounds(
    first: first,
    initial: initial.isBefore(first) ? first : initial,
  );
}

/// 把 [DateTime] 格式化成 `yyyy-MM-dd`（与数据库里的日期串一致）。
String formatDueDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
