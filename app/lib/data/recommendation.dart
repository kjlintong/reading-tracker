import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/book.dart';

/// 推荐书单的四个来源。
///
/// 四档的差别只在「候选从哪来」，后面的「怎么展示、怎么入库」完全一致，
/// 所以它们共用 [RecommendationService] 这一条管线。
enum RecommendSource {
  /// 本地书架里还没读的书。
  ///
  /// 唯一**完全离线**的一档：不需要任何 Key，也不出设备。
  shelfUnread,

  /// 大模型凭训练时的知识推荐。
  llm,

  /// 微信读书书城。
  weread,

  /// 通用搜索 API 拿到候选，再让大模型整理成书单。
  search,

  ;

  /// 稳定的字符串标识，落进设置或统计时用。
  String get id => name;
}

/// 一条推荐结果。
///
/// [Book] 是「补全过元数据的书」，[reason] 是大模型或本地规则给的
/// 一句推荐理由。理由不是装饰——没有理由的书单用户无从判断该不该买。
@immutable
class Recommendation {
  /// 补全过元数据的书。点「加入书架」时直接用它。
  final Book book;

  /// 推荐理由，一句话。
  final String reason;

  /// 这条推荐来自哪一档。混排展示时要标出来。
  final RecommendSource source;

  /// 这本书**已经在书架里**了。
  ///
  /// 档①（书架里的未读书）天然为 true——那些书本来就在库里，
  /// 用户看到它们是为了「提醒自己还有哪些没读」，不是要把它们加进来。
  /// 这类条目**不能**再走「加入书架」，否则会插一条重复记录。
  final bool alreadyInShelf;

  const Recommendation({
    required this.book,
    required this.reason,
    required this.source,
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

  const RecommendationDraft({
    required this.title,
    this.author,
    this.reason,
    this.category,
    this.isbn,
    this.publisher,
    this.description,
    this.coverUrl,
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
      reason: _str(j['reason']) ?? _str(j['why']) ?? _str(j['description']),
      category: _str(j['category']) ?? _str(j['genre']),
      isbn: _str(j['isbn']),
      publisher: _str(j['publisher']),
      coverUrl: _str(j['coverUrl']) ?? _str(j['cover']),
    );
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
