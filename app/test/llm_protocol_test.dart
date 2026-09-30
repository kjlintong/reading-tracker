import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ai/ai_client.dart';
import 'package:reading_tracker/ai/llm_protocol.dart';

/// 把请求拦下来，既不联网也能断言「实际发出去的报文长什么样」。
///
/// 双协议的分歧全在报文里：端点路径、鉴权头、system 的位置、
/// max_tokens 是否存在。这些差异漏掉任何一个都是 400，
/// 而真机上调一次要重装包，用假适配器几毫秒就能锁死。
class _FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) respond;
  final List<RequestOptions> captured = [];

  _FakeAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  group('协议与地址规范化', () {
    test('协议名解析容错', () {
      expect(LlmProtocol.fromString('anthropic'), LlmProtocol.anthropic);
      expect(LlmProtocol.fromString('Claude'), LlmProtocol.anthropic);
      expect(LlmProtocol.fromString('openai'), LlmProtocol.openai);
      expect(LlmProtocol.fromString(null), LlmProtocol.openai);
    });

    test('两家用不同的对话端点', () {
      expect(LlmProtocol.openai.chatPath, 'chat/completions');
      expect(LlmProtocol.anthropic.chatPath, 'messages');
    });

    test('用户把完整端点粘进来也能还原成 Base URL', () {
      expect(
        normalizeBaseUrl('https://api.deepseek.com/v1/chat/completions', LlmProtocol.openai),
        'https://api.deepseek.com/v1',
      );
      expect(
        normalizeBaseUrl('https://api.anthropic.com/v1/messages/', LlmProtocol.anthropic),
        'https://api.anthropic.com/v1',
      );
      expect(
        normalizeBaseUrl('https://token.sensenova.cn/v1//', LlmProtocol.openai),
        'https://token.sensenova.cn/v1',
      );
      expect(normalizeBaseUrl('', LlmProtocol.openai), '');
    });
  });

  group('OpenAI 兼容协议', () {
    test('Bearer 鉴权、端点正确、json 模式带 response_format', () async {
      final adapter = _FakeAdapter((_) => _json({
            'choices': [
              {
                'message': {'content': '{"ok":true}'}
              }
            ]
          }));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = LlmClient(
        dio: dio,
        apiKey: 'sk-test',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
      );

      final out = await client.chat([
        {'role': 'system', 'content': '你是助手'},
        {'role': 'user', 'content': '你好'},
      ], jsonMode: true);

      expect(out, '{"ok":true}');
      final req = adapter.captured.single;
      expect(req.uri.toString(),
          'https://api.deepseek.com/v1/chat/completions');
      expect(req.headers['Authorization'], 'Bearer sk-test');
      expect((req.data as Map)['response_format'], {'type': 'json_object'});
      expect((req.data as Map)['model'], 'deepseek-chat');
      // system 在 OpenAI 里就是一条普通消息
      expect(((req.data as Map)['messages'] as List).first['role'], 'system');
    });

    test('推理模型只回 reasoning_content 时也能取到内容', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) => _json({
              'choices': [
                {
                  'message': {'content': '', 'reasoning_content': '思考结果'}
                }
              ]
            }));
      final client = LlmClient(dio: dio, apiKey: 'k', model: 'm');
      expect(await client.chat([
        {'role': 'user', 'content': 'hi'}
      ]), '思考结果');
    });
  });

  group('Anthropic 协议', () {
    test('端点、鉴权头、system 顶层、max_tokens 必填、content 分块解析', () async {
      final adapter = _FakeAdapter((_) => _json({
            'content': [
              {'type': 'thinking', 'thinking': '内部推理'},
              {'type': 'text', 'text': '正文回答'},
            ],
            'stop_reason': 'end_turn',
          }));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = LlmClient(
        dio: dio,
        apiKey: 'sk-ant-x',
        baseUrl: 'https://api.anthropic.com',
        model: 'claude-sonnet-5',
        protocol: LlmProtocol.anthropic,
      );

      final out = await client.chat([
        {'role': 'system', 'content': '你是阅读顾问'},
        {'role': 'user', 'content': '分析一下'},
      ]);

      expect(out, '正文回答'); // 首个块不是 text 也要能取到最后那个 text
      final req = adapter.captured.single;
      expect(req.uri.toString(), 'https://api.anthropic.com/messages');
      expect(req.headers['x-api-key'], 'sk-ant-x');
      expect(req.headers['anthropic-version'], '2023-06-01');
      expect(req.headers.containsKey('Authorization'), isFalse);

      final body = req.data as Map;
      expect(body['system'], '你是阅读顾问');
      expect(body['max_tokens'], isNotNull);
      // messages 里不能再出现 system，Claude 会直接 400
      for (final m in body['messages'] as List) {
        expect(m['role'], isNot('system'));
      }
    });

    test('json 模式通过 system 指令实现（Claude 没有 response_format）', () async {
      final adapter = _FakeAdapter((_) => _json({
            'content': [
              {'type': 'text', 'text': '[]'}
            ]
          }));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = LlmClient(
        dio: dio,
        apiKey: 'k',
        baseUrl: 'https://api.anthropic.com',
        model: 'claude-sonnet-5',
        protocol: LlmProtocol.anthropic,
      );
      await client.chat([
        {'role': 'user', 'content': 'hi'}
      ], jsonMode: true);

      final body = adapter.captured.single.data as Map;
      expect(body.containsKey('response_format'), isFalse);
      expect(body['system'], contains('JSON'));
    });
  });

  group('错误翻译', () {
    Future<LlmException> failureFor(int status, Object body) async {
      final dio = Dio()
        ..httpClientAdapter =
            _FakeAdapter((_) => _json(body, status));
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: 'm');
      try {
        await client.chat([
          {'role': 'user', 'content': 'hi'}
        ]);
        fail('应当抛错');
      } on LlmException catch (e) {
        return e;
      }
    }

    test('401 说清是 Key 的问题，并带上服务端原话', () async {
      final e = await failureFor(401, {
        'error': {'message': 'Invalid API key provided'}
      });
      expect(e.statusCode, 401);
      expect(e.toString(), contains('401'));
      expect(e.toString(), contains('Invalid API key'));
      expect(e.hint, contains('Key'));
    });

    test('404 指向 Base URL 与模型名', () async {
      final e = await failureFor(404, {'message': 'model not found'});
      expect(e.statusCode, 404);
      expect(e.hint, contains('模型'));
    });

    test('429 与 5xx 给出可操作的处置', () async {
      expect((await failureFor(429, {'msg': 'rate limited'})).hint, contains('稍'));
      final e500 = await failureFor(503, {'detail': 'upstream down'});
      expect(e500.message, contains('503'));
      expect(e500.hint, contains('稍后'));
    });

    test('连不上时不暴露 DioException 原始字符串', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) => throw DioException(
              requestOptions: RequestOptions(path: '/'),
              type: DioExceptionType.connectionError,
              error: 'SocketException: Software caused connection abort',
            ));
      final client = LlmClient(
          dio: dio,
          apiKey: 'k',
          baseUrl: 'https://token.sensenova.cn/v1',
          model: 'm');
      try {
        await client.chat([
          {'role': 'user', 'content': 'hi'}
        ]);
        fail('应当抛错');
      } on LlmException catch (e) {
        final text = e.toString();
        expect(text, contains('连不上'));
        expect(text, contains('token.sensenova.cn'));
        expect(text.contains('DioException'), isFalse);
        expect(text.contains('HttpException'), isFalse);
      }
    });

    test('未配置 Key 时直接给出去哪里配', () async {
      final client = LlmClient(dio: Dio(), model: 'm');
      expect(
        () => client.chat([
          {'role': 'user', 'content': 'hi'}
        ]),
        throwsA(isA<LlmException>()
            .having((e) => e.hint, 'hint', contains('设置'))),
      );
    });
  });

  group('模型列表', () {
    test('解析 data[].id 并排序', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) => _json({
              'data': [
                {'id': 'qwen-plus'},
                {'id': 'deepseek-chat', 'display_name': 'DeepSeek Chat'},
              ]
            }));
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: '');
      final models = await client.listModels();
      expect(models.map((m) => m.id).toList(), ['deepseek-chat', 'qwen-plus']);
    });

    test('网关不提供列表接口时提示手动填写，而不是报「失败」', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) => _json({'error': 'nope'}, 404));
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: '');
      try {
        await client.listModels();
        fail('应当抛错');
      } on LlmException catch (e) {
        expect(e.statusCode, 404);
        expect(e.hint, contains('手动填写'));
      }
    });
  });

  group('连通性测试', () {
    test('返回延迟与模型回复，且不改动实例上的模型名', () async {
      final adapter = _FakeAdapter((_) => _json({
            'choices': [
              {
                'message': {'content': '可用'}
              }
            ]
          }));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: '旧模型');

      final ping = await client.testConnection(overrideModel: '新模型');

      expect(ping.reply, '可用');
      expect(ping.model, '新模型');
      expect(ping.latencyMs, greaterThanOrEqualTo(0));
      expect(client.model, '旧模型');
      expect((adapter.captured.single.data as Map)['model'], '新模型');
    });
  });

  group('宽松 JSON 解析', () {
    test('剥掉 markdown 代码块', () {
      expect(
        parseJsonLoose('```json\n{"a":1}\n```')?['a'],
        1,
      );
    });

    test('前后混入说明文字也能抠出对象', () {
      expect(parseJsonLoose('好的，结果如下：{"a":2} 以上')?['a'], 2);
    });

    test('数组解析支持多种包裹形式', () {
      expect(parseJsonArrayLoose('[{"t":"A"},{"t":"B"}]').length, 2);
      expect(parseJsonArrayLoose('```json\n[{"t":"A"}]\n```').length, 1);
      expect(parseJsonArrayLoose('{"books":[{"t":"A"}]}').length, 1);
      // 无外层方括号的并列对象——实测模型真的会这么吐
      expect(parseJsonArrayLoose('{"t":"A"},{"t":"B"}').length, 2);
      expect(parseJsonArrayLoose('完全不是 JSON'), isEmpty);
    });
  });
}
