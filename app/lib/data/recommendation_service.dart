import '../ai/ai_client.dart';
import '../ai/search_client.dart';
import '../data/database.dart';
import '../data/recommendation.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../perf.dart';

/// 推荐书单服务：两种来源共用一条管线。
///
/// ## 为什么两档要共用一条管线
///
/// 「从哪来」和「怎么办」是两件事：
///   - 从哪来：自己的书架 / 联网
///   - 怎么办：补元数据 → 查重 → 排顺序 → 展示 → 用户勾选 → 入库
///
/// 后半段完全一样，拆开写两遍迟早分叉（比如某档忘了查重，
/// 用户就能把同一本书加两次）。所以两档只负责**产出候选**，
/// 后半段由本类统一收口。
///
/// ## 联网档不暴露具体来源
///
/// 界面���只有「联网」一个入口，具体走搜索+大模型、大模型还是微信读书，
/// 由 [onlinePlan] 按已配置的凭据自动决定。理由见 [OnlinePlan]。
class RecommendationService {
  final BookRepository repo;
  final LlmClient llm;
  final WereadGateway weread;
  final SearchClient search;

  /// 补元数据用（公开书目库 + 微信读书书城）。
  final MetadataClient metadata;

  /// 单本补全的总预算。
  ///
  /// 外部源不可达时（国内直连 Google Books 就是这样），
  /// 每个源都要等满自己的超时；给整次补全一个上限，
  /// 超时就用候选自带的字段入库——
  /// 一本只有书名的书也能进书架，好过页面一直转圈。
  static const Duration _enrichTimeout = Duration(seconds: 10);

  RecommendationService({
    required this.repo,
    required this.llm,
    required this.weread,
    required this.search,
    required this.metadata,
  });

  /// 联网档内部实际走的路子。
  ///
  /// **自动降级，不问用户**。优先级：
  /// 1. 搜索 + 大模型——搜索给当下真实的候选，大模型负责挑与写介绍；
  /// 2. 大模型——凭训练知识推荐（模型不知道新书，但经典书没问题）；
  /// 3. 微信读书书城——中文书库质量高，但排不了阅读顺序。
  ///
  /// 返回 null 表示一个凭据都没有，联网档在界面上置灰。
  OnlinePlan? get onlinePlan {
    if (llm.available && search.available) return OnlinePlan.searchAndModel;
    if (llm.available) return OnlinePlan.modelOnly;
    if (weread.available) return OnlinePlan.wereadOnly;
    return null;
  }

  /// 一档书源的可用性。
  ///
  /// 用户看到的是「这一档能不能用」，而不是一个笼统的报错。
  bool available(RecommendSource source) => switch (source) {
        RecommendSource.shelf => true,
        RecommendSource.online => onlinePlan != null,
      };

  /// 出推荐。
  ///
  /// [keyword] 是用户填的「感兴趣的东西」（可空——空了就按本地画像推）。
  /// [limit] 是最终返回条数上限。
  ///
  /// 返回的是**一份书单**（导语 + 条目），不是一列书名——
  /// 只有书名的列表用户无从判断该从哪本开始。
  Future<RecommendationBundle> recommend(
    RecommendSource source, {
    String? keyword,
    int limit = 8,
  }) async {
    switch (source) {
      case RecommendSource.shelf:
        final drafts = await _fromShelfUnread(limit: limit);
        if (drafts.isEmpty) return const RecommendationBundle();
        return _enrichShelf(drafts, limit: limit);
      case RecommendSource.online:
        return _onlineBundle(keyword: keyword, limit: limit);
    }
  }

  // ── 来源一：自己的书架 ────────────────────────────────────────────────

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

  /// 书架档的收口。
  ///
  /// 这一档的候选本来就来自书架，所以：
  ///   - **不查重**（查重会把这一档全剔光）；
  ///   - **不联网补元数据**（见 [_toBook] 的理由）；
  ///   - 全部标成「已在书架」，不可勾选、不可入库。
  Future<RecommendationBundle> _enrichShelf(
    List<RecommendationDraft> drafts, {
    required int limit,
  }) async {
    final books = await Future.wait(
      drafts.take(limit).map((d) => _toBook(d, RecommendSource.shelf)),
    );
    final kept = <RecommendationDraft>[];
    for (final d in drafts.take(limit)) {
      kept.add(d);
    }
    final orders = _assignOrders(kept);
    final out = <Recommendation>[];
    for (var i = 0; i < books.length; i++) {
      final b = books[i];
      if (b == null) continue;
      out.add(Recommendation(
        book: b,
        reason: kept[i].reason ?? '',
        order: orders[i],
        source: RecommendSource.shelf,
        alreadyInShelf: true,
        group: kept[i].group,
      ));
    }
    return RecommendationBundle(items: out);
  }

