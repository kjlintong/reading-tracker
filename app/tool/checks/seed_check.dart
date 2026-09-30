// 种子数据 → Book 模型 的解析校验（纯 Dart，不依赖 Flutter 插件）
// 运行：dart run tool/checks/seed_check.dart
//
// 验证的是 App 首次启动灌库这条链路中唯一可能出错的环节：
// assets/seed/library.json 的字段能否被 Book.fromMap 无损还原。
// 数据库读写本身由 test/ 下的 flutter_test 集成用例覆盖。

// 校验脚本以 stdout 作为报告载体，print 是唯一合理输出方式
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

int _pass = 0;
int _fail = 0;

void check(bool ok, String label, [String detail = '']) {
  if (ok) {
    _pass++;
  } else {
    _fail++;
    print('  FAIL  $label ${detail.isEmpty ? '' : '→ $detail'}');
  }
}

void main() {
  final file = File('assets/seed/library.json');
  if (!file.existsSync()) {
    print('找不到 assets/seed/library.json，请在 app 目录下运行');
    exit(1);
  }

  final payload = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final rawBooks = payload['books'] as List<dynamic>;
  final rawNotes = (payload['notes'] as List<dynamic>?) ?? [];

  print('种子文件：${rawBooks.length} 本书，${rawNotes.length} 条笔记\n');

  final books = rawBooks
      .whereType<Map>()
      .map((m) => Book.fromMap(Map<String, dynamic>.from(m)))
      .toList();

  check(books.length == 38, '书本总数应为 38', '实际 ${books.length}');

  // 必填字段不能丢
  final noTitle = books.where((b) => b.title.trim().isEmpty).length;
  check(noTitle == 0, '不应有空标题', '空标题 $noTitle 本');

  final noId = books.where((b) => b.id.isEmpty).length;
  check(noId == 0, '不应有空 id', '空 id $noId 本');

  // 元数据补全的产出必须完整落到模型里
  final withCat = books.where((b) => b.categoryPrimary != null && b.categoryPrimary!.isNotEmpty).length;
  check(withCat == books.length, '分类覆盖率应为 100%', '实际 $withCat/${books.length}');

  final withDesc = books.where((b) => b.description != null && b.description!.isNotEmpty).length;
  check(withDesc == books.length, '简介覆盖率应为 100%', '实际 $withDesc/${books.length}');

  final withAuthor = books.where((b) => b.authors.isNotEmpty).length;
  print('作者覆盖：$withAuthor/${books.length}');
  check(withAuthor > books.length * 0.9, '作者覆盖率应高于 90%', '实际 $withAuthor');

  // 枚举解析：字符串 → 枚举，写错会静默退化成默认值，必须显式断言
  final statusSet = <BookStatus>{};
  for (final b in books) {
    statusSet.add(b.status);
  }
  check(statusSet.contains(BookStatus.finished), '应含「已读」状态');
  check(statusSet.contains(BookStatus.wish), '应含「想读」状态');
  check(statusSet.contains(BookStatus.reading), '应含「在读」状态');

  final srcSet = books.map((b) => b.source).toSet();
  check(srcSet.contains(BookSource.notion), '应含 Notion 来源');
  check(srcSet.contains(BookSource.weread), '应含微信读书来源');

  // 数值类型：JSON 里 rating 是 int，模型里是 double，转换不能丢精度
  final rated = books.where((b) => b.rating > 0).toList();
  check(rated.isNotEmpty, '应存在有评分的书');
  final badRating = books.where((b) => b.rating < 0 || b.rating > 5).length;
  check(badRating == 0, '评分应落在 0–5', '越界 $badRating 本');

  final badProgress = books.where((b) => b.progressPercent < 0 || b.progressPercent > 100).length;
  check(badProgress == 0, '进度应落在 0–100', '越界 $badProgress 本');

  // 列表字段：JSON 数组 → List<String>，不能被压成空或混入空串
  final emptyAuthor = books.expand((b) => b.authors).where((a) => a.trim().isEmpty).length;
  check(emptyAuthor == 0, '不应有空作者名', '空作者 $emptyAuthor 条');

  // extra 兜底：Notion 自定义属性不能丢
  final withExtra = books.where((b) => b.extra.isNotEmpty).length;
  print('extra 非空：$withExtra 本（Notion 自定义属性）');

  // 笔记按书名关联（Notion 的 Quotes 库没有 bookId）
  final byTitle = <String, String>{};
  for (final b in books) {
    byTitle.putIfAbsent(b.title.trim(), () => b.id);
  }
  int matched = 0;
  for (final n in rawNotes.whereType<Map>()) {
    final t = (n['bookTitle'] as String?)?.trim() ?? '';
    if (byTitle.containsKey(t)) matched++;
  }
  print('笔记可关联：$matched/${rawNotes.length}');
  check(matched > 0, '至少应能关联部分笔记');

  // 分类归一化后的分布（与 Node 侧保持一致）
  final catCount = <String, int>{};
  for (final b in books) {
    final k = b.categoryPrimary ?? '未分类';
    catCount[k] = (catCount[k] ?? 0) + 1;
  }
  final sorted = catCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  print('\n分类分布（${sorted.length} 类）：');
  for (final e in sorted) {
    print('  ${e.value.toString().padLeft(3)}  ${e.key}');
  }

  print('\n种子数据校验：通过 $_pass，失败 $_fail');
  if (_fail > 0) exit(1);
}
