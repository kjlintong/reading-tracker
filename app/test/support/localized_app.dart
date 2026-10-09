import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:reading_tracker/l10n/app_loc.dart';
import 'package:reading_tracker/l10n/app_localizations.dart';
import 'package:reading_tracker/ui/app_background.dart';
import 'package:reading_tracker/ui/theme.dart';

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

  /// 皮肤背景。
  ///
  /// ## 为什么截图测试**必须**传这个参数
  ///
  /// 本函数是 lib/main.dart 的测试副本，而背景层挂在 `MaterialApp.builder` 上。
  /// 不传就等于**测试环境里根本没有 AppBackground**——
  /// 出图得到的是「贴图皮肤下的界面，但不画贴图」的半透明 PNG
  /// （Scaffold 在贴图模式下是透明的，底下什么都没有 → alpha=0）。
  /// 2026-10-09 用户拿官网截图发现「贴图是透明的、露出网页底色」，
  /// 根因就是这里：真机有背景层，截图路径没有。
  ///
  /// 传 null 则完全不渲染背景层——纯色皮肤截图用这个即可，
  /// 少一层 Stack 也少一层潜在的差异。
  AppTheme? backgroundTheme,

  /// 贴图的加载方式。
  ///
  /// 测试环境的 rootBundle 里 AssetManifest **只有条目名、没有图片字节**，
  /// 于是 `Image.asset` 解码失败、`errorBuilder` 静默返回空——
  /// 出图跑出来是一张纯色纸，看起来像「背景没生效」，实际是图根本没加载。
  /// 传 [MemoryImage]（从文件读字节）才测得到真实合成结果。
  ImageProvider? backgroundImage,
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

        // 与 main.dart 完全同构：背景层挂在 builder 上，覆盖整个 Navigator。
        final bg = backgroundTheme;
        if (bg == null || !bg.hasBackground) return child!;
        return AppBackground(
          theme: bg,
          brightness: Theme.of(context).brightness,
          imageProvider: backgroundImage,
          child: child!,
        );
      },
      home: home,
    );
