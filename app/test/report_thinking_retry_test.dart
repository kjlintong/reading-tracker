import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ai/ai_client.dart';

/// 报告生成的「空内容」回归：推理型模型（商汤 flash 系 2026-10 起默认开思考）
/// 会把 max_tokens 烧光在 reasoning 上，message 里没有 content——表现就是
/// 「模型返回了空内容」。第二次尝试必须带上 `thinking: disabled`；
/// 不认这个字段的严格网关 400 后要自动去掉重试。
///
/// flutter_test 会把真实 HTTP 一律拦成 400，所以走注入的 mock adapter，
/// 顺便把请求体也抓下来断言。
void main() {
  /// 记录请求体 + 按脚本应答的 adapter。脚本耗尽时直接抛状态。
  ({LlmClient client, List<Map<String, dynamic>> bodies}) scripted(
    List<ResponseBody> Function(Map<String, dynamic> body) script,
  ) {
    final bodies = <Map<String, dynamic>>[];
    final dio = Dio()
      ..httpClientAdapter = HttpClientAdapterProxy((body) {
        bodies.add(body);
        return script(body);
      });
    final client = LlmClient(dio: dio, apiKey: 'sk-test', model: 'flash-lite');
    return (client: client, bodies: bodies);
  }

  ResponseBody ok(String content) => ResponseBody.fromString(
        jsonEncode({
          'choices': [
            {
              'index': 0,
              'finish_reason': 'stop',
              'message': {'role': 'assistant', 'content': content},
            }
          ]
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  /// 推理挤爆 max_tokens 的响应：正文缺失，只剩 reasoning（思考文本）。
  /// 现有兜底会把 reasoning 当正文返回——这正好复现用户手机上的
  /// 真实失败链：思考文本被当回复 → 解析不出 JSON → 渲染为空。
  ResponseBody reasoningOnly() => ResponseBody.fromString(
        jsonEncode({
          'choices': [
            {
              'index': 0,
              'finish_reason': 'length',
              'message': {'role': 'assistant', 'reasoning': 'thinking, no braces here'},
            }
          ]
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  test('思考挤爆 token（只回 reasoning）时，重试带 thinking:disabled 且降温', () async {
    var call = 0;
    final (:client, :bodies) = scripted((body) {
      call++;
      return call == 1 ? [reasoningOnly()] : [ok('{"title":"ok"}')];
    });

    final out = await client.generateReportInsights(
      facts: {'total': 3},
      bookList: const [],
      nextCandidates: const [],
      languageCode: 'en',
    );

    expect(out, '{"title":"ok"}');
    expect(bodies, hasLength(2));
    // 两次尝试都显式关思考（不支持该字段的网关会在底层自动去掉重发）
    expect(bodies[0]['thinking'], {'type': 'disabled'});
    expect(bodies[0]['temperature'], 0.6);
    expect(bodies[1]['thinking'], {'type': 'disabled'});
    expect(bodies[1]['temperature'], 0.3);
  });

  test('严格网关对 thinking 字段 400 时，自动去掉重试', () async {
    var call = 0;
    final (:client, :bodies) = scripted((body) {
      call++;
      if (body.containsKey('thinking')) {
        return [
          ResponseBody.fromString(
            jsonEncode({
              'error': {'message': 'Unrecognized request argument: thinking'}
            }),
            400,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          )
        ];
      }
      // 第一次尝试被 400 后去掉字段重发，但模型只回思考文本 → 无效，
      // 触发第二次尝试；第二次同样经历「被拒 → 去掉重发」，这次给有效 JSON。
      return [call == 2 ? reasoningOnly() : ok('{"ok":1}')];
    });

    final out = await client.generateReportInsights(
      facts: {'total': 1},
      bookList: const [],
      nextCandidates: const [],
      languageCode: 'en',
    );

    expect(out, '{"ok":1}');
    // 请求序列：①带 thinking 被 400 拒 → ②去掉重发但只回思考文本 → 无效
    // → ③第二次尝试带 thinking 又被拒 → ④去掉重发成功
    expect(bodies, hasLength(4));
    expect(bodies[0]['thinking'], {'type': 'disabled'});
    expect(bodies[1].containsKey('thinking'), isFalse);
    expect(bodies[2]['thinking'], {'type': 'disabled'});
    expect(bodies[3].containsKey('thinking'), isFalse);
    expect(bodies[3]['temperature'], 0.3);
  });
}

/// 把 [HttpClientAdapter] 收敛成一个同步回调，测试里少写一层样板。
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
