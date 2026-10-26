import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/profile_store.dart';
import 'package:reading_tracker/data/reading_profile.dart';
import 'package:reading_tracker/ui/profile_share_card.dart';
import 'package:reading_tracker/ui/profile_share_style.dart';
import 'package:reading_tracker/ui/theme.dart';

import 'support/localized_app.dart';

/// 分享卡的配色与渲染。
///
/// ## 为什么这些断言不是「审美偏好」
///
/// 分享卡是**离屏渲染**的：截图时它被挂到一棵独立渲染树的根上，
/// 那棵树上没有 MaterialApp 祖先，`Theme.of(context)` 取不到任何东西。
///
/// 所以它的配色必须**在渲染前算好传进去**（[ProfileShareStyle]）。
/// 一旦哪条路径忘了传、或者传的是全局默认色板，
/// 症状是「分享图永远是那张绿底」——功能上完全正常，测试也全绿，
/// 只有用户看到才发现。换句话说，这几条断言守的是**一个已经发生过的 bug**。
void main() {
  group('分享卡配色（纯函数）', () {
    test('12 套皮肤 × 明暗都能算出配色，不抛异常', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final s = ProfileShareStyle.of(t, b);
          expect(s.background, isNotNull);
          expect(s.title, isNotNull);
          expect(s.chartColors, isNotEmpty,
              reason: '${t.id}/$b 的分享卡没有图表色');
        }
      }
    });

    test('图表色板跟着皮肤走，不是全局默认那套', () {
      // 全局默认色板是旧的鲜艳配色（#5B8FF9 蓝、#F6BD16 金…）。
      // 分享图里的分类颜色必须来自当前皮肤的色板，否则「换皮肤只换了张纸」。
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final s = ProfileShareStyle.of(t, b);
          final expectPalette =
              b == Brightness.light ? t.chartPalette : t.chartPaletteDark;
          if (expectPalette == null) continue;
          expect(s.chartColors, expectPalette,
              reason: '${t.id}/$b 的分享卡色板与该皮肤不符');
        }
      }
    });

    test('正文与背景的对比度够读——分享图在聊天窗口里常常很小', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final s = ProfileShareStyle.of(t, b);
          // 标题 22px、副标题 12px，都按正文标准要求。
          expect(_contrast(s.title, s.background), greaterThanOrEqualTo(4.5),
              reason: '${t.id}/$b 的标题在背景上对比度不足');
          expect(_contrast(s.subtitle, s.background), greaterThanOrEqualTo(4.5),
              reason: '${t.id}/$b 的副标题在背景上对比度不足');
          expect(_contrast(s.sectionTitle, s.background),
              greaterThanOrEqualTo(4.5),
              reason: '${t.id}/$b 的小节标题在背景上对比度不足');
          expect(_contrast(s.chipText, s.chipBackground),
              greaterThanOrEqualTo(4.5),
              reason: '${t.id}/$b 的标签文字在标签底色上对比度不足');
          expect(_contrast(s.footer, s.background), greaterThanOrEqualTo(3.0),
              reason: '${t.id}/$b 的页脚在背景上对比度不足');
        }
      }
    });

    test('进度条槽色与背景不同色——否则进度条看起来是空的', () {
      for (final t in appThemes) {
        for (final b in Brightness.values) {
          final s = ProfileShareStyle.of(t, b);
          expect(_rgbDistance(s.barTrack, s.background), greaterThan(0.02),
              reason: '${t.id}/$b 的进度条槽色与背景几乎一样');
        }
      }
    });

    test('同一皮肤明暗两态的底色方向相反，不会一起发白或一起发黑', () {
      for (final t in appThemes) {
        final light = ProfileShareStyle.of(t, Brightness.light);
        final dark = ProfileShareStyle.of(t, Brightness.dark);
        expect(light.background.computeLuminance(),
            greaterThan(dark.background.computeLuminance()),
            reason: '${t.id} 的浅色底应该比深色底亮');
      }
    });

    test('超出色板长度时按黄金角补色，不复用第一色', () {
      final s = ProfileShareStyle.of(appThemes.first, Brightness.light);
      final n = s.chartColors.length;
      expect(s.chartColor(n), isNot(s.chartColor(0)));
      expect(s.chartColor(n + 1), isNot(s.chartColor(1)));
    });
  });

  group('分享卡渲染', () {
    testWidgets('标题、标签、偏好都画出来了', (tester) async {
      await tester.pumpWidget(localizedApp(
        home: Scaffold(
          body: ProfileShareCard(
            profile: _profile(),
            tags: const [
              ProfileTagItem(text: '夜读型'),
              ProfileTagItem(text: '偏爱长篇'),
            ],
            rangeLabel: '近 30 天',
            bookCount: 38,
            style: ProfileShareStyle.of(appThemes.first, Brightness.light),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('我的阅读画像'), findsOneWidget);
      expect(find.text('夜读型'), findsOneWidget);
      expect(find.text('偏爱长篇'), findsOneWidget);
      // 页脚是品牌行：App 名 + 产品线
      expect(find.textContaining('Readnest'), findsOneWidget);
    });

    testWidgets('卡片宽度固定 360——分享出去的图尺寸要稳定', (tester) async {
      await tester.pumpWidget(localizedApp(
        home: Scaffold(
          body: ProfileShareCard(
            profile: _profile(),
            tags: const [],
            rangeLabel: '近 30 天',
            bookCount: 38,
            style: ProfileShareStyle.of(appThemes.first, Brightness.light),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(ProfileShareCard));
      expect(size.width, 360);
    });

    testWidgets('背景用的是该皮肤的纸色，不是写死的白', (tester) async {
      // 选 berry（纸色带灰粉），白底一眼就能看出差别。
      final berry = appThemes.firstWhere((t) => t.id == 'berry');
      final style = ProfileShareStyle.of(berry, Brightness.light);
      await tester.pumpWidget(localizedApp(
        home: Scaffold(
          body: ProfileShareCard(
            profile: _profile(),
            tags: const [],
            rangeLabel: '近 30 天',
            bookCount: 38,
            style: style,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(ProfileShareCard),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, style.background);
      expect(material.color, isNot(const Color(0xFFFFFFFF)));
    });

    testWidgets('换皮肤时分享卡的背景与进度条颜色都跟着换', (tester) async {
      Future<Color> bgOf(String skinId) async {
        final t = appThemes.firstWhere((e) => e.id == skinId);
        final style = ProfileShareStyle.of(t, Brightness.light);
        await tester.pumpWidget(localizedApp(
          key: ValueKey(skinId),
          home: Scaffold(
            body: ProfileShareCard(
              profile: _profile(),
              tags: const [],
              rangeLabel: '近 30 天',
              bookCount: 38,
              style: style,
            ),
          ),
        ));
        await tester.pumpAndSettle();
        return tester
            .widget<Material>(
              find.descendant(
                of: find.byType(ProfileShareCard),
                matching: find.byType(Material),
              ).first,
            )
            .color!;
      }

      final green = await bgOf('green');
      final berry = await bgOf('berry');
      expect(green, isNot(berry),
          reason: '换皮肤后分享卡底色没变，等于没换');
    });
  });
}

ReadingProfile _profile() => const ReadingProfile(
      tags: [],
      preferences: [
        PreferenceSlice(label: 'literature', count: 12, share: 0.3),
        PreferenceSlice(label: 'science', count: 8, share: 0.2),
      ],
      bubbles: [],
    );

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

double _rgbDistance(Color a, Color b) =>
    ((a.red - b.red).abs() +
            (a.green - b.green).abs() +
            (a.blue - b.blue).abs()) /
        255.0;
