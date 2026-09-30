import 'dart:convert';
import 'enums.dart';

/// 统一书籍模型。
///
/// 所有导入源（微信读书 / 掌阅 / 京东读书 / 文石 / 拍照识别 / CSV / 手动）
/// 都必须先转成这个结构再落库。字段大量可空——导入阶段允许残缺记录，
/// 由元数据补全管道后续补齐。extra 用于兜底保存源系统自定义字段，
/// 保证 Notion 迁移时零丢失。
class Book {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final List<String> translators;
  final String? publisher;
  final String? publishedAt;
  final String? isbn13;
  final String? coverUrl;
  final String? coverLocalPath;

  final String? categoryPrimary;
  /// 数据源给出的原始分类，未经归一化。
  /// 保留它是为了让归一化可重复执行——将来词表扩充后可对历史数据重跑，
  /// 不必回头再拉一次数据源。
  final String? categoryRaw;
  final String? categoryPath;
  final List<String> tags;
  final String? description;
  final String language;

  final int? pageCount;
  final int? wordCount;

  final BookFormat format;
  final BookSource source;
  final String? sourceBookId;
  final String? sourceUrl;

  final BookStatus status;
  final double progressPercent;
  final int? currentPage;
  final double rating;

  final String? review;     // 读后感
  final String? summary;    // 摘要（Notion 原有功能）
  final String? highlights; // 摘抄 / 金句

  final String? startedAt;
  final String? finishedAt;
  final String? borrowedFrom;
  final String? dueAt;      // 图书馆应还日期
  final int rereadCount;

  final Map<String, dynamic> extra;
  final String createdAt;
  final String updatedAt;

