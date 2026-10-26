import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_loc.dart';
import '../models/reading_plan.dart';
import 'system_settings.dart';

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

/// 提醒链路的体检结果。
///
/// 用来回答一个用户永远问不出口的问题：**「为什么我收不到提醒？」**
///
/// 提醒能不能送到，取决于四件事，全都不在 App 的控制范围内：
///  1. 通知权限（Android 13+ 的 POST_NOTIFICATIONS）；
///  2. 通知渠道没被用户关掉；
///  3. 系统没把本 App 的后台掐掉（国产 ROM 的省电策略）；
///  4. 闹钟本身还在（AlarmManager 里的排期没被清掉）。
///
/// [ReminderOutcome] 只说得清「这一次排没排上」，说不清「为什么没弹出来」。
/// 这个类把状态一次性摊开，设置页才能如实告诉用户缺哪一环。
class ReminderDiagnostics {
  /// 通知插件是否可用（测试环境 / 不支持的平台为 false）。
  final bool pluginReady;

  /// 系统层面是否允许本 App 发通知。
  ///
  /// 这一项已经**含**了 Android 13+ 的运行时权限：
  /// `NotificationManager.areNotificationsEnabled()` 在权限被拒时返回 false。
  final bool notificationsAllowed;

  /// 已排期的通知条数（来自 AlarmManager 的挂起请求）。
  final int scheduledCount;

  /// 是否已被排除在电池优化之外。
  ///
  /// 为 false 不代表收不到——只是国产 ROM 上很可能被掐。
  final bool batteryExempt;

  /// ROM 品牌标记（miui / coloros / emui / harmony / originos / iqoo /
  /// oneplus / oneui）；原生 AOSP 为空串。
  final String romBrand;

  const ReminderDiagnostics({
    this.pluginReady = false,
    this.notificationsAllowed = false,
    this.scheduledCount = 0,
    this.batteryExempt = false,
    this.romBrand = '',
  });

  /// 系统是否可能在后台掐掉本 App。
  ///
  /// 判定依据两条：没被豁免电池优化，或 ROM 属于有「自启动」概念的国产系。
  bool get backgroundRestricted {
    if (!batteryExempt) return true;
    return const {
      'miui',
      'coloros',
      'emui',
      'harmony',
      'originos',
      'iqoo',
      'oneplus',
    }.contains(romBrand);
  }

