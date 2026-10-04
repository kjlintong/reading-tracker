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

  group('阅读计划注入报告', () {
    /// 抓出发给模型的 user 报文正文。
    /// 报告是「一段时间读得怎么样」的复盘，阅读计划是这段时间里
    /// 用户自己下的注，模型不看到它就只能泛泛而谈。
    Future<String> promptFor(Map<String, dynamic> facts) async {
      final adapter = _FakeAdapter((_) => _json({
            'choices': [
              {
                'message': {'content': '{"headline":"ok"}'}
              }
            ]
          }));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: 'm');
      await client.generateReportInsights(
        facts: facts,
        bookList: const [],
        nextCandidates: const [],
      );
      final messages = (adapter.captured.single.data as Map)['messages'] as List;
      return (messages.last as Map)['content'] as String;
    }

    test('没有计划时完全不提这一节，避免模型硬凑', () async {
      final p = await promptFor({'finished': 1, 'hasLogs': false});
      expect(p.contains('"plans" holds goals'), isFalse);
    });

    test('计划为空数组同样不注入：空数组不等于「有计划」', () async {
      final p = await promptFor({'finished': 1, 'hasLogs': false, 'plans': []});
      expect(p.contains('"plans" holds goals'), isFalse);
    });

    test('有计划时注入分析要求，且要求用具体数字而非下判断', () async {
      final p = await promptFor({
        'finished': 1,
        'hasLogs': false,
        'plans': [
          {
            'kind': 'dailyMinutes',
            'target': 30,
            'current': 12.5,
            'achieved': false,
            'ratio': 0.42,
            'targetMinutesPerDay': 30,
          }
        ],
      });
      expect(p.contains('"plans" holds goals'), isTrue);
      // 底线：没完成不等于失败，模型不许把未达成写成道德问题
      expect(p.contains('missing a goal is not a failure'), isTrue);
      // 要分析规律而不是下判断
      expect(p.contains('describe the'), isTrue);
    });

    test('没有阅读记录时不下发时长维度：不让模型对着 0 编节奏', () async {
      final p = await promptFor({'finished': 1, 'hasLogs': false});
      expect(p.contains('NO reading-time logs'), isTrue);
    });

    test('有阅读记录时不再写「没有记录」那句', () async {
      final p = await promptFor(
          {'finished': 1, 'hasLogs': true, 'minutes': 300, 'streak': 5});
      expect(p.contains('NO reading-time logs'), isFalse);
    });

    test('内容边界始终在场，计划段不能成为绕过边界的通道', () async {
      final p = await promptFor({'finished': 1, 'hasLogs': false});
      expect(p.contains('Never comment on how books were acquired'), isTrue);
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

  /// 「返回结构无法解析」是上一版最让人无从下手的报错：既不说清出了什么事，
  /// 也不带任何原始响应片段。下面每一种形态都在真实网关上出现过。
  group('响应体形态容错', () {
    test('标准 OpenAI 结构', () {
      expect(
        LlmClient.extractReplyText({
          'choices': [
            {
              'message': {'content': 'A'}
            }
          ]
        }),
        'A',
      );
    });

    test('content 为空串时取 reasoning_content', () {
      // 推理模型常常 content:"" 而把正文放进 reasoning_content。
      // 写成 `content is String` 就直接返回空串，报告出来是空白页
      expect(
        LlmClient.extractReplyText({
          'choices': [
            {
              'message': {'content': '', 'reasoning_content': 'R'}
            }
          ]
        }),
        'R',
      );
    });

    test('content 是分块数组', () {
      expect(
        LlmClient.extractReplyText({
          'choices': [
            {
              'message': {
                'content': [
                  {'type': 'text', 'text': 'A'}
                ]
              }
            }
          ]
        }),
        'A',
      );
    });

    test('Anthropic 顶层 content 分块，跳过 thinking', () {
      expect(
        LlmClient.extractReplyText({
          'content': [
            {'type': 'thinking', 'thinking': '内部推理'},
            {'type': 'text', 'text': 'B'},
          ]
        }),
        'B',
      );
    });

    test('补全风格 choices[0].text', () {
      expect(
        LlmClient.extractReplyText({
          'choices': [
            {'text': 'C'}
          ]
        }),
        'C',
      );
    });

    test('Ollama 原生顶层 message', () {
      expect(
        LlmClient.extractReplyText({
          'message': {'role': 'assistant', 'content': 'D'}
        }),
        'D',
      );
    });

    test('外层再包一层 data / result', () {
      expect(
        LlmClient.extractReplyText({
          'data': {
            'choices': [
              {
                'message': {'content': 'E'}
              }
            ]
          }
        }),
        'E',
      );
    });

    test('响应体是纯字符串（网关 Content-Type 给成 text/plain）', () {
      // Dio 不会自动解码非 JSON 的 Content-Type，res.data 就是个 String。
      // 上一版直接判 `d is! Map` 就报「无法解析」，而响应体本身是完好的 JSON
      expect(
        LlmClient.extractReplyText('{"choices":[{"message":{"content":"F"}}]}'),
        'F',
      );
      // 完全不是 JSON 也不是结构问题，那就是正文本身
      expect(LlmClient.extractReplyText('直接就是正文'), '直接就是正文');
    });

    test('SSE 残留也能取到第一个 data 载荷', () {
      expect(
        LlmClient.extractReplyText(
            'data: {"choices":[{"message":{"content":"G"}}]}\n\ndata: [DONE]\n'),
        'G',
      );
    });

    test('Responses 风格 output_text 与 output[]', () {
      expect(LlmClient.extractReplyText({'output_text': 'H'}), 'H');
      expect(
        LlmClient.extractReplyText({
          'output': [
            {
              'type': 'message',
              'content': [
                {'type': 'output_text', 'text': 'I'}
              ]
            }
          ]
        }),
        'I',
      );
    });

    test('认不出的结构返回 null，而不是抛异常', () {
      expect(LlmClient.extractReplyText({'unexpected': 1}), isNull);
      expect(LlmClient.extractReplyText(null), isNull);
      expect(LlmClient.extractReplyText({'choices': []}), isNull);
    });

    test('HTTP 200 里裹着的错误也能被认出来', () {
      expect(
        LlmClient.extractApiError({
          'error': {'message': 'insufficient balance'}
        }),
        'insufficient balance',
      );
      expect(LlmClient.extractApiError({'code': 40001, 'success': false}),
          'code=40001');
      expect(LlmClient.extractApiError({'msg': '模型不存在'}), '模型不存在');
      // 正常响应不能被误判成错误
      expect(
        LlmClient.extractApiError({
          'choices': [
            {
              'message': {'content': 'ok'}
            }
          ]
        }),
        isNull,
      );
    });
  });

  group('响应异常的可诊断性', () {
    test('HTTP 200 裹 error 时报出真正原因，而不是「无法解析」', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
            (_) => _json({'error': {'message': '账户余额不足，请充值'}}));
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: 'm');
      try {
        await client.chat([
          {'role': 'user', 'content': 'hi'}
        ]);
        fail('应当抛错');
      } on LlmException catch (e) {
        expect(e.message, contains('账户余额不足'));
        expect(e.toString(), contains('账户余额不足'));
      }
    });

    test('真的认不出结构时，错误里必须带上原始响应片段', () async {
      final dio = Dio()
        ..httpClientAdapter =
            _FakeAdapter((_) => _json({'weird': '形状完全不一样'}));
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: 'm');
      try {
        await client.chat([
          {'role': 'user', 'content': 'hi'}
        ]);
        fail('应当抛错');
      } on LlmException catch (e) {
        // 没有片段的话，用户和开发都无从判断到底收到了什么
        expect(e.toString(), contains('形状完全不一样'));
        expect(e.raw, isNotNull);
      }
    });

    test('模型不认 response_format 时自动降级重试一次', () async {
      var calls = 0;
      final adapter = _FakeAdapter((_) {
        calls++;
        if (calls == 1) {
          return _json({
            'error': {'message': 'Unsupported parameter: response_format'}
          }, 400);
        }
        return _json({
          'choices': [
            {
              'message': {'content': 'ok'}
            }
          ]
        });
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: 'm');

      expect(
        await client.chat([
          {'role': 'user', 'content': 'hi'}
        ], jsonMode: true),
        'ok',
      );
      expect(calls, 2);
      expect((adapter.captured[0].data as Map).containsKey('response_format'),
          isTrue);
      expect((adapter.captured[1].data as Map).containsKey('response_format'),
          isFalse);
    });

    test('与 response_format 无关的 400 不重试', () async {
      var calls = 0;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((_) {
          calls++;
          return _json({
            'error': {'message': 'model not found'}
          }, 400);
        });
      final client = LlmClient(
          dio: dio, apiKey: 'k', baseUrl: 'https://api.example.com/v1', model: 'm');
      try {
        await client.chat([
          {'role': 'user', 'content': 'hi'}
        ], jsonMode: true);
        fail('应当抛错');
      } on LlmException catch (e) {
        // 模型名写错也是 400，重试只会把一个错误变两个
        expect(calls, 1);
        expect(e.statusCode, 400);
      }
    });
  });
}
