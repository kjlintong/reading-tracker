import 'dart:ui' show Locale;

/// 对外的链接与身份信息，集中在这里。
///
/// 为什么单独抽一个文件：这些常量要在**三处**保持一致——应用内的「关于」区块、
/// 商店后台填写的 URL、以及 `docs/06 / 07` 隐私政策。散落在 UI 代码里迟早会漂移。
///
/// **更改这里任何一条，都要同步：**
/// - `docs/06-隐私政策(中文).md` / `docs/07-Privacy-Policy(EN).md`（第九节联系方式）
/// - `store/tools/gen_listing.py` 的 `APP` 字典（商店文案里的政策链接）
/// - `store/web/`（重新执行 `python3 store/tools/build_site.py`）
///
/// [version] 与 [buildNumber] 必须与 `pubspec.yaml` 的 `version:` 一致，
/// `test/app_info_test.dart` 会读 pubspec 断言这一点——改版本号忘了改这里会直接测试失败。
class AppInfo {
  const AppInfo._();

  /// 产品名。与 `pubspec.yaml` 的 Dart 包名 `reading_tracker` 不同是有意的：
  /// 包名不暴露给用户，改名会破坏 24 个以 `package:reading_tracker/` 导入的文件。
  static const String name = 'Readnest';

  /// 与 `pubspec.yaml` 的 `version: 1.0.0+15` 对应。
  static const String version = '1.0.0';
  static const String buildNumber = '17';

  /// 完整的版本展示串，例如 `0.5.0 (5)`。
  static String get versionLabel => '$version ($buildNumber)';

  static const String developer = 'Tong Lin';
  static const String email = 'ltong9463@gmail.com';

  /// 开发者主页。隐私政策与应用介绍页都挂在这个 GitHub Pages 站点下。
  static const String homepage = 'https://kjlintong.github.io/';

  /// 应用介绍页（商店的「营销网址」用这个，应用内「关于」也链到它）。
  ///
  /// 由 `store/tools/build_site.py` 生成，产物在 `store/web/readnest/`，
  /// 部署方式见 `store/web/README.md`。**中文页**——应用内「关于」的
  /// 用户按界面语言分流没有意义（他就在应用里，语言已经确定），
  /// 而中文页顶部有到英文页的互跳，英文用户多点一次即可。
  static const String appPage = 'https://kjlintong.github.io/readnest/';

  /// 介绍页的英文版，供英文界面直接打开。中文页与它是双向互跳的。
  static const String appPageEn = 'https://kjlintong.github.io/readnest/en.html';

  /// 打赏页（国外）。免费 + 打赏是既定的变现方式，因此**内置**而不是让用户自己填——
  /// 早期版本把打赏链接做成可编辑字段，导致全新安装点按钮只会提示「请先填写链接」，
  /// 等于打赏入口根本不可用。
  static const String tipUrl = 'https://ko-fi.com/ryanlin65969';

  /// 打赏页（中国）。爱发电主页；留空则不显示该入口，便于没有中国渠道时只保留 Ko-fi。
  static const String tipUrlDomestic = 'https://afdian.com/a/ryanlintong';

  /// 隐私政策。两个地址都由 `store/web/` 生成，必须与商店后台填写的一致。
  static const String privacyPolicyZh = 'https://kjlintong.github.io/privacy.html';
  static const String privacyPolicyEn = 'https://kjlintong.github.io/privacy-en.html';

  /// 按界面语言选隐私政策：中文设备看中文版，其余看英文版。
  ///
  /// 不必为 `zh_Hant` 单独准备——繁体用户看简体中文比看英文更合适，
  /// 而 `languageCode` 对 `zh`/`zh_Hant` 都返回 `zh`。
  static String privacyPolicyFor(Locale locale) =>
      locale.languageCode == 'zh' ? privacyPolicyZh : privacyPolicyEn;
}
