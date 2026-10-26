import 'package:flutter/services.dart';

/// 系统设置入口的 Dart 封装。
///
/// 计划提醒是**本地通知**，能不能送达取决于系统允不允许本 App 在后台活着。
/// 这件事用户只能在系统设置里改，App 只能把入口递过去——而「打开某个
/// 系统设置页」需要发 Intent，Flutter 侧没有这个能力
/// （`url_launcher` 只支持 http/tel/mailto 之类的协议），
/// 所以 Android 侧由 `MainActivity` 开了一条 MethodChannel
/// `io.github.ltong9463.readnest/system`。
///
/// 所有方法都在异常时返回 `false`/`''`：
/// 平台通道在测试环境（桌面 Dart VM）不存在，iOS 上也没有这些页，
/// 静默降级比抛异常好——提醒只是增强功能，导航失败不该连累 App。
class SystemSettings {
  const SystemSettings._();

  static const MethodChannel _channel =
      MethodChannel('io.github.ltong9463.readnest/system');

  /// 打开本 App 的通知设置页（通知开关 + 渠道列表）。
  static Future<bool> openNotificationSettings() =>
      _invokeBool('openNotificationSettings');

  /// 打开电池优化「不受限制」列表页。
  ///
  /// 刻意不开 `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`（一键申请）：
  /// 它需要 `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` 权限，
  /// 而 Google Play 只放行「闹钟/计时器类」App 申请这个权限。
  /// 列表页零权限，用户自己找到本 App 点一下即可。
  static Future<bool> openBatteryOptimizationSettings() =>
      _invokeBool('openBatteryOptimizationSettings');

  /// 打开「自启动」管理页。
  ///
  /// 各家 ROM 的入口 Activity 名不同且改版就变，所以 Android 侧按品牌
  /// 逐个尝试，失败时回落到应用详情页。对原生 AOSP 这类没有「自启动」
  /// 概念的机型，调用会落到详情页——所以调用方最好先看 [romBrand]。
  static Future<bool> openAutoStartSettings() =>
      _invokeBool('openAutoStartSettings');

  /// 本 App 是否已被排除在电池优化之外。
  ///
  /// 查询不需要权限（只有「请求豁免」才需要）。
  static Future<bool> isIgnoringBatteryOptimizations() =>
      _invokeBool('isIgnoringBatteryOptimizations');

  /// ROM 品牌标记：miui / coloros / emui / harmony / originos / iqoo /
  /// oneplus / oneui；原生 AOSP 返回空串。
  static Future<String> romBrand() async {
    try {
      final v = await _channel.invokeMethod<String>('romBrand');
      return v ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> _invokeBool(String method) async {
    try {
      final v = await _channel.invokeMethod<bool>(method);
      return v ?? false;
    } catch (_) {
      return false;
    }
  }
}
