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

  /// 占位封面：用书名哈希取一个稳定颜色，再放首字。
  ///
  /// 比统一的灰块好认得多——一眼能分辨出「这本和那本不是一个东西」，
  /// 也不会因为颜色随机而在每次重建时闪来闪去。
  Widget _placeholder(BuildContext context) {
    final h = book.title.hashCode.abs();
    final hue = (h % 360).toDouble();
    final base = HSLColor.fromAHSL(1, hue, 0.28, 0.72).toColor();
    final fg = HSLColor.fromAHSL(1, hue, 0.45, 0.28).toColor();
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
