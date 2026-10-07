import 'dart:convert';
import '../l10n/app_loc.dart';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../data/report_pipeline.dart';
import '../data/report_style.dart';
import '../models/enums.dart';
import 'llm_protocol.dart';

/// 微信读书官方 Agent 网关
///
/// 官方开放的 Skill 端点，可覆盖书架、阅读进度、笔记划线、阅读统计、书城搜索。
/// 相比社区流传的 cookie 抓取方案，稳定性与合规性都更好。
/// 获取 API Key：微信扫码打开 https://weread.qq.com/r/weread-skills 后复制（wrk- 开头）
class WereadGateway {
  static const _gateway = 'https://i.weread.qq.com/api/agent/gateway';
  // 官方 Skill 规范要求，v1.0.3 会被网关提示升级
  static const _skillVersion = '1.0.4';

  final Dio _dio;
  final String? apiKey;

  WereadGateway({Dio? dio, this.apiKey})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  bool get available => apiKey != null && apiKey!.isNotEmpty;

  Future<Map<String, dynamic>> call(String apiName,
      [Map<String, dynamic> payload = const {}]) async {
    if (!available) throw StateError(appLoc.s_178329ba);
    final res = await _dio.post(
      _gateway,
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
      data: jsonEncode({
        'api_name': apiName,
        'skill_version': _skillVersion,
        ...payload,
      }),
    );
    return res.data is Map ? Map<String, dynamic>.from(res.data) : {};
  }

  Future<List<Map<String, dynamic>>> shelf() async {
    final raw = await call('/shelf/sync');
    return _extractBooks(raw);
  }

  Future<List<Map<String, dynamic>>> search(String keyword, {int count = 5}) async {
    final raw = await call('/store/search', {'keyword': keyword, 'scope': 10, 'count': count});
    return _extractBooks(raw).map(toMeta).toList();
  }

  Future<Map<String, dynamic>> readingStats({String mode = 'overall'}) =>
      call('/readdata/detail', {'mode': mode});

  /// 阅读进度。注意：书架接口不含进度，必须单独按 bookId 查询
  Future<Map<String, dynamic>> progress(String bookId) =>
      call('/book/getprogress', {'bookId': bookId});

  /// 解析后的阅读进度
  Future<ReadingProgress> progressOf(String bookId) async =>
      ReadingProgress.fromResponse(bookId, await progress(bookId));

  Future<Map<String, dynamic>> bookInfo(String bookId) =>
      call('/book/info', {'bookId': bookId});

  /// 轻量连通性检查：只做一次书架请求，用来在设置页验证 Key 是否有效
  Future<int> ping() async {
    final raw = await call('/shelf/sync');
    return _extractBooks(raw).length;
  }

  /// 从网关响应中提取书籍数组
  ///
  /// 实测坑：/store/search 返回的是三层嵌套 results[].books[].bookInfo，
  /// 早期版本只探测顶层 books，导致元数据补全从未真正命中。
  static List<Map<String, dynamic>> _extractBooks(Map<String, dynamic> raw) {
    final data = raw['data'] ?? raw;
    if (data is! Map) return data is List ? _asMaps(data) : [];

    for (final key in ['books', 'bookList', 'list', 'items', 'searchBooks']) {
      final v = data[key];
      if (v is List) return _asMaps(v);
    }
    // 三层嵌套：data.results[].books[].bookInfo
    final results = data['results'];
    if (results is List) {
      final out = <Map<String, dynamic>>[];
      for (final r in results) {
        if (r is! Map) continue;
        final books = r['books'];
        if (books is! List) continue;
        for (final b in books) {
          if (b is! Map) continue;
          final info = b['bookInfo'];
          out.add(Map<String, dynamic>.from(info is Map ? info : b));
        }
      }
      if (out.isNotEmpty) return out;
    }
    final nested = data['data'];
    if (nested is Map && nested['books'] is List) return _asMaps(nested['books'] as List);
    return [];
  }

  static List<Map<String, dynamic>> _asMaps(List list) =>
      list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  /// 微信读书书籍原始结构 → 统一元数据（公开，供导入器复用）
  ///
  /// 书架接口实测只返回 10 个字段：
  ///   bookId / deepLink / title / author / updateTime / cover /
  ///   finishReading / readUpdateTime / secret / category
  /// **没有** readingProgress 与 markedStatus，所以进度只能另调
  /// `/book/getprogress` 拿（见 [progress]）。
  static Map<String, dynamic> toMeta(Map<String, dynamic> b) => {
        'title': b['title'],
        'subtitle': b['subTitle'] ?? b['subtitle'],
        'authors': b['author'] != null ? [b['author']] : (b['authors'] ?? []),
        'publisher': b['publisher'] ?? b['publishingHouse'],
        'publishedAt': b['publishTime'] ?? b['publishDate'],
        'coverUrl': b['cover'] ?? b['coverUrl'] ?? b['picUrl'],
        'description': b['intro'] ?? b['description'],
        // 原始分类，交由 Book.withNormalizedCategory() 归口到受控词表
        'categoryRaw': b['category'] ?? b['categoryName'],
        'isbn13': b['isbn'],
        'wordCount': b['wordCount'],
        'sourceBookId': b['bookId']?.toString(),
        'sourceUrl': b['deepLink'],
        'status': deriveStatus(b),
        'addedAt': _epochToIso(b['updateTime']),
        'lastReadAt': _epochToIso(b['readUpdateTime']),
        'source': 'weread',
      };

  /// 由书架字段推导阅读状态。
  ///
  /// 实测坑：`readUpdateTime` **恒大于 0**，哪怕从未读过的书也有值
  /// （可能是平台的默认值或导入前的历史时间），所以不能用 `> 0` 判断有没有读过。
  /// 可用判据是 `readUpdateTime >= updateTime`——即「加入书架之后又读过」，
  /// 实测 55 本里 18 本满足。
  static BookStatus deriveStatus(Map<String, dynamic> b) {
    if (_asInt(b['finishReading']) == 1) return BookStatus.finished;
    final added = _asInt(b['updateTime']);
    final read = _asInt(b['readUpdateTime']);
    if (read != null && added != null && read >= added) return BookStatus.reading;
    if (read != null && added == null) return BookStatus.reading;
    return BookStatus.wish;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// 秒级时间戳 → ISO8601。微信读书所有时间字段都是秒。
  static String? _epochToIso(dynamic v) {
    final sec = _asInt(v);
    if (sec == null || sec <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true)
        .toIso8601String();
  }
}

/// 单本书的阅读进度（来自 `/book/getprogress`）
///
/// 实测响应结构：
/// ```json
/// {"bookId":"3300062053","book":{"chapterUid":296,"chapterIdx":2,
///   "updateTime":1790664442,"readingTime":64,"progress":0,
///   "isStartReading":0,"recordReadingTime":0}}
/// ```
/// 注意 `readingTime` 与 `recordReadingTime` 是两个不同字段，实测
/// `readingTime=64` 而 `recordReadingTime=0`，累计时长应以
/// `recordReadingTime` 优先、为空时回退 `readingTime`。
class ReadingProgress {
  final String bookId;
  /// 0-100 的整数。值为 1 表示 1%，不是 100%
  final int progress;
  final int? chapterUid;
  final int? chapterIdx;
  /// 累计阅读时长（秒）
  final int readingTimeSec;
  /// 是否已开始阅读
  final bool isStartReading;
  final int? finishTime;
  final String? updateAt;

