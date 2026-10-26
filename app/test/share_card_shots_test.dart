import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/profile_store.dart';
import 'package:reading_tracker/data/reading_profile.dart';
import 'package:reading_tracker/ui/brand_mark.dart';
import 'package:reading_tracker/ui/profile_share_card.dart';
import 'package:reading_tracker/ui/profile_share_style.dart';
import 'package:reading_tracker/ui/theme.dart';
import 'package:screenshot/screenshot.dart';

import 'support/localized_app.dart';

/// 分享卡效果图生成器 —— 12 套皮肤 × 明暗，看卡片跟皮肤是否「像同一款产品」。
///
/// ## 为什么值得出图
///
/// 分享卡以前把颜色写死（绿底绿标签白卡片），换皮肤时分享图还是那张绿底，
/// 跟用户眼前的界面完全不像同一款产品。现在配色从皮肤算出来，
/// 但**算得对不对只有看图才知道**：纸色是不是跟界面一致、
/// 标签胶囊在纸色上有没有糊成一片、进度条槽色跟底色分不分得开。
///
/// 断言能守住数值（对比度 ≥4.5），但说不出「好不好看」。
///
/// ## 离屏渲染的坑
///
/// 这张卡是**离屏渲染**的（截图时挂在独立渲染树的根上），
/// 那棵树上没有 MaterialApp 祖先，`Theme.of(context)` 取不到东西——
/// 所以配色是算好传进去的（[ProfileShareStyle]），卡片只管画。
///
/// 品牌角标必须**先解码成 `ui.Image` 再用 `RawImage` 同步绘制**：
/// `Image.asset` 的异步解码只触发重绘（`markNeedsPaint`）不触发 build，
/// 截图流程只等「调度了 build」才重截 → 第一帧截图里根本没有那张图。
///
/// ## 用法
///
/// ```bash
/// SHOTS=1 flutter test test/share_card_shots_test.dart
/// 产物：store/shots/share-*.png
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final enabled = Platform.environment['SHOTS'] == '1';
  const outRoot = '../store/shots';

  Future<ByteData> bytesOf(String path) async =>
      ByteData.view((await File(path).readAsBytes()).buffer);

  setUpAll(() async {
    if (!enabled) return;
    await (FontLoader('TestLatin')..addFont(bytesOf('test/fixtures/simhei.ttf')))
        .load();
    await (FontLoader('TestCJK')..addFont(bytesOf('test/fixtures/simhei.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(bytesOf('test/fixtures/MaterialIcons-Regular.otf')))
        .load();
  });

  /// 一份有代表性的画像数据。
  ///
  /// ⚠️ 类别必须用**中文规范值**（`defaultCategories` 里的那一批），
  /// 不是英文 key：`categoryLabel` 只认规范值做映射，
  /// 拿英文 key 去它会原样返回（`_ => canonical`），
  /// 卡片上就会显示 `litera…` 这种半截英文。
  ReadingProfile sampleProfile() => ReadingProfile(
        preferences: const [
          PreferenceSlice(label: '文学', count: 12, share: 0.30),
          PreferenceSlice(label: '历史', count: 9, share: 0.22),
          PreferenceSlice(label: '科技', count: 7, share: 0.17),
          PreferenceSlice(label: '哲学', count: 5, share: 0.12),
          PreferenceSlice(label: '传记', count: 4, share: 0.10),
        ],
        tags: const [],
      );

  const tags = [
    ProfileTagItem(text: '夜读型'),
    ProfileTagItem(text: '长篇耐受'),
    ProfileTagItem(text: '偏爱文学'),
  ];
  testWidgets('分享卡效果图', (tester) async {
    if (!enabled) return;

    // ⚠️ 必须传 theme：测试环境没有 Roboto，不给 fontFamily 的话
    // 所有中文都会渲染成豆腐块 ▯▯▯。分享卡本身不取 Theme
    // （颜色全从 style 传），但**字体的 fontFamily 来自 Theme**。
    late BuildContext hostCtx;
    await tester.pumpWidget(localizedApp(
      locale: const Locale('zh'),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'TestLatin',
        fontFamilyFallback: const <String>['TestCJK'],
      ),
      home: Builder(builder: (ctx) {
        hostCtx = ctx;
        return const Scaffold(body: SizedBox.shrink());
      }),
    ));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final mark = await loadBrandMark();
      expect(mark, isNotNull, reason: '品牌角标解码失败');

      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final suffix = b == Brightness.light ? 'light' : 'dark';
          final style = ProfileShareStyle.of(t, b);

          // 卡片离屏渲染：外面套一层纸色背景，模拟分享图的底。
          final bytes = await ScreenshotController().captureFromWidget(
            Material(
              color: style.background,
              child: ProfileShareCard(
                profile: sampleProfile(),
                tags: tags,
                rangeLabel: '近 30 天',
                bookCount: 38,
                style: style,
                mark: mark,
              ),
            ),
            pixelRatio: 2.0,
            context: hostCtx,
          );

          final file = File('$outRoot/share-${t.id}-$suffix.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes, flush: true);
        }
      }
      mark?.dispose();
    });
  });
}
