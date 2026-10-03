import 'package:flutter/material.dart';

import '../models/enums.dart';

/// 档案页里的分区容器：一个淡底卡片 + 标题行 + 内容。
///
/// 从 `profile_page.dart` 里提出来，因为「阅读档案」页内联展示
/// 偏好分布 / 性格标签后，两处都要用同一套外壳——各写一份迟早
/// 会在圆角或间距上漂移，两个页面并排看就露馅。
Widget archiveSection(
  ThemeData theme, {
  required String title,
  String? subtitle,
  Widget? trailing,
  required Widget child,
}) {
  final cs = theme.colorScheme;
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 标题必须能被压缩。
            //
            // 原来是 `Text(title) + Spacer() + Text(subtitle)`：Row 会先按
            // 自然宽度放下两个「不灵活」的 Text，再处理 Spacer；一旦两者宽度
            // 之和超过可用宽度，Spacer 只能拿到 0，Row 直接溢出。
            // 换成 Expanded 后标题占满剩余空间，副标题自然贴到右边缘，
            // 视觉与原来一致（标题左对齐、副标题右对齐），且永不溢出。
            //
            // ⚠️ 副标题因此不能太长：它是「不灵活」的那一个，宽度完全由自己
            // 决定。当前各处副标题都是「{n} 本藏书推出」「共 {n} 类」这类短句，
            // 请保持这个量级。
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            if (trailing != null) trailing,
            if (subtitle != null) ...[
              const SizedBox(width: 8),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

/// 档案页的空态。
Widget archiveEmpty(ColorScheme cs, String text) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_outlined,
              size: 28, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

/// 供 [archiveSection] 之外的地方复用的提示小字。
Widget archiveNote(String text, ColorScheme cs) => Text(
      text,
      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
    );

/// 分类规范值 → 当前语言显示名。
///
/// `PreferenceSlice.label` 存的是**规范值**（「文学」这样的中文常量），
/// 它是气泡图取色的 key，不能本地化。所有渲染点都必须过这一层。
String localizedCategory(String canonical) => categoryLabel(canonical);
