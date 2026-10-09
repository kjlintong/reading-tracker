import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'ai_report_page.dart';
import 'archive_section.dart';
import 'profile_sections.dart';

/// 阅读档案：偏好分布 + 性格标签 + 阅读报告。
///
/// 为什么把这几块合到一个入口：「阅读画像」与「AI 报告」回答的其实是
/// 同一类问题——「我是怎样的读者 / 我读出了什么」。拆成多个入口
/// 只是让用户多点几次、还得自己判断该进哪个。
///
/// **顺序：偏好分布 → 性格标签 → 阅读报告**。
/// 前者是「我是谁」（静态画像），后者是「我做完了什么」（回顾），
/// 画像在上、回顾在下符合这一页的自然节奏。
///
/// 偏好分布与性格标签**完全内联展示**：这两块是用户点进档案最想
/// 第一眼看到的内容，多一层跳转就是多一次犹豫。以前页尾还留了一张
/// 「阅读画像」入口卡，但内联版已经能改标签、看分布，那张卡只会在
/// 用户滚动到底时暗示「这里好像还缺点东西」。已删除。
///
/// **阅读计划不在这里**。计划是「我正在做什么」，与笔记同属
/// 「进行中的产出」，已并入第二栏「记录」；档案只留回顾性的内容。
class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = S.of(context);
    // 自动生成了一份新报告时，这里会非 null。关闭后置回 null，
    // 状态存在 provider 里——放本地变量会在重建时丢失，
    // 那条提示就永远消不掉了。
    final notice = ref.watch(autoReportNoticeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.insights)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (notice != null)
            AutoReportNotice(
              message: notice,
              onDismiss: () => ref.read(autoReportNoticeProvider.notifier).state = null,
            ),
          Text(l10n.insightsDesc,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),

          /* ------------------ ① 偏好分布 + ② 性格标签 ------------------ */
          // 两块都内联呈现。它们共用一份画像数据，所以一起交给
          // ProfileSections 加载，避免这页再解析一遍同样的库查询。
          const ProfileSections(),

          /* ------------------------- ③ 阅读报告 ------------------------- */
          const SizedBox(height: 24),
          const AiReportPanel(showEncouragement: false),
        ],
      ),
    );
  }
}
