import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_loc.dart';
import '../models/book.dart';
import '../models/reading_plan.dart';
import '../providers.dart';
import 'plan_editor_sheet.dart';
import 'theme.dart';

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

  /// 刚打卡的那张卡片的 id，用于一次性描边高亮。定时清空。
  String? _pulsing;

  /// 高亮复原用的定时器。dispose 时必须取消，见 [_pulse]。
  Timer? _pulseTimer;

  /// 打卡后的确认小字，挂在对应卡片上。见 [_toast]。
  final Map<String, String> _flash = {};

  /// 确认小字的自动消失定时器（按卡片 id 记）。
  final Map<String, Timer> _flashTimers = {};

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
  ///
  /// 打卡**必须给即时反馈**（震动 + 卡片高亮 + SnackBar）。
  /// 以前这里只是「写库 → 重新加载」：数据确实变了，但界面只有一个
  /// 图标从空心圈变成实心圈，在安静的列表里几乎看不见。用户报告
  /// 「点击完成也没反应」——不是真没写进去，是**看不出写进去了**。
  /// 修 `markedDates` 的 const 集合只是让它真能写进去；让人敢确认，
  /// 还得让这一次点击在视觉与触觉上都成立。
  Future<void> _toggleDone(ReadingPlan p) async {
    final repo = ref.read(repoProvider);
    final reminders = ref.read(planReminderProvider);

    if (p.kind == PlanKind.dailyMinutes) {
      final today = ReadingPlan.todayIso();
      final wasDone = p.doneToday();
      if (wasDone) {
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
      await _load();

      if (!mounted) return;
      if (wasDone) {
        _pulse(p.id);
        _toast(p.id, appLoc.planCheckinUndone);
      } else {
        // 连续天数要在**写入之后**才算得准，所以这里重新构造一份计划。
        final fresh = _plans.firstWhere(
          (e) => e.id == p.id,
          orElse: () => p.copyWith(lastDoneOn: today, checkins: today),
        );
        _pulse(p.id);
        HapticFeedback.mediumImpact();
        _toast(
          p.id,
          fresh.streak > 1
              ? appLoc.planCheckedInStreak(n: fresh.streak)
              : appLoc.planCheckedIn,
        );
      }
    } else {
      await repo.upsertPlan(p.copyWith(
        done: true,
        doneAt: DateTime.now().toIso8601String(),
      ));
      // 一次性目标完成了就把提醒撤掉，否则提醒会在目标早已达成后继续响。
      await reminders.cancel(p.id);
      await _load();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _toast(p.id, appLoc.planFinishedToast);
    }
  }

  /// 弹一条确认提示。
  ///
  /// ## 为什么不用 SnackBar
  ///
  /// SnackBar 在本项目里踩过两次坑，两次都不是测试环境的问题：
  ///
  ///  1. **状态会跨页面留存**。`ScaffoldMessenger` 挂在 App 根部，
  ///     上一个页面退场时它并不销毁——留在树上的旧条会让紧接着的
  ///     `showSnackBar` 断言失败（"A dismissed SnackBar was shown"）。
  ///     快速连续打卡必然触发。
  ///  2. **它会消失**。用户划走列表、或过两秒回神时，那句提示已经没了，
  ///     而「我刚才那一下到底生效没有」恰恰需要稍后再确认一次。
  ///
  /// 所以确认信息**写进卡片本身**：打卡后卡片上出现一条主色小字，
  /// 持续显示到下一次操作。它不会消失、不会顶掉别的页面的提示，
  /// 而且和「连续打卡 N 天」放在一起，是打卡后就地可核对的事实，
  /// 比一闪而过的浮层更实在。
  /// 打卡后的确认信息，写进 [planId] 那张卡片（见 [_toast]）。
  void _toast(String planId, String msg) {
    if (!mounted) return;
    setState(() => _flash[planId] = msg);
    _flashTimers[planId]?.cancel();
    _flashTimers[planId] = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _flash.remove(planId));
      _flashTimers.remove(planId);
    });
  }

  /// 让某张计划卡闪一下主色描边，确认「刚才点的那一下生效了」。
  ///
  /// 定时器**必须在 [dispose] 里取消**：`Future.delayed` 在 widget 测试里
  /// 是 FakeAsync 的 pending timer，页面在它到期前被拆掉时，
  /// flutter_test 会在收尾断言「Timer is still pending」而整例失败——
  /// 表现为断言全过、结果却挂。
  void _pulse(String id) {
    if (!mounted) return;
    _pulseTimer?.cancel();
    setState(() => _pulsing = id);
    _pulseTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && _pulsing == id) setState(() => _pulsing = null);
    });
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    // 每个待触发的定时器都要取消：留在 FakeAsync 里会让 widget 测试
    // 在收尾时断言「Timer is still pending」而整例失败。
    for (final t in _flashTimers.values) {
      t.cancel();
    }
    _flashTimers.clear();
    super.dispose();
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
    //
    // 每日型要**排除**这一条：达成口径是「今天读满了或今天打过卡」，
    // 明天自然为假。若在这里一并隐藏按钮，用户会看到「点完之后按钮
    // 就再也不见了，第二天想继续打卡却找不到入口」——这是把周期任务
    // 做成了一次性任务的观感。每日型保持按钮常驻，靠 `todayDone` 换文案。
    final isDaily = p.kind == PlanKind.dailyMinutes;
    final achieved = prog?.achieved ?? false;
    final isDone = done || (achieved && !isDaily);

    // 每日型是周期任务：勾了只对今天生效，明天照旧。
    final todayDone = isDaily && p.doneToday();
    // 一张卡片在视觉上「已完成」= 计划整体结束，或今天已打卡。
    final doneLook = isDone || todayDone;
    final pulsing = _pulsing == p.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        // 打卡后短暂描一圈主色边，让这一次点击在视觉上「落地」。
        // 描边而不是填充：填充会盖掉卡片的皮肤半透明底。
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pulsing ? cs.primary : Colors.transparent,
          width: 1.6,
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
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
                    backgroundColor:
                        panelColor(context, cs.surfaceContainerHighest),
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
                            todayDone
                                ? appLoc.planDoneToday
                                : appLoc.planMarkToday,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                todayDone ? cs.primary : null,
                            visualDensity: VisualDensity.compact,
                            // 已打卡时仍可点——那是「取消今天的打卡」，
                            // 允许反悔。样式上用浅色底提示这是可撤销状态。
                            backgroundColor:
                                todayDone ? cs.primary.withOpacity(0.10) : null,
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
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
                // 每日型的「周期」语义得说清楚，否则用户又会以为
                // 「勾完这次就没了」。规则推导的可解释性一直不够，
                // 所以这句只在每日型下出现。
                if (isDaily) ...[
                  const SizedBox(height: 5),
                  Text(appLoc.planDailyCycleHint,
                      style: TextStyle(
                          fontSize: 10.5, color: cs.onSurfaceVariant)),
                  if (p.streak > 0) ...[
                    const SizedBox(height: 3),
                    Text(appLoc.planStreak(n: p.streak),
                        style: TextStyle(fontSize: 11, color: cs.primary)),
                  ],
                ],
                // 打卡后的确认小字。挂在卡片上而不是浮在页面上：
                // 浮层会消失、还会和别的页面的提示互相顶掉（见 [_toast]）。
                if (_flash[p.id] != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 13, color: cs.primary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _flash[p.id]!,
                          style:
                              TextStyle(fontSize: 11.5, color: cs.primary),
                        ),
                      ),
                    ],
                  ),
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
