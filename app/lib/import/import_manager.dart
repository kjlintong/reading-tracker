import '../models/book.dart';
import '../l10n/app_loc.dart';
import '../models/enums.dart';
import '../data/database.dart';
import '../ai/ai_client.dart';
import 'llm_shelf_parser.dart';
import 'ocr_line.dart';
import 'shelf_layout.dart';
import 'shelf_ocr_parser.dart';

/// 导入结果统计
class ImportResult {
  final int added;      // 新增
  final int duplicated; // 已存在，跳过
  final int failed;     // 失败
  final List<Book> books;

  ImportResult({
    this.added = 0,
    this.duplicated = 0,
    this.failed = 0,
    this.books = const [],
  });

  ImportResult operator +(ImportResult other) => ImportResult(
        added: added + other.added,
        duplicated: duplicated + other.duplicated,
        failed: failed + other.failed,
        books: [...books, ...other.books],
      );
}

/// 识别阶段做了什么，给确认页展示用
class OcrDiagnostics {
  final int totalLines;
  final int keptLines;
  final bool usedLlm;
  final bool usedLayout;
  final int repairedTitles;

  const OcrDiagnostics({
    this.totalLines = 0,
    this.keptLines = 0,
    this.usedLlm = false,
    this.usedLayout = false,
    this.repairedTitles = 0,
  });
}

/// 导入中心：把各种来源的候选书统一去重、补全元数据后写入本地库
class ImportManager {
  final BookRepository repo;
  final MetadataClient metadata;
  final LlmClient llm;

  /// 是否在公开源落空时用 LLM 兜底补全（会消耗 token，默认关闭）
  bool llmFallback;

  /// 截图识别时是否允许调用大模型整理 OCR 文本
  bool ocrUseLlm;

  ImportManager({
    required this.repo,
    required this.metadata,
    required this.llm,
    this.llmFallback = false,
    this.ocrUseLlm = true,
  });

  /* ---------------------------- 截图识别链路 ---------------------------- */

  /// 截图 OCR 文本 → 书名候选（纯文本入口，保留给测试与降级路径）
  Future<List<TitleCandidate>> parseScreenshot(String ocrText) async {
    return ShelfOcrParser.extract(ocrText);
  }

  /// 完整识别链路：几何布局解析 → 大模型整理 → 权威源补齐截断标题。
  ///
  /// 三步的顺序是有讲究的：
  /// 1. **布局解析**解决「这行文字属于哪本书」，纯文本做不到；
  /// 2. 再让**大模型**挑出真正的书并补全书名，它擅长判断语义、不擅长数字；
  /// 3. 最后用**微信读书书城**实测补齐被截断的标题——模型会说得很像真的，
  ///    但只有权威源的搜索结果能证明这本书确实存在。
  Future<({List<TitleCandidate> candidates, OcrDiagnostics diag})>
      recognizeFromLines(
    List<OcrLine> lines, {
    OcrMode mode = OcrMode.shelf,
    bool? useLlm,
    void Function(String stage)? onStage,
  }) async {
    final totalLines = lines.length;

    onStage?.call(appLoc.s_ebf4bdfb);
    final layout = ShelfLayoutParser.parse(lines, mode: mode);
    // 几何信息不可用时布局解析内部会自动退化成文本解析，
    // 这里只在它彻底没结果时才再跑一次纯文本路径。
    var candidates = layout.isNotEmpty
        ? layout
        : ShelfOcrParser.extract(lines.map((l) => l.text).join('\n'));

    final wantLlm = (useLlm ?? ocrUseLlm) && llm.available && lines.isNotEmpty;
    var usedLlm = false;
    if (wantLlm) {
      onStage?.call(appLoc.s_ba1038b1);
      final smart = await LlmShelfParser(llm).structure(lines, mode: mode);
      if (smart != null && smart.isNotEmpty) {
        usedLlm = true;
        candidates = _mergeCandidates(candidates, smart);
      }
    }

    onStage?.call(appLoc.s_6292a274);
    final repaired = await repairTitles(candidates);

    return (
      candidates: repaired,
      diag: OcrDiagnostics(
        totalLines: totalLines,
        keptLines: candidates.length,
        usedLlm: usedLlm,
        usedLayout: layout.isNotEmpty,
        repairedTitles: repaired.where((c) => c.inferred).length,
      ),
    );
  }