  const ReadingProgress({
    required this.bookId,
    this.progress = 0,
    this.chapterUid,
    this.chapterIdx,
    this.readingTimeSec = 0,
    this.isStartReading = false,
    this.finishTime,
    this.updateAt,
  });

  double get progressPercent => progress.clamp(0, 100).toDouble();

  static ReadingProgress fromResponse(String bookId, Map<String, dynamic> raw) {
    final b = (raw['book'] ?? (raw['data'] is Map ? raw['data']['book'] : null) ?? raw);
    final m = b is Map ? Map<String, dynamic>.from(b) : <String, dynamic>{};
    return ReadingProgress(
      bookId: bookId,
      progress: WereadGateway._asInt(m['progress']) ?? 0,
      chapterUid: WereadGateway._asInt(m['chapterUid']),
      chapterIdx: WereadGateway._asInt(m['chapterIdx']),
      readingTimeSec: _preferNonZero(m['recordReadingTime'], m['readingTime']),
      isStartReading: WereadGateway._asInt(m['isStartReading']) == 1,
      finishTime: WereadGateway._asInt(m['finishTime']),
      updateAt: WereadGateway._epochToIso(m['updateTime']),
    );
  }

  /// 取第一个大于 0 的值。
  ///
  /// 不能用 `??` 兜底：`recordReadingTime` 实测会**存在但为 0**，
  /// `0 ?? readingTime` 得到的是 0 而不是落后的那个值，
  /// 于是一本读了 64 秒的书会被记成 0 秒。
  static int _preferNonZero(dynamic primary, dynamic fallback) {
    final a = WereadGateway._asInt(primary);
    if (a != null && a > 0) return a;
    final b = WereadGateway._asInt(fallback);
    if (b != null && b > 0) return b;
    return 0;
  }
}

/// 书籍元数据补全结果
class MetadataResult {
  final String? title;
  final List<String> authors;
  final String? publisher;
  final String? publishedAt;
  final String? description;
  final String? categoryPrimary;
  final String? coverUrl;
  final String? isbn13;
  final int? pageCount;
  final List<String> tags;
  final String? source;

  MetadataResult({
    this.title,
    this.authors = const [],
    this.publisher,
    this.publishedAt,
    this.description,
    this.categoryPrimary,
    this.coverUrl,
    this.isbn13,
    this.pageCount,
    this.tags = const [],
    this.source,
  });

  factory MetadataResult.fromJson(Map<String, dynamic> j) => MetadataResult(
        title: j['title'] as String?,
        authors: (j['authors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        publisher: j['publisher'] as String?,
        publishedAt: j['publishedAt'] as String?,
        description: j['description'] as String?,
        categoryPrimary: j['categoryPrimary'] as String?,
        coverUrl: j['coverUrl'] as String?,
        isbn13: j['isbn13'] as String?,
        pageCount: j['pageCount'] as int?,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        source: j['source'] as String?,
      );
}

/// 元数据补全：微信读书 → Google Books → Open Library 链式调用
///
/// 说明：Google / Open Library 在部分网络环境不可直连，会自动降级跳过，
/// 不会中断导入流程。
class MetadataClient {
  final Dio _dio;
  final WereadGateway weread;

  MetadataClient({Dio? dio, required this.weread})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
            ));

  Future<MetadataResult?> lookup(String title, {String? author}) async {
    final query = [title, if (author != null) author].join(' ');

    if (weread.available) {
      try {
        final r = await weread.search(query);
        if (r.isNotEmpty) return MetadataResult.fromJson(r.first);
      } catch (_) {
        // 降级到下一个数据源
      }
    }
    try {
      final r = await _googleBooks(query);
      if (r != null) return r;
    } catch (_) {}
    try {
      final r = await _openLibrary(query);
      if (r != null) return r;
    } catch (_) {}
    return null;
  }

  /// 只用权威源（微信读书书城）核对书名。
  ///
  /// OCR 截断的标题（「雅思口语深…」）需要补齐，而补齐结果必须能被验证。
  /// 只信搜索结果里标题与候选「同前缀或互为包含」的那条，避免搜出
  /// 一本毫不相干的书把用户数据污染掉。
  Future<String?> resolveTitle(String partial, {String? author}) async {
    final q = partial.replaceAll(RegExp(r'[.…⋯\s]+$'), '').trim();
    if (q.length < 2) return null;

    if (weread.available) {
      try {
        final r = await weread.search([q, if (author != null) author].join(' '));
        for (final it in r) {
          final t = (it['title'] as String?)?.trim();
          if (t == null || t.isEmpty) continue;
          if (_titleMatches(q, t)) return t;
        }
      } catch (_) {}
    }
    try {
      final r = await _googleBooks(q);
      final t = r?.title?.trim();
      if (t != null && _titleMatches(q, t)) return t;
    } catch (_) {}
    try {
      final r = await _openLibrary(q);
      final t = r?.title?.trim();
      if (t != null && _titleMatches(q, t)) return t;
    } catch (_) {}
    return null;
  }

  /// 候选是否像同一本书：一方是另一方的前缀，或去掉标点后高度重合。
  static bool _titleMatches(String partial, String full) {
    String norm(String s) =>
        s.replaceAll(RegExp(appLoc.s_dd204792), '').toLowerCase();
    final a = norm(partial);
    final b = norm(full);
    if (a.isEmpty || b.isEmpty) return false;
    if (b == a) return true;
    if (b.startsWith(a)) return true;
    // OCR 常有单字识别错误（深/探），允许前缀内 1 字之差
    if (a.length >= 4 && b.length >= a.length) {
      final head = b.substring(0, a.length);
      var diff = 0;
      for (var i = 0; i < a.length; i++) {
        if (head[i] != a[i]) diff++;
      }
      if (diff <= 1) return true;
    }
    return false;
  }

