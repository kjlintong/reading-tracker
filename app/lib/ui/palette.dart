import 'package:flutter/material.dart';

/// 图表配色。
///
/// 取中间明度的色相环，深浅两种主题下都够清楚，且**不依赖 colorScheme**——
/// 主题色只有一组，七八张图会全糊成同一个绿。
///
/// 单独放一个文件是因为统计页与阅读画像页都要用：两处各写一份的话，
/// 同一个分类在两个页面里会是两种颜色，用户会以为数据不一样。
///
/// **为什么是 12 个而不是 8 个**：受控词表有 20 个分类。画像页要展示
/// 占比前 12 类，只准备 8 种颜色的话第 9 类会和第 1 类撞色，
/// 图上两个圆同色、而图例里是两行，等于把对应关系弄丢了。
/// 取色一律走 [chartColorAt]，不要自己写 `[i % length]`——
/// 取模会把「撞色」这件事藏起来，直到用户发现对不上号。
const List<Color> chartPalette = [
  Color(0xFF5B8FF9), // 蓝
  Color(0xFF61DDAA), // 薄荷
  Color(0xFFF6BD16), // 金
  Color(0xFF7262FD), // 靛
  Color(0xFF78D3F8), // 天蓝
  Color(0xFF9661BC), // 紫
  Color(0xFFF6903D), // 橙
  Color(0xFF008685), // 墨绿
  Color(0xFF5D7092), // 灰蓝
  Color(0xFFE8684A), // 砖红
  Color(0xFFB37FEB), // 浅紫
  Color(0xFFCF5C9E), // 洋红
];

/// 第 [i] 个系列的颜色。超出调色板长度时按**黄金角**旋转色相生成。
///
/// 黄金角（137.5°）能让相邻色相始终拉得开，比 `i % length` 强：
/// 后者在第 13 个分类上会直接复用第 1 个分类的颜色。
Color chartColorAt(int i) {
  if (i >= 0 && i < chartPalette.length) return chartPalette[i];
  final hue = (i * 137.508) % 360;
  return HSLColor.fromAHSL(1, hue, 0.52, 0.52).toColor();
}

/// 按展示顺序生成「分类名 → 颜色」的映射。
///
/// 图和图例都用它取色，于是取色这件事只有一处口径：只要两边传进来的是
/// 同一条顺序，圆和图例就必然对得上，**哪怕气泡内部因为 packing 被重排过**。
/// （气泡是按半径降序摆的，同数量的分类之间顺序不保证稳定。）
Map<String, Color> chartColorsFor(List<String> orderedKeys) => {
      for (var i = 0; i < orderedKeys.length; i++)
        orderedKeys[i]: chartColorAt(i),
    };

/// 图例条目。配合 [CompactLegend] 使用。
class LegendItem {
  final Color color;
  final String label;
  final String count;

  /// 占比文字，可留空（没有占比的图例不显示这一列）。
  final String ratio;

  const LegendItem({
    required this.color,
    required this.label,
    required this.count,
    this.ratio = '',
  });
}

/// 紧凑图例：多个条目折行排布，每项「● 名称 数量 占比」横着摆。
///
/// **为什么不用 [LegendRow] 一行一项**：分类数最多能到 20，一行一项
/// 排下来就是一整屏，而图例是**参考信息**不是正文——用户看图时
/// 偶尔瞄一眼，不该为它让出半个屏幕。折行排布能把 10 项的图例
/// 从 ~10 行压到 3~4 行。
///
/// 用 `Wrap` 而不是网格：条目宽度不等（「文学」两字 vs「计算机与互联网」
/// 六字），网格会强行等宽，短名后面拖一大片空白，看着更乱。
class CompactLegend extends StatelessWidget {
  final List<LegendItem> items;

  const CompactLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final it in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: it.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(it.label, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                it.count,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              if (it.ratio.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  it.ratio,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// 图例行。
///
/// 存在的理由：`fl_chart` 与自绘 canvas 上的文字**读屏与 widget 测试
/// 都取不到**（`find.textContaining('经济')` 会找到 0 个）。
/// 所以每张图都必须另有一份文本图例，它同时也是唯一能被断言的部分。
class LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String count;
  final String ratio;

  const LegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.count,
    this.ratio = '',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ),
          Text(count,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
          if (ratio.isNotEmpty) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 42,
              child: Text(ratio,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ),
          ],
        ],
      ),
    );
  }
}
