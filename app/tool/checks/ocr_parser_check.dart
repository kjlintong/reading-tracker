// 纯 Dart 校验：不依赖 Flutter，可直接使用 dart-sdk 运行
// 运行：dart run tool/checks/ocr_parser_check.dart
//
// 校验 Dart 端 OCR 书名提取算法与 Node 端（tools/lib/ocr_clean.mjs）行为一致。
// 两个实现必须产出相同结果，否则跨端数据会不一致。

// ignore_for_file: avoid_print

import 'package:reading_tracker/import/shelf_ocr_parser.dart';

int passed = 0;
int failed = 0;

void check(String name, bool ok, [String detail = '']) {
  if (ok) {
    passed++;
    print('  PASS  $name');
  } else {
    failed++;
    print('  FAIL  $name  $detail');
  }
}

void main() {
  const wereadList = '''
书架
最近阅读
三体
刘慈欣
读至 45%
置身事内
兰小欢
已读完
万历十五年
黄仁宇
100%
人类简史
尤瓦尔·赫拉利
共 128 本
昨天
''';

  print('\n[1] 微信读书列表页');
  final r1 = ShelfOcrParser.extract(wereadList);
  final t1 = r1.map((c) => c.title).toList();
  print('       提取: ${r1.map((c) => '${c.title}(${(c.score * 100).round()}%)')}');

  check('识别出三体', t1.contains('三体'));
  check('识别出置身事内', t1.contains('置身事内'));
  check('识别出万历十五年', t1.contains('万历十五年'));
  check('识别出人类简史', t1.contains('人类简史'));
  check('排除「书架」', !t1.contains('书架'));
  check('排除「最近阅读」', !t1.contains('最近阅读'));
  check('排除进度 45%', !t1.any((t) => t.contains('45%')));
  check('排除 100%', !t1.contains('100%'));
  check('排除「共 128 本」', !t1.any((t) => t.contains('128')));
  check('排除「昨天」', !t1.contains('昨天'));
  check('作者刘慈欣不误判为书名', !t1.contains('刘慈欣'));
  check('作者黄仁宇不误判为书名', !t1.contains('黄仁宇'));
  check('音译作者不误判为书名', !t1.contains('尤瓦尔·赫拉利'));
  check('作者关联到书名',
      r1.firstWhere((c) => c.title == '三体', orElse: () => TitleCandidate(title: '', score: 0)).author == '刘慈欣');

  print('\n[2] 断行合并');
  final r2 = ShelfOcrParser.extract('追风\n筝的人\n百年孤独\n');
  final t2 = r2.map((c) => c.title).toList();
  print('       提取: $t2');
  check('断行标题被合并', t2.any((t) => t.startsWith('追风') && t.length >= 4));
  check('完整标题保留', t2.contains('百年孤独'));

  print('\n[3] 掌阅风格');
  final r3 = ShelfOcrParser.extract('我的图书\n全部\n筛选\n经济学原理\n曼昆\n试读\n');
  final t3 = r3.map((c) => c.title).toList();
  check('识别出经济学原理', t3.contains('经济学原理'));
  check('排除「我的图书」', !t3.contains('我的图书'));

  print('\n[4] 边界');
  check('空输入', ShelfOcrParser.extract('').isEmpty);
  check('纯噪音', ShelfOcrParser.extract('书架\n搜索\n100%\n昨天\n').isEmpty);
  final r4 = ShelfOcrParser.extract('《置身事内》\n兰小欢');
  check('含书名号高分',
      r4.any((c) => c.title.contains('置身事内') && c.score > 0.7));

  print('\n[5] 候选转书籍');
  final cand = ShelfOcrParser.extract('三体\n刘慈欣').first;
  final book = cand.toBook();
  check('书名正确', book.title == '三体', book.title);
  check('作者正确', book.authors.contains('刘慈欣'), book.authors.toString());

  print('\n通过 $passed，失败 $failed');
  if (failed > 0) throw StateError('存在失败用例');
}
