import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ui/app_background.dart';
import 'package:reading_tracker/ui/theme.dart';

import 'support/localized_app.dart';

/// 皮肤背景层的**重建成本**。
///
/// ## 这一组要钉住什么
///
/// 背景层挂在 `MaterialApp.builder` 上、盖住整个 Navigator，
/// 所以**每次路由切换它都会重建一次**。
///
/// 背景三层里有两样东西很贵：全屏高斯模糊（`ImageFilter.blur`）和
/// 半透明层（`Opacity` 的 saveLayer）。重建时若让它们真的重画一遍，
/// 用户点一下按钮、转场动画还没开始，GPU 就得先把整屏重新糊一遍——
/// 真机上实测是「点进新页面卡一秒」。
///
/// 两道防线：
///   1. `RepaintBoundary` 让背景有自己的 compositing layer，内容没变就贴回旧的；
///   2. **模糊滤镜必须是同一个对象**——`RenderImageFilter` 用 `!=` 比较
///      `imageFilter`，新对象永远「不等于」旧对象，于是 `markNeedsPaint`，
///      第 1 道防线直接被抵消。
///
/// 所以这里钉住第 2 条：**同一个 sigma 必须拿到同一个 ImageFilter 实例**。
void main() {
  Future<void> loadFonts() async {
    final bytes = File('test/fixtures/simhei.ttf').readAsBytesSync();
    await (FontLoader('TestLatin')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  }

  setUpAll(loadFonts);

  /// 一个带贴图的皮肤（纯色皮肤没有模糊层，测不到）。
  AppTheme texturedTheme() {
    for (final t in appThemes) {
      if (t.backgroundAsset != null && t.backgroundBlur > 0) return t;
    }
    throw StateError('没有任何带模糊的贴图皮肤，测试前提不成立');
  }

  Widget host(AppTheme theme) => localizedApp(
        theme: ThemeData(
          fontFamily: 'TestLatin',
          fontFamilyFallback: const <String>['TestCJK'],
        ),
        home: AppBackground(
          theme: theme,
          brightness: Brightness.light,
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      );

  /// 取当前画面里那个模糊滤镜。
  ImageFilter? blurOf(WidgetTester tester) {
    final filtered = tester.widgetList<ImageFiltered>(find.byType(ImageFiltered));
    for (final f in filtered) {
      return f.imageFilter;
    }
    return null;
  }

  testWidgets('同一个模糊强度复用同一个滤镜实例', (tester) async {
    final theme = texturedTheme();

    await tester.pumpWidget(host(theme));
    await tester.pump();
    final first = blurOf(tester);
    expect(first, isNotNull, reason: '前提不成立：这套皮肤没有模糊层');

    // 再建一次同样的背景（等价于路由切换触发的那次重建）
    await tester.pumpWidget(host(theme));
    await tester.pump();
    final second = blurOf(tester);

    // ⚠️ 必须 identical（同一个对象），不能只比值：
    // ImageFilter 没有实现值相等，`!=` 是按引用的。
    // 每次新建 → 每次 `markNeedsPaint` → 全屏模糊重算 → 点开页面卡一秒。
    expect(identical(first, second), isTrue,
        reason: '模糊滤镜必须复用同一实例，否则路由切换会重算整屏模糊');
  });

  testWidgets('不同模糊强度用不同滤镜实例', (tester) async {
    final theme = texturedTheme();
    await tester.pumpWidget(host(theme));
    await tester.pump();
    final a = blurOf(tester);
    expect(a, isNotNull);

    // 换一套模糊强度不同的皮肤 → 滤镜应当是另一个实例
    AppTheme other() {
      for (final t in appThemes) {
        if (t.backgroundAsset != null &&
            t.backgroundBlur > 0 &&
            t.backgroundBlur != theme.backgroundBlur) {
          return t;
        }
      }
      // 没有第二个强度就跳过（不常见，但不该因此失败）
      return theme;
    }

    final o = other();
    if (identical(o, theme)) return;

    await tester.pumpWidget(host(o));
    await tester.pump();
    final b = blurOf(tester);
    expect(identical(a, b), isFalse);
  });
}
