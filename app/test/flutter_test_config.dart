import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/l10n/app_loc.dart';
import 'package:reading_tracker/l10n/app_localizations.dart';

/// 全量测试前置（Flutter 约定：`test/flutter_test_config.dart`）。
///
/// 做两件事，缺一都会让大片测试失败：
///
/// 1. **把测试区域固定为中文**。断言写的是中文文案（如 `BookStatus.reading.label`
///    等于「在读」）。不固定的话，测试宿主环境的 locale 是 `en_US`，
///    `MaterialApp` 会解析成英文，界面渲染英文而断言期望中文，必挂。
///
/// 2. **预热 `appLoc`**。本项目大量文案出现在非 Widget 上下文——
///    枚举的 `label` getter、导入解析器、数据聚合、AI 客户端——它们靠全局
///    `appLoc` 取文案（拿不到 `BuildContext`）。纯逻辑测试从不构建
///    `MaterialApp`，也就永远不会调用 `setAppLoc`，于是首次访问即抛
///    `StateError: appLoc accessed before localization init`。
///
/// 生产环境不需要这里的两步：`main()` 在数据库初始化前就已装载本地化，
/// 首帧的 `MaterialApp.builder` 再按系统语言覆盖。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.localeTestValue = const Locale('zh');
  binding.platformDispatcher.localesTestValue = const <Locale>[Locale('zh')];

  // 同步可用的方式只有这一条：gen-l10n 的 delegate.load 对每个受支持 locale
  // 都是同步完成的，因此 await 不会真的挂起，也不会影响测试时序。
  setAppLoc(await S.delegate.load(const Locale('zh')));

  await testMain();
}