  // ── 来源二：联网 ──────────────────────────────────────────────────────

  /// 联网档：把**本地书架里相关的书**与**网上找的新书**合成一份书单。
  ///
  /// ## 为什么本地书架的书要进联网档
  ///
  /// 用户说「我想读博弈论」，期待的是**一份这个主题的书单**。
  /// 如果他书架上已经有《策略思维》，而书单里只出现一堆他没听过的书，
  /// 他会以为「我连这本都没有」——这与事实相反。
  ///
  /// 所以联网档的书单 = **你有的（已在书架）+ 建议再读的（网上新书）**。
  /// 已在书架的那几本标成「已在书架」，不能勾选、不能入库
  /// （入库就是插一条重复记录）。
  ///
  /// ## 网上候选里书架已有的，一律剔掉
  ///
  /// 免得同一本书出现两次：一次在「你有的」段（用本地数据），
  /// 一次在「建议再读」段（用网上数据）。本地数据更准，以本地那份为准。
  /// 已经读完的书同样不该再被推荐。
  Future<RecommendationBundle> _onlineBundle({
    String? keyword,
    int limit = 8,
  }) async {
    // 1. 本地书架里与主题相关的书。
    final local = await _localMatches(keyword: keyword);

    // 2. 网上候选（带模型的导语）。
    final remote = await _fromOnline(keyword: keyword, limit: limit);

    // 3. 剔除书架已有的网上候选；本批内也要去重
    //    （模型偶尔把同一本书写两遍：不同译名、不同副标题）。
    perfMark('svc.shelfKeys.query');
    final shelfKeys = <String>{};
    for (final b in await repo.all()) {
      shelfKeys.add(_normTitle(b.title));
    }
    perfMark('svc.shelfKeys.done');
    final seenRemote = <String>{};
    final remoteDrafts = <RecommendationDraft>[];
    for (final d in remote.items) {
      final key = _normTitle(d.title);
      if (key.isEmpty) continue;
      if (shelfKeys.contains(key)) continue; // 书架里已有
      if (!seenRemote.add(key)) continue; // 本批里重复
      remoteDrafts.add(d);
    }

    // 4. 按模型给的阅读顺序排（没给 order 的排最后，随后由 [_assignOrders] 补位）。
    //
    //    ⚠️ 必须排：模型的 order 可能是 3、1、2（它知道哪本是入门哪本是进阶），
    //    不排的话列表顺序与序号徽章对不上——用户照着序号读会乱。
    remoteDrafts.sort((a, b) {
      final oa = a.order ?? (1 << 30);
      final ob = b.order ?? (1 << 30);
      return oa.compareTo(ob);
    });

    // 5. 网上候选补元数据（并发）。
    final books = await Future.wait(
      remoteDrafts.map((d) => _toBook(d, RecommendSource.online)),
    );

    // 5. 合并：本地在前（你的存量），网上在后（建议再读）。
    //
    //    ⚠️ 两段**各自编号**：本地段不编号（order=0，界面不画序号徽章），
    //    网上段从 1 开始。
    //    本地那几本是「你已经有了」，不是「推荐你接下来读」，
    //    混进阅读顺序里会让序号对不上「先读哪本」这件事。
    final out = <Recommendation>[];
    for (final b in local) {
      out.add(Recommendation(
        book: b,
        reason: (b.description ?? '').trim(),
        order: 0,
        source: RecommendSource.online,
        alreadyInShelf: true,
      ));
    }
    final orders = _assignOrders(remoteDrafts);
    for (var i = 0; i < books.length; i++) {
      final b = books[i];
      if (b == null) continue;
      out.add(Recommendation(
        book: b,
        reason: remoteDrafts[i].reason ?? '',
        order: orders[i],
        source: RecommendSource.online,
        alreadyInShelf: false,
        group: remoteDrafts[i].group,
      ));
    }

    return RecommendationBundle(intro: remote.intro, items: out);
  }

  /// 本地书架里与主题相关的书。
  ///
  /// 有关键词时按书名/作者/分类/简介/标签匹配；没关键词时取「想读」的书
  /// （已买未读，最可能想读的一批）。
  ///
  /// 最多 [_localMatchCap] 本：本地段是补充，不该把网上推荐的位置挤光。
  static const int _localMatchCap = 4;

