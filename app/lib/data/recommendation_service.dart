import '../ai/ai_client.dart';
import '../ai/search_client.dart';
import '../data/database.dart';
import '../data/recommendation.dart';
import '../models/book.dart';
import '../models/enums.dart';

/// 推荐书单服务：四档书源共用一条管线。
///
/// ## 为什么四档要共用一条管线
///
/// 「从哪来」和「怎么办」是两件事：
///   - 从哪来：本地书架 / 大模型知识 / 微信读书 / 搜索+大模型
///   - 怎么办：补元数据 → 查重 → 展示 → 用户勾选 → 入库
///
/// 后半段完全一样，拆开写四遍迟早分叉（比如某档忘了查重，
/// 用户就能把同一本书加两次）。所以四档只负责**产出候选书名**，
/// 后半段由本类统一收口。
///
/// ## 每档的凭据要求
///
/// | 档位 | 需要 | 没有时 |
/// |---|---|---|
/// | shelfUnread | 无 | 永远可用 |
/// | llm | 大模型 Key | 这一档不可用 |
/// | weread | 微信读书 Key | 这一档不可用 |
/// | search | 搜索 Key + 大模型 Key | 这一档不可用 |
///
/// 「没有凭据」不是错误，是**这一档此刻不可用**——用户可能只配了大模型
/// 而没配微信读书，App 不该因此报错，该档显示成不可用即可。
class RecommendationService {
  final BookRepository repo;
  final LlmClient llm;
  final WereadGateway weread;
  final SearchClient search;

  /// 补元数据用（公开书目库 + 微信读书书城）。
  final MetadataClient metadata;

  RecommendationService({
    required this.repo,
    required this.llm,
    required this.weread,
    required this.search,
    required this.metadata,
  });

  /// 一档书源的可用性。
  ///
  /// 用户看到的是「这一档能不能用」，而不是一个笼统的报错。
  bool available(RecommendSource source) => switch (source) {
        RecommendSource.shelfUnread => true,
        RecommendSource.llm => llm.available,
        RecommendSource.weread => weread.available,
        RecommendSource.search => search.available && llm.available,
      };

  /// 出推荐。
  ///
  /// [keyword] 是用户填的关键词（可空）。
  /// [limit] 是最终返回条数上限。
  Future<List<Recommendation>> recommend(
    RecommendSource source, {
    String? keyword,
    int limit = 8,
  }) async {
    final drafts = switch (source) {
      RecommendSource.shelfUnread => await _fromShelfUnread(limit: limit),
      RecommendSource.llm => await _fromLlm(keyword: keyword, limit: limit),
      RecommendSource.weread =>
        await _fromWeread(keyword: keyword, limit: limit),
      RecommendSource.search =>
        await _fromSearch(keyword: keyword, limit: limit),
    };
    if (drafts.isEmpty) return const [];
    return _enrich(drafts, limit: limit, source: source);
  }

  // ── 档①：本地书架未读 ────────────────────────────────────────────────

  /// 从书架里挑还没读的书。
  ///
  /// 「还没读」= 状态是「想读」（[BookStatus.wish]）。
  /// **搁置**的书不算——搁置是「暂时不想读」，把它排除掉等于说
  /// 「搁置的书不值得再读」，那不是搁置的意思。
  ///
  /// 排序按最近加入（createdAt 倒序），不是按 updatedAt：
  /// 整理一次分类就把所有书的 updatedAt 刷成同一天，排序会完全乱掉。
  Future<List<RecommendationDraft>> _fromShelfUnread({int limit = 8}) async {
    final books = await repo.all(
      status: BookStatus.wish,
      orderBy: 'createdAt DESC',
    );
    final out = <RecommendationDraft>[];
    for (final b in books.take(limit)) {
      out.add(RecommendationDraft(
        title: b.title,
        author: b.authors.isEmpty ? null : b.authors.join(' / '),
        reason: b.description,
        category: b.categoryPrimary ?? b.categoryRaw,
        isbn: b.isbn13,
        publisher: b.publisher,
        description: b.description,
        coverUrl: b.coverUrl,
      ));
    }
    return out;
  }