  /// 把大模型结果并回本地结果。
  ///
  /// 同一本书以**大模型的书名**为准（它会把「雅思口语深…」补成完整书名），
  /// 但进度、状态这类结构化字段优先保留本地读到的值——那是从图里
  /// 直接抽出来的数字，比模型的转述可靠。
  static List<TitleCandidate> _mergeCandidates(
    List<TitleCandidate> local,
    List<TitleCandidate> smart,
  ) {
    String norm(String s) =>
        s.replaceAll(RegExp(appLoc.s_427e1f0d), '').toLowerCase();

    final out = <TitleCandidate>[...smart];
    final used = <int>{};
    for (final l in local) {
      final key = norm(l.title);
      var hit = -1;
      for (var i = 0; i < out.length; i++) {
        if (used.contains(i)) continue;
        final k = norm(out[i].title);
        if (k.isEmpty || key.isEmpty) continue;
        if (k == key || k.startsWith(key) || key.startsWith(k)) {
          hit = i;
          break;
        }
      }
      if (hit < 0) {
        out.add(l);
        continue;
      }
      used.add(hit);
      final s = out[hit];
      // 模型补出的书名以它为准，但原文更长的说明模型把噪音也读进去了
      if (l.title.length > s.title.length && !s.inferred) {
        s.title = l.title;
      }
      s.progressPercent ??= l.progressPercent;
      s.statusHint ??= l.statusHint;
      s.author ??= l.author;
      s.truncated = s.truncated || l.truncated;
      if (l.score > s.score) s.score = l.score;
    }
    return out;
  }

  /// 用权威源补齐「被界面截断」的书名。
  ///
  /// 这是截图导入里最容易留下废数据的一环：微信读书/掌阅的书架卡片会把长书名
  /// 截成「雅思口语深…」，OCR 只能忠实照抄。截断的标题既搜不到元数据，
  /// 在书架上也无法辨认，必须先补全。
  ///
  /// 只对**明确截断**或**大模型推测过**的条目联网核对，其余留给用户手改——
  /// 一次截图里几十本，逐本发搜索请求既慢又没必要。
  Future<List<TitleCandidate>> repairTitles(
    List<TitleCandidate> input, {
    int maxLookups = 12,
    void Function(int done, int total)? onProgress,
  }) async {
    final urgent = <int>[];
    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (c.truncated || c.inferred) urgent.add(i);
    }
    final targets = urgent.take(maxLookups).toList();