  Future<List<Book>> _localMatches({String? keyword}) async {
    perfMark('svc.localMatches.start');
    final kw = (keyword ?? '').trim().toLowerCase();
    if (kw.isEmpty) {
      final books = await repo.all(
        status: BookStatus.wish,
        orderBy: 'createdAt DESC',
      );
      perfMark('svc.localMatches.done');
      return books.take(_localMatchCap).toList();
    }
    final books = await repo.all();
    final out = <Book>[];
    for (final b in books) {
      if (_matchesTopic(b, kw)) out.add(b);
      if (out.length >= _localMatchCap) break;
    }
    perfMark('svc.localMatches.done');
    return out;
  }

  /// 这本书和主题有没有关系。
  ///
  /// 书名、作者、分类、简介、标签都算——
  /// 只看书名会漏掉「简介里提到这个领域」的书。
  bool _matchesTopic(Book b, String needle) {
    final hay = <String>[
      b.title,
      ...b.authors,
      b.categoryPrimary ?? '',
      b.categoryRaw ?? '',
      b.description ?? '',
      ...b.tags,
    ];
    for (final h in hay) {
      if (h.toLowerCase().contains(needle)) return true;
    }
    return false;
  }

  /// 联网档的候选产出。
  ///
  /// 具体走哪条路子由 [onlinePlan] 决定，用户不需要（也无权）干预。
  Future<DraftBundle> _fromOnline({
    String? keyword,
    int limit = 8,
  }) async {
    switch (onlinePlan) {
      case OnlinePlan.searchAndModel:
        return _fromSearch(keyword: keyword, limit: limit);
      case OnlinePlan.modelOnly:
        return _fromLlm(keyword: keyword, limit: limit);
      case OnlinePlan.wereadOnly:
        return _fromWeread(keyword: keyword, limit: limit);
      case null:
        return const DraftBundle();
    }
  }

