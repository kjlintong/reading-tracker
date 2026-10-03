import 'package:flutter/material.dart';
import '../l10n/app_loc.dart';

import '../data/date_range.dart';

/// 时间范围选择器。统计页与阅读画像页共用。
///
/// 单独抽出来是因为「选完区间之后必须把口径说明显示出来」这件事
/// 容易被漏掉：阅读时长只有月度粒度，阅读天数只有年度口径。
/// 说明文字跟选择器绑在一起，用一次就带一次，不会漏。
class StatsRangeSelector extends StatelessWidget {
  final StatsRange value;
  final ValueChanged<StatsRange> onChanged;

  /// 当前区间不属于任何预置项时，「自定义」那颗 chip 就会亮起来
  bool _isCustom(StatsRange r) =>
      !r.isAll && StatsRange.presets().every((p) => !_same(p, r));

  static bool _same(StatsRange a, StatsRange b) =>
      a.from == b.from && a.to == b.to;

  const StatsRangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(today.year - 10, 1, 1);

    // showDateRangePicker 对 initialDateRange 有断言：必须落在
    // firstDate..lastDate 之内。而预置区间（如「今年」）的终点是明年 1 月 1 日，
    // 直接拿去当初始值会触发断言，所以要夹一下。
    DateTime clamp(DateTime d) {
      if (d.isBefore(first)) return first;
      if (d.isAfter(today)) return today;
      return d;
    }

    var start = clamp(value.from ?? DateTime(today.year, 1, 1));
    var end = clamp(
        (value.to ?? today.add(const Duration(days: 1)))
            .subtract(const Duration(days: 1)));
    if (end.isBefore(start)) end = start;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: today,
      initialDateRange: DateTimeRange(start: start, end: end),
      helpText: appLoc.s_20a63774,
      saveText: appLoc.s_d507abff,
      cancelText: appLoc.s_a0451c97,
    );
    if (picked != null) onChanged(StatsRange.custom(picked.start, picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final presets = StatsRange.presets();
    final custom = _isCustom(value);

    // 单行下拉 + 紧凑外观，替代原来「一排 chips 换行成两三行」的写法。
    //
    // 原来 chips 有个硬伤：预置项有 6~7 个（本周/本月/今年/去年/全部/自定义…），
    // 在窄屏上必然折行，占掉三四行高度——用户抱怨「占空间太大、不好看」
    // 就是这个。下拉只占一行，展开时才铺开，且顺带把「说明文字」收进
    // 已选项的副标题里，不再单独占一行。
    // 菜单项的文字同样必须带住字族（理由见下方 style 的说明），
    // 否则展开后每个候选都是一排豆腐块。
    final itemStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 13) ??
        const TextStyle(fontSize: 13);

    final items = <DropdownMenuItem<String>>[
      for (final p in presets)
        DropdownMenuItem(
          value: p.label,
          child: Text(p.label, style: itemStyle),
        ),
      DropdownMenuItem(
        value: '__custom__',
        child: Text(
          custom ? value.label : appLoc.s_ff31410d,
          style: itemStyle,
        ),
      ),
    ];

    final current = custom ? '__custom__' : value.label;

    // ⚠️ 下拉的文字样式必须**从主题继承**后再覆盖字号/颜色，
    // 不能直接 `TextStyle(fontSize: 13, color: ...)`。
    //
    // DropdownButton.style 整体替换掉按钮的 DefaultTextStyle，而一个裸
    // TextStyle **不带 fontFamily**，等于把 App 选定的字族丢掉、退回引擎
    // 默认字体。后果在测试渲染环境里最明显：默认字体没有汉字，
    // 区间名整行变成豆腐块（「□□□□」）；真机上若系统字体缺失同理会中招。
    // 用 `theme.textTheme.bodyMedium!.copyWith(...)` 带住字族，只改要改的。
    final style = theme.textTheme.bodyMedium
            ?.copyWith(fontSize: 13, color: cs.onSurface) ??
        TextStyle(fontSize: 13, color: cs.onSurface);

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 15, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isDense: true,
              isExpanded: true,
              style: style,
              items: items,
              onChanged: (v) {
                if (v == null) return;
                if (v == '__custom__') {
                  _pickCustom(context);
                  return;
                }
                final p = presets.firstWhere((e) => e.label == v,
                    orElse: () => value);
                onChanged(p);
              },
            ),
          ),
        ),
        // 口径说明收进图标 tooltip，不再单独占一行——
        // 它是「用到时才查」的信息，常驻显示反而挤占版面
        if (value.note != null)
          Tooltip(
            message: value.note!,
            triggerMode: TooltipTriggerMode.tap,
            child: Icon(Icons.info_outline, size: 15, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}
