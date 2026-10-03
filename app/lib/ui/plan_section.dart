import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_loc.dart';
import '../models/book.dart';
import '../models/reading_plan.dart';
import '../providers.dart';
import 'plan_editor_sheet.dart';

/// 阅读计划板块。嵌在「记录」页（笔记 + 计划）里，不是独立导航栏。
///
/// 设计取舍：计划与笔记同属「用户亲手产出、还在增长」的内容——
/// 笔记是「已经记下的」，计划是「打算去做的」。放在一栏里，
/// 「记录自己的阅读」只需记住一个入口，也避免把已经很满的
/// 底部导航撑到六项。计划曾短暂地放在「阅读档案」里，但档案
/// 是回顾性的（我是怎样的读者），与前瞻性的计划语义不合，已迁出。
class PlanSection extends ConsumerStatefulWidget {
  const PlanSection({super.key});

  @override
  ConsumerState<PlanSection> createState() => _PlanSectionState();
}

class _PlanSectionState extends ConsumerState<PlanSection> {
  List<ReadingPlan> _plans = [];
  Map<String, PlanProgress> _progress = {};
  Map<String, Book> _books = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final repo = ref.read(repoProvider);
    final plans = await repo.plans();
    final books = <String, Book>{};
    for (final b in await repo.all()) {
      books[b.id] = b;
    }
    final prog = <String, PlanProgress>{};
    for (final p in plans) {
      prog[p.id] = await repo.planProgress(p);
    }
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _books = books;
      _progress = prog;
      _loading = false;
    });
  }

  Future<void> _edit([ReadingPlan? plan]) async {
    final saved = await showPlanEditorSheet(context, plan: plan);
    if (saved == true) _load();
  }

  Future<void> _delete(ReadingPlan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(appLoc.planDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(appLoc.planDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repoProvider).deletePlan(p.id);
    await ref.read(planReminderProvider).cancel(p.id);
    _load();
  }

  /// 在计划卡片面上勾一下。
  ///
  /// 两条分支，因为两种计划的「完成」根本不是一个意思：
  ///
  /// - **每日型**：每天读满 N 分钟是**周期任务**，永远不结束。
  ///   勾选只写 `lastDoneOn = 今天`，提醒**继续留着**——明天还要读。
  ///   从前这里写 `done: true` 并 `cancel` 提醒，于是「标记完成就没有了」，
  ///   与用户「这是个每天要做的习惯」的预期完全相反。
  /// - **读完某本书**：一次性目标，勾了就真的结束了，提醒同时撤掉。
  ///
  /// 再点一次取消勾选（每日型）：把 `lastDoneOn` 清掉，允许反悔。
  /// 一次性目标不给撤销——它已经移出「进行中」区，撤销入口在那张卡上。
  Future<void> _toggleDone(ReadingPlan p) async {
    final repo = ref.read(repoProvider);
    final reminders = ref.read(planReminderProvider);

    if (p.kind == PlanKind.dailyMinutes) {
      final today = ReadingPlan.todayIso();
      if (p.doneToday()) {
        // 取消今天的打卡：清掉 lastDoneOn，并从 checkins 集合里移除今天。
        final set = p.markedDates..remove(today);
        await repo.upsertPlan(p.copyWith(
          clearLastDoneOn: true,
          clearCheckins: set.isEmpty,
          checkins: set.isEmpty ? null : set.join(','),
        ));
      } else {
        // 打卡今天：写入 lastDoneOn，并把今天加进 checkins 集合——连续天数由此计算。
        final set = p.markedDates..add(today);
        await repo.upsertPlan(p.copyWith(
          lastDoneOn: today,
          checkins: set.join(','),
        ));
      }
      // 提醒不动：周期任务的提醒每天都该回来。
    } else {
      await repo.upsertPlan(p.copyWith(
        done: true,
        doneAt: DateTime.now().toIso8601String(),
      ));
      // 一次性目标完成了就把提醒撤掉，否则提醒会在目标早已达成后继续响。
      await reminders.cancel(p.id);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = _plans.where((p) => !p.done).toList();
    final donePlans = _plans.where((p) => p.done).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                appLoc.planSectionTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(appLoc.planAdd),
            ),
          ],
        ),
        Text(
          appLoc.planSectionDesc,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),

        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (active.isEmpty)
          _empty(cs)
        else
          for (final p in active)
            _planCard(p, _progress[p.id], done: false),

        if (donePlans.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(appLoc.planDoneSection,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          for (final p in donePlans.take(5))
            _planCard(p, _progress[p.id], done: true),
        ],
      ],
    );
  }

  Widget _empty(ColorScheme cs) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          appLoc.planEmpty,
          style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      );

  Widget _planCard(ReadingPlan p, PlanProgress? prog, {required bool done}) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final book = p.bookId != null ? _books[p.bookId] : null;

    final String title;
    if (p.title != null && p.title!.isNotEmpty) {
      title = p.title!;
    } else if (p.kind == PlanKind.dailyMinutes) {
      title = appLoc.planKindDaily;
    } else if (book != null) {
      title = book.title;
    } else {
      title = appLoc.planKindFinishBook;
    }

    // 达成态自己会「赢得」高亮：计划一旦达标就直接显示达成，
    // 不用用户再点一次「标记完成」，那一步纯属仪式感。
    final achieved = prog?.achieved ?? false;
    final isDone = done || achieved;

    // 每日型是周期任务：勾了只对今天生效，明天照旧。
    final isDaily = p.kind == PlanKind.dailyMinutes;
    final todayDone = isDaily && p.doneToday();
    // 一张卡片在视觉上「已完成」= 计划整体结束，或今天已打卡。
    final doneLook = isDone || todayDone;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  doneLook
                      ? Icons.check_circle
                      : (isDaily
                          ? Icons.timer_outlined
                          : Icons.menu_book_outlined),
                  size: 18,
                  color: doneLook ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(_subtitle(p, prog, book),
                          style: TextStyle(
                              fontSize: 11.5, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                // 编辑/删除收进「更多」里——它们是低频、破坏性操作，
                // 不该和主操作（打卡）抢同一行的注意力。
                IconButton(
                  tooltip: appLoc.planEdit,
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _edit(p),
                  icon: const Icon(Icons.edit_outlined),
                ),
                PopupMenuButton<String>(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  onSelected: (v) {
                    if (v == 'delete') _delete(p);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'delete', child: Text(appLoc.planDelete)),
                  ],
                ),
              ],
            ),

            if (prog != null && prog.target > 0 && !isDone) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: prog.ratio,
                  minHeight: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ],

            // 主操作直接摆在卡片面上：以前它藏在右上角的「⋯」二级菜单里，
            // 用户反馈「标记完成的按钮应该放在面上」——打卡是这张卡片
            // 最高频的动作，不该需要展开菜单才能找到。
            if (!isDone) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isDaily)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleDone(p),
                        icon: Icon(
                          todayDone
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          size: 17,
                        ),
                        label: Text(
                          todayDone ? appLoc.planDoneToday : appLoc.planMarkToday,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: todayDone ? cs.primary : null,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleDone(p),
                        icon: const Icon(Icons.check_circle_outline, size: 17),
                        label: Text(appLoc.planMarkDone,
                            style: const TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  if (p.reminderEnabled) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.notifications_active_outlined,
                        size: 15, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(appLoc.planRemind,
                        style:
                            TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
              // 每日型的「周期」语义得说清楚，否则用户又会以为
              // 「勾完这次就没了」。规则推导的可解释性一直不够，
              // 所以这句只在每日型下出现。
              if (isDaily) ...[
                const SizedBox(height: 5),
                Text(appLoc.planDailyCycleHint,
                    style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
                if (p.streak > 0) ...[
                  const SizedBox(height: 3),
                  Text(appLoc.planStreak(n: p.streak),
                      style: TextStyle(fontSize: 11, color: cs.primary)),
                ],
              ],
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 4),
                child: Text(
                  appLoc.planAchieved,
                  style: TextStyle(fontSize: 11.5, color: cs.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _subtitle(ReadingPlan p, PlanProgress? prog, Book? book) {
    if (p.kind == PlanKind.dailyMinutes) {
      if (prog == null) {
        return appLoc.planProgressDaily(
            current: '0', target: '${p.dailyMinutes ?? 0}');
      }
      return appLoc.planProgressDaily(
        current: prog.current.round().toString(),
        target: '${p.dailyMinutes ?? 0}',
      );
    }

    // 书本型
    if (p.bookId != null && book == null) return appLoc.planBookGone;
    final parts = <String>[
      // 用 int 传：占位符声明是 int，ARB 会自己做本地化数字格式化
      appLoc.planProgressBook(current: (prog?.current ?? 0).round()),
    ];
    if (p.dueDate != null) {
      final d = p.daysUntilDue;
      if (d == null) {
        parts.add(p.dueDate!);
      } else if (d > 0) {
        parts.add(appLoc.planDaysLeft(days: d));
      } else if (d == 0) {
        parts.add(appLoc.planDueToday);
      } else {
        parts.add(appLoc.planOverdue(days: -d));
      }
    }
    return parts.join(' · ');
  }
}
