import 'dart:convert';

import 'database.dart';
import 'date_range.dart';
import '../l10n/app_loc.dart';
import '../models/book.dart';
import '../models/enums.dart';

/// 阅读报告流水线：**算数归本地、解读归模型、排版归模板**。
///
/// 背景：早先的写法是把整包数据塞给模型，让它一次做完「算数 + 解读 +
/// 排版」，生成结果直接存档。这带来三个必然的后果——
///   1. 数据里没有的指标（比如没有任何阅读记录时的「日均时长」）模型也得写，
///      于是只能编；
///   2. Markdown 结构由模型自由发挥，同一份数据重生成两次结构可能不一样；
///   3. 点名环节的书单是按 `updatedAt` 取前 60 本，批量导入后取到的全是
///      最后进来的「想读」书，已读的书一条都进不去，模型无书可点。
///
/// 所以这里把报告拆成四段，模型只做中间那段：
///   切片（本地） → 事实表（本地） → 解读（模型，输出 JSON） → 校验+渲染（本地）

// ---------------------------------------------------------------------------
// 段 1 · 切片
// ---------------------------------------------------------------------------

/// 周期内书籍按「阅读行为」分组。
///
/// 分组的意义：**书架规模不等于阅读行为**。一次性导入 400 本书不会让人
/// 变成「读了 400 本」，把想读的书和读完的书混在一起统计，得出的结论
/// 描述的是导入行为，不是阅读。
class ReportSlice {
  /// 周期内读完（`finishedAt` 落在周期内）。
  final List<Book> finished;

  /// 在读。
  final List<Book> reading;

  /// 在读但进度 < 15% —— 开了坑没填，最值得指出的一类。
  final List<Book> stalled;

  /// 周期内新入库的想读（按 `createdAt` 判定，是「加进书架」不是「读了」）。
  final List<Book> wishAdded;

  /// 有评分的书。
  final List<Book> rated;

  /// 周期内全部书（书架口径）。
  final List<Book> shelf;

  const ReportSlice({
    required this.finished,
    required this.reading,
    required this.stalled,
    required this.wishAdded,
    required this.rated,
    required this.shelf,
  });
}

/// 文件名导进来的脏标题：这类条目进了书单只会让模型瞎点名。
bool _isJunkTitle(String t) {
  final s = t.trim();
  if (s.length <= 1) return true;
  const junk = {'目录', '新建文件夹', '新建文本文档', 'untitled', 'new folder'};
  return junk.contains(s.toLowerCase());
}

ReportSlice sliceBooks({
  required List<Book> books,
  required StatsRange range,
}) {
  final finished = <Book>[];
  final reading = <Book>[];
  final stalled = <Book>[];
  final wishAdded = <Book>[];
  final rated = <Book>[];
  final shelf = <Book>[];

  for (final b in books) {
    if (_isJunkTitle(b.title)) continue;
    shelf.add(b);
    if (b.status == BookStatus.finished) {
      // 完成时间必须落在周期内才算「本期读完」：缺 finishedAt 的书无法
      // 归属到某个周期，硬塞进去会让「本月读了 N 本」这个数字失真。
      if (b.finishedAt != null && range.containsIso(b.finishedAt!)) {
        finished.add(b);
      }
    } else if (b.status == BookStatus.reading) {
      reading.add(b);
      if (b.progressPercent < 15) stalled.add(b);
    } else if (b.status == BookStatus.wish) {
      if (range.containsIso(b.createdAt)) wishAdded.add(b);
    }
    if (b.rating > 0) rated.add(b);
  }
  return ReportSlice(
    finished: finished,
    reading: reading,
    stalled: stalled,
    wishAdded: wishAdded,
    rated: rated,
    shelf: shelf,
  );
}

// ---------------------------------------------------------------------------
// 段 2 · 事实表
// ---------------------------------------------------------------------------

