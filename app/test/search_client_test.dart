import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ai/search_client.dart';

/// 搜索服务客户端的响应解析。
///
/// ## 为什么解析要这么写
///
/// 各家搜索服务的响应形状不一样：Bing 是 `webPages.value[]`、
/// Google 是 `items[]`、还有一堆是 `results[]`。
/// 如果只认一种，用户换了服务就整档失效——而他根本不知道是解析没认出来。
///
/// 所以这里要求：**只要响应里有「一串像结果的东西」就能认出来**。
void main() {
  group('响应解析', () {
    test('Bing 的 webPages.value 形状', () {
      final hits = _parse({
        'webPages': {
          'value': [
            {
              'name': '三体',
              'snippet': '刘慈欣的科幻小说',
              'url': 'https://example.com/santi',
            },
          ],
        },
      });
      expect(hits.single.title, '三体');
      expect(hits.single.snippet, contains('科幻'));
      expect(hits.single.url, 'https://example.com/santi');
    });

    test('Google 的 items 形状', () {
      final hits = _parse({
        'items': [
          {'title': '活着', 'link': 'https://example.com/1'},
        ],
      });
      expect(hits.single.title, '活着');
      expect(hits.single.url, 'https://example.com/1');
    });

    test('常见的 results 形状', () {
      final hits = _parse({
        'results': [
          {'title': '围城', 'description': '钱钟书'},
        ],
      });
      expect(hits.single.title, '围城');
    });

    test('不认识的外层键也能兜底找出数组', () {
      final hits = _parse({
        '我的书单': [
          {'title': '三体'},
        ],
      });
      expect(hits.single.title, '三体');
    });

    test('数组元素里没有 title 的被跳过', () {
      final hits = _parse({
        'items': [
          {'url': 'https://example.com/no-title'},
          {'title': '三体'},
        ],
      });
      expect(hits, hasLength(1));
      expect(hits.single.title, '三体');
    });

    test('title 为空串的也算没有', () {
      final hits = _parse({
        'items': [
          {'title': '   '},
          {'title': '三体'},
        ],
      });
      expect(hits, hasLength(1));
    });

    test('count 在本地截断，不发给服务端', () async {
      final client = SearchClient(apiKey: 'k');
      final hits = _parse({
        'items': [
          {'title': 'a'},
          {'title': 'b'},
          {'title': 'c'},
        ],
      }, count: 2);
      expect(hits, hasLength(2));
      expect(client.available, isTrue);
    });

    test('响应里没有任何数组时返回空列表，不抛异常', () {
      expect(_parse({'error': 'bad request'}), isEmpty);
      expect(_parse({}), isEmpty);
    });

    test('数组元素不是 Map 时被跳过', () {
      final hits = _parse({
        'items': ['just a string', {'title': '三体'}],
      });
      expect(hits.single.title, '三体');
    });
  });

  group('可用性', () {
    test('没有 Key 就不可用', () {
      expect(SearchClient(apiKey: null).available, isFalse);
      expect(SearchClient(apiKey: '').available, isFalse);
      expect(SearchClient(apiKey: 'k').available, isTrue);
    });

    test('默认 endpoint 指向 Bing Web Search', () {
      expect(SearchClient.defaultEndpoint,
          'https://api.bing.microsoft.com/v7.0/search');
      expect(SearchClient(apiKey: 'k').uri.toString(),
          contains('bing.microsoft.com'));
    });

    test('自定义 endpoint 覆盖默认', () {
      final c = SearchClient(apiKey: 'k', endpoint: 'https://example.com/s');
      expect(c.uri.toString(), 'https://example.com/s');
    });

    test('endpoint 留空时回落到默认', () {
      final c = SearchClient(apiKey: 'k', endpoint: '  ');
      expect(c.uri.toString(), contains('bing.microsoft.com'));
    });
  });

  group('请求', () {
    test('没有 Key 时不发请求，直接返回空', () async {
      final client = SearchClient(apiKey: null);
      expect(await client.search('三体'), isEmpty);
    });

    test('空关键词不发请求', () async {
      final client = SearchClient(apiKey: 'k');
      expect(await client.search('   '), isEmpty);
    });

    test('请求体只带 query 这一个字段', () async {
      late Map<String, dynamic> sent;
      late Map<String, dynamic> headers;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          sent = Map<String, dynamic>.from(options.data as Map);
          headers = Map<String, dynamic>.from(options.headers);
          handler.resolve(Response(
            requestOptions: options,
            data: {'items': [{'title': '三体'}]},
          ));
        },
      ));
      final client = SearchClient(dio: dio, apiKey: 'my-key');
      final hits = await client.search('科幻');
      expect(hits.single.title, '三体');
      // 只发 query：各家的参数名不统一，多发一个就可能被拒
      expect(sent.keys, ['query']);
      expect(sent['query'], '科幻');
      // Key 走两个常见头，服务商认哪个都算
      expect(headers['Ocp-Apim-Subscription-Key'], 'my-key');
      expect(headers['X-Goog-Api-Key'], 'my-key');
    });

    test('额外请求头会带上', () async {
      late Map<String, dynamic> headers;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          headers = Map<String, dynamic>.from(options.headers);
          handler.resolve(Response(
            requestOptions: options,
            data: {'items': []},
          ));
        },
      ));
      final client = SearchClient(
        dio: dio,
        apiKey: 'k',
        extraHeaders: const {'X-Custom': 'v'},
      );
      await client.search('x');
      expect(headers['X-Custom'], 'v');
    });
  });
}

/// 直接调内部解析（它就是纯函数）。
List<SearchHit> _parse(Map<String, dynamic> body, {int count = 10}) {
  // _parse 是私有的；通过一个公开的入口间接验证不划算，
  // 所以这里复制它的调用方式：构造客户端并让它解析。
  final hits = SearchClient.parseForTest(body, count: count);
  return hits;
}