  // ── 档②：大模型知识 ──────────────────────────────────────────────────

  /// 让大模型凭训练知识推荐。
  ///
  /// 喂给它的只有**本地画像摘要**（分类占比、作者偏好频次），
  /// 不含任何书名——书名属于用户数据，推荐没必要知道具体是哪几本。
  /// 摘要本身是本地统计出来的，只传统计结果不传明细。
  Future<List<RecommendationDraft>> _fromLlm({
    String? keyword,
    int limit = 8,
  }) async {
    if (!llm.available) return const [];
    final profile = await _profileSummary();
    final raw = await llm.chat([
      {'role': 'system', 'content': _llmSystemPrompt()},
      {'role': 'user', 'content': _buildUserPrompt(profile, keyword, limit)},
    ], temperature: 0.7, jsonMode: true);
    return RecommendationDraft.parseList(raw).take(limit).toList();
  }

  /// 本地画像摘要（**不含书名**）。
  ///
  /// 只给统计结果：分类分布 + 高频作者 + 状态分布。
  /// 作者名算不算隐私？算——但它以「频次」的形式出现，
  /// 大模型看到的是「这位读者常读科幻作者」，不知道具体是谁读过什么。
  Future<String> _profileSummary() async {
    final books = await repo.all();
    if (books.isEmpty) return '（书架是空的）';

    final byCategory = <String, int>{};
    final byAuthor = <String, int>{};
    final byStatus = <String, int>{};
    for (final b in books) {
      final c = b.categoryPrimary ?? b.categoryRaw ?? '未分类';
      byCategory[c] = (byCategory[c] ?? 0) + 1;
      for (final a in b.authors) {
        byAuthor[a] = (byAuthor[a] ?? 0) + 1;
      }
      byStatus[b.status.storageValue] =
          (byStatus[b.status.storageValue] ?? 0) + 1;
    }

    String top(Map<String, int> m, int n) {
      final items = m.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return items.take(n).map((e) => '${e.key}(${e.value})').join('、');
    }

    return '藏书 ${books.length} 本；'
        '分类分布：${top(byCategory, 6)}；'
        '常读作者：${top(byAuthor, 5)}；'
        '状态分布：${top(byStatus, 4)}';
  }

  String _llmSystemPrompt() =>
      '你是一位资深选书人。根据读者的藏书画像，推荐他们可能感兴趣但**尚未读过**的书。\n'
      '要求：\n'
      '1. 只输出 JSON 数组，不要任何解释文字或代码块标记。\n'
      '2. 每个元素包含 title、author、reason、category 四个字段。\n'
      '3. reason 用一句话说明为什么推给这位读者（不超过 40 字）。\n'
      '4. 不要推荐读者已经拥有的书。\n'
      '5. 推荐真实存在的书，不要编造。';

  String _buildUserPrompt(String profile, String? keyword, int limit) {
    final buf = StringBuffer()
      ..writeln('读者画像：$profile');
    if (keyword != null && keyword.trim().isNotEmpty) {
      buf.writeln('额外要求：围绕「${keyword.trim()}」推荐。');
    }
    buf.write('请推荐 $limit 本书。');
    return buf.toString();
  }

  // ── 档③：微信读书书城 ───────────────────────────────────────────────

  /// 直接搜微信读书书城。
  ///
  /// 没有关键词时给一个**由本地画像算出的关键词**去搜——
  /// 书城搜索需要关键词，空搜没有意义。
  Future<List<RecommendationDraft>> _fromWeread({
    String? keyword,
    int limit = 8,
  }) async {
    if (!weread.available) return const [];
    // 关键词缺省时用本地占比最高的分类；连那个都没有（书架是空的）
    // 就退回一个通用词——**不能因为本地没数据就不给结果**。
    final kw = _effectiveKeyword(keyword, await _topCategoryKeyword());

    final raw = await weread.search(kw, count: limit);
    final out = <RecommendationDraft>[];
    for (final m in raw) {
      final meta = MetadataResult.fromJson(m);
      final title = (meta.title ?? '').trim();
      if (title.isEmpty) continue;
      out.add(RecommendationDraft(
        title: title,
        author: meta.authors.isEmpty ? null : meta.authors.join(' / '),
        reason: meta.description,
        category: meta.categoryPrimary,
        isbn: meta.isbn13,
        publisher: meta.publisher,
        description: meta.description,
        coverUrl: meta.coverUrl,
      ));
    }
    return out;
  }