/// 所有数字都在这里算完，**模型不再负责算数**。
///
/// `hasLogs` 为 false 时不下发时长与连续天数——让模型对着 0 写「你的阅读
/// 节奏」是逼它编，不如干脆不给这个维度。
Map<String, dynamic> buildReportFacts(
  ReportSlice s, {
  int readingMinutes = 0,
  int streakDays = 0,
  bool hasLogs = false,
  List<Map<String, dynamic>>? plans,
}) {
  double avgRating = 0;
  if (s.rated.isNotEmpty) {
    avgRating = s.rated.map((b) => b.rating).reduce((a, b) => a + b) /
        s.rated.length;
  }

  final catCount = <String, int>{};
  final srcCount = <String, int>{};
  for (final b in s.shelf) {
    final c = b.categoryPrimary ?? kUncategorized;
    catCount[c] = (catCount[c] ?? 0) + 1;
    srcCount[b.source.label] = (srcCount[b.source.label] ?? 0) + 1;
  }
  final cats = catCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final srcs = srcCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return {
    // 'total' / 'wish' 是给报告页指标 chips 用的别名（shelfTotal / shelfWish
    // 说的是同一件事），保留两套是为了不动 chips 那边的取值。
    'total': s.shelf.length,
    'wish': s.shelf.where((b) => b.status == BookStatus.wish).length,
    'finished': s.finished.length,
    'reading': s.reading.length,
    'stalled': s.stalled.length,
    'wishAdded': s.wishAdded.length,
    'shelfTotal': s.shelf.length,
    'ratedCount': s.rated.length,
    'avgRating': double.parse(avgRating.toStringAsFixed(1)),
    'categoryTop': [
      for (final e in cats.take(6)) {'name': categoryLabel(e.key), 'count': e.value},
    ],
    'sourceTop': [
      for (final e in srcs.take(4)) {'name': e.key, 'count': e.value},
    ],
    'hasLogs': hasLogs,
    if (hasLogs) 'minutes': readingMinutes,
    if (hasLogs) 'streak': streakDays,
    if (plans != null && plans.isNotEmpty) 'plans': plans,
  };
}

// ---------------------------------------------------------------------------
// 书单：按相关性排序，不是按更新时间
// ---------------------------------------------------------------------------

Map<String, dynamic> _bookEntry(Book b) => {
      'id': b.id,
      'title': b.title,
      if (b.authors.isNotEmpty) 'author': b.authors.first,
      if (b.categoryPrimary != null) 'category': categoryLabel(b.categoryPrimary!),
      'status': b.status.name,
      if (b.rating > 0) 'rating': b.rating,
      if (b.progressPercent > 0) 'progress': b.progressPercent.round(),
      if (b.finishedAt != null) 'finishedAt': b.finishedAt,
    };

/// 供模型点名的书单：已读 > 在读 > 有评分 > 新入库。
///
/// 排序逻辑是修掉旧实现的关键——旧实现取 `books.take(60)`，而列表默认
/// 按 `updatedAt` 降序，批量导入后拿到的是最后导入的一批想读书。
List<Map<String, dynamic>> buildBookList(
  ReportSlice s, {
  int finishedCap = 12,
  int readingCap = 10,
  int ratedCap = 8,
  int wishCap = 6,
}) {
  final out = <Map<String, dynamic>>[];
  final seen = <String>{};

  void add(Iterable<Book> src, int cap) {
    for (final b in src) {
      if (out.length >= 40) break;
      if (!seen.add(b.id)) continue;
      if (cap-- <= 0) break;
      out.add(_bookEntry(b));
    }
  }

  add(s.finished, finishedCap);
  // 先拷贝再排序：切片可能来自 const 列表（测试里常见），就地 sort 会抛
  // "Cannot modify an unmodifiable list"。
  add([...s.reading]..sort((a, b) => b.progressPercent.compareTo(a.progressPercent)),
      readingCap);
  add([...s.rated]..sort((a, b) => b.rating.compareTo(a.rating)), ratedCap);
  add(s.wishAdded, wishCap);
  return out;
}

/// 下一步计划的候选书目：正在看的 + 最近想看的 + 接得上已证明口味的库存。
///
/// 有了这份清单，模型推荐的是**你书架上真实存在的书**；没有它，模型会
/// 凭空推荐一本《XXX》，而那本书你根本没有。
List<Map<String, dynamic>> buildNextCandidates(ReportSlice s) {
  final out = <Map<String, dynamic>>[];
  final seen = <String>{};

  void add(Iterable<Book> src, int cap) {
    for (final b in src) {
      if (!seen.add(b.id)) continue;
      if (cap-- <= 0) break;
      out.add(_bookEntry(b));
    }
  }

  // 1) 在读优先：先填坑再开新的
  add(s.reading, 6);

  // 2) 最近加入的想读
  final recentWish = s.wishAdded.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  add(recentWish, 12);

  // 3) 与高分已读书同分类的未读——让推荐接得上已验证的口味
  final likedCats = s.rated
      .where((b) => b.rating >= 4 && b.categoryPrimary != null)
      .map((b) => b.categoryPrimary!)
      .toSet();
  if (likedCats.isNotEmpty) {
    add(
      s.shelf.where((b) =>
          b.status == BookStatus.wish &&
          b.categoryPrimary != null &&
          likedCats.contains(b.categoryPrimary)),
      12,
    );
  }

  // 4) 已读作者的其他在架书
  final readAuthors = {
    for (final b in [...s.finished, ...s.rated])
      for (final a in b.authors) a,
  };
  if (readAuthors.isNotEmpty) {
    add(
      s.shelf.where((b) =>
          b.status == BookStatus.wish &&
          b.authors.any(readAuthors.contains)),
      8,
    );
  }
  return out;
}

