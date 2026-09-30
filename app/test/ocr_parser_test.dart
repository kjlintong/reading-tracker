import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/import/shelf_ocr_parser.dart';

/// 截图 OCR 是「书架导入」的主路径：用户截一张微信读书/掌阅的书架图，
/// 端侧识别出书名后逐个去元数据接口补全。
///
/// 取向是宁可多召回不可漏召回——误判会在确认页被用户剔除（可见可控），
/// 漏掉则用户完全无感知（不可控）。因此断言重点是「不该出现的别出现」。
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

  group('微信读书列表页', () {
    final r = ShelfOcrParser.extract(wereadList);
    final titles = r.map((c) => c.title).toList();

    test('四本书全部识别', () {
      expect(titles, contains('三体'));
      expect(titles, contains('置身事内'));
      expect(titles, contains('万历十五年'));
      expect(titles, contains('人类简史'));
    });

    test('界面噪音与进度信息被排除', () {
      expect(titles, isNot(contains('书架')));
      expect(titles, isNot(contains('最近阅读')));
      expect(titles, isNot(contains('100%')));
      expect(titles, isNot(contains('昨天')));
      expect(titles.any((t) => t.contains('45%')), isFalse);
      expect(titles.any((t) => t.contains('128')), isFalse);
    });

    test('作者行不误判为书名', () {
      expect(titles, isNot(contains('刘慈欣')));
      expect(titles, isNot(contains('黄仁宇')));
      expect(titles, isNot(contains('尤瓦尔·赫拉利')));
    });

    test('作者正确关联到书名', () {
      final t = r.firstWhere((c) => c.title == '三体');
      expect(t.author, '刘慈欣');
    });
  });

  group('断行与书名单行', () {
    test('断行标题被合并', () {
      final t = ShelfOcrParser.extract('追风\n筝的人\n百年孤独\n')
          .map((c) => c.title)
          .toList();
      expect(t.any((x) => x.startsWith('追风') && x.length >= 4), isTrue);
      expect(t, contains('百年孤独'));
    });

    test('含书名号的标题得高分', () {
      final r = ShelfOcrParser.extract('《置身事内》\n兰小欢');
      expect(r.any((c) => c.title.contains('置身事内') && c.score > 0.7), isTrue);
    });
  });

  group('其他平台风格', () {
    test('掌阅：排除筛选栏', () {
      final t = ShelfOcrParser
          .extract('我的图书\n全部\n筛选\n经济学原理\n曼昆\n试读\n')
          .map((c) => c.title)
          .toList();
      expect(t, contains('经济学原理'));
      expect(t, isNot(contains('我的图书')));
    });
  });

  group('边界', () {
    test('空输入与纯噪音返回空', () {
      expect(ShelfOcrParser.extract(''), isEmpty);
      expect(ShelfOcrParser.extract('书架\n搜索\n100%\n昨天\n'), isEmpty);
    });

    test('候选可直接转为 Book', () {
      final book = ShelfOcrParser.extract('三体\n刘慈欣').first.toBook();
      expect(book.title, '三体');
      expect(book.authors, contains('刘慈欣'));
    });
  });
}