  /// 公开书目检索：Google Books + Open Library，返回多条候选。
  ///
  /// 与 [lookup] 的分工很清楚：lookup 是「已知书名、补齐字段」，命中一条就够；
  /// 这里是「用户主动搜索」，必须给多条让用户自己挑——公开书库里同名书、
  /// 不同版次、不同译本遍地都是，替用户拍板等于替他做错误决策。
  ///
  /// 微信读书书城有意不参与：它是中文封闭体系，与国际书目混排只会把
  /// 结果撕成两半，反而更难挑。
  Future<List<MetadataResult>> search(String query, {int limit = 12}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final out = <MetadataResult>[];
    try {
      out.addAll(await _googleBooksList(q, limit));
    } catch (_) {
      // 单个数据源不可达不应让整次搜索失败，继续试下一个
    }
    if (out.length < limit) {
      try {
        out.addAll(await _openLibraryList(q, limit - out.length));
      } catch (_) {}
    }
    return out;
  }

  Future<MetadataResult?> _googleBooks(String query) async {
    final list = await _googleBooksList(query, 1);
    return list.isEmpty ? null : list.first;
  }

  Future<List<MetadataResult>> _googleBooksList(String query, int limit) async {
    final res = await _dio.get(
      'https://www.googleapis.com/books/v1/volumes',
      queryParameters: {
        'q': query,
        // Google Books 的 maxResults 上限是 40，且不给这个参数时默认只有 10
        'maxResults': limit.clamp(1, 40),
      },
    );
    final items = res.data?['items'] as List?;
    if (items == null || items.isEmpty) return const [];
    final out = <MetadataResult>[];
    for (final item in items) {
      final m = _googleVolume(item);
      if (m != null) out.add(m);
    }
    return out;
  }

  /// 单条 Google Books volumeInfo → MetadataResult。
  /// 结构异常（缺 volumeInfo、不是 Map）返回 null 而不是抛异常——
  /// 一个坏条目不该毁掉整批搜索结果。
  static MetadataResult? _googleVolume(dynamic item) {
    if (item is! Map) return null;
    final v = item['volumeInfo'] as Map?;
    if (v == null) return null;
    final date = v['publishedDate'] as String?;
    return MetadataResult(
      title: v['title'] as String?,
      authors: (v['authors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      publisher: v['publisher'] as String?,
      // Google Books 的日期有时是完整时间戳（2019-05-01T00:00:00+00:00），
      // 这里只取到「日」；短于 10 位的（如只有年份）原样保留。
      publishedAt: date == null
          ? null
          : (date.length > 10 ? date.substring(0, 10) : date),
      description: v['description'] as String?,
      categoryPrimary: (v['categories'] as List?)?.first?.toString(),
      coverUrl: (v['imageLinks'] as Map?)?['thumbnail'] as String?,
      pageCount: v['pageCount'] as int?,
      isbn13: ((v['industryIdentifiers'] as List?)?.firstWhere(
            (e) => (e as Map)['type'] == 'ISBN_13',
            orElse: () => {'identifier': null},
          ) as Map?)?['identifier'] as String?,
      source: 'googlebooks',
    );
  }

  Future<MetadataResult?> _openLibrary(String query) async {
    final list = await _openLibraryList(query, 1);
    return list.isEmpty ? null : list.first;
  }

  Future<List<MetadataResult>> _openLibraryList(String query, int limit) async {
    final res = await _dio.get(
      'https://openlibrary.org/search.json',
      queryParameters: {
        'q': query,
        'limit': limit.clamp(1, 40),
        'fields':
            'title,author_name,publisher,first_publish_year,subject,isbn,cover_i,number_of_pages_median',
      },
    );
    final docs = res.data?['docs'] as List?;
    if (docs == null || docs.isEmpty) return const [];
    final out = <MetadataResult>[];
    for (final doc in docs) {
      final m = _openLibraryDoc(doc);
      if (m != null) out.add(m);
    }
    return out;
  }

  static MetadataResult? _openLibraryDoc(dynamic doc) {
    if (doc is! Map) return null;
    final d = doc;
    return MetadataResult(
      title: d['title'] as String?,
      authors: (d['author_name'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      publisher: (d['publisher'] as List?)?.first?.toString(),
      publishedAt: d['first_publish_year']?.toString(),
      categoryPrimary: (d['subject'] as List?)?.first?.toString(),
      coverUrl: d['cover_i'] != null
          ? 'https://covers.openlibrary.org/b/id/${d['cover_i']}-M.jpg'
          : null,
      pageCount: d['number_of_pages_median'] as int?,
      // Open Library 的 isbn 是数组，取第一个；
      // 与 Google Books 的 isbn13 字段对齐，便于去重命中同一条指纹
      isbn13: (d['isbn'] as List?)?.first?.toString(),
      tags: (d['subject'] as List?)?.take(5).map((e) => e.toString()).toList() ?? const [],
      source: 'openlibrary',
    );
  }
}

/* ------------------------------------------------------------------ */
/*                           大模型客户端                              */
/* ------------------------------------------------------------------ */

/// 大模型调用失败。
///
/// 存在的意义只有一个：把 Dio 那一串
/// `DioException [unknown]: null Error: HttpException: Software caused
/// connection abort, uri = ...` 变成人能看懂、且能据此行动的一句话。
/// 那种原始报错既看不出是网络、是 Key、还是模型名错了，也看不出该做什么。
class LlmException implements Exception {
  final String message;
  final int? statusCode;
  final String? raw;
  final String? hint;

  LlmException(this.message, {this.statusCode, this.raw, this.hint});

  @override
  String toString() => hint == null ? message : '$message\n$hint';
}

/// 可选的模型
class LlmModel {
  final String id;
  final String? displayName;
  const LlmModel({required this.id, this.displayName});
}

/// 连通性测试结果
class LlmPing {
  final String model;
  final int latencyMs;
  final String reply;
  const LlmPing({
    required this.model,
    required this.latencyMs,
    required this.reply,
  });
}

/// 大模型客户端，支持 OpenAI 兼容协议与 Anthropic Claude 协议。
///
/// 用户自填 Key，App 不代持任何密钥，也不内置任何默认 Key。
class LlmClient {
  final Dio _dio;
  final String? apiKey;
  String baseUrl;
  String model;
  LlmProtocol protocol;

  /// 单次请求最多生成多少 token。
  /// Anthropic 协议下 `max_tokens` 是必填项，缺了直接 400，所以这里必须有默认值。
  int maxTokens;

  LlmClient({
    Dio? dio,
    this.apiKey,
    this.baseUrl = 'https://token.sensenova.cn/v1',
    this.model = 'sensenova-6.8-flash-lite',
    this.protocol = LlmProtocol.openai,
    this.maxTokens = 4096,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              // 报告是长文本生成，90 秒在慢模型上不够
              receiveTimeout: const Duration(seconds: 180),
            ));

  bool get available => apiKey != null && apiKey!.isNotEmpty;

  String get effectiveBaseUrl => normalizeBaseUrl(baseUrl, protocol);

  Uri get chatUri => Uri.parse('$effectiveBaseUrl/${protocol.chatPath}');
  Uri get modelsUri => Uri.parse('$effectiveBaseUrl/models');

  Map<String, String> get _headers => switch (protocol) {
        LlmProtocol.openai => {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        LlmProtocol.anthropic => {
            'x-api-key': '$apiKey',
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
      };

  /// 一次对话。两种协议在这里分叉。
  ///
  /// [modelOverride] 只给连通性测试用：测试要验证的是「这个模型能不能用」，
  /// 而此时候选模型未必已经写回设置。直接改实例字段会在并发调用时互相踩，
  /// 所以走参数传递。
  Future<String> chat(
    List<Map<String, String>> messages, {
    double temperature = 0.3,
    bool jsonMode = false,
    int? maxTokens,
    String? modelOverride,
  }) async {
    if (!available) {
      throw LlmException(appLoc.s_ad86a5ca, hint: appLoc.s_8a853cbe);
    }
    final useModel = (modelOverride ?? model).trim();
    if (useModel.isEmpty) {
      throw LlmException(appLoc.s_7d704c88, hint: appLoc.s_4508cedd);
    }

    try {
      if (protocol == LlmProtocol.anthropic) {
        return await _chatAnthropic(messages,
            useModel: useModel,
            temperature: temperature,
            jsonMode: jsonMode,
            maxTokens: maxTokens);
      }
      return await _chatOpenAi(messages,
          useModel: useModel,
          temperature: temperature,
          jsonMode: jsonMode,
          maxTokens: maxTokens);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  /// 多模态：把一张图连同提示词一起发给模型。
  ///
  /// 两条协议的图片格式完全不同，且都不能复用 `chat` 那条
  /// `Map<String, String>` 的消息结构——content 变成了块数组：
  ///   - OpenAI：`content: [{type:'text'},{type:'image_url',image_url:{url:'data:…;base64,…'}}]`
  ///   - Anthropic：`content: [{type:'image',source:{type:'base64',media_type,data}},{type:'text'}]`
  ///     **图片块要放在文本块前面**，Claude 对先图后文的排版更稳。
  ///
  /// [mimeType] 必须与字节的实际格式一致，写错会让网关直接拒收。
  /// 调用方统一转成 JPEG 再传，省得在这里猜。
  Future<String> chatWithImage(
    String prompt, {
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    double temperature = 0.1,
    int maxTokens = 3072,
    String? modelOverride,
  }) async {
    if (!available) {
      throw LlmException(appLoc.s_ad86a5ca, hint: appLoc.s_8a853cbe);
    }
    final useModel = (modelOverride ?? model).trim();
    if (useModel.isEmpty) {
      throw LlmException(appLoc.s_7d704c88, hint: appLoc.s_4508cedd);
    }
    final b64 = base64Encode(imageBytes);

    try {
      if (protocol == LlmProtocol.anthropic) {
        final res = await _dio.post(
          chatUri.toString(),
          options: Options(headers: _headers),
          data: {
            'model': useModel,
            'max_tokens': maxTokens,
            'system': appLoc.s_1b5140db,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'image',
                    'source': {
                      'type': 'base64',
                      'media_type': mimeType,
                      'data': b64,
                    },
                  },
                  {'type': 'text', 'text': prompt},
                ],
              },
            ],
          },
        );
        return _unpack(res.data);
      }

      final res = await _dio.post(
        chatUri.toString(),
        options: Options(headers: _headers),
        data: {
          'model': useModel,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:$mimeType;base64,$b64'},
                },
                {'type': 'text', 'text': prompt},
              ],
            },
          ],
        },
      );
      return _unpack(res.data);
    } on DioException catch (e) {
      throw _wrap(e);
    }
  }

