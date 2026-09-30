import 'dart:convert';
import 'package:dio/dio.dart';
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
    if (!available) throw StateError('未配置微信读书 API Key');
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
        s.replaceAll(RegExp(r'[\s·・\-—_:：,，。.·（）()\[\]【】]'), '').toLowerCase();
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

  Future<MetadataResult?> _googleBooks(String query) async {
    final res = await _dio.get(
      'https://www.googleapis.com/books/v1/volumes',
      queryParameters: {'q': query, 'maxResults': 5},
    );
    final items = res.data?['items'] as List?;
    if (items == null || items.isEmpty) return null;
    final v = (items.first as Map)['volumeInfo'] as Map? ?? {};
    return MetadataResult(
      title: v['title'] as String?,
      authors: (v['authors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      publisher: v['publisher'] as String?,
      publishedAt: (v['publishedDate'] as String?)?.substring(0, (v['publishedDate'] as String).length.clamp(0, 10)),
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
    final res = await _dio.get(
      'https://openlibrary.org/search.json',
      queryParameters: {
        'q': query,
        'limit': 5,
        'fields': 'title,author_name,publisher,first_publish_year,subject,isbn,cover_i,number_of_pages_median',
      },
    );
    final docs = res.data?['docs'] as List?;
    if (docs == null || docs.isEmpty) return null;
    final d = docs.first as Map;
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
      throw LlmException('未配置大模型 API Key', hint: '到「设置 → 大模型」填写');
    }
    final useModel = (modelOverride ?? model).trim();
    if (useModel.isEmpty) {
      throw LlmException('未选择模型', hint: '点「拉取模型」从账号可用列表里选一个');
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

  Future<String> _chatOpenAi(
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
    final d = res.data;
    final raw = _truncate(jsonEncode(d));
    if (d is! Map) throw LlmException('返回结构无法解析', raw: raw);

    final choices = d['choices'];
    if (choices is! List || choices.isEmpty) {
      throw LlmException('返回结构无法解析', raw: raw);
    }
    final first = choices.first;
    if (first is Map) {
      final message = first['message'];
      if (message is Map) {
        // 空串必须当作「没给内容」：推理模型（deepseek-reasoner 一类）
        // 常常返回 content:"" 并在 reasoning_content 里放正文。
        // 直接 return content 会把答案吃掉，还返回一个空报告。
        final content = message['content'];
        if (content is String && content.trim().isNotEmpty) return content;
        final reasoning = message['reasoning_content'];
        if (reasoning is String && reasoning.trim().isNotEmpty) {
          return reasoning;
        }
        // content 可能是分块数组（部分网关沿用 Claude 风格）
        if (content is List) {
          final buf = StringBuffer();
          for (final b in content) {
            if (b is Map && b['text'] is String) buf.write(b['text'] as String);
          }
          if (buf.toString().trim().isNotEmpty) return buf.toString();
        }
      }
    }
    throw LlmException('返回结构无法解析', raw: raw);
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
      systemParts.add('只输出合法 JSON，不要输出解释文字或 markdown 代码块。');
    }
    if (turns.isEmpty) {
      throw LlmException('消息为空，无法发送');
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

    final d = res.data;
    if (d is Map) {
      final stop = d['stop_reason'];
      if (stop == 'refusal') {
        throw LlmException('模型拒绝了这次请求');
      }
      final blocks = d['content'];
      if (blocks is List) {
        final buf = StringBuffer();
        for (final b in blocks) {
          if (b is Map && b['type'] == 'text' && b['text'] is String) {
            buf.write(b['text'] as String);
          }
        }
        if (buf.isNotEmpty) return buf.toString();
      }
    }
    throw LlmException('返回结构无法解析', raw: _truncate(jsonEncode(d)));
  }

  /// 拉取该 Key 实际可用的模型列表。
  ///
  /// 各家 `GET /models` 返回结构大同小异（`data[].id`），但也有返回
  /// `models[]` 甚至裸数组的网关，所以逐个兜底探测。
  Future<List<LlmModel>> listModels() async {
    if (!available) {
      throw LlmException('未配置 API Key', hint: '先填 Key 再拉取模型');
    }
    try {
      final res = await _dio.get(
        modelsUri.toString(),
        options: Options(headers: _headers),
      );
      final raw = res.data;
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
        throw LlmException('该服务返回的模型列表为空',
            raw: _truncate(jsonEncode(raw)), hint: '可以手动填写模型名');
      }
      out.sort((a, b) => a.id.toLowerCase().compareTo(b.id.toLowerCase()));
      return out;
    } on DioException catch (e) {
      final wrapped = _wrap(e);
      if (wrapped.statusCode == 404) {
        // statusCode 必须带上：设置页要靠它区分「没有列表接口」和「地址填错」，
        // 丢了它这条例外就跟普通网络故障长得一样了。
        throw LlmException('该服务没有提供模型列表接口 (404)',
            statusCode: 404,
            raw: wrapped.raw,
            hint: '手动填写模型名即可，例如 deepseek-chat / claude-sonnet-5');
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
      throw LlmException('未填写模型名', hint: '先点「拉取模型」或手动填一个');
    }
    final started = DateTime.now();
    final text = await chat(
      [
        {'role': 'user', 'content': '回复两个字：可用'},
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
    final vocab = (categories ?? defaultCategories).join(' / ');
    final raw = await chat(
      [
        {'role': 'system', 'content': '你是图书编目助手。只输出 JSON，不要解释。'},
        {
          'role': 'user',
          'content': '已知书名《$title》${author != null ? '，作者：$author' : ''}。\n'
              '请补充：\n'
              '- categoryPrimary：必须从词表中选一个：$vocab\n'
              '- description：80-150 字中文内容梗概，客观陈述，不含评价\n'
              '- tags：3-5 个中文关键词标签\n'
              '- authors：若能确定作者则给出数组，否则空数组\n'
              '输出格式：{"categoryPrimary":"","description":"","tags":[],"authors":[]}'
        },
      ],
      jsonMode: true,
    );
    return parseJsonLoose(raw);
  }

  /// 生成定期阅读报告
  Future<String> generateReport(String period, Map<String, dynamic> data) async {
    return chat(
      [
        {
          'role': 'system',
          'content': '你是私人阅读顾问。基于数据做客观分析，避免空泛赞美，指出被忽视的结构性问题。'
        },
        {
          'role': 'user',
          'content': '以下是我$period的阅读数据（JSON）：\n${jsonEncode(data)}\n\n'
              '请生成一份中文阅读报告，包含：\n'
              '1. 概览：读完本数、总时长、日均时长\n'
              '2. 结构分析：分类分布、来源平台分布、形态占比\n'
              '3. 习惯洞察：阅读节奏、连续天数、弃读率\n'
              '4. 偏好画像：我可能是什么类型的读者\n'
              '5. 建议：基于缺口给出 3 条具体可执行的下一步建议\n'
              '用 Markdown 输出。'
        },
      ],
      temperature: 0.6,
      maxTokens: 8192,
    );
  }

  /* ----------------------------- 内部工具 ----------------------------- */

  LlmException _wrap(DioException e) {
    final host = chatUri.host;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return LlmException('连接超时：无法在 20 秒内连上 $host',
            hint: '检查网络或 Base URL；国内直连部分海外服务需要代理');
      case DioExceptionType.sendTimeout:
        return LlmException('发送超时', hint: '网络上行不稳定，稍后重试');
      case DioExceptionType.receiveTimeout:
        return LlmException('响应超时：模型 180 秒内没有返回',
            hint: '换一个更快的模型，或把报告周期缩短后重试');
      case DioExceptionType.badCertificate:
        return LlmException('HTTPS 证书校验失败',
            hint: '若使用自建/内网端点请改用可信证书');
      case DioExceptionType.cancel:
        return LlmException('请求已取消');
      case DioExceptionType.connectionError:
        return LlmException('网络不可达：连不上 $host',
            hint: '① 检查手机网络；② 确认 Base URL 写全了（含 /v1）；'
                '③ 该服务是否需要代理；④ 本地服务（Ollama）手机访问不到电脑的 localhost');
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
          return LlmException('连接被中断',
              raw: _truncate(raw),
              hint: '常见于网络权限被拦、代理或防火墙中断连接，也可能是不支持明文 HTTP。稍后重试或换网络');
        }
        return LlmException('网络请求失败',
            raw: _truncate(raw), hint: '检查 Base URL、代理设置与网络环境');
    }

    final code = e.response?.statusCode;
    final body = _truncate(jsonEncode(e.response?.data));
    final detail = _extractMessage(e.response?.data);
    switch (code) {
      case 400:
        return LlmException('请求被拒绝 (400)${detail != null ? '：$detail' : ''}',
            statusCode: code, raw: body, hint: '多半是模型名不对，或该模型不支持当前参数');
      case 401:
        return LlmException('鉴权失败 (401)${detail != null ? '：$detail' : ''}',
            statusCode: code, raw: body, hint: 'API Key 无效或已过期，重新复制一个');
      case 402:
        return LlmException('账户余额不足 (402)', statusCode: code, raw: body);
      case 403:
        return LlmException('无权限 (403)${detail != null ? '：$detail' : ''}',
            statusCode: code, raw: body, hint: 'Key 没有该模型的调用权限，或未实名/未开通');
      case 404:
        return LlmException('接口或模型不存在 (404)${detail != null ? '：$detail' : ''}',
            statusCode: code, raw: body, hint: '核对 Base URL 是否填到 /v1；模型名可用「拉取模型」获取');
      case 422:
        return LlmException('参数不合法 (422)${detail != null ? '：$detail' : ''}',
            statusCode: code, raw: body);
      case 429:
        return LlmException('触发限流 (429)', statusCode: code, raw: body, hint: '稍等再试，或升级套餐');
      case 500:
      case 502:
      case 503:
      case 504:
        return LlmException('服务端错误 ($code)', statusCode: code, raw: body, hint: '对端的问题，稍后重试');
      default:
        return LlmException('请求失败${code != null ? ' ($code)' : ''}'
            '${detail != null ? '：$detail' : ''}',
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
    return '网络请求失败，检查手机网络与「设置 → 大模型」里的 Base URL';
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