  const Book({
    required this.id,
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.translators = const [],
    this.publisher,
    this.publishedAt,
    this.isbn13,
    this.coverUrl,
    this.coverLocalPath,
    this.categoryPrimary,
    this.categoryRaw,
    this.categoryPath,
    this.tags = const [],
    this.description,
    this.language = 'zh',
    this.pageCount,
    this.wordCount,
    this.format = BookFormat.ebook,
    this.source = BookSource.manual,
    this.sourceBookId,
    this.sourceUrl,
    this.status = BookStatus.wish,
    this.progressPercent = 0,
    this.currentPage,
    this.rating = 0,
    this.review,
    this.summary,
    this.highlights,
    this.startedAt,
    this.finishedAt,
    this.borrowedFrom,
    this.dueAt,
    this.rereadCount = 0,
    this.extra = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.create({String? title, BookSource source = BookSource.manual}) {
    final now = DateTime.now().toIso8601String();
    return Book(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title ?? '',
      source: source,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 书籍指纹，用于跨源去重：ISBN 优先，其次书名+首位作者
  String get fingerprint {
    if (isbn13 != null && isbn13!.isNotEmpty) return 'isbn:$isbn13';
    final t = title.trim().toLowerCase();
    final a = authors.isNotEmpty ? authors.first.trim().toLowerCase() : '';
    return 'ta:$t|$a';
  }

  bool get isBorrowed => status == BookStatus.borrowed;

  /// 归一化分类：把 `categoryRaw`（数据源原始分类）过一遍受控词表，
  /// 结果写进 `categoryPrimary`，原始值原样保留。
  ///
  /// 所有落库路径都必须先过这一步。微信读书返回的是自有体系
  /// （经济理财 / 个人成长 / 哲学宗教…），不归一化会让「经济理财」与
  /// 「经济」并列成两个分类，直接污染统计。幂等：已归一化的再跑一次不变。
  Book withNormalizedCategory() {
    final raw = (categoryRaw ?? categoryPrimary)?.trim();
    if (raw == null || raw.isEmpty) {
      // 空白分类按「没有分类」处理。copyWith 用 `?? this.x` 兜底，传 null
      // 清不掉字段，所以这里绕过它直接重建，免得一个空串在统计里
      // 变成独立的一格。走 toMap/fromMap 是刻意的——只改这两个字段，
      // 其余字段与列表/Map 的编解码都复用既有路径，不会漏字段。
      if (categoryPrimary == null && categoryRaw == null) return this;
      return Book.fromMap({
        ...toMap(),
        'categoryPrimary': null,
        'categoryRaw': null,
      });
    }
    final normalized = normalizeCategory(raw);
    if (normalized == categoryPrimary && categoryRaw == raw) return this;
    return copyWith(categoryRaw: raw, categoryPrimary: normalized);
  }

  /// 距离还书日天数，负数表示已逾期
  int? get daysUntilDue {
    if (dueAt == null) return null;
    final due = DateTime.tryParse(dueAt!);
    if (due == null) return null;
    final now = DateTime.now();
    return DateTime(due.year, due.month, due.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  Book copyWith({
    String? title,
    String? subtitle,
    List<String>? authors,
    List<String>? translators,
    String? publisher,
    String? publishedAt,
    String? isbn13,
    String? coverUrl,
    String? coverLocalPath,
    String? categoryPrimary,
    String? categoryRaw,
    String? categoryPath,
    List<String>? tags,
    String? description,
    String? language,
    int? pageCount,
    int? wordCount,
    BookFormat? format,
    BookSource? source,
    String? sourceBookId,
    String? sourceUrl,
    BookStatus? status,
    double? progressPercent,
    int? currentPage,
    double? rating,
    String? review,
    String? summary,
    String? highlights,
    String? startedAt,
    String? finishedAt,
    String? borrowedFrom,
    String? dueAt,
    int? rereadCount,
    Map<String, dynamic>? extra,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authors: authors ?? this.authors,
      translators: translators ?? this.translators,
      publisher: publisher ?? this.publisher,
      publishedAt: publishedAt ?? this.publishedAt,
      isbn13: isbn13 ?? this.isbn13,
      coverUrl: coverUrl ?? this.coverUrl,
      coverLocalPath: coverLocalPath ?? this.coverLocalPath,
      categoryPrimary: categoryPrimary ?? this.categoryPrimary,
      categoryRaw: categoryRaw ?? this.categoryRaw,
      categoryPath: categoryPath ?? this.categoryPath,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      language: language ?? this.language,
      pageCount: pageCount ?? this.pageCount,
      wordCount: wordCount ?? this.wordCount,
      format: format ?? this.format,
      source: source ?? this.source,
      sourceBookId: sourceBookId ?? this.sourceBookId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      currentPage: currentPage ?? this.currentPage,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      summary: summary ?? this.summary,
      highlights: highlights ?? this.highlights,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      borrowedFrom: borrowedFrom ?? this.borrowedFrom,
      dueAt: dueAt ?? this.dueAt,
      rereadCount: rereadCount ?? this.rereadCount,
      extra: extra ?? this.extra,
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'authors': jsonEncode(authors),
        'translators': jsonEncode(translators),
        'publisher': publisher,
        'publishedAt': publishedAt,
        'isbn13': isbn13,
        'coverUrl': coverUrl,
        'coverLocalPath': coverLocalPath,
        'categoryPrimary': categoryPrimary,
        'categoryRaw': categoryRaw,
        'categoryPath': categoryPath,
        'tags': jsonEncode(tags),
        'description': description,
        'language': language,
        'pageCount': pageCount,
        'wordCount': wordCount,
        'format': format.name,
        'source': source.name,
        'sourceBookId': sourceBookId,
        'sourceUrl': sourceUrl,
        'status': status.name,
        'progressPercent': progressPercent,
        'currentPage': currentPage,
        'rating': rating,
        'review': review,
        'summary': summary,
        'highlights': highlights,
        'startedAt': startedAt,
        'finishedAt': finishedAt,
        'borrowedFrom': borrowedFrom,
        'dueAt': dueAt,
        'rereadCount': rereadCount,
        'extra': jsonEncode(extra),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory Book.fromMap(Map<String, dynamic> m) => Book(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        subtitle: m['subtitle'] as String?,
        authors: _decodeList(m['authors']),
        translators: _decodeList(m['translators']),
        publisher: m['publisher'] as String?,
        publishedAt: m['publishedAt'] as String?,
        isbn13: m['isbn13'] as String?,
        coverUrl: m['coverUrl'] as String?,
        coverLocalPath: m['coverLocalPath'] as String?,
        categoryPrimary: m['categoryPrimary'] as String?,
        categoryRaw: m['categoryRaw'] as String?,
        categoryPath: m['categoryPath'] as String?,
        tags: _decodeList(m['tags']),
        description: m['description'] as String?,
        language: m['language'] as String? ?? 'zh',
        pageCount: m['pageCount'] as int?,
        wordCount: m['wordCount'] as int?,
        format: BookFormat.fromString(m['format'] as String?),
        source: BookSource.fromString(m['source'] as String?),
        sourceBookId: m['sourceBookId'] as String?,
        sourceUrl: m['sourceUrl'] as String?,
        status: BookStatus.fromString(m['status'] as String?),
        progressPercent: (m['progressPercent'] as num?)?.toDouble() ?? 0,
        currentPage: m['currentPage'] as int?,
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        review: m['review'] as String?,
        summary: m['summary'] as String?,
        highlights: m['highlights'] as String?,
        startedAt: m['startedAt'] as String?,
        finishedAt: m['finishedAt'] as String?,
        borrowedFrom: m['borrowedFrom'] as String?,
        dueAt: m['dueAt'] as String?,
        rereadCount: m['rereadCount'] as int? ?? 0,
        extra: _decodeMap(m['extra']),
        createdAt: m['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        updatedAt: m['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      );

  static List<String> _decodeList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    try {
      final d = jsonDecode(v as String);
      return d is List ? d.map((e) => e.toString()).toList() : [];
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> _decodeMap(dynamic v) {
    if (v == null) return {};
    if (v is Map) return Map<String, dynamic>.from(v);
    try {
      final d = jsonDecode(v as String);
      return d is Map ? Map<String, dynamic>.from(d) : {};
    } catch (_) {
      return {};
    }
  }
}

/// 阅读日志：一次阅读行为，用于时长统计与连续天数
class ReadingLog {
  final String id;
  final String bookId;
  final String date; // YYYY-MM-DD
  final int durationMin;
  final int? pagesFrom;
  final int? pagesTo;
  final String? note;
  final BookSource source;

  const ReadingLog({
    required this.id,
    required this.bookId,
    required this.date,
    this.durationMin = 0,
    this.pagesFrom,
    this.pagesTo,
    this.note,
    this.source = BookSource.manual,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookId': bookId,
        'date': date,
        'durationMin': durationMin,
        'pagesFrom': pagesFrom,
        'pagesTo': pagesTo,
        'note': note,
        'source': source.name,
      };

  factory ReadingLog.fromMap(Map<String, dynamic> m) => ReadingLog(
        id: m['id'] as String,
        bookId: m['bookId'] as String,
        date: m['date'] as String,
        durationMin: m['durationMin'] as int? ?? 0,
        pagesFrom: m['pagesFrom'] as int?,
        pagesTo: m['pagesTo'] as int?,
        note: m['note'] as String?,
        source: BookSource.fromString(m['source'] as String?),
      );
}

/// 笔记 / 划线 / 想法
class Note {
  final String id;
  final String bookId;
  final NoteType type;
  final String content;
  final String? chapter;
  final int? pageAt;
  final BookSource source;
  final String createdAt;

  const Note({
    required this.id,
    required this.bookId,
    this.type = NoteType.highlight,
    required this.content,
    this.chapter,
    this.pageAt,
    this.source = BookSource.manual,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'bookId': bookId,
        'type': type.name,
        'content': content,
        'chapter': chapter,
        'pageAt': pageAt,
        'source': source.name,
        'createdAt': createdAt,
      };

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as String,
        bookId: m['bookId'] as String,
        type: NoteType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => NoteType.highlight,
        ),
        content: m['content'] as String? ?? '',
        chapter: m['chapter'] as String?,
        pageAt: m['pageAt'] as int?,
        source: BookSource.fromString(m['source'] as String?),
        createdAt: m['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );
}