  /// 这个模型看起来支不支持图片输入。
  ///
  /// 只能靠名字猜，没有可靠的查询接口。猜错不致命——网关会返回
  /// 400/422，调用方按失败处理并回落到端侧 OCR 即可。
  /// 但**不能在不支持的模型上白等一次超时**，所以先把明显是纯文本的
  /// 名字挡掉（含 embed / moderation / whisper 的）。
  bool get supportsVision {
    final m = model.toLowerCase();
    if (m.isEmpty) return false;
    const textOnly = ['embed', 'moderation', 'whisper', 'tts', 'dall-e'];
    for (final t in textOnly) {
      if (m.contains(t)) return false;
    }
    return true;
  }

  Future<String> _chatOpenAi(
    List<Map<String, String>> messages, {
    required String useModel,
    required double temperature,
    required bool jsonMode,
    int? maxTokens,
  }) async {
    if (!jsonMode) {
      return _postOpenAi(messages,
          useModel: useModel,
          temperature: temperature,
          jsonMode: false,
          maxTokens: maxTokens);
    }
    try {
      return await _postOpenAi(messages,
          useModel: useModel,
          temperature: temperature,
          jsonMode: true,
          maxTokens: maxTokens);
    } on DioException catch (e) {
      // 不少轻量模型根本不认 response_format，直接 400。
      // 这时降级重试一次——模型自己硬输出 JSON 也还有 parseJsonLoose 兜底，
      // 好过让「元数据兜底补全」整条链路因为一个可选参数彻底不可用。
      if (!_isJsonModeRejection(e)) rethrow;
      return _postOpenAi(messages,
          useModel: useModel,
          temperature: temperature,
          jsonMode: false,
          maxTokens: maxTokens);
    }
  }

  Future<String> _postOpenAi(
    List<Map<String, String>> messages, {
    required String useModel,
    required double temperature,
    required bool jsonMode,
    int? maxTokens,
  }) async {
    final res = await _dio.post(
      chatUri.toString(),
      options: Options(headers: _headers),
      data: {
        'model': useModel,
        'messages': messages,
        'temperature': temperature,
        if (jsonMode) 'response_format': {'type': 'json_object'},
        if (maxTokens != null) 'max_tokens': maxTokens,
      },
    );
    return _unpack(res.data);
  }

