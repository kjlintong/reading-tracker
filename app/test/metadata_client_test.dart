import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ai/ai_client.dart';

/// 公开书目库的**熔断与降级**行为。
///
/// ## 为什么单独测这个
///
/// Google Books 在国内直连不可达（真机实测：connectTimeout 打满，
/// 页面上表现为推荐列表一直转圈）。修复方式有两个：
///
/// 一是**熔断**：连不上就跳过它一段时间，别每本书都白等一次；
/// 二是**超时**：查一本书等太久不值得，拿不到就降级。
///
/// 这两条都是「失败路径」，正常路径的测试根本走不到——
/// 必须专门构造失败来验证。
void main() {
  /// 按 host 分流的 Dio。
  ///
  /// [onGoogle] / [onOpenLibrary] 各自决定这个源怎么响应：
  /// 立即返回 / 挂起 / 抛异常。
  Dio splitDio({
    required void Function(RequestOptions, RequestInterceptorHandler) onGoogle,
    required void Function(RequestOptions, RequestInterceptorHandler)
        onOpenLibrary,
  }) {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.uri.host.contains('googleapis')) {
          onGoogle(options, handler);
        } else {
          onOpenLibrary(options, handler);
        }
      },
    ));
    return dio;
  }

  void ok(RequestOptions options, RequestInterceptorHandler handler,
          {Map<String, dynamic> data = const <String, dynamic>{}}) {
    handler.resolve(Response(requestOptions: options, data: data));
  }

  void boom(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      ),
    );
  }

  MetadataClient clientWith(Dio dio) =>
      MetadataClient(dio: dio, weread: WereadGateway(apiKey: null));

  group('Google Books 熔断', () {
    test('连不上时跳过 Google，改用 Open Library', () async {
      var openLibHits = 0;
      final dio = splitDio(
        onGoogle: boom,
        onOpenLibrary: (o, h) {
          openLibHits++;
          ok(o, h);
        },
      );

      final client = clientWith(dio);
      await client.lookup('三体');
      expect(openLibHits, 1, reason: 'Google 挂了要去问 Open Library');
    });

    test('熔断后不再请求 Google', () async {
      var googleHits = 0;
      var openLibHits = 0;
      final dio = splitDio(
        onGoogle: (o, h) {
          googleHits++;
          boom(o, h);
        },
        onOpenLibrary: (o, h) {
          openLibHits++;
          ok(o, h);
        },
      );

      final client = clientWith(dio);
      await client.lookup('三体');
      expect(googleHits, 1, reason: '第一次应该试一次 Google');

      await client.lookup('活着');
      expect(googleHits, 1, reason: '熔断期内不该再打 Google');
      expect(openLibHits, 2, reason: '每次都要问 Open Library');
    });

    test('「查无结果」不触发熔断', () async {
      var googleHits = 0;
      final dio = splitDio(
        onGoogle: (o, h) {
          googleHits++;
          ok(o, h, data: <String, dynamic>{
            'totalItems': 0,
            'items': <dynamic>[],
          });
        },
        onOpenLibrary: (o, h) => ok(o, h, data: <String, dynamic>{
              'docs': <dynamic>[],
            }),
      );

      final client = clientWith(dio);
      await client.lookup('查不到的书');
      await client.lookup('也查不到');
      // 连得通只是没收录——不能因此把源关掉
      expect(googleHits, 2);
    });
  });

  group('单源超时', () {
    test('源挂着不动时，超时后降级到下一个源', () async {
      var openLibHits = 0;
      final dio = splitDio(
        // 永远不响应
        onGoogle: (o, h) {},
        onOpenLibrary: (o, h) {
          openLibHits++;
          ok(o, h);
        },
      );

      final client = clientWith(dio);
      final sw = Stopwatch()..start();
      await client.lookup('三体');
      sw.stop();

      expect(openLibHits, 1, reason: 'Google 挂住时要降级到 Open Library');
      expect(
        sw.elapsed,
        lessThan(const Duration(seconds: 25)),
        reason: '不能干等到 Dio 的 connectTimeout（12 秒）再叠加',
      );
    });
  });
}