// ---------------------------------------------------------------------------
// 组装：一次算出模型需要的一切
// ---------------------------------------------------------------------------

/// 交给模型的一整套输入。单独成类是为了让调用方（报告页）不需要关心
/// 切片、事实表、书单三者的构造顺序。
class ReportBundle {
  final ReportSlice slice;
  final Map<String, dynamic> facts;
  final List<Map<String, dynamic>> bookList;
  final List<Map<String, dynamic>> nextCandidates;

  /// 模型唯一允许引用的书 id（书单 + 候选），校验层拿它做白名单。
  final Set<String> knownIds;

  /// id → 书名，渲染时把 id 还原成《书名》。
  final Map<String, String> titleById;

  const ReportBundle({
    required this.slice,
    required this.facts,
    required this.bookList,
    required this.nextCandidates,
    required this.knownIds,
    required this.titleById,
  });
}

Future<ReportBundle> buildReportBundle({
  required BookRepository repo,
  required List<Book> books,
  required StatsRange range,
}) async {
  final slice = sliceBooks(books: books, range: range);

  // 没有阅读记录就不谈时长：minutes 为 0 的情况既有「真没记录」也有
  // 「记了但为 0」，统一按「没有这个维度」处理最安全。
  final minutes = await repo.totalReadingMinutes();
  final streak = await repo.readingStreakDays();
  final hasLogs = minutes > 0 || streak > 0;

  // 计划只取这个周期内仍然有效的：把一条早就删掉的计划塞进去，
  // 模型会拿它当近况分析。
  final plans = <Map<String, dynamic>>[];
  for (final pr in await repo.activePlanProgress()) {
    final created = DateTime.tryParse(pr.plan.createdAt);
    if (created != null && !range.containsIso(pr.plan.createdAt)) continue;
    plans.add(pr.toReportJson());
  }

  final facts = buildReportFacts(
    slice,
    readingMinutes: minutes,
    streakDays: streak,
    hasLogs: hasLogs,
    plans: plans.isEmpty ? null : plans,
  );
  final bookList = buildBookList(slice);
  final nextCandidates = buildNextCandidates(slice);

  return ReportBundle(
    slice: slice,
    facts: facts,
    bookList: bookList,
    nextCandidates: nextCandidates,
    knownIds: {
      for (final e in bookList) '${e['id']}',
      ...{for (final e in nextCandidates) '${e['id']}'},
    },
    titleById: {for (final b in slice.shelf) b.id: b.title},
  );
}

// ---------------------------------------------------------------------------
// 段 3 · 模型解读的提示词（不再包含任何排版要求）
// ---------------------------------------------------------------------------

/// 事实表里允许引用的占位符。模型写 `[[finished]]`，渲染时本地替换，
/// 这样报告里的数字不可能与数据库不一致。
const List<String> kFactPlaceholders = [
  'finished',
  'reading',
  'stalled',
  'wishAdded',
  'shelfTotal',
  'ratedCount',
  'avgRating',
  'minutes',
  'streak',
];

