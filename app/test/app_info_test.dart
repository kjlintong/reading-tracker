import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/app_info.dart';

/// [AppInfo] 是应用内「关于」、商店后台与隐私政策**三处共用的**对外信息。
/// 它一旦漂移，表现是「商店里写的政策地址和应用里点开的不一样」这种
/// 只有在审核或用户投诉时才会暴露的问题，所以在这里用断言钉死。
void main() {
  group('版本号', () {
    test('与 pubspec.yaml 的 version 一致', () {
      // 版本号有两份：pubspec 是构建时真正生效的，AppInfo 是界面上显示的。
      // 靠人工同步必然会忘，所以让测试盯着。
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final m = RegExp(r'^version:\s*(\S+)\s*$', multiLine: true)
          .firstMatch(pubspec);
      expect(m, isNotNull, reason: 'pubspec.yaml 里找不到 version: 行');

      final raw = m!.group(1)!; // 形如 0.5.0+5
      final parts = raw.split('+');
      expect(parts.first, AppInfo.version,
          reason: 'AppInfo.version 与 pubspec 不一致，请同步 lib/app_info.dart');
      if (parts.length > 1) {
        expect(parts[1], AppInfo.buildNumber,
            reason: 'AppInfo.buildNumber 与 pubspec 不一致');
      }
    });

    test('versionLabel 同时含版本号与构建号', () {
      expect(AppInfo.versionLabel, contains(AppInfo.version));
      expect(AppInfo.versionLabel, contains(AppInfo.buildNumber));
    });
  });

  group('对外链接', () {
    final urls = <String, String>{
      'homepage': AppInfo.homepage,
      'appPage': AppInfo.appPage,
      'tipUrl': AppInfo.tipUrl,
      'privacyPolicyZh': AppInfo.privacyPolicyZh,
      'privacyPolicyEn': AppInfo.privacyPolicyEn,
    };

    test('全部是 https 且可解析', () {
      urls.forEach((name, url) {
        final uri = Uri.tryParse(url);
        expect(uri, isNotNull, reason: '$name 不是合法 URL：$url');
        expect(uri!.scheme, 'https', reason: '$name 必须走 https：$url');
        expect(uri.host, isNotEmpty, reason: '$name 缺少主机名：$url');
      });
    });

    test('打赏页指向 Ko-fi', () {
      // 打赏是既定的变现方式，链接被误改成占位符就等于入口失效。
      expect(Uri.parse(AppInfo.tipUrl).host, contains('ko-fi.com'));
    });

    test('隐私政策与应用落地页同源于开发者站点', () {
      // 商店后台填的地址必须与应用内「关于」里点开的一致，
      // 因此两者都挂在同一个站点下。
      final host = Uri.parse(AppInfo.homepage).host;
      for (final url in [AppInfo.privacyPolicyZh, AppInfo.privacyPolicyEn]) {
        expect(Uri.parse(url).host, host,
            reason: '隐私政策 $url 与主页 $host 不同源，商店填写时容易填错');
      }
    });

    test('中英政策是两个不同的地址', () {
      expect(AppInfo.privacyPolicyZh, isNot(AppInfo.privacyPolicyEn));
    });
  });

  group('按语言选隐私政策', () {
    test('zh 与 zh_Hant 都取中文版', () {
      expect(AppInfo.privacyPolicyFor(const Locale('zh')), AppInfo.privacyPolicyZh);
      expect(AppInfo.privacyPolicyFor(const Locale('zh', 'Hant')),
          AppInfo.privacyPolicyZh);
    });

    test('其余语言取英文版', () {
      for (final code in ['en', 'ja', 'de', 'fr']) {
        expect(AppInfo.privacyPolicyFor(Locale(code)), AppInfo.privacyPolicyEn,
            reason: '$code 应回落到英文政策');
      }
    });
  });
}
