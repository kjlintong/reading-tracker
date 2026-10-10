import 'package:flutter/material.dart';

import '../l10n/app_loc.dart';

/// 自动搁置执行后，书架页顶部的提示条。
///
/// 告知用户这一轮挪走了几本书，并提供「撤销」——撤销会把它们恢复回
/// 「在读」并刷新阅读时间。提示条本身不持久（关掉或撤销后清空），
/// 状态存在 [autoShelveNoticeProvider] 里。
class AutoShelveNoticeBanner extends StatelessWidget {
  final String message;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;

  const AutoShelveNoticeBanner({
    super.key,
    required this.message,
    required this.onUndo,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 17, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12.5)),
          ),
          TextButton(
            onPressed: onUndo,
            child: Text(appLoc.undo),
          ),
          IconButton(
            iconSize: 17,
            visualDensity: VisualDensity.compact,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
