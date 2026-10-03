import '../l10n/app_loc.dart';

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/enums.dart';

/// 阅读状态 + 借阅编辑区。
///
/// 抽出来是因为「书籍详情页」和「手动编辑页」都要用同一套控件，
/// 两处各写一份必然会漂移——状态语义刚统一（见 [BookStatus] 的注释），
/// 再让两个界面各自解释一遍就白改了。
///
/// 两个设计决定：
///  1. **状态下面配一行说明**。「已读 vs 在读」的歧义不是换个词能消掉的，
///     得让用户看到判据是「进度到没到 100%」。这行字随选中的状态变化。
///  2. **借阅是独立开关，不是第五个状态**。勾上才展开来源与应还日期，
///     不勾就完全不占地方——绝大多数书不是借来的。
///
/// 第三个决定：**「已归还」不是关掉开关的同义词**。关掉开关是「我填错了，
/// 这本书其实不是借的」，归还则是「书还回去了，但它确实曾经是借来的」。
/// 两者对借阅数据的结果一样（都要清空），但对用户的心智完全不同——
/// 只提供开关的话，刚还完书的用户得自己想明白「得把开关关掉」，
/// 而那个动作在他眼里意味着「删除一个事实」，不是「完成一件事」。
class StatusEditor extends StatefulWidget {
  final BookStatus status;
  final bool isBorrowed;
  final String? borrowedFrom;
  final String? dueAt;

  /// 状态变更。父组件负责落库。
  final ValueChanged<BookStatus> onStatusChanged;

  /// 借阅开关变更。
  final ValueChanged<bool> onBorrowedChanged;

  /// 借阅来源变更（去抖由父组件处理）。
  final ValueChanged<String> onBorrowedFromChanged;

  /// 应还日期变更。null 表示清除。
  final ValueChanged<String?> onDueAtChanged;

  /// 标记已归还。父组件负责清空借阅字段**并取消还书提醒**。
  ///
  /// 可空：编辑页（[BookFormPage]）里还没有落库的书，归还语义不成立
  /// ——归还的是「已经在书架上的那本书」，不传就不显示这个按钮。
  final VoidCallback? onReturned;

  const StatusEditor({
    super.key,
    required this.status,
    required this.isBorrowed,
    required this.onStatusChanged,
    required this.onBorrowedChanged,
    required this.onBorrowedFromChanged,
    required this.onDueAtChanged,
    this.onReturned,
    this.borrowedFrom,
    this.dueAt,
  });

  @override
  State<StatusEditor> createState() => _StatusEditorState();
}

class _StatusEditorState extends State<StatusEditor> {
  /// 借阅来源输入框。**必须是长生命周期的 controller**：
  /// 放在 build 里 new 一个会让每次重建都重置光标位置
  /// （用户打第二个字时光标跳回开头），而且旧的那批永远不会被释放。
  late final TextEditingController _fromCtrl;

  @override
  void initState() {
    super.initState();
    _fromCtrl = TextEditingController(text: widget.borrowedFrom ?? '');
  }

  @override
  void didUpdateWidget(covariant StatusEditor old) {
    super.didUpdateWidget(old);
    // 外部值变了（例如从库里重载）才回写，避免打断用户正在进行的输入
    if (widget.borrowedFrom != old.borrowedFrom &&
        widget.borrowedFrom != _fromCtrl.text) {
      _fromCtrl.text = widget.borrowedFrom ?? '';
    }
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(appLoc.statusSectionTitle),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in BookStatus.values)
              ChoiceChip(
                label: Text(s.label, style: const TextStyle(fontSize: 12)),
                selected: widget.status == s,
                onSelected: (_) => widget.onStatusChanged(s),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(widget.status.hint,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),

        /* ------------------------- 借阅 ------------------------- */
        Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.local_library_outlined,
                    size: 20, color: cs.primary),
                title: Text(appLoc.borrowFlag,
                    style: const TextStyle(fontSize: 13.5)),
                value: widget.isBorrowed,
                onChanged: widget.onBorrowedChanged,
              ),
              if (widget.isBorrowed) ...[
                TextField(
                  controller: _fromCtrl,
                  onChanged: widget.onBorrowedFromChanged,
                  decoration: InputDecoration(
                    labelText: appLoc.borrowFrom,
                    hintText: appLoc.borrowFromHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                _DueDateRow(
                  dueAt: widget.dueAt,
                  onChanged: widget.onDueAtChanged,
                  theme: theme,
                ),
                const SizedBox(height: 6),

                // 归还动作。放在这块区域的**最下面**：用户的阅读顺序是
                // 「确认这是借的书 → 从谁那儿借的 → 什么时候还 → 还了」，
                // 归还天然是这条线的终点。
                //
                // 用 OutlinedButton 而不是 TextButton：这是这块区域里唯一
                // 会清数据、且不可撤销的操作，视觉重量要和旁边的日期选择
                // 拉开一档，避免手滑点中。
                if (widget.onReturned != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: widget.onReturned,
                      icon: const Icon(Icons.assignment_turned_in_outlined,
                          size: 17),
                      label: Text(appLoc.borrowReturn,
                          style: const TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appLoc.borrowReturnDesc,
                    style:
                        TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 应还日期一行：显示当前值与剩余天数，点右侧按钮选日期或清除。
///
/// 剩余天数直接标出来（「还有 3 天到期」/「已逾期 2 天」）——用户填了日期
/// 之后真正想知道的不是那个日期本身，而是「还剩几天」。
class _DueDateRow extends StatelessWidget {
  final String? dueAt;
  final ValueChanged<String?> onChanged;
  final ThemeData theme;

  const _DueDateRow({
    required this.dueAt,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final parsed = dueAt == null ? null : DateTime.tryParse(dueAt!);
    final days = _daysUntil(parsed);

    // 逾期用错误色，其他情况用普通文字色
    final (String text, Color color) = switch (days) {
      null => (appLoc.borrowDueUnset, cs.onSurfaceVariant),
      < 0 => (appLoc.borrowOverdue(days: -days), cs.error),
      _ => (appLoc.borrowDueIn(days: days), cs.onSurfaceVariant),
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parsed == null
                    ? appLoc.borrowDue
                    : '${appLoc.borrowDue} · '
                        '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-'
                        '${parsed.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(text, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.event_outlined, size: 16),
          onPressed: () => _pick(context, parsed),
          label: Text(appLoc.borrowDue),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(fontSize: 12),
          ),
        ),
        if (parsed != null)
          IconButton(
            tooltip: appLoc.borrowClearDue,
            iconSize: 18,
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }

  /// 按自然日算差值，与 [Book.daysUntilDue] 口径一致——
  /// 差一分钟不该算成「还有 0 天」。
  int? _daysUntil(DateTime? due) {
    if (due == null) return null;
    final now = DateTime.now();
    return DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  Future<void> _pick(BuildContext context, DateTime? current) async {
    final now = DateTime.now();
    final base = current ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      // 借阅的应还日期基本都在未来；允许往前选一点是为了补录逾期未还的书
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    onChanged(picked.toIso8601String());
  }
}

/// 区块标题。与 book_detail_page 里的 `_section` 同款，
/// 单独提出来是为了让两个页面看起来是一套排版。
class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}
