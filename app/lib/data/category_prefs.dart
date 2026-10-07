/// 用户自定义分类的存取。
///
/// 只负责「怎么存」，词表本体（[CategoryVocabulary]）在 `models/enums.dart`——
/// 归一化判定要在没有 BuildContext 的地方调用，放在离它最近的地方。
///
/// 存两个名单而不是一份完整词表，理由见 [CategoryVocabulary] 的注释：
/// 默认分类将来还会扩充，存快照会让新分类永远进不了老用户的列表。
library;

import 'dart:convert';

import '../models/enums.dart';

/// settings 表的键：用户新增的分类（JSON 数组）。
const String kCustomCategoriesKey = 'custom_categories';

/// settings 表的键：用户从默认分类里移除的（JSON 数组）。
const String kHiddenCategoriesKey = 'hidden_categories';

/// 解析 settings 里存的分类名单。
///
/// 任何异常都退化成空列表：一个损坏的偏好值不该让书架打不开。
/// 空列表的语义是「用户没改过」，恰好是安全的默认值。
List<String> parseCategoryList(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final d = jsonDecode(raw);
    if (d is List) {
      return [
        for (final e in d)
          if (e.toString().trim().isNotEmpty) e.toString().trim(),
      ];
    }
  } catch (_) {
    // 忽略：存进来的不是合法 JSON（手改过、或旧版本留下的格式）
  }
  return const [];
}

String encodeCategoryList(List<String> v) => jsonEncode(v);

/// 把 settings 里读到的两个名单装进全局词表。
void applyCategoryVocabulary({String? custom, String? hidden}) {
  categoryVocabulary = CategoryVocabulary(
    custom: parseCategoryList(custom),
    hidden: parseCategoryList(hidden),
  );
}

/// 新增一个分类，返回是否真的加进去了。
///
/// 重名直接拒绝：同一个分类出现两次会让下拉框出现两个一样的选项，
/// 用户无法分辨该选哪个，也违反「受控词表防分类爆炸」的初衷。
///
/// 重新加回一个已删除的**默认**分类时，实际做的是「取消隐藏」——
/// 所以它回到默认词表里原来的位置，而不是跑到自定义分类那一截。
bool addCategory(String name) {
  final s = name.trim();
  if (s.isEmpty || s == kUncategorized) return false;
  if (categoryVocabulary.contains(s)) return false;
  categoryVocabulary = CategoryVocabulary(
    custom: [...categoryVocabulary.custom, s],
    hidden: [
      for (final c in categoryVocabulary.hidden)
        if (c != s) c,
    ],
  );
  return true;
}

/// 移除一个分类，返回它原本是不是默认分类。
///
/// 默认分类进 hidden 名单（将来「恢复默认」能认回来），
/// 自定义分类直接从 custom 名单删掉——它就是用户加的，删了就是删了。
bool removeCategory(String name) {
  final wasDefault = categoryVocabulary.isDefault(name);
  categoryVocabulary = CategoryVocabulary(
    custom: [
      for (final c in categoryVocabulary.custom)
        if (c != name) c,
    ],
    hidden: wasDefault
        ? [...categoryVocabulary.hidden, name]
        : categoryVocabulary.hidden,
  );
  return wasDefault;
}

/// 改名：新旧名字在各自名单里对调，保持展示位置不变。
///
/// 默认分类改名后必须**同时进 hidden**：否则 active 会在默认那一截里
/// 再吐出一个旧名字，界面上「宗教」和「信仰」同时存在，
/// 而用户只想保留「信仰」。
void renameCategory(String oldName, String newName) {
  final s = newName.trim();
  if (s.isEmpty || s == oldName) return;
  final hidden = [
    for (final c in categoryVocabulary.hidden)
      if (c != oldName) c,
  ];
  if (categoryVocabulary.isDefault(oldName)) hidden.add(oldName);
  categoryVocabulary = CategoryVocabulary(
    custom: [
      for (final c in categoryVocabulary.custom)
        if (c != oldName) c,
      s,
    ],
    hidden: hidden,
  );
}

/// 恢复默认：两个名单一起清空。
void restoreDefaultCategories() {
  categoryVocabulary = CategoryVocabulary.empty;
}
