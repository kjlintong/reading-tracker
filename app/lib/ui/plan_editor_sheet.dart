import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_loc.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/reading_plan.dart';
import '../providers.dart';
import '../services/plan_reminder.dart';

/// 打开计划编辑抽屉。[plan] 为空表示新建。
/// 保存成功返回 true。
Future<bool?> showPlanEditorSheet(BuildContext context,
        {ReadingPlan? plan}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => PlanEditorSheet(plan: plan),
    );

class PlanEditorSheet extends ConsumerStatefulWidget {
  final ReadingPlan? plan;
  const PlanEditorSheet({super.key, this.plan});

  @override
  ConsumerState<PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends ConsumerState<PlanEditorSheet> {
  late PlanKind _kind;
  late final TextEditingController _title;
  late int _minutes;
  String? _bookId;
  String? _dueDate;
  late bool _remind;

  List<Book> _books = [];
  bool _booksLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _kind = p?.kind ?? PlanKind.dailyMinutes;
    _title = TextEditingController(text: p?.title ?? '');
    _minutes = p?.dailyMinutes ?? 20;
    _bookId = p?.bookId;
    _dueDate = p?.dueDate;
    _remind = p?.reminderEnabled ?? false;
    _loadBooks();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    // 只列「还没读完」的书：计划指向一本已读完的书没有意义。
    // 编辑既有计划时，把当前选中的那本也带上，否则下拉框会选不中。
    final all = await ref.read(repoProvider).all();
    final usable = all
        .where((b) => b.status != BookStatus.finished || b.id == _bookId)
        .toList();
    if (mounted) {
      setState(() {
        _books = usable;
        _booksLoading = false;
      });
    }
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final initial = _dueDate != null
        ? (DateTime.tryParse(_dueDate!) ?? now)
        : now.add(const Duration(days: 14));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save() async {
    // 书本型必须选到一本书，否则计划落库后无从判定
    if (_kind == PlanKind.finishBook && _bookId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(appLoc.planPickBook)));
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(repoProvider);
    final base = widget.plan;
    final plan = ReadingPlan(
      id: base?.id ??
          'plan_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      kind: _kind,
      createdAt: base?.createdAt ?? DateTime.now().toIso8601String(),
      title: _title.text.trim().isEmpty ? null : _title.text.trim(),
      dailyMinutes: _kind == PlanKind.dailyMinutes ? _minutes : null,
      bookId: _kind == PlanKind.finishBook ? _bookId : null,
      dueDate: _kind == PlanKind.finishBook ? _dueDate : null,
      reminderEnabled: _remind,
      done: base?.done ?? false,
      doneAt: base?.doneAt,
    );

    await repo.upsertPlan(plan);

    // 提醒的调度放在落库之后：先保证数据存下来了，
    // 万一通知权限被拒，也不至于把用户的计划一起弄丢。
    final reminders = ref.read(planReminderProvider);
    if (_remind) {
      final outcome = await reminders.schedule(plan);
      if (!mounted) {
        // 页面已经关了就不弹了（用户点了保存后立刻返回）
      } else if (outcome == ReminderOutcome.denied) {
        // 只有「真的没权限」才说权限。以前把「排不上」一律说成没权限，
        // 于是用户明明给了权限还被告知没开——见 ReminderOutcome 的注释。
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(appLoc.planReminderDenied)));
      } else if (outcome == ReminderOutcome.unavailable) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(appLoc.planReminderUnavailable)));
      }
      // scheduled / skippedNotDue：无需提示。后者是「这条计划按规则
      // 不用提醒」（截止日不足 3 天），属于正常情况，弹提示反而像报错。
    } else {
      await reminders.cancel(plan.id);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return SizedBox(
      height: maxH,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.plan == null ? appLoc.planAdd : appLoc.planEdit,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(appLoc.planSave),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                /* ------------------------- 类型 ------------------------- */
                SegmentedButton<PlanKind>(
                  segments: [
                    ButtonSegment(
                      value: PlanKind.dailyMinutes,
                      icon: const Icon(Icons.timer_outlined, size: 17),
                      label: Text(appLoc.planKindDaily),
                    ),
                    ButtonSegment(
                      value: PlanKind.finishBook,
                      icon: const Icon(Icons.menu_book_outlined, size: 17),
                      label: Text(appLoc.planKindFinishBook),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: _saving
                      ? null
                      : (s) => setState(() => _kind = s.first),
                ),
                const SizedBox(height: 6),
                Text(
                  _kind == PlanKind.dailyMinutes
                      ? appLoc.planKindDailyDesc
                      : appLoc.planKindFinishBookDesc,
                  style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),

                if (_kind == PlanKind.dailyMinutes) ...[
                  Text(appLoc.planDailyTarget,
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  // 15 分钟一档、20~120 分钟：日常目标落在这个区间的
                  // 绝大多数，做成滑块比数字键盘少一大堆点击
                  Slider(
                    value: _minutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    label: appLoc.planMinutesUnit(n: _minutes),
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _minutes = v.round()),
                  ),
                  Center(
                    child: Text(
                      appLoc.planMinutesUnit(n: _minutes),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ] else ...[
                  if (_booksLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child:
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _bookId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: appLoc.planPickBook,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final b in _books)
                          DropdownMenuItem(
                            value: b.id,
                            child: Text(b.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _bookId = v),
                    ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _saving ? null : _pickDue,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: appLoc.planDueLabel,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dueDate ?? appLoc.planDueUnset,
                              style: TextStyle(
                                color: _dueDate == null
                                    ? cs.onSurfaceVariant
                                    : cs.onSurface,
                              ),
                            ),
                          ),
                          const Icon(Icons.event_outlined, size: 18),
                          if (_dueDate != null)
                            IconButton(
                              iconSize: 16,
                              visualDensity: VisualDensity.compact,
                              onPressed: _saving
                                  ? null
                                  : () => setState(() => _dueDate = null),
                              icon: const Icon(Icons.close),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                TextField(
                  controller: _title,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: appLoc.planTitleLabel,
                    hintText: appLoc.planTitleHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),

                /* ------------------------- 提醒 ------------------------- */
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    secondary: Icon(Icons.notifications_outlined,
                        size: 20, color: cs.primary),
                    title: Text(appLoc.planRemind,
                        style: const TextStyle(fontSize: 13.5)),
                    subtitle: Text(
                      appLoc.planRemindOff,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                    value: _remind,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _remind = v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