  /// 服务端明确表示不支持 `response_format` 时才认为可以降级重试。
  /// 不能对所有 400 都重试——模型名写错也是 400，重试只会把一个错误变两个。
  static bool _isJsonModeRejection(DioException e) {
    if (e.response?.statusCode != 400) return false;
    final msg = '${e.response?.data}'.toLowerCase();
    return msg.contains('response_format') ||
        msg.contains('json_object') ||
        msg.contains('json mode');
  }

  /// 响应体 → 正文。两种协议的收尾都走这里。
  ///
  /// 抠不到正文时**必须把原始响应带进报错里**：上一版只丢一句
  /// 「返回结构无法解析」，用户不知道发生了什么，开发者也拿不到任何线索。
  /// 真实遇到过的情况是网关用 HTTP 200 返回 `{"error":...}`（欠费、无权限、
  /// 模型不存在），那句报错把真正的原因整个吞掉了。
  static String _unpack(Object? data) {
    final body = _asJson(data);
    final text = extractReplyText(body);
    if (text != null) return text;

    final head = _preview(body);

    final apiError = extractApiError(body);
    if (apiError != null) {
      throw LlmException(
        appLoc.s_c94c96fc(apiError: apiError),
        raw: head,
        hint: appLoc.s_3b43c7c4(head: head),
      );
    }
    throw LlmException(
      appLoc.s_231cf54a,
      raw: head,
      hint: appLoc.s_90747d4c(head: head),
    );
  }

  /// Anthropic Messages API。
  ///
  /// 与 OpenAI 的四处硬差异，任何一处漏掉都是 400：
  ///   1. system 提示不是消息，是顶层字段；
  ///   2. max_tokens 必填；
  ///   3. 鉴权头是 x-api-key 而不是 Authorization；
  ///   4. 返回的 content 是**分块数组**，而且首个块不一定是 text
  ///      （开了 thinking 或工具调用时前面会有 thinking / tool_use 块）。
  Future<String> _chatAnthropic(
    List<Map<String, String>> messages, {
    required String useModel,
    required double temperature,
    required bool jsonMode,
    int? maxTokens,
  }) async {
    final systemParts = <String>[];
    final turns = <Map<String, String>>[];
    for (final m in messages) {
      final role = m['role'];
      final content = m['content'] ?? '';
      if (role == 'system') {
        systemParts.add(content);
      } else if (role == 'assistant') {
        turns.add({'role': 'assistant', 'content': content});
      } else {
        turns.add({'role': 'user', 'content': content});
      }
    }
    if (jsonMode) {
      systemParts.add(appLoc.s_1b5140db);
    }
    if (turns.isEmpty) {
      throw LlmException(appLoc.s_9d9714af);
    }

    final res = await _dio.post(
      chatUri.toString(),
      options: Options(headers: _headers),
      data: {
        'model': useModel,
        if (systemParts.isNotEmpty) 'system': systemParts.join('\n\n'),
        'messages': turns,
        'max_tokens': maxTokens ?? this.maxTokens,
        'temperature': temperature,
      },
    );

    final body = _asJson(res.data);
    if (body is Map && body['stop_reason'] == 'refusal') {
      throw LlmException(appLoc.s_f44ff25c,
          hint: appLoc.s_cad5bf6e);
    }
    return _unpack(body);
  }

  /// 拉取该 Key 实际可用的模型列表。
  ///
  /// 各家 `GET /models` 返回结构大同小异（`data[].id`），但也有返回
  /// `models[]` 甚至裸数组的网关，所以逐个兜底探测。
  Future<List<LlmModel>> listModels() async {
    if (!available) {
      throw LlmException(appLoc.s_0f7b54a1, hint: appLoc.s_345e9547);
    }
    try {
      final res = await _dio.get(
        modelsUri.toString(),
        options: Options(headers: _headers),
      );
      final raw = _asJson(res.data);
      final out = <LlmModel>[];

      void take(List list) {
        for (final e in list) {
          if (e is String) {
            out.add(LlmModel(id: e));
          } else if (e is Map) {
            final id = e['id'] ?? e['model'] ?? e['name'];
            if (id is String && id.isNotEmpty) {
              out.add(LlmModel(
                id: id,
                displayName: e['display_name'] as String? ?? e['description'] as String?,
              ));
            }
          }
        }
      }

      if (raw is List) take(raw);
      if (raw is Map) {
        for (final key in ['data', 'models', 'model_list', 'result']) {
          final v = raw[key];
          if (v is List) {
            take(v);
            if (out.isNotEmpty) break;
          }
        }
      }
      if (out.isEmpty) {
        final apiError = extractApiError(raw);
        throw LlmException(
            apiError == null ? appLoc.s_3a5d4cca : appLoc.s_cea80527(apiError: apiError),
            raw: _preview(raw, 300),
            hint: apiError == null
                ? appLoc.s_4674d953
                : appLoc.s_749fc40e(raw: _preview(raw, 300)));
      }
      out.sort((a, b) => a.id.toLowerCase().compareTo(b.id.toLowerCase()));
      return out;
    } on DioException catch (e) {
      final wrapped = _wrap(e);
      if (wrapped.statusCode == 404) {
        // statusCode 必须带上：设置页要靠它区分「没有列表接口」和「地址填错」，
        // 丢了它这条例外就跟普通网络故障长得一样了。
        throw LlmException(appLoc.s_8add575d,
            statusCode: 404,
            raw: wrapped.raw,
            hint: appLoc.s_53fb436d);
      }
      throw wrapped;
    }
  }

  /// 连通性测试：发一条极短的请求，返回模型回复与耗时。
  ///
  /// 特意走真实对话端点而不是 `/models` —— 后者能通不代表对话能用，
  /// 常见情形是 Key 有列表权限却没有对应模型的调用权限。
  Future<LlmPing> testConnection({String? overrideModel}) async {
    final useModel = (overrideModel ?? model).trim();
    if (useModel.isEmpty) {
      throw LlmException(appLoc.s_438a5695, hint: appLoc.s_1da90e20);
    }
    final started = DateTime.now();
    final text = await chat(
      [
        {'role': 'user', 'content': appLoc.s_2abb6b8a},
      ],
      temperature: 0,
      maxTokens: 64,
      modelOverride: useModel,
    );
    return LlmPing(
      model: useModel,
      latencyMs: DateTime.now().difference(started).inMilliseconds,
      reply: text.trim(),
    );
  }

