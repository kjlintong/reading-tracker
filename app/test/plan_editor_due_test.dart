import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/models/reading_plan.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/plan_editor_sheet.dart';

import 'support/localized_app.dart';

/// 计划编辑抽屉：截止日选择器的行为。
///
/// ## 这一组测试要钉住什么
///
/// 编辑一条**已逾期**的读书计划时，点「截止日」必须能打开日期选择器，
/// 而且日历要停在**已存的那个截止日**上。
///
/// 旧实现把 `firstDate` 固定成「昨天」，于是已存截止日落在下限之前：
/// - debug 下 `showDatePicker` 断言失败 → 点开就是红屏；
/// - release 下不报错，日历翻到没有那一天的月份，
///   存着的截止日在界面上消失，保存后被静默改成别的日期。
///
/// 所以这里既要点得开（不能崩），也要看得对（停在已存日期上）。
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  late Database raw;
  late BookRepository repo;

  String nowIso() => DateTime.now().toIso8601String();

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  Widget harness(Widget child) => ProviderScope(
        overrides: [repoProvider.overrideWithValue(repo)],
        child: localizedApp(
          // 抽屉本体是 bottom sheet 的内容，依赖 Material 祖先
          //（InkWell 的墨水效果要往上找 Material）。
          // 直接把它当 home 挂上去会抛「No Material widget found」。
          home: Scaffold(body: child),
        ),
      );

  /// 数据库查询是真实异步，testWidgets 跑在 FakeAsync 里，
  /// 不交还控制权给真实事件循环，Future 永远不 resolve。
  Future<void> settleAsync(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  Future<void> pumpEditor(WidgetTester tester, ReadingPlan plan) async {
    await tester.pumpWidget(harness(PlanEditorSheet(plan: plan)));
    await settleAsync(tester);
  }

  ReadingPlan overduePlan() {
    final past = DateTime.now().subtract(const Duration(days: 40));
    return ReadingPlan(
      id: 'p1',
      kind: PlanKind.finishBook,
      createdAt: nowIso(),
      bookId: 'b1',
      dueDate:
          '${past.year.toString().padLeft(4, '0')}-'
          '${past.month.toString().padLeft(2, '0')}-'
          '${past.day.toString().padLeft(2, '0')}',
    );
  }

  testWidgets('已逾期的计划点开截止日：日期选择器能打开（不崩）',
      (tester) async {
    await pumpEditor(tester, overduePlan());

    // 抽屉里能看到已存的截止日
    final past = DateTime.now().subtract(const Duration(days: 40));
    final dueText =
        '${past.year.toString().padLeft(4, '0')}-'
        '${past.month.toString().padLeft(2, '0')}-'
        '${past.day.toString().padLeft(2, '0')}';
    expect(find.text(dueText), findsOneWidget);

    // 点它 —— 旧实现在这里直接断言失败（debug），
    // 测试因此会在这里抛异常而不是走到下一行。
    await tester.tap(find.text(dueText));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('已逾期的计划：日历停在已存的那个截止日上',
      (tester) async {
    await pumpEditor(tester, overduePlan());

    final past = DateTime.now().subtract(const Duration(days: 40));
    final dueText =
        '${past.year.toString().padLeft(4, '0')}-'
        '${past.month.toString().padLeft(2, '0')}-'
        '${past.day.toString().padLeft(2, '0')}';
    await tester.tap(find.text(dueText));
    await tester.pumpAndSettle();

    // 日历翻到了已存截止日所在的月份，且那天被选中。
    // 旧实现会把日历翻到「现在」这个月 —— 已存日期所在的那个月
    // 根本不在视野里，日期事实上就「消失」了。
    final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(picker.initialDate, isNotNull);
    expect(
      '${picker.initialDate!.year.toString().padLeft(4, '0')}-'
      '${picker.initialDate!.month.toString().padLeft(2, '0')}-'
      '${picker.initialDate!.day.toString().padLeft(2, '0')}',
      dueText,
      reason: '日历必须落在已存的截止日上，而不是跳到别的月份',
    );
  });

  testWidgets('已逾期的计划：下限退到已存截止日，那一天仍可选',
      (tester) async {
    await pumpEditor(tester, overduePlan());

    final past = DateTime.now().subtract(const Duration(days: 40));
    final dueText =
        '${past.year.toString().padLeft(4, '0')}-'
        '${past.month.toString().padLeft(2, '0')}-'
        '${past.day.toString().padLeft(2, '0')}';
    await tester.tap(find.text(dueText));
    await tester.pumpAndSettle();

    final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));

    // 下限必须退到已存截止日本身 —— 早于它的那天不可选，
    // 但**截止日当天要能选回去**（这是修复的核心）。
    // 旧实现的下限固定在「昨天」，于是截止日当天反而选不了。
    expect(
      '${picker.firstDate!.year.toString().padLeft(4, '0')}-'
      '${picker.firstDate!.month.toString().padLeft(2, '0')}-'
      '${picker.firstDate!.day.toString().padLeft(2, '0')}',
      dueText,
      reason: '下限应退到已存截止日，而不是固定在「昨天」',
    );

    // 日格本身也要是可点的。
    // Material 3 的日期头会把日号渲染成大号文字，
    // 所以不能直接 find.text(日号)（会同时命中标题）——
    // 必须限定在 InkResponse 里面：被禁用的日格没有 InkResponse
    // （源码里 isDisabled 时只包一层 ExcludeSemantics）。
    final dayNo = '${picker.initialDate!.day}';
    final dayCell = find.descendant(
      of: find.byType(InkResponse),
      matching: find.text(dayNo),
    );
    expect(dayCell, findsWidgets,
        reason: '截止日当天在日历里应当是可点的（存在 InkResponse）');

    // 点它 —— Material 3 的日历模式下，点日期**只改选中态，不关弹窗**，
    // 还要再点「确定」才返回。所以这里分两步。
    await tester.tap(dayCell.first);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget,
        reason: 'Material 3 日历模式下点日期不直接关闭弹窗');

    // 点「确定」。文案随语言变，从 MaterialLocalizations 取，别硬编码。
    final ctx = tester.element(find.byType(DatePickerDialog));
    final okLabel = MaterialLocalizations.of(ctx).okButtonLabel;
    await tester.tap(find.widgetWithText(TextButton, okLabel));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
    expect(find.text(dueText), findsOneWidget,
        reason: '选回原截止日后，抽屉里显示的日期应当没变');
  });
}
