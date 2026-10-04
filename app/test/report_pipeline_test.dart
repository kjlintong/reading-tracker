// 报告流水线的单元测试。
//
// 这里锁的是三条保证，它们正是旧实现做不到的：
//   1. 结构恒定 —— 排版由本地模板决定，模型只影响措辞；
//   2. 点名不编造 —— 模型提到的书必须来自下发的清单；
//   3. 数字可溯源 —— 数字走占位符，渲染时本地替换，不可能与库里不一致。
import 'package:flutter_test/flutter_test.dart';

import 'package:reading_tracker/data/date_range.dart';
import 'package:reading_tracker/data/report_pipeline.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

Book _book(
  String title, {
  BookStatus status = BookStatus.wish,
  double rating = 0,
  double progress = 0,
  String? finishedAt,
  String? category,
  List<String> authors = const [],
}) {
  final b = Book.create(title: title);
  return b.copyWith(
    status: status,
    rating: rating,
    progressPercent: progress,
    finishedAt: finishedAt,
    categoryPrimary: category,
    authors: authors,
  );
}

void main() {
  group('切片：书架规模不等于阅读行为', () {
    final range = StatsRange(
      label: '2026',
      from: DateTime(2026, 1, 1),
      to: DateTime(2027, 1, 1),
    );

    test('完成时间不在周期内就不算本期读完', () {
      final slice = sliceBooks(
        books: [
          _book('今年读完的', status: BookStatus.finished,
              finishedAt: '2026-05-01'),
          _book('去年读完的', status: BookStatus.finished,
              finishedAt: '2025-05-01'),
          // 已读但没有完成时间：无法归属到任何周期，不能算进本期
          _book('没写完成时间的', status: BookStatus.finished),
        ],
        range: range,
      );
      expect(slice.finished.map((b) => b.title), ['今年读完的']);
      // 但它仍然在书架口径里
      expect(slice.shelf.length, 3);
    });

    test('在读且进度极低单独归为 stalled', () {
      final slice = sliceBooks(
        books: [
          _book('开了个头', status: BookStatus.reading, progress: 5),
          _book('读了大半', status: BookStatus.reading, progress: 60),
        ],
        range: range,
      );
      expect(slice.stalled.map((b) => b.title), ['开了个头']);
      expect(slice.reading.length, 2);
    });

    test('脏标题不进切片', () {
      final slice = sliceBooks(
        books: [_book('目录'), _book('x'), _book('正常的书')],
        range: range,
      );
      expect(slice.shelf.map((b) => b.title), ['正常的书']);
    });
  });

  group('书单：按相关性排序，不是按更新时间', () {
    test('已读优先于在读优先于想读', () {
      final slice = ReportSlice(
        finished: [_book('读完的')],
        reading: [],
        stalled: [],
        // 想读排在前面也没用：排序不看输入顺序
        wishAdded: [_book('想读一'), _book('想读二')],
        rated: [],
        shelf: const [],
      );
      final list = buildBookList(slice);
      expect(list.first['title'], '读完的');
    });

    test('批量导入不会把已读书挤出书单', () {
      // 旧实现取 books.take(60)，批量导入后拿到的全是最后进来的想读书，
      // 模型因此无书可点。这条用例就是那个 bug 的回归锁。
      final slice = ReportSlice(
        finished: [for (var i = 0; i < 5; i++) _book('已读$i')],
        reading: [_book('在读的书', progress: 40)],
        stalled: const [],
        wishAdded: [for (var i = 0; i < 60; i++) _book('导入$i')],
        rated: const [],
        shelf: const [],
      );
      final list = buildBookList(slice);
      final titles = list.map((e) => e['title']).toList();
      expect(titles.where((t) => t.toString().startsWith('已读')).length, 5);
      expect(titles.contains('在读的书'), isTrue);
    });
  });

  group('校验：模型不能凭空造书', () {
    final known = {'a1', 'b2'};
    final titles = {'a1': '置身事内', 'b2': '沉思录'};

    test('编造的 id 整条丢掉，已知的保留', () {
      final p = parseReportPayload('''{
        "naming": [
          {"id": "a1", "line": "这本读完了"},
          {"id": "zz99", "line": "这本是我编的"},
          {"id": "b2", "line": "这本开了头"}
        ]
      }''', knownBookIds: known);
      expect(p.naming.length, 2);
      expect(p.naming.map((n) => n.id), ['a1', 'b2']);
      expect(p.naming.any((n) => n.line.contains('编的')), isFalse);
    });

    test('下一步计划里推荐了没在架上的书，同样丢掉', () {
      final p = parseReportPayload('''{
        "nextPlan": {
          "focus": "先把在读的收尾",
          "reads": [
            {"id": "b2", "why": "已经读了一部分"},
            {"id": "nope", "why": "这本根本不存在"}
          ]
        }
      }''', knownBookIds: known);
      expect(p.nextReads.map((n) => n.id), ['b2']);
    });

    test('完全不是 JSON 时返回空载荷而不是抛异常', () {
      final p = parseReportPayload('抱歉，我做不到', knownBookIds: known);
      expect(p.isEmpty, isTrue);
    });

    test('markdown 代码围栏里包着 JSON 也能解析', () {
      final p = parseReportPayload(
        '```json\n{"headline": "今年读得不错"}\n```',
        knownBookIds: known,
      );
      expect(p.headline, '今年读得不错');
    });
  });

  group('渲染：结构恒定、数字可溯源', () {
    final facts = <String, dynamic>{
      'finished': 7,
      'reading': 3,
      'stalled': 2,
      'avgRating': 4.2,
      'hasLogs': false,
    };
    final titles = {'a1': '置身事内', 'b2': '沉思录'};

    test('占位符替换成事实表里的数字', () {
      final md = renderReport(
        parseReportPayload('''{
          "headline": "这个月读完 [[finished]] 本，还有 [[reading]] 本在读",
          "activity": ["开坑未填的有 [[stalled]] 本"],
          "naming": [{"id": "a1", "line": "读完 [[finished]] 本里最扎实的一本"}]
        }''', knownBookIds: {'a1'}),
        facts: facts,
        titleById: titles,
      );
      expect(md.contains('读完 7 本'), isTrue);
      expect(md.contains('3 本在读'), isTrue);
      expect(md.contains('[[finished]]'), isFalse);
    });

    test('未知占位符渲染成破折号，不会漏出原始标记', () {
      final md = renderReport(
        parseReportPayload('{"headline": "日均 [[nope]] 分钟"}',
            knownBookIds: {}),
        facts: facts,
        titleById: titles,
      );
      expect(md.contains('[['), isFalse);
      expect(md.contains('—'), isTrue);
    });

    test('空的小节整节省略，不硬凑', () {
      final md = renderReport(
        parseReportPayload('{"headline": "还行", "activity": ["一条观察"]}',
            knownBookIds: {}),
        facts: facts,
        titleById: titles,
      );
      // 只有概览与本期阅读两节有点名和画像都没出现
      expect(md.contains('## '), isTrue);
      final headings = RegExp(r'^## .*$', multiLine: true)
          .allMatches(md)
          .map((m) => m.group(0))
          .toList();
      expect(headings.length, 2, reason: '空节不该出现：${headings.join(' | ')}');
    });

    test('点名用《》包裹书名，渲染器认得', () {
      final md = renderReport(
        parseReportPayload(
          '{"naming": [{"id": "a1", "line": "读完最扎实的一本"}]}',
          knownBookIds: {'a1'},
        ),
        facts: facts,
        titleById: titles,
      );
      expect(md.contains('《置身事内》'), isTrue);
    });
  });

  group('提示词：没有的数据维度不下发', () {
    test('没有阅读记录时明令禁止谈时长与节奏', () {
      final p = buildInsightsPrompt(
        facts: {'finished': 5, 'hasLogs': false},
        bookList: const [],
        nextCandidates: const [],
        zh: true,
      );
      expect(p.contains('NO reading-time logs'), isTrue);
      expect(p.contains('"minutes"'), isFalse);
    });

    test('有阅读记录时不再写那句禁令', () {
      final p = buildInsightsPrompt(
        facts: {'finished': 5, 'hasLogs': true, 'minutes': 600, 'streak': 9},
        bookList: const [],
        nextCandidates: const [],
        zh: true,
      );
      expect(p.contains('NO reading-time logs'), isFalse);
    });

    test('书架偏好不能从想读里推断', () {
      final p = buildInsightsPrompt(
        facts: {'finished': 5, 'hasLogs': false},
        bookList: const [],
        nextCandidates: const [],
        zh: true,
      );
      expect(p.contains('Never infer taste from the wishlist'), isTrue);
    });
  });
}