  /// 一切正常：能发通知、且没有已知的后台限制。
  bool get ok => pluginReady && notificationsAllowed && !backgroundRestricted;
}

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

  /// 计划提醒的 Android 通知渠道 id。
  ///
  /// **带 _v2 后缀是刻意的**：Android 的通知渠道一旦创建就固定下来，
  /// 之后再改代码里的 importance **不会覆盖已有渠道**——系统沿用创建时
  /// 的设置（用户改过则用用户的）。原来这个渠道是
  /// `Importance.defaultImportance`：只进通知栏、有声音，**不弹横幅**。
  /// 用户看到的正是「没有弹出提醒」。
  ///
  /// 要让新设置生效，只能换一个新 id，让系统新建一个渠道。
  /// 旧渠道留着无害（它只是不再被使用）。
  static const String planChannel = 'reading_plans_v2';

  /// 自动报告提醒的渠道 id。同样带 _v2，理由同上。
  static const String reportChannel = 'reports_v2';

  Future<void> init() async {
    if (_ready) return;
    try {
      // flutter_local_notifications 的 zonedSchedule 要求时区库已初始化，
      // 否则会抛「TimeZone not initialized」。latest_all 含全部时区数据。
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_deviceZone()));

      // 小图标必须是**纯白剪影**。用彩色启动图标 @mipmap/ic_launcher 的话，
      // 系统会按 alpha 通道把它压成一块白方块，少数 ROM 还会因图标不合法
      // 干脆不显示这条通知。
      const android = AndroidInitializationSettings('@drawable/ic_stat_readnest');
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

  /// 体检当前提醒链路的状态。给设置页用。
  ///
  /// **绝不抛异常**：任何一项查不到就当 false / 0。
  Future<ReminderDiagnostics> diagnose() async {
    await init();
    if (!_ready) {
      return const ReminderDiagnostics();
    }
    var allowed = false;
    var count = 0;
    try {
      allowed = await hasPermission();
      final pending = await _plugin.pendingNotificationRequests();
      count = pending.length;
    } catch (_) {}
    var exempt = false;
    var brand = '';
    try {
      exempt = await SystemSettings.isIgnoringBatteryOptimizations();
      brand = await SystemSettings.romBrand();
    } catch (_) {}
    return ReminderDiagnostics(
      pluginReady: true,
      notificationsAllowed: allowed,
      scheduledCount: count,
      batteryExempt: exempt,
      romBrand: brand,
    );
  }

  /// 提醒的挂钟时刻（当地时间 24 小时制）。
  ///
  /// 用户明确要求：**每日计划与到期提醒都在晚上 9 点**。
  /// 9 点是「今天还读得进去，但该收尾了」的时段——早上 9 点提醒「3 天后到期」
  /// 既没用（那会儿用户多半没空决定读不读），也吵。
  static const int reminderHour = 21;

  /// 为一条计划安排提醒。
  ///
  /// 两种计划各自对应一个时间点，**都在当地时间 [reminderHour] 点**：
  ///  - 每日时长型：**每天 21:00**。用 `matchDateTimeComponents: time`
  ///    让系统按挂钟时间每天重复——这正是用户要的「周期任务」语义：
  ///    提醒是常驻的，不因为某天标了「今天读完」就消失。
  ///    关闭提醒 / 删除计划时用 [cancel] 撤掉。
  ///  - 读完某本书：**截止日前 3 天**的 21:00。一次性。
  ///
  /// 返回值区分「排上了 / 按规则不用排 / 没权限 / 平台不可用」四种，
  /// 详见 [ReminderOutcome]。调用方据此决定要不要提示用户。
  Future<ReminderOutcome> schedule(ReadingPlan plan) =>
      _schedule(plan, askPermission: true);

  /// 重新排期所有「开了提醒」的计划，返回排成功的条数。
  ///
  /// ## 为什么必须有这一步
  ///
  /// AlarmManager 里的闹钟**不会自己回来**，这些情况都会让它消失：
  ///  - 国产 ROM 的「清理后台」/ 省电策略（最常见）；
  ///  - 用户在系统里对 App「强制停止」；
  ///  - 覆盖安装（应用数据被换掉，插件的排期缓存也可能丢）；
  ///  - 用户改了系统时间/时区，原排期失效。
  ///
  /// 从前只有「用户手动改一次计划」才会重排，于是用户看到的现象就是
  /// **「提醒只在打开 App 时才有」**——因为那次保存才把闹钟补上，
  /// 而闹钟补上后如果又被 ROM 清掉，就再没有下一次了。
  ///
  /// 现在每次启动（以及每次回到前台）都补一遍，把丢失的排期找回来。
  ///
  /// **不弹权限框**：这里只查状态不索取权限（[askPermission] 为 false）。
  /// 启动时弹系统的通知权限框既突兀又常被拒，用户没上下文时最不该被打扰。
  Future<int> resync(List<ReadingPlan> plans) async {
    await init();
    if (!_ready) return 0;
    var n = 0;
    for (final p in needsReminder(plans)) {
      final outcome = await _schedule(p, askPermission: false);
      if (outcome == ReminderOutcome.scheduled) n++;
    }
    return n;
  }

  /// 从一批计划里挑出**需要排提醒**的那些。
  ///
  /// 抽成纯函数是为了能穷举测试：这几个条件一旦写错，
  /// 表现是「提醒莫名消失」或「该提醒的不提醒」，在真机上极难复现。
  ///
  /// 两条排除规则：
  ///  - 没开提醒的：用户自己关掉的，不再替他排；
  ///  - 已整体结束的（[ReadingPlan.done]）：一次性目标做完就该撤。
  ///
  /// 注意**每日型计划打卡后不算 done**——那是「今天读完了」，
  /// 明天还要读，提醒要留着。
  @visibleForTesting
  static List<ReadingPlan> needsReminder(List<ReadingPlan> plans) => [
        for (final p in plans)
          if (p.reminderEnabled && !p.done) p,
      ];

  Future<ReminderOutcome> _schedule(
    ReadingPlan plan, {
    required bool askPermission,
  }) async {
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
      when = nextDailySlot();
      title = appLoc.planReminderDailyTitle;
      body = appLoc.planReminderDailyBody(minutes: plan.dailyMinutes ?? 0);
      // 每日型是周期任务：只排一次，让系统按时间每天重复
      repeat = DateTimeComponents.time;
    } else {
      final due =
          plan.dueDate == null ? null : DateTime.tryParse(plan.dueDate!);
      if (due == null) return ReminderOutcome.skippedNotDue;
      final t = bookReminderAt(due);
      if (t == null || !t.isAfter(DateTime.now())) {
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
    if (askPermission) {
      if (!await requestPermission()) return ReminderOutcome.denied;
    } else if (!await hasPermission()) {
      // 重排期时不索取权限，但没权限就别排——排了也发不出来。
      return ReminderOutcome.denied;
    }

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

  /// 下一个尚未过去的「今天 [reminderHour]:00」；今天已过点则顺延到明天。
  ///
  /// 抽出成静态方法是为了能单测时刻计算，不用真机等时钟。
  @visibleForTesting
  static DateTime nextDailySlot([DateTime? now]) {
    final t = now ?? DateTime.now();
    var slot = DateTime(t.year, t.month, t.day, reminderHour, 0);
    if (!slot.isAfter(t)) {
      slot = slot.add(const Duration(days: 1));
    }
    return slot;
  }

  /// 「读完一本书」型计划的提醒时刻：截止日前 3 天的 [reminderHour] 点。
  ///
  /// 返回 null 表示不该排（缺截止日 / 距截止已不足 3 天）。
  ///
  /// **必须先减 3 天再造时刻**：反过来（先造 21:00 再减 3 天）结果一样，
  /// 但减法跨月时 `DateTime` 会自动进位，写成同一天减法看不出差别，
  /// 单测能立刻抓到这个顺序错误。
  @visibleForTesting
  static DateTime? bookReminderAt(DateTime due, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final at = DateTime(due.year, due.month, due.day, reminderHour, 0)
        .subtract(const Duration(days: 3));
    return at.isAfter(t) ? at : null;
  }

  Future<bool> _show({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _tz(when),
      _details(planChannel),
      // iOS 10 以前不支持时区，靠这个参数决定「绝对时刻」还是「挂钟时间」。
      // 我们构造的都是本地挂钟时间，所以选 wallClock。
      // 参数在 17.x 仍是必填，不能省。
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      // inexactAllowWhileIdle → AlarmManager.setAndAllowWhileIdle：
      // 非精确但在 Doze 里照样会响，且**不需要任何特殊权限**。
      //
      // 不用 exactAllowWhileIdle：它要求 SCHEDULE_EXACT_ALARM，
      // 而 Google Play 只放行「闹钟/计时器类」App 申请该权限，
      // 读书打卡类 App 申请会被拒。差个十来分钟对「21:00 提醒读书」
      // 完全无所谓，被商店拒审才是真要命。
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
    );
    return true;
  }

  /// Android 通知渠道。
  ///
  /// 渠道一旦创建，用户在系统设置里改过重要性/声音之后再改代码是**不生效**
  /// 的（系统沿用旧配置），所以这里按用途分渠道，并且一次定好不再变动。
  ///
  /// 重要性用 [Importance.high] 而不是 `defaultImportance`：
  /// 后者只进通知栏、不弹横幅，用户会以为「没收到提醒」。
  /// 要改重要性必须换渠道 id（见 [planChannel]）。
  ///
  /// 渠道名与描述走中文常量而非 ARB：Android 渠道名只在系统设置里显示，
  /// 那里没有本 App 的语言上下文；用 appLoc 反而会随 App 语言切换而错位。
  NotificationDetails _details(String channelId) => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          '阅读提醒',
          channelDescription: '每日阅读提醒、计划到期提醒与阅读报告提醒',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

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

  /// 立刻弹一条通知（不排期、立即显示）。
  ///
  /// 给「自动生成的报告已就绪」用——它不是计划提醒，而是一条
  /// 「有事发生了、请回来看」的消息，与计划提醒共用权限，
  /// 所以放在同一个服务里，而不是再造一个插件实例。
  ///
  /// **不在这里索取权限**。若用户还没授权就静默返回：
  /// 自动生成报告是后台行为，弹一个权限框既突兀又常被拒。
  /// 真想提醒，就该在用户主动开启计划提醒时一并拿到授权。
  Future<void> notifyNow({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    if (!_ready) return;
    if (!await hasPermission()) return;
    try {
      await _plugin.show(id, title, body, _details(reportChannel));
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
