import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_loc.dart';
import '../models/reading_plan.dart';

/// 调度一条提醒的结果。
///
/// 以前 [PlanReminderService.schedule] 只返回 `bool`，调用方把 `false`
/// 一律当成「没权限」，于是**只要排不上就弹「通知权限没开」**——
/// 而实际原因可能是「截止日不足 3 天所以没排」「计划没填截止日」
/// 「平台通道不可用」。用户明明给了权限却被告知没权限，
/// 就是这么来的。这里把原因显式带出来，让 UI 说人话。
enum ReminderOutcome {
  /// 已排上。
  scheduled,

  /// 已授权，但这条计划按规则不该排（截止日太近 / 缺截止日）。
  /// **不是错误**，不需要提示用户。
  skippedNotDue,

  /// 用户拒绝了通知权限。要提示去开权限。
  denied,

  /// 平台不支持 / 初始化失败（测试环境、桌面端）。静默即可。
  unavailable,
}

///
/// 设计原则：**永不抛异常**。通知失败绝不能让计划数据保存失败——
/// 与 [SecretStore] 同样的取舍：平台能力是增强，不是前置条件。
/// 在测试环境、未授权、厂商 ROM 收紧后台等情况下，
/// 所有方法都静默降级为 no-op 或返回 false。
///
/// 权限策略：**不在启动时索要**。系统通知权限弹窗在用户还没有
/// 任何上下文时出现极易被拒，一旦被拒（Android 会记住这个决定），
/// 之后用户真想开张提醒也要去系统设置里手动改。所以我们只在
/// 用户主动打开计划里的「提醒」开关、并且真的保存时才请求。
class PlanReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// 通知 id 必须是 32 位 int。计划 id 是字符串，用稳定的哈希映射，
  /// 保证同一条计划每次调度/取消都落到同一个 id 上——
  /// 否则取消时找不到那条通知，提醒永远撤不掉。
  static int _idOf(String planId) => planId.hashCode & 0x7fffffff;

  Future<void> init() async {
    if (_ready) return;
    try {
      // flutter_local_notifications 的 zonedSchedule 要求时区库已初始化，
      // 否则会抛「TimeZone not initialized」。latest_all 含全部时区数据。
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_deviceZone()));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (_) {
      // 平台通道不可用（测试 / 不支持的平台）
    }
  }

  /// 设备时区名（IANA）。取不到就退回 UTC——时刻会偏，但不会崩。
  ///
  /// 不引入 `flutter_timezone` 插件：多一个平台依赖只为了拿一个字符串，
  /// 而这些时刻都是「晚上 20:30」「早上 9:00」这类宽松提醒，
  /// 差几个时区不是致命问题。真机上 Dart 的 `DateTime.now().timeZoneName`
  /// 在 Android 上返回缩写（如 CST），映射不稳定，索性不用。
  static String _deviceZone() {
    final offset = DateTime.now().timeZoneOffset;
    // 常见偏移直接映射，覆盖东亚与欧美主要时区
    switch (offset.inMinutes) {
      case 480:
        return 'Asia/Shanghai';
      case 540:
        return 'Asia/Tokyo';
      case 0:
        return 'UTC';
      case -300:
        return 'America/New_York';
      case -480:
        return 'America/Los_Angeles';
      case 60:
        return 'Europe/Berlin';
      default:
        return 'UTC';
    }
  }

  /// 请求通知权限。返回是否已获授权。
  ///
  /// 注意 `requestNotificationsPermission()` 的返回值有三种：
  /// `true`（已授权）/ `false`（被拒）/ **`null`（该平台版本不需要这个权限）**。
  /// 从前写成 `granted ?? true`，看似对——但 `?? true` 也会在
  /// **`impl` 为 null**（插件没注册上）时兜出 true，于是「根本没申请」
  /// 被当成「已授权」，随后真正 `zonedSchedule` 时才失败。
  /// 现在把「拿不到平台实现」明确判成 [ReminderOutcome.unavailable]。
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (impl == null) return false;
        // Android 13+ 才有 POST_NOTIFICATIONS；低版本返回 null（无需请求）
        final granted = await impl.requestNotificationsPermission();
        return granted ?? true;
      }
      if (Platform.isIOS) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (impl == null) return false;
        final granted = await impl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
    } catch (_) {}
    return false;
  }

  /// 已授权但**不弹窗**地查一次权限状态（Android 13+）。
  ///
  /// 用于「用户说给了权限，到底给没给」这种事后核对——
  /// [_show] 的失败不该再猜原因。
  Future<bool> hasPermission() async {
    await init();
    if (!_ready) return false;
    try {
      if (Platform.isAndroid) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (impl == null) return false;
        final enabled = await impl.areNotificationsEnabled();
        return enabled ?? false;
      }
      if (Platform.isIOS) {
        final impl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (impl == null) return false;
        final opts = await impl.checkPermissions();
        return opts?.isEnabled ?? false;
      }
    } catch (_) {}
    return false;
  }

  /// 为一条计划安排提醒。
  ///
  /// 两种计划各自对应一个时间点：
  ///  - 每日时长型：**每天 20:30**。用 `matchDateTimeComponents: time`
  ///    让系统按挂钟时间每天重复——这正是用户要的「周期任务」语义：
  ///    提醒是常驻的，不因为某天标了「今天读完」就消失。
  ///    关闭提醒 / 删除计划时用 [cancel] 撤掉。
  ///  - 读完某本书：**截止日前 3 天**的早上 9:00。一次性。
  ///
  /// 返回值区分「排上了 / 按规则不用排 / 没权限 / 平台不可用」四种，
  /// 详见 [ReminderOutcome]。调用方据此决定要不要提示用户。
  Future<ReminderOutcome> schedule(ReadingPlan plan) async {
    await init();
    if (!_ready) return ReminderOutcome.unavailable;

    // 计算该排在什么时候。**先算再问权限**——算不出时间点（截止日太近、
    // 缺截止日）时压根不该弹权限弹窗：用户只是想加个计划，
    // 莫名其妙被问「允不允许通知」是纯粹的打扰。
    final DateTime when;
    final String title;
    final String body;
    final DateTimeComponents? repeat;
    if (plan.kind == PlanKind.dailyMinutes) {
      var t = DateTime.now();
      t = DateTime(t.year, t.month, t.day, 20, 30);
      // 已经过点就排到明天，避免「设了提醒马上响」这种骚扰
      if (!t.isAfter(DateTime.now())) {
        t = t.add(const Duration(days: 1));
      }
      when = t;
      title = appLoc.planReminderDailyTitle;
      body = appLoc.planReminderDailyBody(minutes: plan.dailyMinutes ?? 0);
      // 每日型是周期任务：只排一次，让系统按时间每天重复
      repeat = DateTimeComponents.time;
    } else {
      final due =
          plan.dueDate == null ? null : DateTime.tryParse(plan.dueDate!);
      if (due == null) return ReminderOutcome.skippedNotDue;
      final t =
          DateTime(due.year, due.month, due.day, 9, 0).subtract(const Duration(days: 3));
      if (!t.isAfter(DateTime.now())) {
        // 截止日不足 3 天：一条马上要响的「还有 3 天到期」只会让人困惑。
        // 这不是失败，是「这条计划不需要提醒」。
        return ReminderOutcome.skippedNotDue;
      }
      when = t;
      title = appLoc.planReminderBookTitle;
      body = appLoc.planReminderBookBody(days: 3);
      repeat = null;
    }

    // 要排了才问权限。
    if (!await requestPermission()) return ReminderOutcome.denied;

    try {
      await _show(
        id: _idOf(plan.id),
        title: title,
        body: body,
        when: when,
        matchDateTimeComponents: repeat,
      );
      return ReminderOutcome.scheduled;
    } catch (_) {
      // zonedSchedule 本身失败：多半是厂商 ROM 拦了精确定时 / 渠道被关。
      // 归到 unavailable——不是权限问题，别误导用户去翻权限开关。
      return ReminderOutcome.unavailable;
    }
  }

  Future<bool> _show({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reading_plans',
        '阅读计划提醒',
        channelDescription: '每日阅读提醒与计划到期提醒',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _tz(when),
      details,
      // iOS 10 以前不支持时区，靠这个参数决定「绝对时刻」还是「挂钟时间」。
      // 我们构造的都是本地挂钟时间，所以选 wallClock。
      // 参数在 17.x 仍是必填，不能省。
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
    return true;
  }

  /// 取消一条计划的通知。计划完成 / 删除 / 关掉提醒开关时都要调。
  Future<void> cancel(String planId) async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancel(_idOf(planId));
    } catch (_) {}
  }

  /// 撤销所有计划提醒（例如用户在设置里一键关闭全部提醒）。
  Future<void> cancelAll() async {
    await init();
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// 把本地的「挂钟时间」转成调度需要的 [tz.TZDateTime]。
  ///
  /// 直接 `TZDateTime.from(d, tz.local)` 会因为 [d] 本身带本地 offset
  /// 而被再偏一次。我们构造的都是本地日历时间，所以按年月日时分
  /// 逐字段重建，语义最清楚。
  static tz.TZDateTime _tz(DateTime d) =>
      tz.TZDateTime(tz.local, d.year, d.month, d.day, d.hour, d.minute);
}
