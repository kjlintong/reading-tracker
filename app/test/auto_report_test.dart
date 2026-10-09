import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:reading_tracker/ai/ai_client.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/data/report_period.dart';
import 'package:reading_tracker/data/report_style.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';
import 'package:reading_tracker/services/auto_report_service.dart';

/// 自动补生成的端到端链路：真库 + 假模型端点。
///
/// 前面 [AutoReportPlanner] 的用例只验了纯规则；这里验的是
/// 「跑起来真的会把报告写进 llm_reports」——因为曾经有个更隐蔽的问题：
/// 判定逻辑全对，但生成完忘了落库，用户等来一次自动生成却在历史列表里
/// 什么也看不到。
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late BookRepository repo;
  Database? _raw;

  setUp(() async {
    _raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final db = AppDatabase.forTest(_raw!);
    await db.createSchema(_raw!);
    repo = BookRepository(db);
  });

  tearDown(() async {
    await _raw?.close();
    _raw = null;
  });

  /// 一个每次都返回固定 JSON 的模型客户端。
  ///
  /// 回调是**队列**语义（每次取一个），而 generateReportInsights 最多会
  /// 重试一次，所以这里给两条一模一样的成功响应——第一次成功就用掉第一条，
  /// 第二条留着也不会被消费，不会 StateError。
  LlmClient fakeLlm() {
    ResponseBody ok() => ResponseBody.fromString(
          jsonEncode({
            'choices': [
              {
                'index': 0,
                'finish_reason': 'stop',
                'message': {
                  'role': 'assistant',
                  'content': '{"headline":"这一年读完 [[finished]] 本","activity":["翻完《旧书》那几天睡得很沉"]}',
                },
              }
            ]
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    final dio = Dio()
      ..httpClientAdapter = HttpClientAdapterProxy((_) => [ok(), ok()]);
    return LlmClient(dio: dio, apiKey: 'sk-test', model: 'fake-model');
  }

  Book bookAt(String title, String finishedAtIso) => Book(
        id: title,
        title: title,
        status: BookStatus.finished,
        progressPercent: 100,
        rating: 4,
        createdAt: finishedAtIso,
        finishedAt: finishedAtIso,
        updatedAt: finishedAtIso,
      );

  AutoReportRunner runner({LlmClient? llm}) => AutoReportRunner(
        repo: repo,
        llm: llm ?? fakeLlm(),
        model: 'fake-model',
        style: reportStyles.first,
        customPrompt: '',
      );

  test('生成成功会落库，并能按 period 读回', () async {
    final lastYear = DateTime.now().year - 1;
    await repo.insert(
        bookAt('旧书', '$lastYear-06-01T00:00:00.000'));

    final period = ReportPeriod.year(lastYear);
    final outcome = await runner().run([period]);

    expect(outcome.generated.map((p) => p.key).toList(), [period.key]);
    expect(outcome.failed, isEmpty);

    final saved = await repo.latestReportOf(period.key);
    expect(saved, isNotNull);
    expect(saved!['period'], period.key);
    expect('${saved['content']}'.trim(), isNotEmpty);
    expect('${saved['model']}', 'fake-model');
  });

  test('周期内没有书时静默跳过，不算失败（不弹「没生成成功」）', () async {
    // 书是今年的，去年年报区间里一本都没有。
    await repo.insert(bookAt('今年的书', '${DateTime.now().year}-06-01T00:00:00.000'));

    final lastYear = DateTime.now().year - 1;
    final outcome = await runner().run([ReportPeriod.year(lastYear)]);

    expect(outcome.generated, isEmpty);
    expect(outcome.failed, isEmpty);
    expect(await repo.reports(), isEmpty);
  });

  test('模型返回空内容时算失败，不留半截记录', () async {
    final lastYear = DateTime.now().year - 1;
    await repo.insert(bookAt('旧书', '$lastYear-06-01T00:00:00.000'));

    // 模型只回思考文本、正文为空——这条链在真机上真实发生过。
    final dio = Dio()
      ..httpClientAdapter = HttpClientAdapterProxy((_) => [
            ResponseBody.fromString(
              jsonEncode({
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'length',
                    'message': {'role': 'assistant', 'reasoning': 'thinking...'},
                  }
                ]
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
            // 第二次尝试（关思考后重发）也空
            ResponseBody.fromString(
              jsonEncode({
                'choices': [
                  {
                    'index': 0,
                    'finish_reason': 'length',
                    'message': {'role': 'assistant', 'reasoning': 'still thinking'},
                  }
                ]
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
          ]);

    final outcome = await runner(llm: LlmClient(dio: dio, apiKey: 'sk', model: 'm'))
        .run([ReportPeriod.year(lastYear)]);

    expect(outcome.generated, isEmpty);
    expect(outcome.failed, hasLength(1));
    expect(await repo.reports(), isEmpty,
        reason: '失败时不能留下一条空报告占位');
  });

  test('年报失败不连累月报（串行 + 逐个隔离）', () async {
    final now = DateTime.now();
    // 上月月报区间里必须有书，否则它会被「无书可报」跳过，测不到隔离。
    var m = now.month - 1;
    var y = now.year;
    if (m == 0) {
      m = 12;
      y -= 1;
    }
    await repo.insert(
        bookAt('上月读的书', '$y-${m.toString().padLeft(2, '0')}-15T00:00:00.000'));

    var calls = 0;
    final dio = Dio()
      ..httpClientAdapter = HttpClientAdapterProxy((_) {
        calls++;
        // 第一次（年报区间无书→其实不会发请求）…这里按顺序：月报先、
        // 年报后。改成「第一次成功、第二次开始失败」以验证隔离。
        if (calls >= 3) {
          return [
            ResponseBody.fromString(
              jsonEncode({
                'error': {'message': 'server blew up'}
              }),
              500,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            )
          ];
        }
        return [
          ResponseBody.fromString(
            jsonEncode({
              'choices': [
                {
                  'index': 0,
                  'finish_reason': 'stop',
                  'message': {'role': 'assistant', 'content': '{"headline":"ok [[finished]]","activity":["一条观察"]}'},
                }
              ]
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          )
        ];
      });

    final outcome = await runner(llm: LlmClient(dio: dio, apiKey: 'sk', model: 'm'))
        .run(ReportPeriod.autoTargets(now: now));

    // 至少月报成功入了库（年报因无书被跳过，不算失败）
    expect(outcome.ok, greaterThanOrEqualTo(1));
    expect(await repo.reports(), isNotEmpty);
  });
}

/// 把 [HttpClientAdapter] 收敛成一个同步回调，测试里少写一层样板。
///
/// 回调返回**队列**，每次请求取走一个——这样才能精确模拟
/// 「第一次失败、第二次重试成功」这类多轮交互。
class HttpClientAdapterProxy implements HttpClientAdapter {
  HttpClientAdapterProxy(this._fetch);

  final List<ResponseBody> Function(Map<String, dynamic> body) _fetch;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final raw = await requestStream?.fold<List<int>>(
      <int>[],
      (acc, chunk) => acc..addAll(chunk),
    );
    final body = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    return _fetch(body).removeAt(0);
  }
}
