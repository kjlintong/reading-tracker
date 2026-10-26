import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/profile_store.dart';
import '../data/reading_profile.dart';
import '../l10n/app_loc.dart';
import '../models/enums.dart';
import 'profile_share_style.dart';

/// 分享用的画像卡片。
///
/// ## 配色从哪来
///
/// 全部取自传入的 [ProfileShareStyle]——那是当前皮肤 + 当前明暗算出来的
/// 一组颜色。卡片**不自己去找 Theme**：
/// 它会被离屏渲染（截图时挂在独立渲染树的根上），那棵树上没有
/// MaterialApp 祖先，`Theme.of(context)` 在里面取不到任何东西。
///
/// 以前这张卡把颜色全部写死（绿底绿标签白卡片），正是因为「离屏没有
/// Theme」这个限制。但写死有另一个后果：换皮肤时分享图还是那张绿底，
/// 跟用户眼前的界面完全不像同一款产品。现在改成**把配色算好再传进来**，
/// 离屏渲染只管画，不问 Theme。
///
/// 尺寸（360 宽）与字号保持不变：分享出去的图要跟以前一样能看，
/// 变的只是颜色。
class ProfileShareCard extends StatelessWidget {
  final ReadingProfile profile;
  final List<ProfileTagItem> tags;
  final String rangeLabel;
  final int bookCount;
  final ProfileShareStyle style;

  /// 品牌角标。已解码成 [ui.Image]，用 [RawImage] 同步绘制。
  final ui.Image? mark;

  const ProfileShareCard({
    super.key,
    required this.profile,
    required this.tags,
    required this.rangeLabel,
    required this.bookCount,
    required this.style,
    this.mark,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = profile.preferences;
    final maxCount =
        prefs.isEmpty ? 1 : prefs.map((p) => p.count).reduce(math.max);
    final s = style;

    return Material(
      color: s.background,
      child: Container(
        width: 360,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(appLoc.s_e97565e5,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: s.title)),
                ),
                if (mark != null) ...[
                  const SizedBox(width: 10),
                  RawImage(
                    image: mark,
                    width: 20,
                    height: 20,
                    filterQuality: FilterQuality.medium,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(appLoc.s_d9579b73(rangeLabel: rangeLabel, bookCount: bookCount),
                style: TextStyle(fontSize: 12, color: s.subtitle)),

            if (tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(appLoc.s_bfc50de8,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: s.sectionTitle)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.chipBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t.text,
                          style: TextStyle(fontSize: 13, color: s.chipText)),
                    ),
                ],
              ),
            ],

            if (prefs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(appLoc.s_ab5cc063,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: s.sectionTitle)),
              const SizedBox(height: 10),
              for (var i = 0; i < prefs.length && i < 8; i++) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(categoryLabel(prefs[i].label),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: s.sectionTitle)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: prefs[i].count / maxCount,
                          minHeight: 10,
                          backgroundColor: s.barTrack,
                          valueColor: AlwaysStoppedAnimation(s.chartColor(i)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${prefs[i].count}',
                        style: TextStyle(fontSize: 12, color: s.subtitle)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.menu_book, size: 13, color: s.footer),
                const SizedBox(width: 5),
                // 品牌行：App 名 + 产品线。App 名走 appTitle（品牌名不翻译），
                // 产品线走已有文案 s_9de44e0f——不新增 ARB 键。
                Text(
                  '${appLoc.appTitle} · ${appLoc.s_9de44e0f}',
                  style: TextStyle(fontSize: 11, color: s.footer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
