import 'app_localizations.dart';

// 全局本地化访问器。
//
// gen-l10n 生成的 [S] 通过 `S.of(context)` 访问，要求调用点持有 BuildContext。
// 但本项目有大量字符串出现在非 Widget 上下文：枚举的 `label` getter、
// 导入解析器、AI 客户端、Provider 中的提示语等。为避免在每个调用点都传递
// context，这里在 MaterialApp.builder 中把当前 [S] 实例缓存为全局单例，
// 使任何位置都能用 `appLoc.<key>` 获取本地化字符串。
//
// 安全性：首帧 MaterialApp.builder 执行后 `_appLoc` 即就绪；所有用户交互
// 路径都满足该前提。仅在极早的初始化阶段（runApp 之前）调用才可能未就绪，
// 而本项目没有此类用法。

S? _appLoc;

/// 在 [MaterialApp.builder] 中调用，缓存当前本地化实例。
void setAppLoc(S s) => _appLoc = s;

/// 无需 [BuildContext] 的本地化访问器。
///
/// 返回当前 locale 对应的 [S] 实例；若本地化尚未初始化则抛出异常，
/// 提示该调用发生得过早（正常用户交互路径不会触发）。
S get appLoc {
  final s = _appLoc;
  if (s == null) {
    throw StateError('appLoc accessed before localization init');
  }
  return s;
}
