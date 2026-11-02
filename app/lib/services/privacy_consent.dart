import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 首次启动的隐私政策知情同意。
///
/// **为什么必须做**：国内应用商店（含 vivo）审核硬性要求——App 首次启动时
/// 必须以弹窗形式明示个人信息处理规则，并取得用户明示同意；同意前不得
/// 读取任何个人信息、不得发起网络请求。没有这一环会被直接驳回。
///
/// **判定标准（对应 vivo 审核规范）**：
/// - 提供明确的「同意」与「不同意」两个按钮，不使用「好的 / 我知道了」这类
///   无法清晰表达用户意愿的措辞；
/// - 不默认勾选任何选项；
/// - 用户拒绝时不阻断 App 启动，但**必须**在首次进入前明确告知；
/// - 用户勾选同意后持久化，卸载重装才重新询问。
///
/// **同意状态存在哪**：用 `shared_preferences` 而不是 `settings` 表。
/// 后者会被自动备份一并导出，而「同意记录」属于设备本地状态，
/// 不应随备份文件流转到别的设备上。
class PrivacyConsent {
  PrivacyConsent._();

  /// 同意状态的存储键。带版本号，便于将来政策内容有实质性变更时
  /// 重新征求同意（政策变了却沿用旧同意，在合规上站不住）。
  static const String prefKey = 'privacy_consent_v1';

  /// 是否已同意。用 `SharedPreferences` 而非内存变量——进程被杀后重启
  /// 不该重新弹窗骚扰用户。
  static Future<bool> isAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKey) ?? false;
    } catch (_) {
      // 读失败时按「未同意」处理：宁可多问一次，不可默认放行。
      return false;
    }
  }

  /// 记录用户已同意。
  static Future<void> accept() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, true);
    } catch (_) {
      // 写失败不阻断流程：本次会话内仍按已同意处理（由调用方维持内存态）。
    }
  }

  /// 清空同意记录。仅供「重置应用数据」之类的场景使用。
  @visibleForTesting
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKey);
    } catch (_) {
      // 同上，忽略。
    }
  }
}
