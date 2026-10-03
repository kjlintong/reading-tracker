import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reading_tracker/l10n/app_loc.dart';
import 'package:reading_tracker/l10n/app_localizations.dart';

/// 测试用的 [MaterialApp] 外壳：补齐与 `lib/main.dart` **完全一致**的本地化接线。
///
/// 为什么必须有这个辅助，而不是各测试里裸写 `MaterialApp(home: page)`：
///
/// - 少了 `localizationsDelegates`，`S.of(context)` 会返回 null，并在生成代码
///   的 `Localizations.of<S>(context, S)!` 处直接抛 `_TypeError`
///   —— 页面一渲染就崩，且报错信息指向生成文件，很难定位到「测试少挂 delegate」。
/// - 少了 `builder`，非 Widget 路径依赖的全局 `appLoc` 不会被刷新成本次 locale。
///
/// 测试要复刻生产接线而不是绕过它：否则测试全绿也说明不了 App 真的能跑。
///
/// [key] 用于「同一个用例内多轮重 pump」的场合：不给 key 时 MaterialApp
/// 会被逐层复用，其内部 Navigator 的路由栈会跨轮残留（上一轮 push 出去的
/// 页面带进下一轮）。需要每轮彻底重开就传一个每轮唯一的值。
MaterialApp localizedApp({
  required Widget home,
  ThemeData? theme,
  Locale? locale,
  Key? key,
}) =>
    MaterialApp(
      key: key,
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: locale,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      builder: (BuildContext context, Widget? child) {
        // 与 main.dart 的 builder 语义一致：把当前 locale 的 S 缓存为全局实例
        setAppLoc(S.of(context));
        return child!;
      },
      home: home,
    );
