import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/import/ocr_line.dart';
import 'package:reading_tracker/import/shelf_layout.dart';
import 'package:reading_tracker/models/enums.dart';

/// 版面解析是截图导入的核心：它决定「这一行属于哪本书」。
///
/// 这些用例都照着真实的书架截图构造坐标——三列栅格、封面在上、
/// 书名在封面下方（可能换行）、进度压在最底下一行。
/// 纯文本解析在这里会彻底失效：没有坐标，「0.8%」无法判断属于哪本书。
void main() {
  OcrLine l(String text, double left, double top,
          {double width = 120, double height = 22}) =>
      OcrLine(
        text: text,
        left: left,
        top: top,
        right: left + width,
        bottom: top + height,
      );

  List<String> titles(List<dynamic> r) =>
      r.map((e) => e.title as String).toList();

  group('三列书架栅格', () {
    final lines = <OcrLine>[
      // 顶部界面：搜索框、筛选、管理——必须被丢掉
      l('书架内搜索', 20, 60, width: 300),
      l('筛选', 300, 60, width: 40),
      l('管理', 360, 60, width: 40),

      // 第一列
      l('室内设计风格详', 20, 500),
      l('解式', 20, 524),
      l('0.8%', 20, 552, width: 50),
      l('那些即将消失的', 20, 900),
      l('地方', 20, 924),
      l('0.3%', 20, 952, width: 50),
      l('人像摄影摆姿实用技巧', 20, 1200),

      // 第二列
      l('西西弗神话（加缪作品精装版）', 160, 500),
      l('11.5%', 160, 552, width: 50),
      l('已读完', 160, 880, width: 50),
      l('共11本', 160, 902, width: 50),
      l('微表情心理学全书', 160, 1200),
      l('（全三册）', 160, 1224),
      l('未读', 160, 1252, width: 40),

      // 第三列
      l('EYE上这样的旅行', 300, 500),
      l('0.3%', 300, 552, width: 50),
      l('哲学的邀约（全2册）', 300, 880),
      l('未读', 300, 932, width: 40),
      l('中国历史通论', 300, 1200),
      l('（增订本）', 300, 1224),
      l('未读', 300, 1252, width: 40),
    ];

    final result = ShelfLayoutParser.parse(lines);

    test('每一格都识别出来，且换行的书名被拼回完整', () {
      final t = titles(result);
      expect(t, contains('室内设计风格详解式'));
      expect(t, contains('那些即将消失的地方'));
      expect(t, contains('西西弗神话（加缪作品精装版）'));
      expect(t, contains('微表情心理学全书（全三册）'));
      expect(t, contains('EYE上这样的旅行'));
      expect(t, contains('哲学的邀约（全2册）'));
      expect(t, contains('中国历史通论（增订本）'));
    });

    test('界面文字没有混进书名', () {
      final t = titles(result);
      expect(t, isNot(contains('书架内搜索')));
      expect(t, isNot(contains('筛选')));
      expect(t, isNot(contains('管理')));
    });

    test('进度按列归属到正确的书，而不是就近乱配', () {
      // 这是纯文本解析永远做不到的一条：文字流里 0.8% 紧跟 解式，
      // 但只有坐标能证明它属于第一列的「室内设计风格详解式」
      void check(String title, double progress) {
        final c = result.firstWhere((e) => e.title == title,
            orElse: () => fail('没识别出 $title'));
        expect(c.progressPercent, progress, reason: '$title 的进度应为 $progress');
      }

      check('室内设计风格详解式', 0.8);
      check('那些即将消失的地方', 0.3);
      check('西西弗神话（加缪作品精装版）', 11.5);
      check('EYE上这样的旅行', 0.3);
    });

    test('状态词被识别成状态而不是书名', () {
      final yue = result.firstWhere((e) => e.title == '哲学的邀约（全2册）');
      expect(yue.statusHint, BookStatus.wish);
      expect(titles(result), isNot(contains('未读')));
      expect(titles(result), isNot(contains('已读完')));
      expect(titles(result), isNot(contains('共11本')));
    });

    test('置信度整体高于阈值，可默认勾选', () {
      expect(result.every((e) => e.score >= 0.35), isTrue);
      final withMeta = result.where((e) => e.progressPercent != null).length;
      expect(withMeta, greaterThanOrEqualTo(4));
    });
  });

  group('被界面截断的标题', () {
    test('行尾省略号被标记为截断，书名保持原样交给联网补齐', () {
      final r = ShelfLayoutParser.parse([
        l('雅思口语深…', 20, 500),
        l('已读8%', 20, 552, width: 50),
      ]);
      final c = r.firstWhere((e) => e.title.startsWith('雅思口语深'));
      expect(c.truncated, isTrue);
      // 解析阶段不猜书名——猜是离线行为，错了没人能发现。
      // 补齐交给联网的权威源，补了什么会被标出来
      expect(c.title, '雅思口语深…');
      expect(c.progressPercent, 8);
    });

    test('正常书名不会被误判为截断', () {
      final r = ShelfLayoutParser.parse([l('活着', 20, 500)]);
      expect(r.first.truncated, isFalse);
    });
  });

  group('阅读器内页截图', () {
    test('章节标题、英文副标题、页码、状态栏都不产生假书', () {
      final r = ShelfLayoutParser.parse([
        l('第一章 法国室内设计发展史', 30, 100, width: 260),
        l('Chapter 1 The History of French Interior Design', 30, 160, width: 300),
        l('4/249', 300, 1200, width: 40),
        l('21:19', 20, 20, width: 40),
        l('36.8 KB/s', 300, 20, width: 60),
      ]);
      expect(r, isEmpty);
    });
  });

  group('封面照', () {
    test('取字号最大的一行作为书名，并关联作者', () {
      final r = ShelfLayoutParser.parse(
        [
          l('活着', 100, 300, width: 200, height: 60),
          l('余华 著', 150, 400, width: 120, height: 28),
          l('作家出版社', 120, 450, width: 180, height: 18),
        ],
        mode: OcrMode.cover,
      );
      expect(r.first.title, '活着');
      expect(r.first.author, '余华');
    });

    test('作者行不会同时作为一本候选书出现', () {
      final r = ShelfLayoutParser.parse(
        [
          l('置身事内', 100, 300, width: 200, height: 60),
          l('兰小欢 著', 150, 400, width: 120, height: 30),
        ],
        mode: OcrMode.cover,
      );
      expect(titles(r), contains('置身事内'));
      expect(titles(r).any((t) => t.contains('兰小欢 著')), isFalse);
    });
  });

  group('封面美术字', () {
    test('全大写英文被降权，中文书名胜出', () {
      final r = ShelfLayoutParser.parse([
        l('SMALL GARDEN HANDBOOK', 20, 400, width: 130, height: 20),
        l('生活美学：', 20, 500, width: 130),
        l('已读1%', 20, 552, width: 50),
      ]);
      expect(titles(r), contains('生活美学：'));
      expect(titles(r).any((t) => t.contains('SMALL GARDEN')), isFalse);
    });

    test('长短混排时不会把美术字和书名粘在一起', () {
      final r = ShelfLayoutParser.parse([
        l('SMALL GARDEN HANDBOOK', 20, 400, width: 130, height: 20),
        l('生活美学', 20, 500, width: 130),
      ]);
      expect(titles(r).any((t) => t.contains('生活美学') && t.contains('GARDEN')),
          isFalse);
    });
  });

  group('几何信息缺失', () {
    test('没有坐标时退回纯文本解析，而不是把整页揉成一列', () {
      final r = ShelfLayoutParser.parse([
        const OcrLine.text('三体'),
        const OcrLine.text('刘慈欣'),
        const OcrLine.text('100%'),
        const OcrLine.text('置身事内'),
      ]);
      expect(titles(r), contains('三体'));
      expect(titles(r), contains('置身事内'));
    });
  });
}
