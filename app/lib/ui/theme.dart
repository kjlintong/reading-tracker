import 'package:flutter/material.dart';

import '../l10n/app_loc.dart';

/// 应用主题（换肤）注册表。
///
/// 设计目标：**新增一套皮肤 = 往 [appThemes] 里加一条配置**，
/// 不需要动 `main.dart`、不需要改任何页面代码。
///
/// 每套皮肤用一个 [AppTheme] 描述：
///  - [id] 要持久化进数据库（改了就丢失用户选择），一经发布不要再改；
///  - [labelKey] 是本地化键名，取显示名时经 [AppTheme.labelOf]；
///  - [seeds] 决定 `ColorScheme.fromSeed` 的种子色——
///    这是 Material 3 的核心：**一个种子色能推导出整套和谐配色**，
///    所以加皮肤通常只需要挑一个好种子色，外加图表色板。
///  - [chartPalette] 可选：不填则沿用全局默认色板（见 palette.dart）。
///
/// **明暗两态各自一个种子色**而不是同一个：深色背景下同一个种子色
/// 会显得过暗（M3 的 tonal palette 在 dark 下取值不同，同色号观感差很多），
/// 所以这里刻意分开给，允许为深色单独调亮。
@immutable
class AppTheme {
  /// 持久化标识。发布后不可更改（否则用户已选的皮肤会失效）。
  final String id;

  /// 本地化键名（对应 ARB 里的 key）。取显示名走 [labelOf]。
  final String labelKey;

  /// 浅色模式的种子色。
  final Color lightSeed;

  /// 深色模式的种子色。
  final Color darkSeed;

  /// 该皮肤专属的图表色板。为 null 时用全局默认（chartPalette）。
  ///
  /// 为什么允许每套皮肤自带色板：图表色是「数据编码」，需要与主题底色
  /// 有足够对比。若皮肤底色与默认色板撞色（例如墨绿底色 + 默认的墨绿系列），
  /// 图上会出现看不见的系列——因此重要皮肤应各自指定色板。
  final List<Color>? chartPalette;

  const AppTheme({
    required this.id,
    required this.labelKey,
    required this.lightSeed,
    required this.darkSeed,
    this.chartPalette,
  });

  /// 显示名。用 [themeLabelOf] 查表，而不是 S.of(context)——
  /// 主题名要在 MaterialApp 构建之前（还不能取 context 时）就可能用到。
  String get label => themeLabelOf(labelKey);

  /// 由 id 反查皮肤；未知 id 回落到默认（第一个）。
  static AppTheme byId(String? id) {
    for (final t in appThemes) {
      if (t.id == id) return t;
    }
    return appThemes.first;
  }
}

/// 主题显示名的键 → 文案。
///
/// 走 [appLoc]（ARB）。历史上这里写死了「绿意 / Green」这样的双语串，
/// 理由是「语言切换的同一帧要立刻跟着变」——但 [appLoc] 就是在
/// `MaterialApp.builder` 里按 locale 设的，切语言时它已经换好了，
/// 不必为了这一点把文案硬编码在代码里（硬编码的代价是英文界面里
/// 混着中文，正是用户报的问题）。
///
/// 新增皮肤时在 ARB 里补一条，键名与这里的 [AppTheme.labelKey] 对应。
String themeLabelOf(String labelKey) => switch (labelKey) {
      'themeGreen' => appLoc.themeGreen,
      'themeInk' => appLoc.themeInk,
      'themeAmber' => appLoc.themeAmber,
      'themeBlue' => appLoc.themeBlue,
      'themeRose' => appLoc.themeRose,
      _ => labelKey,
    };

/// 全部可用皮肤。**顺序即设置页的展示顺序**，第一个是默认皮肤。
///
/// 加皮肤只需在末尾追加一条；`_themeLabels` 里补上对应文案。
/// 后续用户自己设计皮肤的接入点就在这里。
const List<AppTheme> appThemes = [
  // 默认：沿用产品最初的绿色（图标与商店素材都是这个色系）
  AppTheme(
    id: 'green',
    labelKey: 'themeGreen',
    lightSeed: Color(0xFF3B6D11),
    darkSeed: Color(0xFF97C459),
  ),
  // 墨韵：接近中性的深灰蓝，偏「纸质书 / 严肃阅读」
  AppTheme(
    id: 'ink',
    labelKey: 'themeInk',
    lightSeed: Color(0xFF37474F),
    darkSeed: Color(0xFF90A4AE),
  ),
  // 暖阳：暖橙，偏「夜晚台灯下读书」
  AppTheme(
    id: 'amber',
    labelKey: 'themeAmber',
    lightSeed: Color(0xFF9A5B00),
    darkSeed: Color(0xFFE8A33D),
  ),
  // 远山：靛蓝，偏「安静、理性」
  AppTheme(
    id: 'blue',
    labelKey: 'themeBlue',
    lightSeed: Color(0xFF1F4E8C),
    darkSeed: Color(0xFF7FA9E0),
  ),
  // 樱粉：柔和粉紫，偏「轻阅读 / 文学」
  AppTheme(
    id: 'rose',
    labelKey: 'themeRose',
    lightSeed: Color(0xFF9C3B5E),
    darkSeed: Color(0xFFE79BB4),
  ),
];

/// 明暗模式选择。
///
/// 单独一个枚举而不是直接用 `ThemeMode`：`ThemeMode.system` 的语义
/// 在设置页要显示成「跟随系统」，而 [ThemeMode] 本身没有 label，
/// 也便于将来扩展（例如「按时间自动切换」）。
enum AppBrightness {
  system('system'),
  light('light'),
  dark('dark');

  final String id;
  const AppBrightness(this.id);

  static AppBrightness fromString(String? s) => switch (s) {
        'light' => light,
        'dark' => dark,
        _ => system,
      };

  ThemeMode get themeMode => switch (this) {
        system => ThemeMode.system,
        light => ThemeMode.light,
        dark => ThemeMode.dark,
      };

  /// 显示名。
  ///
  /// 走 [appLoc]（ARB）而不是像 [_themeLabels] 那样写死双语：
  /// 写死的 '浅色 / Light' 在英文界面里会整串照搬显示，
  /// 中文用户看到「浅色 / Light」也不自然。这里的分支只有三个固定选项，
  /// 不必像皮肤那样担心「新增条目要补三份文案」。
  String get label => switch (this) {
        system => appLoc.brightnessSystem,
        light => appLoc.brightnessLight,
        dark => appLoc.brightnessDark,
      };

  IconData get icon => switch (this) {
        system => Icons.brightness_auto_outlined,
        light => Icons.light_mode_outlined,
        dark => Icons.dark_mode_outlined,
      };
}

/// 按皮肤 + 明暗构造 [ThemeData]。
///
/// 集中在这里而不是散落在 main.dart：改主题细节（圆角、字体等）
/// 只改这一个函数，全部皮肤一起生效。
ThemeData buildTheme(AppTheme theme, Brightness brightness) {
  final seed = brightness == Brightness.light ? theme.lightSeed : theme.darkSeed;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // 卡片与导航栏用 surface 系，避免 M3 默认的 tinted surface 在
    // 某些皮肤下把正文衬得过灰（可读性问题，不是审美偏好）
    scaffoldBackgroundColor: scheme.surface,
  );
}