String buildInsightsPrompt({
  required Map<String, dynamic> facts,
  required List<Map<String, dynamic>> bookList,
  required List<Map<String, dynamic>> nextCandidates,
  required bool zh,
}) {
  final hasLogs = facts['hasLogs'] == true;
  // 没有阅读记录时干脆不提时长类维度：让模型对着 0 写「你的阅读节奏」，
  // 等于逼它编。
  final missing = hasLogs
      ? ''
      : '\n- There are NO reading-time logs in the data. '
          'Never mention reading duration, daily average, consecutive days, '
          'or abandonment rate. Those dimensions simply do not exist here.';
  // 计划是读者自己下的注，没达成不等于失败——这条与风格无关，任何语气
  // 都不许把「没完成」写成道德问题。没有计划时整段不发，避免模型硬凑一节。
  final planNote = (facts['plans'] as List?)?.isNotEmpty == true
      ? '\n- "plans" holds goals the reader set for themselves. State each '
          'with numbers (target vs actual). For unmet goals describe the '
          'pattern (e.g. "every Wednesday dropped out"), never moralize — '
          'missing a goal is not a failure.'
      : '';

  final b = StringBuffer()
    ..writeln('You turn a reader\'s data into insight. Output JSON only.')
    ..writeln()
    ..writeln('FACTS (already computed — never recalculate or contradict them):')
    ..writeln(jsonEncode(facts))
    ..writeln()
    ..writeln('PLACEHOLDERS: when a sentence needs a number from FACTS, write '
        'the placeholder instead: ${kFactPlaceholders.map((k) => '[[$k]]').join(', ')}.')
    ..writeln('Example: "You finished [[finished]] books this period." '
        'Never invent a number, and never leave an unresolved placeholder.')
    ..writeln()
    ..writeln('BOOKS (id / title / author / category / status / rating / progress):')
    ..writeln(jsonEncode(bookList))
    ..writeln()
    ..writeln('NEXT-CANDIDATES (books on the shelf to consider for the next plan):')
    ..writeln(jsonEncode(nextCandidates))
    ..writeln()
    ..writeln('OUTPUT this exact JSON shape:')
    ..writeln('''{
  "headline": "one sentence on the period",
  "overview": ["..."],
  "activity": ["..."],
  "shelf": ["..."],
  "habits": ["..."],
  "naming": [{"id": "<book id from BOOKS>", "line": "..."}],
  "profile": "...",
  "nextPlan": {
    "focus": "one sentence on what to do first",
    "reads": [{"id": "<book id from NEXT-CANDIDATES>", "why": "..."}],
    "rhythm": "ordering and pacing"
  }
}''')
    ..writeln()
    ..writeln('RULES:')
    ..writeln('- Every "id" MUST come from BOOKS or NEXT-CANDIDATES. '
        'Never invent a book or an id.')
    ..writeln('- Every claim must be traceable to FACTS or to a listed book. '
        'If you cannot back it up, leave the array empty.')
    ..writeln('- 2-5 items per array. Empty arrays are fine and preferred '
        'over filler.')
    ..writeln('- "profile" describes reading taste only (finished + rated books). '
        'Never infer taste from the wishlist — an imported backlog is not a preference.')
    ..writeln('- "shelf" describes composition only (what is on the shelf), '
        'no taste judgments.')
    ..writeln('- "nextPlan" must be concrete: pick from NEXT-CANDIDATES, '
        'put the in-progress books first, and say why in that order.')
    ..writeln('- Stay inside reading: what to read, how to read, how to record. '
        'Never comment on how books were acquired, never push reviews, '
        'sharing, or streaks, and pass no judgment beyond reading.')
    ..writeln('- Do not write Markdown, headings, or book brackets. Plain text only.')
    ..write(missing)
    ..write(planNote);

  final lang = zh
      ? '\n\nLANGUAGE: write every field value in Simplified Chinese. '
          'Foreign book titles may stay in their original script, but the '
          'narrative must be Chinese only — never mix languages.'
      : '\n\nLANGUAGE: write every field value in English. Foreign book '
          'titles may stay in their original script, but the narrative must '
          'be English only — never mix languages.';
  b.write(lang);
  return b.toString();
}

// ---------------------------------------------------------------------------
// 段 4 · 校验
// ---------------------------------------------------------------------------

class ReportNaming {
  final String id;
  final String line;
  const ReportNaming({required this.id, required this.line});
}

class ReportPayload {
  final String? headline;
  final List<String> overview;
  final List<String> activity;
  final List<String> shelf;
  final List<String> habits;
  final List<ReportNaming> naming;
  final String? profile;
  final List<ReportNaming> nextReads;
  final String? nextFocus;
  final String? nextRhythm;
  const ReportPayload({
    this.headline,
    this.overview = const [],
    this.activity = const [],
    this.shelf = const [],
    this.habits = const [],
    this.naming = const [],
    this.profile,
    this.nextReads = const [],
    this.nextFocus,
    this.nextRhythm,
  });

  bool get isEmpty =>
      (headline == null || headline!.trim().isEmpty) &&
      overview.isEmpty &&
      activity.isEmpty &&
      shelf.isEmpty &&
      habits.isEmpty &&
      naming.isEmpty &&
      (profile == null || profile!.trim().isEmpty) &&
      nextReads.isEmpty;
}

String _stripFence(String raw) {
  var s = raw.trim();
  if (s.startsWith('```')) {
    s = s.replaceFirst(RegExp(r'^```[a-zA-Z]*\s*'), '');
    if (s.endsWith('```')) s = s.substring(0, s.length - 3);
  }
  return s.trim();
}

List<String> _strList(Object? v, {int cap = 6}) {
  if (v is! List) return const [];
  final out = <String>[];
  for (final e in v) {
    final s = '$e'.trim();
    if (s.isNotEmpty) out.add(s);
    if (out.length >= cap) break;
  }
  return out;
}

