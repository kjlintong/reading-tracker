import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/book.dart';

/// 推荐书单的两种来源。
///
/// ## 为什么只给两个
///
/// 早先是四档（本地书架 / 大模型 / 微信读书 / 搜索+大模型），
/// 每一档单独一个分段按钮。结果是**用户要替 App 决定技术方案**：
/// 「我该用微信读书还是让大模型推荐？」——这不是用户该操心的事，
/// 他只知道自己想要「联网找书」。
///
/// 所以对外只有两档：
///   - [shelf]：从自己的书架里挑（已经买了、还没读的）
///   - [online]：联网找新书
///
/// [online] 内部具体走哪条路子（搜索+大模型 / 大模型 / 微信读书）
/// 由 [RecommendationService.onlinePlan] 自己决定并自动降级，
/// **不暴露给用户**。用户配了哪个 Key 就走哪条，一条都没配才置灰。
enum RecommendSource {
  /// 从自己的书架里挑还没读的书。零凭据，永远可用。
  shelf,

  /// 联网找新书。
  online,

  ;

  /// 稳定的字符串标识，落进设置或统计时用。
  String get id => name;
}

/// 联网档内部实际走的路子。
///
/// 这是**实现细节**，不出现在界面上。优先级从高到低：
/// 1. [searchAndModel]——搜索给当下真实的候选，大模型负责挑与写介绍；
/// 2. [modelOnly]——大模型凭训练知识推荐；
/// 3. [wereadOnly]——微信读书书城搜索。
enum OnlinePlan {
  /// 搜索 API 拿候选 + 大模型整理成书单。
  searchAndModel,

  /// 大模型凭训练时的知识推荐。
  modelOnly,

  /// 微信读书书城搜索。
  wereadOnly,
}

/// 一条推荐结果。
///
/// [Book] 是「补全过元数据的书」，[reason] 是一句话介绍，
/// [order] 是**建议的阅读顺序**。
@immutable
class Recommendation {
  /// 补全过元数据的书。点「加入书架」时直接用它。
  final Book book;

  /// 一句话介绍：这本书好在哪、为什么推给你。
  ///
  /// 不是装饰——没有介绍的书单用户无从判断该不该买。
  final String reason;

  /// 建议的阅读顺序，从 1 开始。
  ///
  /// 0 表示**没有排序信息**（比如只配了微信读书、没配大模型时，
  /// 书城搜索的结果只能按相关度排，说不上是「入门还是深入」）。
  final int order;

  /// 这条推荐来自哪一档。混排展示时要标出来。
  final RecommendSource source;

  /// 这本书**已经在书架里**了。
  ///
  /// 书架那档天然为 true——那些书本来就在库里，
  /// 用户看到它们是为了「提醒自己还有哪些没读」，不是要把它们加进来。
  /// 这类条目**不能**再走「加入书架」，否则会插一条重复记录。
  final bool alreadyInShelf;

  const Recommendation({
    required this.book,
    required this.reason,
    required this.source,
    this.order = 0,
    this.alreadyInShelf = false,
  });
}

/// 大模型返回的推荐条目（解析用）。
///
/// 刻意用松散解析：大模型返回的 JSON 经常多一层壳、少一个字段、
/// 把数字写成字符串。宁可少收一条，也不要整批丢弃——
/// 用户看到「推荐了 0 本」比看到「少了一条」更挫败。
@immutable
class RecommendationDraft {
  final String title;
  final String? author;
  final String? reason;
  final String? category;
  final String? isbn;

  /// 出版社。补全失败时用它兜底。
  final String? publisher;

  /// 简介。
  final String? description;

  /// 封面图 URL。
  final String? coverUrl;

  /// 建议的阅读顺序（1 起）。
  ///
  /// 大模型给的是数字，但经常写成字符串（`"1"`）或者用别的键名
  /// （`rank` / `index` / `position`），所以解析放宽到能吃下这些。
  final int? order;

  const RecommendationDraft({
    required this.title,
    this.author,
    this.reason,
    this.category,
    this.isbn,
    this.publisher,
    this.description,
    this.coverUrl,
    this.order,
  });

  /// 从大模型返回的 JSON 对象里取一条。
  ///
  /// 返回 null 表示这条完全不可用（没有书名）。
  static RecommendationDraft? fromJson(Map<String, dynamic> j) {
    final title = (_str(j['title']) ?? _str(j['name']) ?? '').trim();
    if (title.isEmpty) return null;
    return RecommendationDraft(
      title: title,
      author: _str(j['author']) ?? _str(j['authors']),
      reason: _str(j['reason']) ?? _str(j['why']) ?? _str(j['intro'])
          ?? _str(j['description']),
      category: _str(j['category']) ?? _str(j['genre']),
      isbn: _str(j['isbn']),
      publisher: _str(j['publisher']),
      coverUrl: _str(j['coverUrl']) ?? _str(j['cover']),
      order: _order(j),
    );
  }

