import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import '../l10n/app_localizations.dart';

/// 首次启动的隐私政策同意弹窗。
///
/// **为什么必须存在**：国内应用商店审核要求 App 首次启动即以弹窗明示
/// 个人信息处理规则并取得用户明示同意，同意前不得收集个人信息、不得联网。
/// 这是上架的硬性门槛，不是可选的体验优化。
///
/// **设计约束**（照着审核规范逐条满足）：
/// - 按钮措辞是明确的「同意」/「不同意」，**不是**「好的 / 我知道了」；
/// - 不预勾选任何复选框；
/// - 弹窗内直接给出隐私政策全文链接，且弹窗内容本身摘要说明了
///   收集什么、用途、第三方 SDK，用户不点链接也能判断；
/// - 提供「不同意」路径：用户拒绝后照常可用 App，只是不发起网络请求
///   （App 本来也不在启动时联网），并明确告知用户在哪里能重新同意。
class PrivacyConsentDialog extends StatelessWidget {
  final VoidCallback onAgreed;

  /// 用户点「不同意」时的回调。传 null 则只关闭弹窗。
  final VoidCallback? onDeclined;

  const PrivacyConsentDialog({
    super.key,
    required this.onAgreed,
    this.onDeclined,
  });

  /// 展示弹窗并等待用户选择。
  ///
  /// 返回 true 表示用户明确同意。
  static Future<bool> show(
    BuildContext context, {
    required VoidCallback onAgreed,
    VoidCallback? onDeclined,
  }) async {
    final agreed = await showDialog<bool>(
      context: context,
      // 不可通过点击外部或返回键绕过——必须做出明确选择。
      barrierDismissible: false,
      builder: (ctx) => PrivacyConsentDialog(
        onAgreed: () {
          Navigator.of(ctx).pop(true);
          onAgreed();
        },
        onDeclined: onDeclined == null
            ? null
            : () {
                Navigator.of(ctx).pop(false);
                onDeclined();
              },
      ),
    );
    return agreed ?? false;
  }

  Future<void> _openPolicy(BuildContext context) async {
    final url = AppInfo.privacyPolicyFor(Localizations.localeOf(context));
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // 拉不起浏览器不是致命问题：摘要已在弹窗里给出，用户仍可做选择。
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.privacyDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.privacyDialogIntro,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _Bullet(
              icon: Icons.lock_outline,
              text: l10n.privacyDialogLocal,
            ),
            _Bullet(
              icon: Icons.cloud_outlined,
              text: l10n.privacyDialogOptional,
            ),
            _Bullet(
              icon: Icons.article_outlined,
              text: l10n.privacyDialogPermission,
            ),
            const SizedBox(height: 12),
            // 政策全文链接。放在弹窗内而不是只藏在设置页里——
            // 审核要求「明示」时能点开全文核查。
            InkWell(
              onTap: () => _openPolicy(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.privacyDialogFullPolicy,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 「不同意」放在左侧：审核要求提供**明确的拒绝选项**，
        // 位置与视觉权重都应当和「同意」区分开，不做成默认焦点。
        TextButton(
          onPressed: onDeclined == null
              ? () => Navigator.of(context).pop(false)
              : () {
                  Navigator.of(context).pop(false);
                  onDeclined!();
                },
          child: Text(l10n.privacyDialogDisagree),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onAgreed();
          },
          child: Text(l10n.privacyDialogAgree),
        ),
      ],
    );
  }
}

/// 弹窗里的一行要点（图标 + 文字）。
class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
