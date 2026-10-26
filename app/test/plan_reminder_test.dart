import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/report_period.dart';
import 'package:reading_tracker/models/reading_plan.dart';
import 'package:reading_tracker/services/auto_report_service.dart';
import 'package:reading_tracker/services/plan_reminder.dart';

void main() {
  group('每日打卡写入（回归）', () {
    // 这条用例守的是用户报告的「点击完成没反应」。
    //
    // 根因：`markedDates` 在 checkins 为空时返回 `const {}`，
    // 打卡逻辑对它 `..add(today)` 会抛 UnsupportedError。异常在 async
    // 链里没人接，于是既没写库也没重绘——界面上「点了跟没点一样」。
    //
    // 如果哪天有人为了「省一点分配」把这里改回 const，这条会立刻红。
    test('空 checkins 时也能 add 打卡日期', () {
      final p = ReadingPlan(
        id: 'p1',
        kind: PlanKind.dailyMinutes,
        createdAt: '2026-10-01T00:00:00.000',
        dailyMinutes: 20,
      );
      expect(p.checkins, isNull);

      final set = p.markedDates..add('2026-10-09');
      expect(set, contains('2026-10-09'));
      expect(p.markedDates, isEmpty,
          reason: 'markedDates 必须每次返回新集合，不能是共享实例');
    });

    test('两次打卡互不污染', () {
      final p = ReadingPlan(
        id: 'p1',
        kind: PlanKind.dailyMinutes,
        createdAt: '2026-10-01T00:00:00.000',
        dailyMinutes: 20,
        checkins: '2026-10-08',
      );
      final a = p.markedDates..add('2026-10-09');
      final b = p.markedDates;
      expect(a.length, 2);
      expect(b.length, 1, reason: '第二次取用不能被上一次 add 污染');
    });

    test('打卡后 doneToday 为真，连续天数累加', () {
      final today = ReadingPlan.todayIso();
      var p = ReadingPlan(
        id: 'p1',
        kind: PlanKind.dailyMinutes,
        createdAt: '2026-10-01T00:00:00.000',
        dailyMinutes: 20,
      );
      expect(p.doneToday(), isFalse);
      p = p.copyWith(lastDoneOn: today, checkins: today);
      expect(p.doneToday(), isTrue);
      expect(p.streak, 1);
    });
  });

  group('提醒时刻：每天 21:00', () {
    test('未到 21:00 排今天', () {
      final at = PlanReminderService.nextDailySlot(DateTime(2026, 10, 9, 14));
      expect(at, DateTime(2026, 10, 9, 21));
    });

    test('正好 21:00 顺延到明天，避免刚设就响', () {
      final at = PlanReminderService.nextDailySlot(DateTime(2026, 10, 9, 21));
      expect(at, DateTime(2026, 10, 10, 21));
    });

    test('已过 21:00 顺延到明天', () {
      final at = PlanReminderService.nextDailySlot(DateTime(2026, 10, 9, 23, 30));
      expect(at, DateTime(2026, 10, 10, 21));
    });

    test('跨月顺延正确', () {
      final at = PlanReminderService.nextDailySlot(DateTime(2026, 10, 31, 22));
      expect(at, DateTime(2026, 11, 1, 21));
    });

    test('提醒时刻常量就是 21 点', () {
      expect(PlanReminderService.reminderHour, 21);
    });
  });

  group('提醒时刻：到期前三天 21:00', () {
    test('距截止 5 天 → 前 3 天 21:00', () {
      final at = PlanReminderService.bookReminderAt(
        DateTime(2026, 10, 14),
        now: DateTime(2026, 10, 9, 10),
      );
      expect(at, DateTime(2026, 10, 11, 21));
    });

    test('距截止不足 3 天不排（不是失败，是没必要）', () {
      expect(
        PlanReminderService.bookReminderAt(
          DateTime(2026, 10, 11),
          now: DateTime(2026, 10, 9, 10),
        ),
        isNull,
      );
    });

    test('已过期不排', () {
      expect(
        PlanReminderService.bookReminderAt(
          DateTime(2026, 10, 1),
          now: DateTime(2026, 10, 9),
        ),
        isNull,
      );
    });

    test('跨月减三天不会算错', () {
      // 11 月 2 日截止 → 提醒在 10 月 30 日。减法必须能向前借月。
      final at = PlanReminderService.bookReminderAt(
        DateTime(2026, 11, 2),
        now: DateTime(2026, 10, 9),
      );
      expect(at, DateTime(2026, 10, 30, 21));
    });

    test('跨年减三天正确', () {
      final at = PlanReminderService.bookReminderAt(
        DateTime(2027, 1, 2),
        now: DateTime(2026, 12, 20),
      );
      expect(at, DateTime(2026, 12, 30, 21));
    });
  });

  group('自动生成的周期选择', () {
    test('年报取去年、月报取上月', () {
      final t = ReportPeriod.autoTargets(now: DateTime(2026, 9, 30));
      expect(t.map((p) => p.key).toList(), ['2026-08', '2025']);
    });

    test('1 月回退到去年 12 月，年报仍是去年', () {
      final t = ReportPeriod.autoTargets(now: DateTime(2027, 1, 5));
      expect(t.map((p) => p.key).toList(), ['2026-12', '2026']);
    });

    test('自动生成的周期必须在候选列表里（下拉框要能选中）', () {
      // DropdownButton 的 value 必须在 items 里，否则运行期断言崩。
      final cands = ReportPeriod.candidates(now: DateTime(2027, 1, 5));
      for (final p in ReportPeriod.autoTargets(now: DateTime(2027, 1, 5))) {
        expect(cands.any((c) => c.key == p.key), isTrue,
            reason: '${p.key} 不在候选里，点开历史报告会崩');
      }
    });

    test('候选含近 4 年，覆盖去年年报', () {
      final list = ReportPeriod.candidates(now: DateTime(2027, 1, 5));
      expect(list.where((p) => p.isYear).length, 4);
      expect(list.any((p) => p.key == '2026'), isTrue);
    });
  });

  group('自动生成的开关与节流', () {
    final now = DateTime(2026, 9, 30);

    test('总开关关闭时不跑', () {
      expect(
        AutoReportPlanner.shouldRun(
          enabled: false,
          wantYear: true,
          wantMonth: true,
          alreadyRanThisMonth: false,
          now: now,
        ),
        isFalse,
      );
    });

    test('两种报告都没开时不跑', () {
      expect(
        AutoReportPlanner.shouldRun(
          enabled: true,
          wantYear: false,
          wantMonth: false,
          alreadyRanThisMonth: false,
          now: now,
        ),
        isFalse,
      );
    });

    test('本月已跑过就不再跑（防止每天烧 token）', () {
      expect(
        AutoReportPlanner.shouldRun(
          enabled: true,
          wantYear: true,
          wantMonth: true,
          alreadyRanThisMonth: true,
          now: now,
        ),
        isFalse,
      );
    });

    test('正常情况会跑', () {
      expect(
        AutoReportPlanner.shouldRun(
          enabled: true,
          wantYear: true,
          wantMonth: false,
          alreadyRanThisMonth: false,
          now: now,
        ),
        isTrue,
      );
    });

    test('只开月报时，年报不进待生成', () {
      final targets = ReportPeriod.autoTargets(now: now);
      final pending = AutoReportPlanner.pending(
        targets: targets,
        existing: {},
        wantYear: false,
        wantMonth: true,
      );
      expect(pending.map((p) => p.key).toList(), ['2026-08']);
    });

    test('已存档的周期不重复生成', () {
      final targets = ReportPeriod.autoTargets(now: now);
      final pending = AutoReportPlanner.pending(
        targets: targets,
        existing: {'2026-08'},
        wantYear: true,
        wantMonth: true,
      );
      expect(pending.map((p) => p.key).toList(), ['2025']);
    });

    test('全都齐了就没有待生成', () {
      final pending = AutoReportPlanner.pending(
        targets: ReportPeriod.autoTargets(now: now),
        existing: {'2026-08', '2025'},
        wantYear: true,
        wantMonth: true,
      );
      expect(pending, isEmpty);
    });

    test('月份标记补零', () {
      expect(AutoReportPlanner.monthTag(DateTime(2026, 9, 5)), '2026-09');
      expect(AutoReportPlanner.monthTag(DateTime(2026, 12, 31)), '2026-12');
    });

    test('默认兜底是年报+月报（与设置页默认值同源）', () {
      // 这条守的是「设置里没写过这个键」的用户：启动时的兜底必须与
      // 报告设置页显示的默认开关一致，否则用户看到一个关着的月报开关，
      // 却每月照样被自动生成——完全无法理解。
      //
      // 断言的是**行为**而非字面量：拿兜底串去跑一遍 planner，
      // 确认它真的会把两个周期都放进待生成。
      const fallback = 'year,month';
      final pending = AutoReportPlanner.pending(
        targets: ReportPeriod.autoTargets(now: DateTime(2026, 9, 30)),
        existing: {},
        wantYear: fallback.contains('year'),
        wantMonth: fallback.contains('month'),
      );
      expect(pending.map((p) => p.key).toList(), ['2026-08', '2025']);
    });
  });

  group('提醒体检（用户报「提醒只在打开 App 时才有」）', () {
    // 用户报的现象是：App 开着就收到提醒，不开就收不到。
    // 成因全在系统侧，App 里看不出来，只能靠体检把状态摆出来。
    // 这些判据决定设置页上「后台运行」那一行显示什么、
    // 要不要给出「去调整后台运行」的入口。

    test('没豁免电池优化 → 判为后台受限', () {
      // 没豁免就判受限：宁可多提醒一次用户去设置里看一眼，
      // 也不能反过来——放过了受限的用户就永远收不到提醒。
      const d = ReminderDiagnostics(
        pluginReady: true,
        notificationsAllowed: true,
        batteryExempt: false,
      );
      expect(d.backgroundRestricted, isTrue);
      expect(d.ok, isFalse, reason: '受限就不算一切正常');
    });

    test('豁免了电池优化且是原生 ROM → 不判受限', () {
      const d = ReminderDiagnostics(
        pluginReady: true,
        notificationsAllowed: true,
        batteryExempt: true,
        romBrand: '',
      );
      expect(d.backgroundRestricted, isFalse);
      expect(d.ok, isTrue);
    });

    test('国产 ROM 即便豁免了电池优化，仍要提示开自启动', () {
      // 小米/华为/OPPO/vivo 的「自启动」是**独立于电池优化**的一道开关：
      // 关着的话系统照样会清掉 AlarmManager 里的闹钟。
      // 只看 batteryExempt 会漏掉这一类——而这恰好是最常见的那个。
      for (final brand in ['miui', 'coloros', 'emui', 'harmony', 'originos']) {
        final d = ReminderDiagnostics(
          pluginReady: true,
          notificationsAllowed: true,
          batteryExempt: true,
          romBrand: brand,
        );
        expect(d.backgroundRestricted, isTrue, reason: brand);
      }
    });

    test('通知没允许 → 一定不算正常', () {
      const d = ReminderDiagnostics(
        pluginReady: true,
        notificationsAllowed: false,
        batteryExempt: true,
      );
      expect(d.ok, isFalse);
    });

    test('插件不可用时不算正常，且不抛异常', () {
      const d = ReminderDiagnostics();
      expect(d.pluginReady, isFalse);
      expect(d.ok, isFalse);
      expect(d.scheduledCount, 0);
    });
  group('重排期筛选（needsReminder）', () {
    // 这条筛选决定了「哪些计划该有系统闹钟」。
    // 写错了两种表现都很隐蔽：
    //  - 漏排：用户开了提醒却收不到（就是这次报的那个问题）；
    //  - 多排：已经结束的计划还在响，或者用户自己关掉的提醒又冒出来。

    ReadingPlan daily({
      String id = 'p1',
      bool remind = true,
      bool done = false,
    }) =>
        ReadingPlan(
          id: id,
          kind: PlanKind.dailyMinutes,
          createdAt: '2026-10-01T00:00:00.000',
          dailyMinutes: 20,
          reminderEnabled: remind,
          done: done,
        );

    test('开了提醒且未结束 → 要排', () {
      final out = PlanReminderService.needsReminder([daily()]);
      expect(out.length, 1);
      expect(out.first.id, 'p1');
    });

    test('没开提醒 → 不排', () {
      final out = PlanReminderService.needsReminder([daily(remind: false)]);
      expect(out, isEmpty);
    });

    test('已整体结束 → 不排', () {
      final out = PlanReminderService.needsReminder([daily(done: true)]);
      expect(out, isEmpty);
    });

    test('每日型打卡后仍要排——「今天读完」不等于计划结束', () {
      // 这是最容易写错的一条：打卡只写 lastDoneOn，done 仍是 false。
      // 若筛选误用 lastDoneOn 判断，用户的每日提醒会在打第一次卡后消失。
      final p = daily().copyWith(lastDoneOn: '2026-10-26');
      expect(p.done, isFalse);
      expect(PlanReminderService.needsReminder([p]).length, 1);
    });

    test('混合批次里只挑出该排的那些', () {
      final out = PlanReminderService.needsReminder([
        daily(id: 'a'),
        daily(id: 'b', remind: false),
        daily(id: 'c', done: true),
        daily(id: 'd'),
      ]);
      expect(out.map((p) => p.id).toList(), ['a', 'd']);
    });

    test('空批次不炸', () {
      expect(PlanReminderService.needsReminder([]), isEmpty);
    });
  });
  group('提醒是否真的会响（reminderWillFire）', () {
    // 这条判定决定卡片上写「🔔 到期前提醒我」还是「已逾期，不会再提醒」。
    //
    // 写错的后果：一条早已逾期的计划照样显示「到期前提醒我」，
    // 用户等不到提醒只会更困惑——「我明明开了提醒」。
    // 反过来写错更糟：真的会响的计划显示成「不会再提醒」，用户就不管了。

    String isoInDays(int days) {
      final d = DateTime.now().add(Duration(days: days));
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    ReadingPlan book({
      String? due,
      bool remind = true,
    }) =>
        ReadingPlan(
          id: 'b1',
          kind: PlanKind.finishBook,
          createdAt: '2026-10-01T00:00:00.000',
          bookId: 'book-1',
          dueDate: due,
          reminderEnabled: remind,
        );

    test('每日型：只要开着提醒就永远会响', () {
      final p = ReadingPlan(
        id: 'd1',
        kind: PlanKind.dailyMinutes,
        createdAt: '2026-10-01T00:00:00.000',
        dailyMinutes: 20,
        reminderEnabled: true,
      );
      expect(p.reminderWillFire, isTrue);
    });

    test('没开提醒 → 不会响', () {
      final p = ReadingPlan(
        id: 'd2',
        kind: PlanKind.dailyMinutes,
        createdAt: '2026-10-01T00:00:00.000',
        dailyMinutes: 20,
        reminderEnabled: false,
      );
      expect(p.reminderWillFire, isFalse);
    });

    test('书本型：距截止 5 天 → 会响（提醒排在截止前 3 天）', () {
      expect(book(due: isoInDays(5)).reminderWillFire, isTrue);
    });

    test('书本型：距截止正好 3 天 → 会响（正是提醒时刻）', () {
      expect(book(due: isoInDays(3)).reminderWillFire, isTrue);
    });

    test('书本型：距截止不足 3 天 → 不会响', () {
      // 「还有 3 天到期」在只剩 2 天时说出来只会让人困惑，
      // 所以系统干脆不排——卡片也必须如实说「不会再提醒」。
      expect(book(due: isoInDays(2)).reminderWillFire, isFalse);
      expect(book(due: isoInDays(1)).reminderWillFire, isFalse);
    });

    test('书本型：已逾期 → 不会响', () {
      expect(book(due: isoInDays(-1)).reminderWillFire, isFalse);
      expect(book(due: isoInDays(-30)).reminderWillFire, isFalse);
    });

    test('书本型：没设截止日 → 不会响（算不出提醒时刻）', () {
      expect(book(due: null).reminderWillFire, isFalse);
    });

    test('书本型：截止日非法 → 不会响', () {
      expect(book(due: '不是日期').reminderWillFire, isFalse);
    });
  });
  });
}
