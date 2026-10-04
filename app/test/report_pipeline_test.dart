// 报告流水线的单元测试。
//
// 这里锁的是四条保证，它们正是旧实现做不到的：
//   1. 结构恒定 —— 排版由本地模板决定，模型只影响措辞；
//   2. 点名不编造 —— 模型提到的书必须来自下发的清单；
//   3. 数字可溯源 —— 数字走占位符，渲染时本地替换，不可能与库里不一致；
//   4. 时间可区分 —— 书单带日期、近期的书优先，旧存货不会被当成当下意图。
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/data/database.dart';
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

/// 时间可控的书：`Book.create` 的 createdAt 恒为「现在」，测不了时间口径。
Book _bookAt(
  String title, {
  BookStatus status = BookStatus.wish,
  double rating = 0,
  double progress = 0,
  String? finishedAt,
  String? startedAt,
  String? createdAt,
  String? category,
}) =>
    Book(
      id: title,
      title: title,
      status: status,
      rating: rating,
      progressPercent: progress,
      finishedAt: finishedAt,
      startedAt: startedAt,
      createdAt: createdAt ?? '2026-01-01T00:00:00.000',
      updatedAt: createdAt ?? '2026-01-01T00:00:00.000',
      categoryPrimary: category,
    );

String _isoDaysAgo(int d) =>
    DateTime.now().subtract(Duration(days: d)).toIso8601String();

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

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

    test('脏标题不进阅读分组，但仍算书架上的一本', () {
      final slice = sliceBooks(
        books: [_book('目录'), _book('x'), _book('正常的书')],
        range: range,
      );
      // 书架规模必须和 App 书架页对得上，不能因为标题脏就少算几本
      expect(slice.shelf.length, 3);
      expect(slice.wishAdded.map((b) => b.title), ['正常的书']);
    });

    test('截断的导入残条不进书单', () {
      final slice = sliceBooks(
        books: [
          _book('Jiao Yi Xi Tong Yu Fang Fa (Yua'),
          _book('哈耶克作品集 (哈耶克) (rary)'),
          _book('交易系统与方法'),
        ],
        range: range,
      );
      expect(slice.wishAdded.map((b) => b.title), ['交易系统与方法']);
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

  group('书单：带时间，近期的优先', () {
    test('条目带上加入日期与完成日期', () {
      final list = buildBookList(
        ReportSlice(
          finished: [
            _bookAt('读完的', status: BookStatus.finished,
                finishedAt: '2026-03-02T10:00:00.000',
                createdAt: '2026-01-05T10:00:00.000'),
          ],
          reading: const [],
          stalled: const [],
          wishAdded: [
            _bookAt('想读的', createdAt: '2026-04-01T10:00:00.000'),
          ],
          rated: const [],
          shelf: const [],
        ),
      );
      final byTitle = {for (final e in list) e['title']: e};
      expect(byTitle['读完的']!['finishedAt'], '2026-03-02');
      expect(byTitle['读完的']!['addedAt'], '2026-01-05');
      expect(byTitle['想读的']!['addedAt'], '2026-04-01');
    });

    test('最近读完的排在最前', () {
      // 输入顺序故意反着给：排序必须看 finishedAt，不能看列表顺序。
      // 年报里「读了 20 本」看不出哪本刚读完，顺序决定了模型先点谁。
      final list = buildBookList(
        ReportSlice(
          finished: [
            _bookAt('三月读完的', status: BookStatus.finished,
                finishedAt: '2026-03-01T00:00:00.000'),
            _bookAt('一月读完的', status: BookStatus.finished,
                finishedAt: '2026-01-01T00:00:00.000'),
          ],
          reading: const [],
          stalled: const [],
          wishAdded: const [],
          rated: const [],
          shelf: const [],
        ),
      );
      expect(list.first['title'], '三月读完的');
    });

    test('最近加进书架的想读排在最前', () {
      final list = buildBookList(
        ReportSlice(
          finished: const [],
          reading: const [],
          stalled: const [],
          wishAdded: [
            _bookAt('年初加的', createdAt: '2026-01-02T00:00:00.000'),
            _bookAt('昨天加的', createdAt: '2026-06-28T00:00:00.000'),
          ],
          rated: const [],
          shelf: const [],
        ),
      );
      expect(list.first['title'], '昨天加的');
    });

    test('recent 只标近期动过的书', () {
      final since = DateTime.now().subtract(const Duration(days: 30));
      final list = buildBookList(
        ReportSlice(
          finished: const [],
          reading: const [],
          stalled: const [],
          wishAdded: [
            _bookAt('上周加的', createdAt: _isoDaysAgo(7)),
            _bookAt('两年前加的', createdAt: _isoDaysAgo(730)),
          ],
          rated: const [],
          shelf: const [],
        ),
        recentSince: since,
      );
      final byTitle = {for (final e in list) e['title']: e};
      expect(byTitle['上周加的']!['recent'], true);
      // 老存货不带这个标记：不标，模型就不会把它当作「现在想读」
      expect(byTitle['两年前加的']!.containsKey('recent'), isFalse);
    });

    test('recent 看的是阅读行为，不是入库时间', () {
      // 一次批量导入会把几百本书的 createdAt 刷成同一天：拿它判近期的话，
      // 五月读完的书也会变成「刚读的」，标记就没有区分度了。
      final since = DateTime.now().subtract(const Duration(days: 30));
      final list = buildBookList(
        ReportSlice(
          finished: [
            _bookAt('年初读完、上周才导入', status: BookStatus.finished,
                finishedAt: '2026-02-01', createdAt: _isoDaysAgo(3)),
            _bookAt('上周读完的', status: BookStatus.finished,
                finishedAt: _isoDaysAgo(5), createdAt: _isoDaysAgo(3)),
          ],
          reading: const [],
          stalled: const [],
          wishAdded: const [],
          rated: const [],
          shelf: const [],
        ),
        recentSince: since,
      );
      final byTitle = {for (final e in list) e['title']: e};
      expect(byTitle['年初读完、上周才导入']!.containsKey('recent'), isFalse);
      expect(byTitle['上周读完的']!['recent'], true);
    });
  });

  group('近期窗口：只在长周期里单独统计', () {
    test('年报带近 30 天与近半年两档，月报都不带', () {
      final slice = sliceBooks(books: const [], range: StatsRange.all);
      final yearly = buildReportFacts(
        slice,
        recencyDays: 30,
        finishedRecent: 2,
        wishAddedRecent: 5,
        halfYearDays: 180,
        finishedHalfYear: 9,
        wishAddedHalfYear: 40,
      );
      expect(yearly['recentDays'], 30);
      expect(yearly['finishedRecent'], 2);
      expect(yearly['wishAddedRecent'], 5);
      expect(yearly['halfYearDays'], 180);
      expect(yearly['finishedHalfYear'], 9);

      // 月报里窗口和周期本身重合，再给一份只会让模型把同一句写两遍
      final monthly = buildReportFacts(slice);
      expect(monthly.containsKey('recentDays'), isFalse);
      expect(monthly.containsKey('finishedRecent'), isFalse);
      expect(monthly.containsKey('halfYearDays'), isFalse);
    });

    test('年报里两档窗口各算各的', () async {
      final raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
      addTearDown(() => raw.close());
      final db = AppDatabase.forTest(raw);
      await db.createSchema(raw);
      final repo = BookRepository(db);

      final books = [
        _bookAt('刚读完一', status: BookStatus.finished,
            finishedAt: _isoDaysAgo(3)),
        _bookAt('刚读完二', status: BookStatus.finished,
            finishedAt: _isoDaysAgo(20)),
        _bookAt('年初读完', status: BookStatus.finished,
            finishedAt: _isoDaysAgo(200)),
      ];
      final bundle = await buildReportBundle(
        repo: repo,
        books: books,
        range: StatsRange(
          label: '全部',
          from: DateTime(2020, 1, 1),
          to: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      expect(bundle.facts['finished'], 3);
      // 累计 3 本看不出「现在还读不读」，近 30 天的 2 本才说明问题
      expect(bundle.facts['finishedRecent'], 2);
      // 200 天前那本落在半年窗口之外：两档数字不同，说的正是趋势
      expect(bundle.facts['finishedHalfYear'], 2);
    });

    test('近期窗口的锚点是今天，不是周期末', () async {
      // 「今年」的 to 是明年 1 月 1 日：拿周期末减 30 天会得到一个未来的
      // 日期，近 30 天恒为 0，刚读完的书一条都进不来。
      final raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
      addTearDown(() => raw.close());
      final db = AppDatabase.forTest(raw);
      await db.createSchema(raw);
      final repo = BookRepository(db);

      final bundle = await buildReportBundle(
        repo: repo,
        books: [
          _bookAt('上周读完的', status: BookStatus.finished,
              finishedAt: _isoDaysAgo(7)),
        ],
        range: StatsRange(
          label: '2026',
          from: DateTime(DateTime.now().year, 1, 1),
          to: DateTime(DateTime.now().year + 1, 1, 1),
        ),
      );
      expect(bundle.facts['finishedRecent'], 1);
      expect(bundle.facts['finishedHalfYear'], 1);
      // periodEnd 也得是「今天」，否则模型会以为现在是明年
      expect(bundle.facts['periodEnd'].toString().startsWith('2027'), isFalse);
    });

    test('跨度不到半年的周期只给 30 天档', () async {
      final raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
      addTearDown(() => raw.close());
      final db = AppDatabase.forTest(raw);
      await db.createSchema(raw);
      final repo = BookRepository(db);

      final bundle = await buildReportBundle(
        repo: repo,
        books: [
          _bookAt('读完的', status: BookStatus.finished,
              finishedAt: _isoDaysAgo(10)),
        ],
        range: StatsRange(
          label: '近三个月',
          from: DateTime.now().subtract(const Duration(days: 100)),
          to: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      expect(bundle.facts['recentDays'], 30);
      // 窗口比周期还宽的话，它和「本期读完」是同一件事，没有额外信息
      expect(bundle.facts.containsKey('halfYearDays'), isFalse);
    });
  });

  group('衍生指标：把计数换算成读者自己算不出来的数', () {
    final year = StatsRange(
      label: '2026',
      from: DateTime(2026, 1, 1),
      to: DateTime(2027, 1, 1),
    );

    test('沉寂天数、完成月份数、清空书架需要的年数', () {
      final now = DateTime.now();
      final books = [
        _bookAt('一月读完的', status: BookStatus.finished, finishedAt: _isoDaysAgo(150)),
        _bookAt('五月读完的', status: BookStatus.finished, finishedAt: _isoDaysAgo(40)),
        for (var i = 0; i < 48; i++) _bookAt('想读$i'),
      ];
      final slice = sliceBooks(books: books, range: year);
      final d = derivedInsights(
        slice: slice, range: year, anchor: now, spanDays: 365,
      );
      // 「最后一本是 40 天前」比「近半年读完 2 本」直白
      expect(d['silenceDays'], greaterThanOrEqualTo(39));
      // 两本书只落在两个不同的月份：9 本读完≠读了 9 个月
      expect(d['finishedMonths'], 2);
      // 一年 2 本、想读 48 本 -> 24 年。「48 本想读」是不可感的数字
      expect(d['backlogYears'], 24);
    });

    test('跨度过大时不给外推年数，但沉寂天数照给', () {
      // 「全部时间」没有起点，跨度是个天文数字，外推出来的年数荒谬到
      // 模型会照着写一句「按这个速度你要读 4000 年」
      final slice = sliceBooks(
        books: [_bookAt('读完的', status: BookStatus.finished, finishedAt: _isoDaysAgo(30))],
        range: StatsRange.all,
      );
      final d = derivedInsights(
        slice: slice,
        range: StatsRange.all,
        anchor: DateTime.now(),
        spanDays: 1 << 30,
      );
      expect(d.containsKey('backlogYears'), isFalse);
      // 不依赖跨度的指标照常给
      expect(d.containsKey('silenceDays'), isTrue);
    });

    test('高分书与本期高分书分开给，能看出口味分叉', () {
      final books = [
        _bookAt('往年高分甲', status: BookStatus.finished, rating: 5, finishedAt: _isoDaysAgo(500)),
        _bookAt('往年高分乙', status: BookStatus.finished, rating: 4, finishedAt: _isoDaysAgo(400)),
        _bookAt('本期高分', status: BookStatus.finished, rating: 5, finishedAt: _isoDaysAgo(20)),
        _bookAt('读完没评分', status: BookStatus.finished, finishedAt: _isoDaysAgo(30)),
      ];
      final slice = sliceBooks(books: books, range: year);
      final d = derivedInsights(
        slice: slice, range: year, anchor: DateTime.now(), spanDays: 365,
      );
      expect(d['highRated'], 3);
      // 3 本 4 星以上只有 1 本出自本期：今年的阅读偏离了拿高分的那条线
      expect(d['highRatedPeriod'], 1);
      expect(d['unratedFinished'], 1);
      expect('${d['ratingSpread']}', contains('5★×2'));
    });

    test('在读的平均开坑天数与最大分类占比', () {
      final books = [
        _bookAt('开了三个月的坑', status: BookStatus.reading, startedAt: _isoDaysAgo(90)),
        _bookAt('上个月开的坑', status: BookStatus.reading, startedAt: _isoDaysAgo(30)),
        for (var i = 0; i < 3; i++) _bookAt('社科$i', category: '社科'),
        for (var i = 0; i < 2; i++) _bookAt('文学$i', category: '文学'),
      ];
      final slice = sliceBooks(books: books, range: year);
      final d = derivedInsights(
        slice: slice, range: year, anchor: DateTime.now(), spanDays: 365,
      );
      expect(d['readingAgeDays'], 60);
      // 分母是**整个书架**（7 本，含两本在读），不是只数已分类的
      expect(d['topCategoryShare'], 43);
    });

    test('衍生指标进了占位符清单，模型才引用得到', () {
      final p = buildInsightsPrompt(
        facts: {
          'finished': 2,
          'hasLogs': false,
          'backlogYears': 24,
          'silenceDays': 40,
        },
        bookList: const [],
        nextCandidates: const [],
        languageCode: 'zh',
      );
      expect(p.contains('[[backlogYears]]'), isTrue);
      expect(p.contains('[[silenceDays]]'), isTrue);
      // 「无聊」的病根是复述数字，这两条规则是直接对着它开的
      expect(p.contains('NEVER just restate'), isTrue);
      expect(p.contains('DERIVED facts'), isTrue);
      // 事实表里没有的键绝不列，否则模型照写就渲染成破折号
      expect(p.contains('[[topCategoryShare]]'), isFalse);
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
        languageCode: 'zh',
      );
      expect(p.contains('NO reading-time logs'), isTrue);
      expect(p.contains('"minutes"'), isFalse);
    });

    test('有阅读记录时不再写那句禁令', () {
      final p = buildInsightsPrompt(
        facts: {'finished': 5, 'hasLogs': true, 'minutes': 600, 'streak': 9},
        bookList: const [],
        nextCandidates: const [],
        languageCode: 'zh',
      );
      expect(p.contains('NO reading-time logs'), isFalse);
    });

    test('书架偏好不能从想读里推断', () {
      final p = buildInsightsPrompt(
        facts: {'finished': 5, 'hasLogs': false},
        bookList: const [],
        nextCandidates: const [],
        languageCode: 'zh',
      );
      expect(p.contains('Never infer taste from the wishlist'), isTrue);
    });

    test('占位符只列事实表里真的有的键', () {
      // 列出了却没有值，模型照写就会渲染成破折号
      final p = buildInsightsPrompt(
        facts: {'finished': 5, 'hasLogs': false},
        bookList: const [],
        nextCandidates: const [],
        languageCode: 'zh',
      );
      expect(p.contains('[[finished]]'), isTrue);
      expect(p.contains('[[minutes]]'), isFalse);
      expect(p.contains('[[finishedRecent]]'), isFalse);
    });

    test('有近期窗口时明确要求区分新旧', () {
      final p = buildInsightsPrompt(
        facts: {
          'finished': 12,
          'hasLogs': false,
          'recentDays': 30,
          'finishedRecent': 0,
          'wishAddedRecent': 5,
          'halfYearDays': 180,
          'finishedHalfYear': 9,
          'wishAddedHalfYear': 40,
        },
        bookList: const [],
        nextCandidates: const [],
        languageCode: 'zh',
      );
      expect(p.contains('RECENCY'), isTrue);
      expect(p.contains('old backlog'), isTrue);
      // 近 30 天挂零而近半年有 9 本——这个落差是数据里最该说的一句话
      expect(p.contains('short window shows far less'), isTrue);
      expect(p.contains('[[finishedHalfYear]]'), isTrue);
    });
  });

  group('提示词：语言跟随 App 语言', () {
    String prompt(String code) => buildInsightsPrompt(
          facts: {'finished': 1, 'hasLogs': false},
          bookList: const [],
          nextCandidates: const [],
          languageCode: code,
        );

    test('中文界面出中文报告', () {
      final p = prompt('zh');
      expect(p.contains('简体中文'), isTrue);
      expect(p.contains('LANGUAGE'), isTrue);
    });

    test('德语界面出德语报告，不是退回英文', () {
      // 旧实现只有中英两档：选 Deutsch 的时候正文照样是英文
      final p = prompt('de');
      expect(p.contains('Deutsch'), isTrue);
      expect(p.contains('"de"'), isTrue);
      expect(p.contains('English only'), isFalse);
    });

    test('法语与西语同样按语言码走', () {
      expect(prompt('fr').contains('Français'), isTrue);
      expect(prompt('es').contains('Español'), isTrue);
    });

    test('未知语言码也不至于写出空指令', () {
      final p = prompt('xx');
      expect(p.contains('XX'), isTrue);
      expect(p.contains('LANGUAGE'), isTrue);
    });
  });
}