  /// 拿本地占比最高的分类当搜索词。
  ///
  /// 书架空时返回空串——调用方负责决定退路（不能直接放弃整档）。
  Future<String> _topCategoryKeyword() async {
    final books = await repo.all();
    if (books.isEmpty) return '';
    final byCategory = <String, int>{};
    for (final b in books) {
      final c = b.categoryPrimary ?? b.categoryRaw;
      if (c == null || c.trim().isEmpty) continue;
      byCategory[c] = (byCategory[c] ?? 0) + 1;
    }
    if (byCategory.isEmpty) return '';
    final top = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return top.first.key;
  }

  /// 通用兜底关键词。
  ///
  /// 书架是空的（新用户）时，本地画像算不出任何分类，档③与档④就会
  /// 整档无结果——而新用户恰恰是最需要「找书」的人。所以本地推不出
  /// 关键词时，退回一个中性词，**宁可给一批泛泛的推荐，也不给空白页**。
  static const String _fallbackKeyword = '好书';

  /// 决定实际用的搜索词。
  ///
  /// 优先级：用户填的关键词 → 本地画像算出的分类 → 通用兜底词。
  /// 返回值一定非空。
  String _effectiveKeyword(String? userKeyword, String localKeyword) {
    final u = userKeyword?.trim() ?? '';
    if (u.isNotEmpty) return u;
    final l = localKeyword.trim();
    if (l.isNotEmpty) return l;
    return _fallbackKeyword;
  }

  /// 搜索 API 的查询串。
  ///
  /// 兜底词本身已经是「好书」，再拼一次会变成「好书 好书 推荐」，
  /// 搜索质量反而下降——所以兜底词走另一条句式。
  String _searchQuery(String keyword) => keyword == _fallbackKeyword
      ? '好书推荐'
      : '$keyword 好书 推荐';

  // ── 档④：搜索 API + 大模型整理 ──────────────────────────────────────

  /// 先用搜索 API 拿候选，再让大模型整理成书单。
  ///
  /// 为什么不让大模型直接推荐（第②档那样）？因为**大模型不知道新书**。
  /// 训练数据有截止时间，让它推荐「最近值得读的书」只能编。
  /// 搜索 API 给出当下真实的候选，大模型只负责挑与写理由。
  ///
  /// 这一档需要两个 Key（搜索 + 大模型），缺一不可。
  Future<List<RecommendationDraft>> _fromSearch({
    String? keyword,
    int limit = 8,
  }) async {
    if (!search.available || !llm.available) return const [];

    final kw = _effectiveKeyword(keyword, await _topCategoryKeyword());

    final hits = await search.search(_searchQuery(kw), count: limit * 3);
    if (hits.isEmpty) return const [];

    // 把搜索结果交给大模型：只让它挑书名和写理由，不让它自由发挥。
    final raw = await llm.chat([
      {'role': 'system', 'content': _searchLlmSystemPrompt()},
      {'role': 'user', 'content': _buildSearchPrompt(kw, hits, limit)},
    ], temperature: 0.4, jsonMode: true);
    return RecommendationDraft.parseList(raw).take(limit).toList();
  }

  String _searchLlmSystemPrompt() =>
      '你是一位选书编辑。下面给你的是搜索引擎返回的候选网页标题与摘要。\n'
      '请从中挑出**真实存在且值得推荐**的书籍，整理成 JSON 数组。\n'
      '要求：\n'
      '1. 只输出 JSON 数组，不要解释文字。\n'
      '2. 每个元素包含 title、author（可选）、reason、category（可选）。\n'
      '3. reason 说明这本书好在哪、适合什么样的读者（一句话，40 字内）。\n'
      '4. **只从候选里挑**，不要加入候选之外的书。\n'
      '5. 候选里没有明确书名的条目直接跳过。';