  /// 元数据兜底：公开源查不到时，用 LLM 推断分类 / 简介 / 标签
  Future<Map<String, dynamic>?> inferMetadata(String title,
      {String? author, List<String>? categories}) async {
    // 候选词表给的是「当前语言的可读名」：这样模型照抄回来的分类与它写的
    // 简介 / 标签语言一致。落库前会经 Book.withNormalizedCategory()
    // 反查回规范值（categoryLabel 的逆映射），不会把显示名写进数据库。
    // 用生效词表：用户自己加的分类也要在候选里，否则模型永远猜不到它，
    // 只能把书塞进「其他」。
    final vocab =
        (categories ?? categoryVocabulary.active.map(categoryLabel).toList())
            .join(' / ');
    final raw = await chat(
      [
        {'role': 'system', 'content': appLoc.s_ad736a74},
        {
          'role': 'user',
          'content': appLoc.s_4304f539(title: title, author: author != null ? appLoc.s_854a34ca(author: author) : '', vocab: vocab)
        },
      ],
      jsonMode: true,
    );
    return parseJsonLoose(raw);
  }

  /// 让模型基于统计给一组「性格标签」。
  ///
  /// 提示词里有两条硬约束，都是踩过坑加的：
  ///   - 「每条都要能从数据里找到依据」：不写这句，模型会给出
  ///     「热爱生活」这类任何书单都成立的标签，看两遍就腻；
  ///   - 「不要出现『读者』『爱好者』」：这类词信息量为零。
  ///
  /// 返回值是**并列展示**的一版，不覆盖规则推导出来的那版——
  /// 用户自己挑更可信的那一组。
  Future<List<String>> suggestProfileTags(Map<String, dynamic> summary) async {
    final raw = await chat(
      [
        {'role': 'system', 'content': appLoc.s_cbe8aa6b},
        {
          'role': 'user',
          'content': appLoc.s_3864d3b4(summary: jsonEncode(summary))
        },
      ],
      jsonMode: true,
      temperature: 0.8,
    );

    final obj = parseJsonLoose(raw);
    final list = obj?['tags'] ?? obj?['labels'] ?? obj?['data'];
    final out = <String>[];
    if (list is List) {
      for (final e in list) {
        final t = e is Map ? '${e['tag'] ?? e['name'] ?? ''}' : '$e';
        final s = t.trim();
        if (s.isNotEmpty) out.add(s);
      }
    } else {
      // 模型直接给了裸数组
      for (final e in parseJsonArrayLoose(raw)) {
        final s = '${e['tag'] ?? e['name'] ?? ''}'.trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
    return out.take(12).toList();
  }

  /// 让模型把事实表解读成结构化洞察。
  ///
  /// 与旧实现「一次调用同时算数 + 解读 + 排版」的根本区别：事实表和书单
  /// 由 [report_pipeline.dart] 在本地算好，这里只让模型输出 JSON，排版
  /// 交给本地模板——于是报告结构恒定，数字不可能与库里的不一致。
  ///
  /// [bookList] / [nextCandidates] 是模型**唯一**允许点名与推荐的书：
  /// 校验层拿它们的 id 做白名单，模型凭空编出来的书会被整条丢掉。
  ///
  /// 返回模型原始输出（JSON 文本），解析校验由调用方走 [parseReportPayload]。
  /// 两次都拿不到可用内容时返回 null。
  Future<String?> generateReportInsights({
    required Map<String, dynamic> facts,
    required List<Map<String, dynamic>> bookList,
    required List<Map<String, dynamic>> nextCandidates,
    ReportStyle? style,
    String? customPrompt,
    String? languageCode,
  }) async {
    final s = style ?? reportStyles.first;
    final custom = customPrompt?.trim() ?? '';
    final useCustom = s.isCustom && custom.isNotEmpty;
    final extra = useCustom ? custom : (s.instruction ?? '');

    // 报告语言跟随 App 语言：localeName 形如 "de"/"zh"，直接交给提示词，
    // 由 languageName 换成该语言的自称（Deutsch / 简体中文）。
    final lang = languageCode ?? appLoc.localeName;

    final prompt = StringBuffer(
      buildInsightsPrompt(
        facts: facts,
        bookList: bookList,
        nextCandidates: nextCandidates,
        languageCode: lang,
      ),
    );
    if (extra.isNotEmpty) {
      prompt
        ..writeln()
        ..writeln('STYLE (tone only - never change the JSON shape): $extra');
    }

    Future<String?> attempt(double temperature) async {
      final raw = await chat(
        [
          {'role': 'system', 'content': s.persona},
          {'role': 'user', 'content': prompt.toString()},
        ],
        temperature: temperature,
        jsonMode: true,
        maxTokens: 4096,
      );
      return raw.trim().isEmpty ? null : raw;
    }

    // 拿不到内容就降温度重试一次。旧实现没有重试：模型一次抽风
    // 就直接变成一份空报告，用户只能干等。
    return await attempt(0.6) ?? await attempt(0.3);
  }

  /* ----------------------------- 内部工具 ----------------------------- */

  LlmException _wrap(DioException e) {
    final host = chatUri.host;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return LlmException(appLoc.s_46e5ebef(host: host),
            hint: appLoc.s_3c836870);
      case DioExceptionType.sendTimeout:
        return LlmException(appLoc.s_84264711, hint: appLoc.s_225ed2e1);
      case DioExceptionType.receiveTimeout:
        return LlmException(appLoc.s_b265cf86,
            hint: appLoc.s_cc12eea3);
      case DioExceptionType.badCertificate:
        return LlmException(appLoc.s_d711b259,
            hint: appLoc.s_4722b0f8);
      case DioExceptionType.cancel:
        return LlmException(appLoc.s_07a2b144);
      case DioExceptionType.connectionError:
        return LlmException(appLoc.s_8ae0b0e4(host: host),
            hint: appLoc.s_0a9425b8);
      case DioExceptionType.badResponse:
        break;
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        final raw = e.error?.toString() ?? e.message ?? '';
        // Android 上被系统层掐断的典型表现。最常见的原因是 release 包缺少
        // INTERNET 权限，其次是企业网络/代理中断了 TLS 连接。
        if (raw.contains('Software caused connection abort') ||
            raw.contains('Connection reset') ||
            raw.contains('Connection closed')) {
          return LlmException(appLoc.s_554d5235,
              raw: _truncate(raw),
              hint: appLoc.s_020fe21a);
        }
        return LlmException(appLoc.s_dfde23b1,
            raw: _truncate(raw), hint: appLoc.s_2ae4f5fe);
    }

    final code = e.response?.statusCode;
    final body = _truncate(jsonEncode(e.response?.data));
    final detail = _extractMessage(e.response?.data);
    switch (code) {
      case 400:
        return LlmException(appLoc.s_d6ac5952(detail: detail != null ? appLoc.s_edf331af(detail: detail) : ''),
            statusCode: code, raw: body, hint: appLoc.s_cb980461);
      case 401:
        return LlmException(appLoc.s_d9775d22(detail: detail != null ? appLoc.s_edf331af(detail: detail) : ''),
            statusCode: code, raw: body, hint: appLoc.s_c4198142);
      case 402:
        return LlmException(appLoc.s_e06ab1cc, statusCode: code, raw: body);
      case 403:
        return LlmException(appLoc.s_05b3ec8b(detail: detail != null ? appLoc.s_edf331af(detail: detail) : ''),
            statusCode: code, raw: body, hint: appLoc.s_f00f6ff2);
      case 404:
        return LlmException(appLoc.s_016f7576(detail: detail != null ? appLoc.s_edf331af(detail: detail) : ''),
            statusCode: code, raw: body, hint: appLoc.s_a8aa2c59);
      case 422:
        return LlmException(appLoc.s_9688a257(detail: detail != null ? appLoc.s_edf331af(detail: detail) : ''),
            statusCode: code, raw: body);
      case 429:
        return LlmException(appLoc.s_1b3daaa3, statusCode: code, raw: body, hint: appLoc.s_2a564df1);
      case 500:
      case 502:
      case 503:
      case 504:
        return LlmException(appLoc.s_6627221e(code: code), statusCode: code, raw: body, hint: appLoc.s_2fe391dd);
      default:
        return LlmException(appLoc.s_679e6c2e(code: code != null ? ' ($code)' : '', detail: detail != null ? appLoc.s_edf331af(detail: detail) : ''),
            statusCode: code, raw: body);
    }
  }

  /// 从各家格式不一的错误体里挖出一句可读原因
  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      final err = data['error'];
      if (err is Map && err['message'] is String) return _short(err['message'] as String);
      if (err is String) return _short(err);
      for (final k in ['message', 'msg', 'error_msg', 'detail']) {
        final v = data[k];
        if (v is String && v.trim().isNotEmpty) return _short(v);
      }
    }
    return null;
  }