  /// 取出阅读顺序。
  ///
  /// 模型的输出在这一项上极不统一：`order` / `rank` / `index` / `position`，
  /// 值可能是数字也可能是字符串。认不出来的就当没有——
  /// 顺序是锦上添花，缺了不该把整条推荐丢掉。
  static int? _order(Map<String, dynamic> j) {
    for (final key in const ['order', 'rank', 'index', 'position', 'seq']) {
      final v = j[key];
      if (v == null) continue;
      if (v is int) return v > 0 ? v : null;
      if (v is num) {
        final i = v.toInt();
        return i > 0 ? i : null;
      }
      final parsed = int.tryParse(v.toString().trim());
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  /// 解析一段 JSON 文本，返回可用的条目列表。
  ///
  /// 宽容到能吃下三种常见形态：
  ///   - `[{...}, {...}]`            —— 裸数组
  ///   - `{"books": [{...}]}`        —— 带一个包裹键
  ///   - `{"recommendations": [...]}`
  /// 以及数组里混着字符串（模型偶尔直接给书名）的情况。
  static List<RecommendationDraft> parseList(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      // 不是 JSON：退化成「按行取书名」。模型偶尔会回纯文本书单。
      return _fromPlainLines(text);
    }

    final list = _asList(decoded);
    final out = <RecommendationDraft>[];
    for (final item in list) {
      if (item is Map) {
        final d = RecommendationDraft.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (d != null) out.add(d);
      } else if (item is String && item.trim().isNotEmpty) {
        out.add(RecommendationDraft(title: item.trim()));
      }
    }
    return out;
  }

  /// 从大模型返回的一段纯文本里抠出书名。
  ///
  /// 典型形态是 Markdown 列表：
  /// ```
  /// 1. 《三体》— 刘慈欣 — 硬科幻经典
  /// 2. 《活着》— 余华
  /// ```
  /// 逐行解析：取书名号里的内容，没有书名号就取行首。
  ///
  /// ## 为什么要求至少有一行带书名号
  ///
  /// 兜底不能无节制：模型返回一句「这不是 JSON」时，
  /// 无限制的兜底会把它当成一本名叫「这不是 JSON」的书——
  /// 用户看到的是一本莫名其妙的书，而不是「这次没解析出结果」。
  ///
  /// 所以：**整段文本里只要有一行带书名号**，就按 Markdown 列表解析；
  /// 一行都没有则判定为「不是书单」，返回空。
  /// 这条界线的取舍是：宁可漏掉几本没有书名号的书，
  /// 也不要凭空造出一堆乱码书名。
  static List<RecommendationDraft> _fromPlainLines(String raw) {
    final lines = raw.split('\n');
    final bookTitle = RegExp(r'[《「【]([^》」】]+)[》」】]');
    final hasBrackets =
        lines.any((l) => bookTitle.hasMatch(l));
    if (!hasBrackets) return const [];

    final out = <RecommendationDraft>[];
    for (final line in lines) {
      final t = line.trim();
      if (t.isEmpty) continue;
      // 去掉行首的序号与项目符号
      final cleaned = t.replaceFirst(RegExp(r'^[\-\*•\[\]\d\.\s]+'), '');
      if (cleaned.isEmpty) continue;
      final m = bookTitle.firstMatch(cleaned);
      // 整段里已经确认有书名号了，所以**没有书名号的行是引导语**
      //（「给你推荐几本：」），不是书名——跳过它。
      if (m == null) continue;
      final title = m.group(1)!.trim();
      if (title.isEmpty || title.length > 80) continue;
      // 「——」之后的当理由
      final dash = RegExp(r'[—–]{1,2}').firstMatch(cleaned);
      final reason = dash != null
          ? cleaned.substring(dash.end).trim()
          : (cleaned.length > title.length
              ? cleaned.substring(title.length).trim()
              : null);
      out.add(RecommendationDraft(
        title: title,
        reason: (reason == null || reason.isEmpty) ? null : reason,
      ));
    }
    return out;
  }

  /// 从 JSON 值里取出数组。
  ///
  /// 模型可能给 `{"books": [...]}`，也可能给 `{"result": {"items": [...]}}`，
  /// 甚至给一个随手起的键名（`{"我的书单": [...]}`）。
  /// 所以除了已知键名，还要有**兜底**：任何 Map 里找到的第一处数组都算数。
  ///
  /// 兜底的代价是可能取错数组（比如 `{"meta": [...], "books": [...]}`），
  /// 但取错的后果只是解析不出条目——而**整批丢弃**的后果是用户看到
  /// 「推荐了 0 本」。宁可取错也不能丢。
  static List<dynamic> _asList(dynamic v) {
    if (v is List) return v;
    if (v is Map) {
      // 优先命中已知键名
      for (final key in const [
        'books',
        'recommendations',
        'items',
        'results',
        'data',
        'list',
      ]) {
        final got = v[key];
        if (got is List) return got;
        if (got is Map) {
          final nested = _asList(got);
          if (nested.isNotEmpty) return nested;
        }
      }
      // 兜底：任何一处数组
      for (final got in v.values) {
        if (got is List) return got;
        if (got is Map) {
          final nested = _asList(got);
          if (nested.isNotEmpty) return nested;
        }
      }
    }
    return const [];
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }
}