  /// 让大模型凭训练知识推荐。
  ///
  /// 喂给它的只有**本地画像摘要**（分类占比、作者偏好频次），
  /// 不含任何书名——书名属于用户数据，推荐没必要知道具体是哪几本。
  /// 摘要本身是本地统计出来的，只传统计结果不传明细。
  Future<DraftBundle> _fromLlm({
    String? keyword,
    int limit = 8,
  }) async {
    if (!llm.available) return const DraftBundle();
    final profile = await _profileSummary();
    final raw = await llm.chat([
      {'role': 'system', 'content': _llmSystemPrompt()},
      {'role': 'user', 'content': _buildUserPrompt(profile, keyword, limit)},
    ], temperature: 0.7, jsonMode: true);
    final bundle = RecommendationDraft.parseBundle(raw);
    return DraftBundle(
      intro: bundle.intro,
      items: bundle.items.take(limit).toList(),
    );
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
      '1. 只输出 JSON 对象，不要任何解释文字或代码块标记。格式：\n'
      '   {"intro": "一段选书指南", "items": [{"title": "...", "author": "...", '
      '"reason": "...", "category": "...", "order": 1, "group": "..."}]}\n'
      '2. **intro 是一段总体介绍**（2~4 句，120 字以内）：\n'
      '   这批书分成哪几条线、先读哪本合适、适合什么样的读者。\n'
      '   例：「博弈论书籍分两条线：通俗读物培养策略直觉，教材走理论体系。'
      '先定自己是想看懂生活里的博弈，还是真学一门分析工具，再挑书。」\n'
      '   它是给读者的**导读**，不是复述书名。\n'
      '3. 每个条目包含 title、author、reason、category、order 五个字段。\n'
      '4. reason 用一句话说明这本书好在哪、为什么推给这位读者（不超过 40 字）。\n'
      '5. **order 是建议的阅读顺序**，从 1 开始按「先入门、再进阶、最后深入」排；\n'
      '   同一难度层次的书顺序可以随意，但不要重复。\n'
      '6. group 可选：若这批书天然分几档（如「零基础通俗入门」「系统学习」），\n'
      '   就给同一档的书写**完全相同**的 group 值；不需要分组就省略这个字段。\n'
      '7. 不要推荐读者已经拥有的书。\n'
      '8. 推荐真实存在的书，不要编造。';

  String _buildUserPrompt(String profile, String? keyword, int limit) {
    final buf = StringBuffer()
      ..writeln('读者画像：$profile');
    final topic = keyword?.trim() ?? '';
    if (topic.isNotEmpty) {
      buf.writeln('读者感兴趣的主题：$topic');
      buf.writeln('请围绕这个主题推荐，并按由浅入深的顺序排列。');
    } else {
      buf.writeln('读者没有指定主题，请根据画像选一个合适的方向，并按由浅入深排序。');
    }
    buf.write('请推荐 $limit 本书。');
    return buf.toString();
  }

  // ── 档③：微信读书书城 ───────────────────────────────────────────────

  /// 直接搜微信读书书城。
  ///
  /// 没有关键词时给一个**由本地画像算出的关键词**去搜——
  /// 书城搜索需要关键词，空搜没有意义。
  Future<DraftBundle> _fromWeread({
    String? keyword,
    int limit = 8,
  }) async {
    if (!weread.available) return const DraftBundle();
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
    return DraftBundle(items: out);
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
  Future<DraftBundle> _fromSearch({
    String? keyword,
    int limit = 8,
  }) async {
    if (!search.available || !llm.available) return const DraftBundle();

    final kw = _effectiveKeyword(keyword, await _topCategoryKeyword());

    final hits = await search.search(_searchQuery(kw), count: limit * 3);
    if (hits.isEmpty) return const DraftBundle();

    // 把搜索结果交给大模型：只让它挑书名和写理由，不让它自由发挥。
    final raw = await llm.chat([
      {'role': 'system', 'content': _searchLlmSystemPrompt()},
      {'role': 'user', 'content': _buildSearchPrompt(kw, hits, limit)},
    ], temperature: 0.4, jsonMode: true);
    final bundle = RecommendationDraft.parseBundle(raw);
    return DraftBundle(
      intro: bundle.intro,
      items: bundle.items.take(limit).toList(),
    );
  }

  String _searchLlmSystemPrompt() =>
      '你是一位选书编辑。下面给你的是搜索引擎返回的候选网页标题与摘要。\n'
      '请从中挑出**真实存在且值得推荐**的书籍，整理成一份书单。\n'
      '要求：\n'
      '1. 只输出 JSON 对象，不要解释文字。格式：\n'
      '   {"intro": "一段选书指南", "items": [{"title": "...", "author": "...", '
      '"reason": "...", "category": "...", "order": 1, "group": "..."}]}\n'
      '2. **intro 是一段总体介绍**（2~4 句，120 字以内）：\n'
      '   这批书怎么组织、先读哪本合适、适合什么样的读者。\n'
      '   它是给读者的**导读**，不是复述书名。\n'
      '3. 每个条目包含 title、author（可选）、reason、category（可选）、order。\n'
      '4. reason 说明这本书好在哪、适合什么样的读者（一句话，40 字内）。\n'
      '5. **order 是建议的阅读顺序**，从 1 开始按「先入门、再进阶、最后深入」排；\n'
      '   同一难度层次的书顺序可以随意，但不要重复。\n'
      '6. group 可选：若这批书天然分几档（如「零基础通俗入门」「系统学习」），\n'
      '   就给同一档的书写**完全相同**的 group 值；不需要分组就省略这个字段。\n'
      '7. **只从候选里挑**，不要加入候选之外的书。\n'
      '8. 候选里没有明确书名的条目直接跳过。';

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

  // ── 收口辅助 ─────────────────────────────────────────────────────────

  /// 给候选分配阅读顺序。
  ///
  /// 大模型给了 order 就用它（它知道哪本是入门哪本是进阶）；
  /// 没给就按出现顺序补上——**顺序信息缺失不该让整份书单看起来没有顺序**。
  ///
  /// 补位时跳过已被占用的号，避免出现「1、1、3」这种编号。
  static List<int> _assignOrders(List<RecommendationDraft> drafts) {
    final out = List<int>.filled(drafts.length, 0);
    final taken = <int>{};

    // 先放模型给的
    for (var i = 0; i < drafts.length; i++) {
      final o = drafts[i].order;
      if (o != null && o > 0 && !taken.contains(o)) {
        out[i] = o;
        taken.add(o);
      }
    }
    // 剩下的按出现顺序补
    var next = 1;
    for (var i = 0; i < drafts.length; i++) {
      if (out[i] != 0) continue;
      while (taken.contains(next)) {
        next++;
      }
      out[i] = next;
      taken.add(next);
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

    // 书架那档**不去网上补元数据**。
    //
    // 两个理由，第二个更要命：
    // 一是慢——网络不可达时每本都要等满超时；
    // 二是**会用网络版本的作者/简介覆盖用户自己填的内容**。
    // 候选本来就来自书架，作者、简介、分类、封面全都在，
    // 拿网上的版本去覆盖等于用低质量数据污染用户的数据。
    if (source != RecommendSource.shelf) {
      try {
        final m = await metadata
            .lookup(title, author: d.author)
            .timeout(_enrichTimeout, onTimeout: () => null);
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
      source: (source == RecommendSource.online &&
              onlinePlan == OnlinePlan.wereadOnly)
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