    var done = 0;
    for (final i in targets) {
      final c = input[i];
      onProgress?.call(done, targets.length);
      try {
        final resolved =
            await metadata.resolveTitle(c.title, author: c.author);
        if (resolved != null && resolved.trim().isNotEmpty) {
          final t = resolved.trim();
          if (t != c.title) {
            c.rawText = c.rawText.isEmpty ? c.title : c.rawText;
            c.title = t;
            c.inferred = true;
            // 补齐后的书名是经过权威源确认的，可信度上调
            c.score = (c.score + 0.2).clamp(0.0, 0.98);
            c.reason = c.reason.isEmpty ? appLoc.s_af041a1b : appLoc.s_988dd5cb(reason: c.reason);
          } else {
            // 搜到的就是它本身——说明没被截断，去掉误报
            c.truncated = false;
            c.score = (c.score + 0.1).clamp(0.0, 0.98);
          }
        }
      } catch (_) {
        // 单个核对失败不影响其它条目
      }
      done++;
    }
    onProgress?.call(targets.length, targets.length);
    return input;
  }

  /* ---------------------------- 微信读书 ---------------------------- */

  /// 从微信读书官方接口导入书架
  ///
  /// 书架接口能给出「读完没有 / 有没有读过 / 什么时候加入书架」，
  /// 但**给不出阅读百分比**——那个必须逐本调 `/book/getprogress`，
  /// 55 本就是 55 次请求，所以默认不拉，由 [syncProgress] 单独按需触发。
  Future<List<Book>> fetchWereadShelf(WereadGateway gateway) async {
    final raw = await gateway.shelf();
    return raw.map((b) {
      final m = WereadGateway.toMeta(b);
      final addedAt = m['addedAt'] as String?;
      final lastReadAt = m['lastReadAt'] as String?;
      final status = m['status'] as BookStatus? ?? BookStatus.wish;
      return Book.create(
        title: (m['title'] as String?) ?? '',
        source: BookSource.weread,
      ).copyWith(
        authors: _authorList(m['authors']),
        publisher: m['publisher'] as String?,
        coverUrl: m['coverUrl'] as String?,
        description: m['description'] as String?,
        categoryRaw: m['categoryRaw'] as String?,
        sourceBookId: m['sourceBookId'] as String?,
        sourceUrl: m['sourceUrl'] as String?,
        status: status,
        wordCount: (m['wordCount'] as num?)?.toInt(),
        // 只有确实读过的书才该有开始时间。未读的书 readUpdateTime 也有值
        // （可能是入架前的历史时间），直接写进 startedAt 会凭空造出阅读记录。
        startedAt: status == BookStatus.reading ? lastReadAt : null,
        extra: {
          if (addedAt != null) 'wereadAddedAt': addedAt,
          if (lastReadAt != null) 'wereadLastReadAt': lastReadAt,
        },
      ).withNormalizedCategory();
    }).where((b) => b.title.isNotEmpty).toList();
  }

  /// 逐本拉取阅读进度并回写。
  ///
  /// 书架接口不含进度，只能一本一本地问，因此这个动作是显式触发的、
  /// 有进度回调的，让用户看得到它在做什么、也能中途了解还剩多少。
  /// 单本失败只跳过该本，不中断整批。
  Future<int> syncProgress(
    List<String> sourceBookIds, {
    required WereadGateway gateway,
    void Function(int done, int total)? onProgress,
  }) async {
    var updated = 0;
    for (var i = 0; i < sourceBookIds.length; i++) {
      final id = sourceBookIds[i];
      onProgress?.call(i, sourceBookIds.length);
      try {
        final p = await gateway.progressOf(id);
        final existing = await repo.bySourceBookId(id, BookSource.weread);
        if (existing == null) continue;

        await repo.update(existing.copyWith(
          progressPercent: p.progressPercent,
          // 进度 >0 或已标记开始阅读，就认为确实在读；
          // 不改「已读」状态——那是用户自己的判断
          status: existing.status == BookStatus.finished
              ? BookStatus.finished
              : (p.isStartReading || p.progress > 0
                  ? BookStatus.reading
                  : existing.status),
          currentPage: p.chapterIdx,
          extra: {
            ...existing.extra,
            if (p.readingTimeSec > 0) 'wereadReadingTimeSec': p.readingTimeSec,
            if (p.updateAt != null) 'wereadProgressUpdatedAt': p.updateAt,
          },
        ));
        updated++;
      } catch (_) {
        // 单本失败跳过，继续下一本
      }
    }
    onProgress?.call(sourceBookIds.length, sourceBookIds.length);
    return updated;
  }

  /// 微信读书把多个作者拼在一个字符串里，换行/顿号分隔的也常见
  static List<String> _authorList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      final out = <String>[];
      for (final e in v) {
        out.addAll(_splitAuthors(e.toString()));
      }
      return out;
    }
    return _splitAuthors(v.toString());
  }

  static List<String> _splitAuthors(String s) => s
      .split(RegExp(appLoc.s_a746d189))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /* ---------------------------- 入库 ---------------------------- */

  /// 把一组书去重后写入本地库
  ///
  /// 分类归一化在这里统一做——它是所有导入路径（微信读书 / OCR / CSV）的
  /// 唯一收口，放在这里就不会出现「某条链路忘了归一化」导致统计口径分裂。
  /// 幂等，重复调用不会改变结果。
  Future<ImportResult> commit(
    List<Book> books, {
    bool enrichMetadata = true,
    void Function(int done, int total)? onProgress,
    List<String>? failures,
  }) async {
    int added = 0, duplicated = 0, failed = 0;
    final committed = <Book>[];

    for (var i = 0; i < books.length; i++) {
      onProgress?.call(i, books.length);
      // 入口先归一化一次：数据源给的是自有分类体系（经济理财 / 个人成长…）
      var book = books[i].withNormalizedCategory();
      try {
        // 1) 去重
        final dup = await repo.findDuplicate(book);
        if (dup != null) {
          // 已存在：只补齐缺失字段，不覆盖用户已填内容
          book = _mergeIntoExisting(dup, book).withNormalizedCategory();
          await repo.update(book);
          duplicated++;
          committed.add(book);
          continue;
        }

        // 2) 元数据补全（补回来的分类同样是数据源原始值，需要再归一化）
        if (enrichMetadata) {
          book = (await _enrich(book)).withNormalizedCategory();
        }

        // 3) 入库
        await repo.insert(book);
        added++;
        committed.add(book);
      } catch (e) {
        // 单本失败不应中断整批，但原因必须留痕——否则用户只看到
        // 「失败 3 本」却无从判断是网络、限流还是数据本身的问题
        failed++;
        failures?.add(appLoc.s_a4ec75fd(title: book.title.isEmpty ? book.id : book.title, e: e));
      }
    }
    onProgress?.call(books.length, books.length);
    return ImportResult(
      added: added, duplicated: duplicated, failed: failed, books: committed);
  }

  /// 单本补全（公开源链式 → LLM 兜底）
  Future<Book> _enrich(Book book) async {
    final m = await metadata.lookup(book.title,
        author: book.authors.isNotEmpty ? book.authors.first : null);

    if (m != null) {
      book = book.copyWith(
        authors: book.authors.isEmpty && m.authors.isNotEmpty ? m.authors : null,
        publisher: book.publisher ?? m.publisher,
        publishedAt: book.publishedAt ?? m.publishedAt,
        description: book.description ?? m.description,
        categoryPrimary: book.categoryPrimary ?? m.categoryPrimary,
        coverUrl: book.coverUrl ?? m.coverUrl,
        isbn13: book.isbn13 ?? m.isbn13,
        pageCount: book.pageCount ?? m.pageCount,
        tags: book.tags.isEmpty && m.tags.isNotEmpty ? m.tags : null,
      );
    }

    if (llmFallback &&
        llm.available &&
        (book.categoryPrimary == null || book.description == null)) {
      final inferred = await llm.inferMetadata(
        book.title,
        author: book.authors.isNotEmpty ? book.authors.first : null,
      );
      if (inferred != null) {
        book = book.copyWith(
          categoryPrimary: book.categoryPrimary ?? inferred['categoryPrimary'] as String?,
          description: book.description ?? inferred['description'] as String?,
          tags: book.tags.isEmpty
              ? (inferred['tags'] as List?)?.map((e) => e.toString()).toList()
              : null,
          authors: book.authors.isEmpty
              ? (inferred['authors'] as List?)?.map((e) => e.toString()).toList()
              : null,
        );
      }
    }
    return book;
  }

  /// 已存在记录的增量合并：只填补空缺，绝不覆盖用户已填内容
  Book _mergeIntoExisting(Book existing, Book incoming) {
    return existing.copyWith(
      subtitle: existing.subtitle ?? incoming.subtitle,
      authors: existing.authors.isEmpty ? incoming.authors : null,
      translators: existing.translators.isEmpty ? incoming.translators : null,
      publisher: existing.publisher ?? incoming.publisher,
      publishedAt: existing.publishedAt ?? incoming.publishedAt,
      isbn13: existing.isbn13 ?? incoming.isbn13,
      coverUrl: existing.coverUrl ?? incoming.coverUrl,
      categoryPrimary: existing.categoryPrimary ?? incoming.categoryPrimary,
      description: existing.description ?? incoming.description,
      pageCount: existing.pageCount ?? incoming.pageCount,
      wordCount: existing.wordCount ?? incoming.wordCount,
      tags: existing.tags.isEmpty ? incoming.tags : null,
      summary: existing.summary ?? incoming.summary,
      review: existing.review ?? incoming.review,
    );
  }
}
