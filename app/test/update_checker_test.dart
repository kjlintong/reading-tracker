import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/services/update_checker.dart';

/// 一个只回放预置 JSON 的 Dio adapter。
///
/// ## 为什么不用 `dio` 自带的 mock
///
/// 手写一个二十行的 adapter 反而更省事：额外依赖一个包只为
/// 「给定 URL 返回给定 JSON」这一种能力不划算。
///
/// 另一个理由更实际：`flutter_test` 会拦真实网络请求。测试里任何一次
/// 真实的 DNS 解析都会挂住整个用例（表现为超时而不是断言失败），
/// 所以**必须**注入，不能让 [UpdateChecker] 自己建实例。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }
}

/// 构造一个形如 `{"tag_name": ..., "assets": [...]}` 的响应体。
///
/// ⚠️ 手工拼 JSON 字符串是这个测试最容易踩的坑：body 里的换行
/// 是 JSON 字符串内的**控制字符**，直接塞进 `'...'` 拼出来的
/// 伪 JSON 会在 dio 解码时抛 `FormatException`，而报错还包在
/// DioException 里，看起来像网络问题、实际是测试数据造错了。
/// 统一走 [jsonEncode]，它会正确转义。
String _release({
  String tag = 'v1.1.0',
  String body = '',
  List<String> assetNames = const ['Readnest-v1.1.0-release.apk'],
}) =>
    jsonEncode({
      'tag_name': tag,
      'body': body,
      'published_at': '2026-10-09T09:00:00Z',
      'assets': [
        for (final n in assetNames)
          {'name': n, 'browser_download_url': 'https://example.test/$n'},
      ],
    });

ResponseBody _ok(String json) => ResponseBody.fromString(
      json,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  group('UpdateChecker', () {
    test('取到 tag 里的版本号、发布说明与 APK 直链', () async {
      final body = '## 新版\n\n- 加了检查更新\n- 修了筛选抽屉';
      final adapter = _FakeAdapter((_) async => _ok(_release(body: body)));
      final info =
          await UpdateChecker(dio: Dio()..httpClientAdapter = adapter)
              .checkForUpdate(currentVersion: '1.0.0');

      expect(info.latestVersion, '1.1.0',
          reason: 'tag 里的 v 前缀要去掉，否则与 AppInfo.version 的 1.0.0 比不相等');
      expect(info.currentVersion, '1.0.0');
      expect(info.isUpdateAvailable, isTrue);
      expect(info.downloadUrl.toString(),
          'https://example.test/Readnest-v1.1.0-release.apk');
      expect(info.publishedAt, isNotNull);
      expect(info.releaseNotes, contains('加了检查更新'));
      expect(adapter.requests.single.headers['User-Agent'], contains('Readnest'),
          reason: 'GitHub 匿名请求要带 UA，否则容易被直接拒');
    });

    test('更新说明里的标题标记与列表符号被规整成段落', () async {
      final body = '## 新版\n\n- 加了检查更新\n- 修了筛选抽屉';
      final adapter = _FakeAdapter((_) async => _ok(_release(body: body)));
      final info = await UpdateChecker(dio: Dio()..httpClientAdapter = adapter)
          .checkForUpdate();
      final lines = info.releaseNotes.split('\n');
      expect(lines, isNotEmpty);
      expect(lines.every((l) => l.startsWith('- ')), isTrue,
          reason: '正文里每条都该有统一前缀，弹窗按段落渲染时行为才一致');
      expect(info.releaseNotes, isNot(contains('#')),
          reason: 'Markdown 标题标记不该出现在纯文本里');
    });

    test('aab 不算安装包——只认 apk', () async {
      final adapter = _FakeAdapter(
          (_) async => _ok(_release(assetNames: const ['app.aab'])));
      final info = await UpdateChecker(dio: Dio()..httpClientAdapter = adapter)
          .checkForUpdate();
      expect(info.downloadUrl, isNull,
          reason: 'aab 只能通过 Play 分发，直接给用户下载没有意义');
    });

    test('版本号按数字比较，1.10.0 > 1.9.0', () async {
      final adapter =
          _FakeAdapter((_) async => _ok(_release(tag: 'v1.10.0')));
      final info = await UpdateChecker(dio: Dio()..httpClientAdapter = adapter)
          .checkForUpdate(currentVersion: '1.9.0');
      expect(info.isUpdateAvailable, isTrue,
          reason: '字符串比较会得出 1.10.0 < 1.9.0，这里必须按数字比');
    });

    test('当前版本比线上新（装了预发布包）不算有更新', () async {
      final adapter = _FakeAdapter((_) async => _ok(_release(tag: 'v1.0.0')));
      final info = await UpdateChecker(dio: Dio()..httpClientAdapter = adapter)
          .checkForUpdate(currentVersion: '1.1.0');
      expect(info.isUpdateAvailable, isFalse);
    });

    test('预发布后缀不比大小：1.1.0-rc1 按 1.1.0 算', () async {
      final adapter =
          _FakeAdapter((_) async => _ok(_release(tag: 'v1.1.0-rc1')));
      final info = await UpdateChecker(dio: Dio()..httpClientAdapter = adapter)
          .checkForUpdate(currentVersion: '1.1.0');
      expect(info.isUpdateAvailable, isFalse);
    });

    test('网络失败抛 network 错误，不静默当作「已是最新」', () async {
      final adapter = _FakeAdapter(
          (_) async => throw DioException(requestOptions: RequestOptions()));
      await expectLater(
        UpdateChecker(dio: Dio()..httpClientAdapter = adapter).checkForUpdate(),
        throwsA(isA<UpdateCheckException>()
            .having((e) => e.kind, 'kind', UpdateCheckError.network)),
      );
    });

    test('返回内容缺 tag_name 抛 malformed，而不是当成没更新', () async {
      final adapter = _FakeAdapter((_) async => _ok('{"foo": 1}'));
      await expectLater(
        UpdateChecker(dio: Dio()..httpClientAdapter = adapter).checkForUpdate(),
        throwsA(isA<UpdateCheckException>()
            .having((e) => e.kind, 'kind', UpdateCheckError.malformed)),
      );
    });
  });
}
