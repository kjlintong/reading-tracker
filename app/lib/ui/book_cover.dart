import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_loc.dart';
import '../models/book.dart';

/// 书籍封面。**书架、详情页、任何要画书封的地方都走这里**。
///
/// ## 为什么必须共用
///
/// 封面有两个来源：用户从相册选的本地文件（`coverLocalPath`）和
/// 联网匹配来的远程 URL（`coverUrl`）。此前书架与详情页各写了一份渲染，
/// 且都**只判 `coverUrl`**——本地封面写进了库却从来没有被读过，
/// 用户改完封面保存、回详情页一看还是旧图，看起来就是「保存没生效」。
///
/// 两份实现还意味着任何一个修复都只能修一半。合并成一个组件后，
/// 优先级、降级、占位三件事只有一处定义，两处渲染不可能再分叉。
///
/// ## 优先级：本地 > 远程 > 占位
///
/// 本地文件是用户**亲手选的**，一定比自动匹配的 URL 更权威；
/// 而且用户换封面时的诉求正是「盖掉」那张联网图。
///
/// ## 降级链
///
/// 本地文件可能已被系统清理（相册缓存、换机迁移）→ 退回远程 URL；
/// 远程可能断网 / 链接失效 → 退回占位块。占位块按书名哈希取色，
/// 保证同一本书记忆点稳定，不会每次重建都闪一个颜色。
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.radius = 6,
    this.placeholderFontSize = 15,
  });

  final Book book;

  /// 圆角。列表用小圆角、详情页大封面也用同一套尺寸。
  final double radius;

  /// 占位块里书名字号。详情页封面比列表大，字要跟着放大，
  /// 否则占位图看起来像没排版。
  final double placeholderFontSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final local = book.coverLocalPath;
    if (local != null && local.isNotEmpty) {
      final file = File(local);
      return Image.file(
        file,
        fit: BoxFit.cover,
        // 文件被删/读不了时不能只画个破图：退回远程，再退回占位。
        // 这两级在用户眼里是「封面还在」，比一个错误图标好得多。
        errorBuilder: (_, __, ___) => _remoteOrPlaceholder(context),
      );
    }
    return _remoteOrPlaceholder(context);
  }

  Widget _remoteOrPlaceholder(BuildContext context) {
    final url = book.coverUrl;
    if (url == null || url.isEmpty) return _placeholder(context);
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(context),
      loadingBuilder: (ctx, child, p) =>
          p == null ? child : _placeholder(context),
    );
  }

  /// 占位封面：用书名哈希取一个**跟随当前皮肤**的颜色，再放首字。
  ///
  /// 比统一的灰块好认得多——一眼能分辨出「这本和那本不是一个东西」，
  /// 也不会因为颜色随机而在每次重建时闪来闪去。
  ///
  /// ## 为什么色相不能取全色环
  ///
  /// 此前用 `hash % 360` 取任意色相，于是**绿色主题下会出现粉、blue、紫色
  /// 的封面块**：界面是绿的，书封却是别的主题色，看起来像配色事故。
  /// 占位封面在书架上占的面积不小，用户没上传封面时它是画面的主要色彩，
  /// 必须与主题同属一个色系。
  ///
  /// 现在从主题种子的色相出发，在 [hueSpread] 的范围内按书名哈希取偏移：
  ///  - 同一本书在任何皮肤下都稳定（哈希没变）；
  ///  - 同一皮肤下所有占位封面互相协调（都在 ±spread 内）；
  ///  - 相邻两本仍能分辨（偏移量按黄金角错开，不会扎堆）。
  ///
  /// 饱和度与明度也一并受约束：过高会变成糖果色抢戏，过低则和卡片底色
  /// 糊在一起、看不出边界。
  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    // 基准色相取自 **primary**（而不是纸色）：primary 是 M3 从种子色推导的
    // 主色，色相与种子色一致但饱和度足够高，不会像极低饱和的纸色那样
    // 在 8bit 量化后丢失色相信息（实测低饱和纸色的 hue 会归零）。
    final seedHue = HSLColor.fromColor(theme.colorScheme.primary).hue;
    final h = book.title.hashCode.abs();
    // 把hash 映射到 [-1, 1] 的**连续**系数再乘以跨度，而不是 `hash % 9 - 4`
    // 这种取档位的方式：后者对某些书名会落到档位边缘（例如 9 个档位时
    // 《Dune》的哈希给出第 4 档，也就是满偏 31.5°），偏移量取决于哈希的
    // 低位比特而非书名本身，看起来就是「有的书偏得多、有的偏得少」。
    // 跨度一路从 42° 收到 28° 再收到 16°，两次都是被样张图逼出来的：
    // 42° 时青绿（172.7°）能偏到 214.7°，那已经是蓝；
    // 28° 收成 145~201° 之后颜色**落在正确家族内**，但六张封面看上去
    // 仍是「一片蓝灰」——因为青绿到天蓝这段 hues 上色相变化本身就小，
    // 42%~ 84% 的高明度又进一步压平了差异。
    //
    // 结论：同族内的层次**不能只靠色相**。16° 把色相锁死在绿松石~青绿，
    // 层次改由明度承担（84% → 70%），于是每本书靠深浅区分，
    // 而底色仍牢牢在家族内，不会再冒出蓝方块。
    const hueSpread = 16.0;
    final unit = ((h % 1009) / 1009.0) * 2 - 1; // 1009 是质数，避免与低位相关
    final hue = (seedHue + unit * hueSpread + 360) % 360;
    // 暗色模式下书封整体压暗，否则一堆浅色方块会在深底上「发亮」。
    final isDark = theme.brightness == Brightness.dark;
    //饱和度 0.26 太低：那已经是「淡到看不出色相」的程度，
    //于是 172°(青绿) 与 200°(天蓝) 渲染出来几乎是同一种灰蓝——
    // 图上表现为「湖绿皮肤里混进三个蓝方块」。代码没错，是取值太淡。
    //
    // 0.42 能让色相真正显形：青绿家族落在绿松石~天青，
    // 与主色仍同族（明度远高于纸色，不会抢戏），但彼此可分辨。
    // 另外按 unit 的绝对值微调明度：偏得越远的越深一点，
    // 于是同一皮肤下几本书的深浅也有层次，不只靠色相区分。
    final base = HSLColor.fromAHSL(
      1,
      hue,
      isDark ? 0.46 : 0.40,
      isDark ? 0.30 + unit.abs() * 0.10 : 0.84 - unit.abs() * 0.14,
    ).toColor();
    final fg = HSLColor.fromAHSL(1, hue, 0.52, isDark ? 0.82 : 0.26).toColor();
    final chars = book.title.replaceAll(RegExp(appLoc.s_0d65fca2), '');
    return Container(
      color: base,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Text(
        chars.isEmpty ? '?' : chars.substring(0, chars.length >= 2 ? 2 : 1),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontSize: placeholderFontSize,
          height: 1.15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
