import 'package:flutter/material.dart';

import 'palette.dart';
import 'theme.dart';

/// 分享卡的配色方案。
///
/// ## 为什么单独抽一个类
///
/// 分享卡是**离屏渲染**的：它被 `ScreenshotController.captureFromWidget`
/// 挂到渲染树的根上，**没有 MaterialApp 祖先**，于是
/// `Theme.of(context)` 在里面取不到任何东西——之前这张卡能把颜色写死，
/// 正是因为「离屏没有 Theme」这个限制。
///
/// 但写死颜色有另一个后果：换皮肤时分享图还是那张绿底绿标签的图，
/// 跟用户眼前的界面完全不像同一款产品。
///
/// 所以这里改成**把配色算好再传进去**：样式是一个纯函数，
/// 由当前皮肤 + 当前明暗推出，页面在渲染前算一次传进来。
/// 离屏渲染只管画，不问 Theme。
///
/// ## 取色规则
///
/// 全部取自该皮肤的 `ColorScheme`，不额外造色——
/// 分享图里的每个颜色都必须是这套皮肤里真实存在的颜色，
/// 否则「跟界面像一家」这件事只成立一半。
@immutable
class ProfileShareStyle {
  /// 卡片底色。用纸色（`surface`），不是纯白：
  /// 分享到深色聊天窗口时纯白会晃眼，用纸色则与 App 界面一致。
  final Color background;

  /// 标题色。用主色——这是画面里最该被看见的颜色。
  final Color title;

  /// 副标题（区间说明）色。
  final Color subtitle;

  /// 小节标题色。
  final Color sectionTitle;

  /// 标签胶囊底色。
  final Color chipBackground;

  /// 标签胶囊文字色。
  final Color chipText;

  /// 进度条底槽色。
  final Color barTrack;

  /// 页脚（品牌行）色。比副标题再淡一档。
  final Color footer;

  /// 图表色板。取该皮肤的色板，深浅两态各自独立。
  final List<Color> chartColors;

  const ProfileShareStyle({
    required this.background,
    required this.title,
    required this.subtitle,
    required this.sectionTitle,
    required this.chipBackground,
    required this.chipText,
    required this.barTrack,
    required this.footer,
    required this.chartColors,
  });

  /// 从主题数据派生。
  ///
  /// 页面走这条：拿 `Theme.of(context)` 即可，
  /// 不用关心当前是哪套皮肤、哪个明暗。
  factory ProfileShareStyle.fromTheme(ThemeData data) {
    final cs = data.colorScheme;
    return ProfileShareStyle(
      background: cs.surface,
      title: cs.primary,
      subtitle: cs.onSurfaceVariant,
      sectionTitle: cs.onSurface,
      chipBackground: cs.secondaryContainer,
      chipText: cs.onSecondaryContainer,
      barTrack: cs.surfaceContainerHighest,
      footer: cs.onSurfaceVariant,
      chartColors: data.extension<ChartPalette>()?.colors ?? chartPalette,
    );
  }

  /// 从皮肤 + 明暗派生。纯函数：同样的入参永远得到同样的配色。
  ///
  /// 页面用 [fromTheme] 就够了；这个入口是给**纯函数测试**用的——
  /// 测试不需要造 widget 树就能断言「12 套皮肤 × 明暗的分享卡配色
  /// 都在正确的亮度方向上」。
  factory ProfileShareStyle.of(AppTheme theme, Brightness brightness) =>
      ProfileShareStyle.fromTheme(buildTheme(theme, brightness));

  /// 第 [i] 个系列的颜色。
  ///
  /// 走 [chartColorAtFrom] 而不是页面里的 `chartColorAt(i, context)`：
  /// 后者依赖 context 里的 Theme 扩展，离屏渲染时拿不到，
  /// 会悄悄退回全局默认色板——分享图里的分类颜色就与皮肤无关了。
  Color chartColor(int i) => chartColorAtFrom(chartColors, i);
}
