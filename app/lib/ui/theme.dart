import 'package:flutter/material.dart';

import '../l10n/app_loc.dart';
import 'palette.dart';

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

  /// 深色模式专用的图表色板。为 null 时沿用 [chartPalette]。
  ///
  /// ## 为什么深色要单独一套，而不是同一套色板通吃
  ///
  /// 约束变了：浅色模式要求色板**比纸色深**，深色模式要求**比纸色亮**。
  /// 同一组12 色若在两种模式下都满足两边的亮度差，等于被两套相反的
  /// 约束夹在中间——结果通常是深色模式下最暗的那几色沉进纸里看不见。
  ///
  /// 所以深色版是**独立求解**的：色相家族相同（还是这套皮肤的气质），
  /// 但明度分布整体上移，保证每一色都与深色纸留得出亮度差。
  final List<Color>? chartPaletteDark;

  /// 纸感底色的**饱和度**：0.04 = 近乎中性的高级纸，0.13 = 带氛围的活泼纸。
  ///
  /// ## 为什么需要这个字段
  ///
  /// 此前所有皮肤共用同一套纸色（`#FCFBF7` / `#171A16`），换肤只换了主色，
  /// 底色始终是同一张米白。结果是：无论选哪套皮肤，界面都不像那套皮肤
  /// ——绿意配米白、樱粉也配米白。高级感恰恰来自底色与主色之间的这种
  /// **克制关系**，而不是主色本身有多艳。
  ///
  /// 有了它，同一个种子色相就能派生出两种气质：
  ///  - `0.04~0.05`：**高级**。纸色接近中性，主色是画面里唯一的彩色，
  ///    视觉重心稳，像好纸配硬壳。
  ///  - `0.12~0.13`：**活泼**。纸色明显带上主色的氛围，整屏是一个色系，
  ///    卡片与背景的层次靠明度差而不是色相差拉开。
  ///
  /// 这个值**就是纸色的 HSL 饱和度**，不是「相对系数」：纸色明度高达 0.98，
  /// RGB 三通道只剩几十个色阶，饱和度太小会被 8bit 量化抹平
  /// （详见 [_paperRamp] 的注释）。
  ///
  /// 不给 0.04 以下：低于它 8bit 量化会把色相判成 0，纸色变成纯灰。
  /// 不给 0.15 以上：完全浸染后卡片描边（来自 `outlineVariant`）整体染色，
  /// 看着脏而不是精致。
  final double paperTint;

  const AppTheme({
    required this.id,
    required this.labelKey,
    required this.lightSeed,
    required this.darkSeed,
    this.chartPalette,
    this.chartPaletteDark,
    this.paperTint = 0.05,
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

/// 由种子色相派生一套「纸色」表面色。
///
///## 为什么要派生而不是写死
///
/// 写死一套米白（此前的做法）意味着换肤只换主色，底色永远是同一张纸，
/// 于是每套皮肤看起来都差不多。新做法让底色**跟着主色的色相走**，
/// 只用 [AppTheme.paperTint] 控制浸染程度——同一色相因此能表达
/// 两种气质：纸色接近中性时显得克制高级，纸色带上主色时显得活泼统一。
///
/// 六档明度取自 M3 的 surface 层级（低 → 高 = 暗 → 亮，浅色模式下反之）。
/// 关键约束：**相邻档的明度差必须够大**。活泼皮肤里色相都一样，
/// 层次全靠明度差撑着；差值小于 3% 时卡片边界就消失了。
List<Color> _paperRamp(Color seed, bool isLight, double tint) {
  final hsl = HSLColor.fromColor(seed);
  // 饱和度直接由 paperTint 线性映射，不再乘系数：
  //
  // 纸色明度高达 0.98，此时 RGB 三通道只剩几十个色阶可分配，
  // 饱和度必须**大到能在 8bit 上活下来**才有效。实测：按0.055 系数缩放时，
  // tint=0.03 与 tint=0.15 在浅色下都会被量化成同一个 0.0526——
  // 高级皮肤与活泼皮肤在白天看起来毫无区别，paperTint 等于白设。
  //
  // 所以这里让 paperTint 直接就是纸色的饱和度，并把下限抬到 0.04：
  //  - 0.04 上色阶足够（保底），足以让 hue 不被量化成 0；
  //  - 0.10~0.13 在纸色上仍看不出「染色」，但整屏氛围已经不同。
  //
  // 深色模式纸色明度低（0.075~0.268），同样的饱和度看起来更明显，
  // 因此深色端统一乘 0.85 收一档。
  final sat = ((isLight ? tint : tint * 0.85)).clamp(0.04, 1.0);
  final lums = isLight
      ? const [0.985, 0.962, 0.936, 0.906, 0.874, 0.838]
      : const [0.075, 0.108, 0.142, 0.180, 0.222, 0.268];
  return [
    for (final l in lums) HSLColor.fromAHSL(1, hsl.hue, sat, l).toColor(),
  ];
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
      'themeMidnight' => appLoc.themeMidnight,
      'themePlum' => appLoc.themePlum,
      'themeLagoon' => appLoc.themeLagoon,
      'themeCitrus' => appLoc.themeCitrus,
      'themeBerry' => appLoc.themeBerry,
      _ => labelKey,
    };

/// 全部可用皮肤。**顺序即设置页的展示顺序**，第一个是默认皮肤。
///
/// 加皮肤只需在末尾追加一条；`_themeLabels` 里补上对应文案。
/// 后续用户自己设计皮肤的接入点就在这里。
const List<AppTheme> appThemes = [
  // ── 默认 ──────────────────────────────────────────────────────────
  // 默认：沿用产品最初的绿色（图标与商店素材都是这个色系）。
  // paperTint 极低：纸色几乎中性，主色是画面里唯一的彩色。
  AppTheme(
    id: 'green',
    labelKey: 'themeGreen',
    lightSeed: Color(0xFF3B6D11),
    darkSeed: Color(0xFF97C459),
    paperTint: 0.050,
    chartPalette: _evergreen,
    chartPaletteDark: _evergreenDark,
  ),

  // ── 高级向：纸色接近中性，主色克制，像好纸配硬壳 ────────────────
  // 墨韵：接近中性的深灰蓝，偏「纸质书 / 严肃阅读」
  AppTheme(
    id: 'ink',
    labelKey: 'themeInk',
    lightSeed: Color(0xFF37474F),
    darkSeed: Color(0xFF90A4AE),
    paperTint: 0.040,
    chartPalette: _slate,
    chartPaletteDark: _slateDark,
  ),
  // 远山：靛蓝，偏「安静、理性」
  AppTheme(
    id: 'blue',
    labelKey: 'themeBlue',
    lightSeed: Color(0xFF1F4E8C),
    darkSeed: Color(0xFF7FA9E0),
    paperTint: 0.045,
    chartPalette: _indigo,
    chartPaletteDark: _indigoDark,
  ),
  // 黛蓝：比远山更深更沉，几乎是无彩色——高级感最强的一套
  AppTheme(
    id: 'midnight',
    labelKey: 'themeMidnight',
    lightSeed: Color(0xFF2A3B52),
    darkSeed: Color(0xFF8FA6C4),
    paperTint: 0.042,
    chartPalette: _midnight,
    chartPaletteDark: _midnightDark,
  ),
  // 檀紫：沉静的紫调，偏文学与诗集
  AppTheme(
    id: 'plum',
    labelKey: 'themePlum',
    lightSeed: Color(0xFF5B3E63),
    darkSeed: Color(0xFFB694C4),
    paperTint: 0.055,
    chartPalette: _plum,
    chartPaletteDark: _plumDark,
  ),

  // ── 活泼向：纸色明显带主色，整屏一个色系 ────────────────────────
  // 暖阳：暖橙，偏「夜晚台灯下读书」
  AppTheme(
    id: 'amber',
    labelKey: 'themeAmber',
    lightSeed: Color(0xFF9A5B00),
    darkSeed: Color(0xFFE8A33D),
    paperTint: 0.120,
    chartPalette: _honey,
    chartPaletteDark: _honeyDark,
  ),
  // 樱粉：柔和粉紫，偏「轻阅读 / 文学」
  AppTheme(
    id: 'rose',
    labelKey: 'themeRose',
    lightSeed: Color(0xFF9C3B5E),
    darkSeed: Color(0xFFE79BB4),
    paperTint: 0.130,
    chartPalette: _blossom,
    chartPaletteDark: _blossomDark,
  ),
  // 湖绿：清新青绿，偏旅行与自然
  AppTheme(
    id: 'lagoon',
    labelKey: 'themeLagoon',
    lightSeed: Color(0xFF00695C),
    darkSeed: Color(0xFF5FD3C0),
    paperTint: 0.115,
    chartPalette: _lagoon,
    chartPaletteDark: _lagoonDark,
  ),
  // 蜜柑：明快的橙黄，最活泼的一套
  AppTheme(
    id: 'citrus',
    labelKey: 'themeCitrus',
    lightSeed: Color(0xFFB25000),
    darkSeed: Color(0xFFFFB74D),
    paperTint: 0.135,
    chartPalette: _citrus,
    chartPaletteDark: _citrusDark,
  ),
  // 莓果：亮玫红，偏言情与流行
  AppTheme(
    id: 'berry',
    labelKey: 'themeBerry',
    lightSeed: Color(0xFFAD1457),
    darkSeed: Color(0xFFFF8FB1),
    paperTint: 0.125,
    chartPalette: _berry,
    chartPaletteDark: _berryDark,
  ),
];

// ── 各皮肤的图表色板 ────────────────────────────────────────────────
//
// 每套皮肤都自带色板，而不是共用 palette.dart 的默认色板：
// 图表色是「数据编码」，必须与**当前纸色底**都有足够对比。
// 共用一套色板时，活泼皮肤（纸色被主色浸染）最容易出现
// 「图上一个系列和背景几乎同色」的情况——那不是配色难看，是数据看不见了。
//
// 取色规则：同一色相族内取不同明度/饱和度，保证两两之间可区分；
// 深浅两态用同一组色（图表背景随之切换明度，不需要两套）。

// 绿意 / 常青：绿系为主，黄与青做对比
const List<Color> _evergreen = [
  Color(0xFFB0B250),
  Color(0xFF70591F),
  Color(0xFFA2853E),
  Color(0xFF7A6E4E),
  Color(0xFF82B232),
  Color(0xFF4F8425),
  Color(0xFF42B275),
  Color(0xFF789278),
  Color(0xFF36AC30),
  Color(0xFF207035),
  Color(0xFF92B090),
  Color(0xFF299158),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _evergreenDark = [
  Color(0xFF97B292),
  Color(0xFF70631F),
  Color(0xFFB2A071),
  Color(0xFF957A38),
  Color(0xFF76A12D),
  Color(0xFFB2B135),
  Color(0xFF67B25F),
  Color(0xFF5C705C),
  Color(0xFF38B234),
  Color(0xFF399562),
  Color(0xFF78927C),
  Color(0xFF1F701F),
];

// 墨韵 / 石板：中性灰蓝为主，少数暖色点缀
const List<Color> _slate = [
  Color(0xFF2B9A5F),
  Color(0xFF1F7045),
  Color(0xFF52A78D),
  Color(0xFF527060),
  Color(0xFF349EB2),
  Color(0xFF4A32AC),
  Color(0xFF928BAA),
  Color(0xFF6F887B),
  Color(0xFF5F5586),
  Color(0xFF2A7A92),
  Color(0xFF5A71B2),
  Color(0xFF1F4E70),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _slateDark = [
  Color(0xFF32A6B2),
  Color(0xFF30A266),
  Color(0xFF50B28D),
  Color(0xFF708883),
  Color(0xFF3D447A),
  Color(0xFF2A7996),
  Color(0xFF7A6CB2),
  Color(0xFF4E746B),
  Color(0xFF4332B2),
  Color(0xFF237C4C),
  Color(0xFF86A4A3),
  Color(0xFF5D509D),
];

// 远山 / 靛蓝
const List<Color> _indigo = [
  Color(0xFF6190A2),
  Color(0xFF248076),
  Color(0xFF3AB29C),
  Color(0xFF857791),
  Color(0xFF3282B2),
  Color(0xFF222770),
  Color(0xFFA08AB2),
  Color(0xFF5C706C),
  Color(0xFF395382),
  Color(0xFF5D298B),
  Color(0xFF3232B2),
  Color(0xFF6850B2),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _indigoDark = [
  Color(0xFF71B0B2),
  Color(0xFF288091),
  Color(0xFF34B2A4),
  Color(0xFF3B7066),
  Color(0xFF466DAF),
  Color(0xFF1F4A70),
  Color(0xFF3632B2),
  Color(0xFF5A938B),
  Color(0xFFA492B2),
  Color(0xFF533684),
  Color(0xFF8971A5),
  Color(0xFF6D5693),
];

// 黛蓝 / 午夜：更深沉，蓝紫与钢灰
const List<Color> _midnight = [
  Color(0xFF56B2AD),
  Color(0xFF2B568B),
  Color(0xFF30AA8E),
  Color(0xFF80A199),
  Color(0xFF3384B2),
  Color(0xFF237463),
  Color(0xFFA08DB2),
  Color(0xFF613E84),
  Color(0xFF3F2DA0),
  Color(0xFF291F70),
  Color(0xFF66709E),
  Color(0xFF7F4BB2),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _midnightDark = [
  Color(0xFF3F7065),
  Color(0xFF6DB2A2),
  Color(0xFF32AFB2),
  Color(0xFF3242B2),
  Color(0xFF7B48AF),
  Color(0xFF23577D),
  Color(0xFF5478B0),
  Color(0xFF897B96),
  Color(0xFF288F8D),
  Color(0xFF4E3E70),
  Color(0xFFA292B2),
  Color(0xFF6B657B),
];

// 檀紫：紫与玫调
const List<Color> _plum = [
  Color(0xFF6F51B2),
  Color(0xFF7B226C),
  Color(0xFF612A98),
  Color(0xFF8D4D7C),
  Color(0xFF504270),
  Color(0xFFB239B1),
  Color(0xFFB28CB2),
  Color(0xFF9D7196),
  Color(0xFF70262A),
  Color(0xFF705D5C),
  Color(0xFFB23266),
  Color(0xFF95423F),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _plumDark = [
  Color(0xFF7A738C),
  Color(0xFF794AB2),
  Color(0xFF9C92B2),
  Color(0xFF564570),
  Color(0xFF502DA1),
  Color(0xFF892672),
  Color(0xFFB26C9F),
  Color(0xFF7A5554),
  Color(0xFFB23450),
  Color(0xFFA82FA6),
  Color(0xFFA35974),
  Color(0xFF703432),
];

// 暖阳 / 蜜色：橙黄与琥珀
const List<Color> _honey = [
  Color(0xFFB2AE8F),
  Color(0xFF8F6531),
  Color(0xFFA92F30),
  Color(0xFF7F3951),
  Color(0xFFB2525F),
  Color(0xFF70261F),
  Color(0xFFB2943C),
  Color(0xFFA47883),
  Color(0xFF7AAC30),
  Color(0xFF68705C),
  Color(0xFF86916E),
  Color(0xFF5B8024),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _honeyDark = [
  Color(0xFFB28A93),
  Color(0xFFB24359),
  Color(0xFFB27132),
  Color(0xFF704441),
  Color(0xFF992B2C),
  Color(0xFF4B7522),
  Color(0xFF95616D),
  Color(0xFF66705C),
  Color(0xFFAFB247),
  Color(0xFF879D61),
  Color(0xFF9CB286),
  Color(0xFF70AF31),
];

// 樱粉 / 花信
const List<Color> _blossom = [
  Color(0xFFA65F9B),
  Color(0xFF763C88),
  Color(0xFFAF92B2),
  Color(0xFF704847),
  Color(0xFFB23281),
  Color(0xFF9B632B),
  Color(0xFF9532B2),
  Color(0xFF806970),
  Color(0xFFB24F4D),
  Color(0xFF70201F),
  Color(0xFFAB8967),
  Color(0xFF8A2762),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _blossomDark = [
  Color(0xFFAB7DB2),
  Color(0xFF683270),
  Color(0xFFB23286),
  Color(0xFF8B7284),
  Color(0xFF9D46AB),
  Color(0xFF70351F),
  Color(0xFF9A2B40),
  Color(0xFF9F845C),
  Color(0xFFB25254),
  Color(0xFF70584B),
  Color(0xFFB2A48F),
  Color(0xFF906628),
];

// 湖绿 / 湖蓝
const List<Color> _lagoon = [
  Color(0xFF61B264),
  Color(0xFF32B236),
  Color(0xFF32B298),
  Color(0xFF829E83),
  Color(0xFF92AFB2),
  Color(0xFF237B25),
  Color(0xFF4D8BA7),
  Color(0xFF67717E),
  Color(0xFF3262B2),
  Color(0xFF415670),
  Color(0xFF308967),
  Color(0xFF284090),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _lagoonDark = [
  Color(0xFF6E9E6E),
  Color(0xFF2FA64E),
  Color(0xFF8FB28F),
  Color(0xFF467846),
  Color(0xFF2C8387),
  Color(0xFF1F7026),
  Color(0xFF8692B2),
  Color(0xFF525F7E),
  Color(0xFF3DB295),
  Color(0xFF3254B2),
  Color(0xFF6A7A98),
  Color(0xFF2A4970),
];

// 蜜柑 / 活力橙
const List<Color> _citrus = [
  Color(0xFFB28541),
  Color(0xFF9C2C64),
  Color(0xFF8E5328),
  Color(0xFF705F4B),
  Color(0xFF9EB25C),
  Color(0xFF701F2C),
  Color(0xFFB23432),
  Color(0xFF9B6E84),
  Color(0xFF809A2B),
  Color(0xFF838462),
  Color(0xFFB2A48C),
  Color(0xFF5E701F),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _citrusDark = [
  Color(0xFFB28E9B),
  Color(0xFFAC4333),
  Color(0xFF917D77),
  Color(0xFF8E3254),
  Color(0xFFB24B71),
  Color(0xFF53701F),
  Color(0xFF8BB246),
  Color(0xFF6A705C),
  Color(0xFFABB273),
  Color(0xFF705332),
  Color(0xFF8E7A28),
  Color(0xFFB28C4A),
];

// 莓果 / 亮玫
const List<Color> _berry = [
  Color(0xFFB292B1),
  Color(0xFF6E3391),
  Color(0xFF935BB2),
  Color(0xFF82728B),
  Color(0xFFAF31A5),
  Color(0xFF701F45),
  Color(0xFFB2886F),
  Color(0xFF786255),
  Color(0xFFB23454),
  Color(0xFF923729),
  Color(0xFF9D4C77),
  Color(0xFFB26132),
];

/// 深色模式专用：同一色相家族，明度分布重新求解以适配深色纸。
const List<Color> _berryDark = [
  Color(0xFF9B7DA6),
  Color(0xFF70384B),
  Color(0xFF832525),
  Color(0xFF73517C),
  Color(0xFFB25B8E),
  Color(0xFFB232B2),
  Color(0xFFA84758),
  Color(0xFF8D2771),
  Color(0xFFB27947),
  Color(0xFF92716C),
  Color(0xFFB2957B),
  Color(0xFF915B35),
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
  final seed =
      brightness == Brightness.light ? theme.lightSeed : theme.darkSeed;
  final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final isLight = brightness == Brightness.light;
  // A quiet paper canvas gives the collection room to breathe without
  // replacing the selected theme's accent or changing its light/dark behavior.
  //
  // 纸色不再写死：由种子色相 + paperTint 派生（见 [_paperRamp]）。
  // 写死米白时换肤只换主色，每套皮肤看起来都一样——那是「不高级」的根因。
  final paper = _paperRamp(seed, isLight, theme.paperTint);
  final scheme = base.copyWith(
    surface: paper[1],
    background: paper[1],
    surfaceContainerLowest: paper[0],
    surfaceContainerLow: paper[2],
    surfaceContainer: paper[3],
    surfaceContainerHigh: paper[4],
    surfaceContainerHighest: paper[5],
  );
  final outline = scheme.outlineVariant.withOpacity(isLight ? 0.72 : 0.65);
  final baseTextTheme = isLight
      ? Typography.material2021().black
      : Typography.material2021().white;
  final textTheme = baseTextTheme.apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
    fontFamily: 'Roboto',
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // 图表色板跟着皮肤走：活泼皮肤的纸色被主色浸染，
    // 共用色板会出现「系列与背景对比不足」——那不是不好看，是数据看不见。
    extensions: <ThemeExtension<dynamic>>[
      ChartPalette(
        // 深色模式优先用深色专用色板；没给就退回浅色那套。
        isLight
            ? (theme.chartPalette ?? chartPalette)
            : (theme.chartPaletteDark ?? theme.chartPalette ?? chartPalette),
      ),
    ],
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    textTheme: textTheme.copyWith(
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.6,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
      bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
      ),
    ),
    cardTheme: CardTheme(
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: outline),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: MaterialStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
                fontWeight: states.contains(MaterialState.selected)
                    ? FontWeight.w600
                    : FontWeight.w500,
              )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: outline,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: outline),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
    ),
  );
}
