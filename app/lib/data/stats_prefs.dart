/// 统计页「结构分析」里七张图表的可见性偏好。
///
/// 为什么要有这个东西：这七张图的价值对每个人是不一样的。
/// 只在乎「读了多少本」的人，被七张图拖着滚三屏是纯粹的负担；
/// 想知道「我是不是只读一类书」的人则一张都不想少。让用户自己裁掉
/// 不关心的，比替所有人保留全部更尊重人。
///
/// 存储形态：settings 表里的一个 KV，
/// `stats_hidden_charts` = 逗号分隔的图表 id。
///
/// ⚠️ **存「隐藏了哪些」而不是「显示了哪些」**。
/// 存白名单的话，将来新增一张图，所有老用户的白名单里都没有它 →
/// 新图默认不出现，等于白做；存黑名单则新图天然是「可见」。
/// 默认值（null / 空）因此就是「全部显示」，不需要额外迁移。
library;

/// 七张图的稳定 id。
///
/// 用字符串常量而不是 enum 下标：下标会因为插入/重排而整体漂移，
/// 用户存下来的偏好会突然指到别的图上。id 一旦发布就不能再改名。
class StatsChart {
  static const status = 'status';
  static const category = 'category';
  static const trend = 'trend';
  static const readingTime = 'readingTime';
  static const rating = 'rating';
  static const progress = 'progress';
  static const source = 'source';

  /// 展示顺序 = 这里列出的顺序，与界面上的排布一致。
  static const all = <String>[
    status,
    category,
    trend,
    readingTime,
    rating,
    progress,
    source,
  ];
}

const statsHiddenChartsKey = 'stats_hidden_charts';

/// 解码 `stats_hidden_charts`。
///
/// 坏数据一律当「没有隐藏任何图」处理——一份写坏的 KV 不该让统计页
/// 变成空白。同时把不认识的 id 过滤掉：可能是旧版本留下的、
/// 也可能是手改的，留着只会让「已隐藏 N 张」的数字对不上。
Set<String> decodeHiddenCharts(String? raw) {
  if (raw == null || raw.trim().isEmpty) return <String>{};
  final known = StatsChart.all.toSet();
  return raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty && known.contains(e))
      .toSet();
}

/// 编码。空集合写成空串（而不是 `''` 之外的什么哨兵），
/// 与 `profile_tags_main` 的「空 = 没改过」是同一种约定。
String encodeHiddenCharts(Set<String> hidden) {
  final known = StatsChart.all.where(hidden.contains).toList();
  return known.join(',');
}
