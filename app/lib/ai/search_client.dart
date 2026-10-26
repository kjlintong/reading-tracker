import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 通用搜索服务客户端。
///
/// ## 为什么要「通用」而不是直接写死 Bing
///
/// 搜索 API 的可用性依赖用户的订阅与配额：Bing Web Search 要 Azure 订阅，
/// 换成别的服务（新拟态、Serper、Brave…）协议又各不相同。
/// 写死一家 = 用户没有 Key 时这一档直接废掉。
///
/// 所以这里做成一组可配置：用户填 **endpoint + Key**，
/// 请求体按 OpenAI 兼容的 `query` 字段发，响应按「一串结果、
/// 每条有 title 与 url/snippet」的通用形状解析。
/// Bing 的 Web Search v7 只要把 endpoint 指到
/// `https://api.bing.microsoft.com/v7.0/search` 就能直接用——
/// 它返回的 `webPages.value[]` 正好是 title+snippet+url。
///
/// ## 为什么不发 query 的其他参数
///
/// 各家搜索的参数名不统一（`count` / `top` / `num`），
/// 多发一个不认识的字段有的服务会 400。
/// 只发 `query` 是**所有主流服务都认的最小交集**，
/// 条数不够就在本地截断。
class SearchClient {
  final Dio _dio;
  final String? apiKey;

  /// 搜索服务的地址。留空则用 [defaultEndpoint]。
  final String endpoint;

  /// 额外的请求头。某些服务（如 Bing）要 `Ocp-Apim-Subscription-Key`
  /// 而不是 `Authorization`，用户可在这里补。
  final Map<String, String> extraHeaders;

  SearchClient({
    Dio? dio,
    this.apiKey,
    this.endpoint = defaultEndpoint,
    this.extraHeaders = const {},
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 25),
            ));

  /// Bing Web Search v7。
  static const String defaultEndpoint =
      'https://api.bing.microsoft.com/v7.0/search';

  /// 没配 Key 就不发请求——省一次注定失败的往返。
  bool get available => apiKey != null && apiKey!.isNotEmpty;

  /// 实际请求的地址。留空则用 [defaultEndpoint]。
  Uri get uri {
    final e = endpoint.trim();
    final base = e.isEmpty ? defaultEndpoint : e;
    return Uri.parse(base);
  }

  /// 搜一把，返回候选条目。
  ///
  /// [count] 是**本地**截断数，不发给服务端——各家参数名不统一，
  /// 发了反而可能 400。
  Future<List<SearchHit>> search(String query, {int count = 10}) async {
    if (!available) return const [];
    final q = query.trim();
    if (q.isEmpty) return const [];

    final res = await _dio.post<Map<String, dynamic>>(
      uri.toString(),
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Ocp-Apim-Subscription-Key': apiKey!,
        'X-Goog-Api-Key': apiKey!,
        ...extraHeaders,
      }),
      data: {'query': q},
    );

    final body = res.data;
    if (body == null) return const [];
    return _parse(body, count);
  }

  /// 从响应里抠出候选列表。
  ///
  /// 兼容三种常见形状：
  ///   - Bing:   `webPages.value[]`
  ///   - Google: `items[]`
  ///   - 通用:   `results[]` / `data[]` / 顶层数组
  static List<SearchHit> _parse(Map<String, dynamic> body, int count) {
    final raw = _findList(body);
    final out = <SearchHit>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final title = (m['name'] ?? m['title'] ?? m['heading'])?.toString().trim()
          ?? '';
      if (title.isEmpty) continue;
      final url = (m['url'] ?? m['link'] ?? m['webUrl'] ?? m['displayUrl'])
              ?.toString()
              .trim() ??
          '';
      final snippet = (m['snippet'] ?? m['description'] ?? m['summary'] ?? m['text'])
              ?.toString()
              .trim() ??
          '';
      out.add(SearchHit(title: title, url: url, snippet: snippet));
      if (out.length >= count) break;
    }
    return out;
  }

  /// 解析响应的公开入口，供测试直接验证各种形状。
  @visibleForTesting
  static List<SearchHit> parseForTest(Map<String, dynamic> body,
      {int count = 10}) =>
      _parse(body, count);

  /// 在响应里递归找第一处「看起来像结果列表」的数组。
  static List<dynamic> _findList(dynamic v) {
    if (v is List) return v;
    if (v is Map) {
      // 优先命中已知键名
      for (final key in const [
        'webPages',
        'items',
        'results',
        'data',
        'organic_results',
        'hits',
      ]) {
        final got = v[key];
        if (got is List) return got;
        if (got is Map) {
          final inner = _findList(got);
          if (inner.isNotEmpty) return inner;
        }
      }
      // 兜底：任何形如 {value: [...]} 的包装
      for (final got in v.values) {
        if (got is List && got.isNotEmpty) return got;
        if (got is Map) {
          final inner = _findList(got);
          if (inner.isNotEmpty) return inner;
        }
      }
    }
    return const [];
  }
}

/// 一条搜索结果。
class SearchHit {
  final String title;
  final String url;
  final String snippet;

  const SearchHit({
    required this.title,
    required this.url,
    required this.snippet,
  });
}