  String _buildSearchPrompt(String keyword, List<SearchHit> hits, int limit) {
    final buf = StringBuffer()..writeln('主题：$keyword');
    buf.writeln('候选：');
    for (var i = 0; i < hits.length; i++) {
      final h = hits[i];
      buf.writeln('${i + 1}. ${h.title}');
      if (h.snippet.isNotEmpty) {
        buf.writeln('   摘要：${h.snippet}');
      }
    }
    buf.write('请挑出最多 $limit 本并整理成 JSON 数组。');
    return buf.toString();
  }

  // ── 统一收口：补元数据 → 查重 → 出结果 ─────────────────────────────

  /// 给候选补元数据，并剔除已在书架里的。
  ///
  /// 查重是**按书名**（忽略大小写与空格），不是按 ISBN：
  /// 搜索与大模型给的 ISBN 十有八九是编的或格式不对，
  /// 按 ISBN 查重等于没查。
  ///
  /// ## 档①要豁免查重
  ///
  /// 本地书架那档的候选**本来就来自书架**——推荐的是「你买了但还没读的书」，
  /// 它们当然已在库里。若照常查重，结果会被全部剔除，这一档永远返回空。
  ///
  /// 豁免的语义是：这一档的候选不来自外部，不存在「重复推荐」的问题。
  Future<List<Recommendation>> _enrich(
    List<RecommendationDraft> drafts, {
    required int limit,
    required RecommendSource source,
  }) async {
    final known = <String>{};
    if (source != RecommendSource.shelfUnread) {
      final existing = await repo.all();
      known.addAll({for (final b in existing) _normTitle(b.title)});
    }

    final out = <Recommendation>[];
    final seen = <String>{};
    for (final d in drafts) {
      if (out.length >= limit) break;
      final key = _normTitle(d.title);
      if (key.isEmpty) continue;
      if (known.contains(key)) continue; // 已经在书架里
      if (!seen.add(key)) continue; // 本批里重复

      final book = await _toBook(d, source);
      if (book == null) continue;
      out.add(Recommendation(
        book: book,
        reason: d.reason ?? '',
        source: source,
        alreadyInShelf: source == RecommendSource.shelfUnread,
      ));
    }
    return out;
  }

  /// 候选 → Book。
  ///
  /// 优先用公开书目库补全元数据（作者、封面、简介、分类），
  /// 补不上就只留书名——**一本只有书名的书也能进书架**，
  /// 用户自己填细节比功能不可用强。
  Future<Book?> _toBook(RecommendationDraft d, RecommendSource source) async {
    var title = d.title.trim();
    var authors = <String>[];
    var publisher = d.publisher;
    var description = d.description;
    var category = d.category;
    var isbn = d.isbn;
    var coverUrl = d.coverUrl;

    try {
      final m = await metadata.lookup(title, author: d.author);
      if (m != null) {
        final t = (m.title ?? '').trim();
        if (t.isNotEmpty) title = t;
        if (m.authors.isNotEmpty) {
          authors = m.authors
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        publisher = m.publisher ?? publisher;
        description = m.description ?? description;
        category = m.categoryPrimary ?? category;
        isbn = m.isbn13 ?? isbn;
        coverUrl = m.coverUrl ?? coverUrl;
      }
    } catch (_) {
      // 补全失败不致命：下面还有兜底。
    }

    if (authors.isEmpty && d.author != null) {
      authors = d.author!
          .split(RegExp(r'[,、/;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final now = DateTime.now().toUtc().toIso8601String();
    return Book(
      id: '',
      title: title,
      authors: authors,
      publisher: publisher,
      description: description,
      categoryRaw: category,
      isbn13: isbn,
      coverUrl: coverUrl,
      source: source == RecommendSource.weread
          ? BookSource.weread
          : BookSource.manual,
      // 归一化统一由入库流程收口，这里只写 categoryRaw。
      status: BookStatus.wish,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 书名归一化：去空格、去大小写差异。
  ///
  /// 中文书名常带空格（"三体 " vs " 三体"），
  /// 不归一化就会把同一本书当成两本。
  static String _normTitle(String t) =>
      t.replaceAll(RegExp(r'\s+'), '').toLowerCase();
}