  static String? _short(String s) {
    final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.isEmpty) return null;
    return t.length <= 140 ? t : '${t.substring(0, 140)}…';
  }

  static String? _truncate(String? s, [int max = 500]) {
    if (s == null) return null;
    return s.length <= max ? s : '${s.substring(0, max)}…';
  }

  /* ------------------------- 响应体解析 ------------------------- */
  /*
   * 这一组刻意做成 static + 纯函数：它们是「各家网关长得不一样」这件事的
   * 全部复杂度所在，必须能脱离网络在单测里逐个形态钉住。
   */

  /// 响应体解码。
  ///
  /// Dio 只在 `Content-Type` 是 JSON 时才自动解码。实测有网关把它写成
  /// `text/plain`（甚至 `text/event-stream`），此时 `res.data` 是 **String**——
  /// 上一版代码直接判 `d is! Map` 就抛「返回结构无法解析」，
  /// 明明响应体是完好的 JSON，只是没被解码。
  static Object? _asJson(Object? data) {
    if (data is! String) return data;
    final t = data.trim();
    if (t.isEmpty) return '';
    if (t.startsWith('{') || t.startsWith('[')) {
      try {
        return jsonDecode(t);
      } catch (_) {
        return t;
      }
    }
    // 少数网关无视 stream=false 仍然回 SSE，只取第一个 data: 载荷
    if (t.startsWith('data:') || t.contains('\ndata:')) {
      for (final line in t.split('\n')) {
        final s = line.trim();
        if (!s.startsWith('data:')) continue;
        final payload = s.substring(5).trim();
        if (payload.isEmpty || payload == '[DONE]') continue;
        try {
          return jsonDecode(payload);
        } catch (_) {
          break;
        }
      }
    }
    return t;
  }

  /// 响应体 → 正文。抠不到返回 null。
  ///
  /// 只认 `choices[0].message.content` 是不够的，下面每一种都在真实网关
  /// 上出现过，任何一种没覆盖到，界面上就是一句「返回结构无法解析」——
  /// 用户既看不懂也无法自救：
  ///
  /// 1. 标准 OpenAI 兼容：`choices[0].message.content`
  /// 2. 推理模型：`content` 是空串，正文在 `message.reasoning_content`
  /// 3. 分块数组：`content: [{type: 'text', text: '…'}]`（部分网关仿 Claude）
  /// 4. 补全风格：`choices[0].text`
  /// 5. 外层再包一层：`{data:{…}}` / `{result:{…}}` / `{output:{…}}`
  /// 6. Ollama 原生 `/api/chat`：顶层 `{message:{content:'…'}}`
  /// 7. Responses 风格：顶层 `output_text` / `output[].content[].text`
  /// 8. 整个响应体就是纯文本（见 [_asJson]）
  static String? extractReplyText(Object? body) {
    final b = _asJson(body);

    // 纯文本响应：解不出 JSON 就把它本身当正文
    if (b is String) return _nonEmpty(b);
    // 少数网关直接给 content 分块数组
    if (b is List) return _textFromBlocks(b);
    if (b is! Map) return null;

    // 先剥常见包装层，剥不动再往下走
    for (final key in ['data', 'result', 'output', 'response', 'body']) {
      final v = b[key];
      if (v is Map || v is List) {
        final inner = extractReplyText(v);
        if (inner != null) return inner;
      }
    }

    // choices[0] / choices[n]
    final choices = b['choices'];
    if (choices is List) {
      for (final c in choices) {
        if (c is! Map) continue;
        final t = _textFromMessage(c['message']) ??
            _textFromMessage(c['delta']) ??
            _plainText(c['text']);
        if (t != null) return t;
      }
    }

    // Anthropic 原生：顶层 content 分块数组
    // Ollama 原生：顶层 message
    final t = _textFromMessage(b['message']) ??
        _plainText(b['content']) ??
        _textFromBlocks(b['content']) ??
        _plainText(b['output_text']) ??
        _textFromBlocks(b['output']);
    return t;
  }

  /// 从响应体里挖出服务端错误信息。
  ///
  /// 存在的理由：**部分网关用 HTTP 200 返回错误**（欠费 / 模型不存在 /
  /// Key 无权限）。不专门查这个字段，用户看到的就是「返回结构无法解析」，
  /// 而真正的原因整整齐齐地躺在响应体里。
  static String? extractApiError(Object? body) {
    final b = _asJson(body);
    if (b is! Map) return null;

    final err = b['error'];
    if (err is String) return _nonEmpty(err);
    if (err is Map) {
      final t = _nonEmpty('${err['message'] ?? err['msg'] ?? err['detail'] ?? ''}');
      if (t != null) return t;
    }
    for (final k in ['message', 'msg', 'error_msg', 'errorMessage', 'detail']) {
      final v = b[k];
      if (v is String) {
        final t = _nonEmpty(v);
        if (t != null) return t;
      }
    }
    // {"success": false, "code": 40001} 这类没有文字说明的
    final code = b['code'];
    if (code != null && (b['success'] == false || b['status'] == false)) {
      return 'code=$code';
    }
    return null;
  }

  static String? _textFromMessage(Object? m) {
    if (m is String) return _nonEmpty(m);
    if (m is! Map) return null;
    final content = m['content'];
    if (content is String) {
      // 空串必须当作「没给内容」：推理模型（deepseek-reasoner 一类）
      // 常常 `content:""` 而把正文放在 reasoning_content 里。
      // 上一版写成 `content is String` 就直接 return 空串，
      // 报告出来是空白页，比报错还难查。
      final t = _nonEmpty(content);
      if (t != null) return t;
    }
    if (content is List) {
      final t = _textFromBlocks(content);
      if (t != null) return t;
    }
    final reasoning = m['reasoning_content'] ?? m['reasoning'];
    return reasoning is String ? _nonEmpty(reasoning) : null;
  }

  /// 分块数组 → 文本。跳过 thinking / tool_use 块：
  /// 它们是模型的中间过程，不是给用户的结果。
  static String? _textFromBlocks(Object? blocks) {
    if (blocks is! List) return null;
    final buf = StringBuffer();
    for (final b in blocks) {
      if (b is String) {
        buf.write(b);
        continue;
      }
      if (b is! Map) continue;
      final type = b['type'];
      if (type == 'thinking' || type == 'tool_use' || type == 'tool_result') continue;
      final t = b['text'] ?? b['content'];
      if (t is String) {
        buf.write(t);
      } else if (t is Map && t['value'] is String) {
        buf.write(t['value'] as String);
      } else if (t is List) {
        // Responses 风格是两层：output[].content[].text
        final inner = _textFromBlocks(t);
        if (inner != null) buf.write(inner);
      }
    }
    return _nonEmpty(buf.toString());
  }

  static String? _plainText(Object? v) => v is String ? _nonEmpty(v) : null;

  static String? _nonEmpty(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  /// 响应体的单行预览。jsonEncode 遇到不支持的类型会抛异常，
  /// 而这里恰恰是「已经出了意外」的路径，绝不能再抛第二次。
  static String _preview(Object? data, [int max = 160]) {
    String s;
    try {
      s = data is String ? data : jsonEncode(data);
    } catch (_) {
      s = '$data';
    }
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.isEmpty) return appLoc.s_0cf0a499;
    return s.length <= max ? s : '${s.substring(0, max)}…';
  }
}