/// 解析并校验模型输出。
///
/// 校验是这套流程的保险丝：**点名与推荐里出现的书必须来自下发清单**，
/// 否则模型一句《XXX》就能凭空造出一本你没读过的书。
ReportPayload parseReportPayload(
  String raw, {
  required Set<String> knownBookIds,
}) {
  Map<String, dynamic>? obj;
  try {
    obj = jsonDecode(_stripFence(raw)) as Map<String, dynamic>?;
  } catch (_) {
    return const ReportPayload();
  }
  if (obj == null) return const ReportPayload();

  String? str(Object? v) {
    final s = '$v'.trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  List<ReportNaming> namings(Object? v, Set<String> pool) {
    if (v is! List) return const [];
    final out = <ReportNaming>[];
    for (final e in v) {
      if (e is! Map) continue;
      final id = '${e['id'] ?? ''}'.trim();
      final line = str(e['line'] ?? e['why'] ?? e['text']);
      if (id.isEmpty || line == null) continue;
      if (!pool.contains(id)) continue; // 不在下发清单 → 幻觉，丢弃
      out.add(ReportNaming(id: id, line: line));
    }
    return out;
  }

  final plan = obj['nextPlan'];
  final planMap = plan is Map ? plan : const <String, dynamic>{};

  return ReportPayload(
    headline: str(obj['headline']),
    overview: _strList(obj['overview']),
    activity: _strList(obj['activity']),
    shelf: _strList(obj['shelf']),
    habits: _strList(obj['habits']),
    naming: namings(obj['naming'], knownBookIds),
    profile: str(obj['profile']),
    nextReads: namings(planMap['reads'], knownBookIds),
    nextFocus: str(planMap['focus']),
    nextRhythm: str(planMap['rhythm']),
  );
}

// ---------------------------------------------------------------------------
// 段 5 · 渲染
// ---------------------------------------------------------------------------

String _fill(String text, Map<String, dynamic> facts) {
  return text.replaceAllMapped(RegExp(r'\[\[(\w+)\]\]'), (m) {
    final v = facts[m.group(1)];
    return v == null ? '—' : '$v';
  });
}

/// 把结构化结果拼成 Markdown。结构恒定，风格只影响措辞不影响排版。
String renderReport(
  ReportPayload p, {
  required Map<String, dynamic> facts,
  required Map<String, String> titleById,
}) {
  final out = StringBuffer();
  void section(String title, List<String> lines) {
    if (lines.isEmpty) return; // 空节直接省略，不硬凑
    out.writeln('## $title');
    for (final l in lines) {
      out.writeln('- ${_fill(l, facts)}');
    }
    out.writeln();
  }

  final head = p.headline;
  if (head != null && head.trim().isNotEmpty) {
    out.writeln('## ${appLoc.s_9f2c1d4e}');
    out.writeln(_fill(head, facts));
    out.writeln();
    if (p.overview.isNotEmpty) {
      for (final l in p.overview) {
        out.writeln('- ${_fill(l, facts)}');
      }
      out.writeln();
    }
  }

  section(appLoc.s_0f2b6c1a, p.activity);
  section(appLoc.s_7d1a4e35, p.shelf);
  section(appLoc.s_3c58b0d2, p.habits);

  if (p.naming.isNotEmpty) {
    out.writeln('## ${appLoc.s_4b7e2a19}');
    for (final n in p.naming) {
      final t = titleById[n.id] ?? '';
      out.writeln('- 《$t》${_fill(n.line, facts)}');
    }
    out.writeln();
  }

  if (p.profile != null && p.profile!.trim().isNotEmpty) {
    out.writeln('## ${appLoc.s_6e39f7c4}');
    out.writeln(_fill(p.profile!, facts));
    out.writeln();
  }

  final focus = p.nextFocus;
  if (focus != null || p.nextReads.isNotEmpty || p.nextRhythm != null) {
    out.writeln('## ${appLoc.s_1a8d53f6}');
    if (focus != null) out.writeln(_fill(focus, facts));
    if (p.nextReads.isNotEmpty) {
      out.writeln();
      for (final n in p.nextReads) {
        final t = titleById[n.id] ?? '';
        out.writeln('- 《$t》— ${_fill(n.line, facts)}');
      }
    }
    final rhythm = p.nextRhythm;
    if (rhythm != null) {
      out.writeln();
      out.writeln(_fill(rhythm, facts));
    }
    out.writeln();
  }

  return out.toString().trim();
}
