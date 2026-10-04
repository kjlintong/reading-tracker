/// 语言代码 → 该语言的自称。
///
/// 用「自称」（Deutsch 而不是「德语」）是本地化界面的通行做法：
/// 用户在自己看不懂的语言里找「德语」这两个汉字，是找不到的。
/// 未知语言码回落到大写代码，至少不是空白。
///
/// 放在 l10n 而不是 UI 层，是因为除了设置页的语言选项，AI 提示词也要用
/// 它告诉模型「用哪种语言写报告」——那份提示词在数据层拼装，不该去
/// import 一个页面文件。
String languageName(String code) => switch (code) {
      'zh' => '简体中文',
      'en' => 'English',
      'de' => 'Deutsch',
      'fr' => 'Français',
      'es' => 'Español',
      'ja' => '日本語',
      'ko' => '한국어',
      _ => code.toUpperCase(),
    };

/// 语言名 → 代码，供「按名字选语言」的场景反查。
String? languageCodeOf(String name) {
  for (final c in const ['zh', 'en', 'de', 'fr', 'es', 'ja', 'ko']) {
    if (languageName(c) == name) return c;
  }
  return null;
}