/// 把任意异常翻成一句能给用户看的话。
///
/// 页面里直接 `'失败：$e'` 会把 DioException 的原始串糊到界面上——
/// 用户看到的是 `DioException [unknown]: null Error: HttpException:
/// Software caused connection abort, uri = https://...`，
/// 既看不懂也不知道下一步做什么。凡是要展示给用户的错误必须过这里。
///
/// 这条正是「阅读报告生成失败」那个反馈的另一半：根因是 release 包
/// 缺 INTERNET 权限（已修），但即便修好根因，错误文案本身也必须可操作。
String describeLlmError(Object e) {
  if (e is LlmException) return e.toString();
  final text = e.toString();
  // 兜底：真的漏出一个未包装的网络异常时，至少不暴露内部结构
  if (text.contains('DioException') ||
      text.contains('SocketException') ||
      text.contains('HttpException') ||
      text.contains('ClientException')) {
    return appLoc.s_9ed7e745;
  }
  return text;
}

/// 宽松 JSON 解析
///
/// 即便开启 json_object 模式，模型仍可能输出非规范结构：
/// 实测出现多个并列对象用逗号分隔但无外层方括号（{"a":1},{"a":2}），
/// 以及前后混入说明文字。逐层降级尝试，全部失败才返回 null。
Map<String, dynamic>? parseJsonLoose(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
      .replaceAll(RegExp(r'```\s*$'), '')
      .trim();
  for (final candidate in [cleaned, '[$cleaned]']) {
    try {
      final v = jsonDecode(candidate);
      if (v is Map<String, dynamic>) return v;
      if (v is List && v.isNotEmpty && v.first is Map) {
        return Map<String, dynamic>.from(v.first as Map);
      }
    } catch (_) {
      // 继续尝试下一种
    }
  }
  final m = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
  if (m == null) return null;
  try {
    return jsonDecode(m.group(0)!) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// 从模型输出里抠出 JSON 数组（元素为对象）
///
/// 与 [parseJsonLoose] 的区别：这个要的是**列表**。模型很爱在数组外面
/// 裹一层说明文字或代码块，所以先剥壳再按方括号配对截取。
List<Map<String, dynamic>> parseJsonArrayLoose(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r'```(?:json)?\s*', multiLine: true), '')
      .replaceAll(RegExp(r'```'), '')
      .trim();

  Object? tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> fromList(Object? v) => v is List
      ? v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList()
      : const [];

  final direct = tryDecode(cleaned);
  final l1 = fromList(direct);
  if (l1.isNotEmpty) return l1;
  if (direct is Map) {
    for (final key in ['books', 'items', 'data', 'result', 'list']) {
      final l = fromList(direct[key]);
      if (l.isNotEmpty) return l;
    }
  }

  // 截取最外层方括号
  final start = cleaned.indexOf('[');
  final end = cleaned.lastIndexOf(']');
  if (start >= 0 && end > start) {
    final l = fromList(tryDecode(cleaned.substring(start, end + 1)));
    if (l.isNotEmpty) return l;
  }

  // 最后兜底：逐个抓最外层花括号对象
  final objs = <Map<String, dynamic>>[];
  var depth = 0;
  var begin = -1;
  for (var i = 0; i < cleaned.length; i++) {
    final c = cleaned[i];
    if (c == '{') {
      if (depth == 0) begin = i;
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0 && begin >= 0) {
        final v = tryDecode(cleaned.substring(begin, i + 1));
        if (v is Map) objs.add(Map<String, dynamic>.from(v));
        begin = -1;
      }
    }
  }
  return objs;
}

/// 来源平台 → 需要 OCR 兜底的判断
bool needsOcrFallback(BookSource source) =>
    source != BookSource.weread; // 微信读书有官方接口，其余靠截图
