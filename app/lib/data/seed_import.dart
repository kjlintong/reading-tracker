import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/book.dart';
import '../models/enums.dart';
import 'database.dart';

/// 种子数据导入。
///
/// 随包发布 `assets/seed/library.json`（38 本合成示例书，分类与简介覆盖率
/// 100%），首次启动时自动灌库。
///
/// 用合成数据而不是真实书库：仓库是公开的，真实书单里的阅读偏好、私人页码、
/// 平台内部 ID 都指向一个具体的人（生成脚本见 tools/gen-sample-library.py）。
/// 用户打开 App 依然能看到形态完整的示例书架与统计，而不是空列表。
///
/// 导入是幂等的：通过 settings 表里的 seedVersion 记录版本，
/// 已导入过则跳过。用户后续在 App 内的修改不会被覆盖。
class SeedImporter {
  static const String _assetPath = 'assets/seed/library.json';

  /// 种子数据版本。数据重新生成后需递增，否则老用户不会更新。
  ///
  /// v2026-09-30.1：换用合成示例书库（数据脱敏），真实书单不再随包发布。
  /// v2026-09-29.2：附带 categoryRaw 回填。早期版本导入时 Book 还没有
  /// 这个字段，数据源原始分类被丢弃；递增版本号让老装机重跑一次导入，
  /// 按 id 精确补回原始分类并重跑归一化。
  static const String _seedVersion = '2026-09-30.1';

  final BookRepository _repo;
  SeedImporter(this._repo);

  /// 若尚未导入过当前版本，则执行导入。
  ///
  /// 返回本次实际新增的书本数；已导入过返回 0。
  Future<int> importIfNeeded() async {
    final done = await _repo.getSetting('seedVersion');
    if (done == _seedVersion) return 0;

    final raw = await rootBundle.loadString(_assetPath);
    if (raw.isEmpty) return 0;

    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return 0;
    }

    final added = await _importBooks(payload);
    await _importNotes(payload);
    await _importStats(payload);

    await _repo.setSetting('seedVersion', _seedVersion);
    return added;
  }

  /// 强制重新导入（设置页「重置示例数据」用）
  Future<int> forceImport() async {
    await _repo.setSetting('seedVersion', '');
    return importIfNeeded();
  }

  Future<int> _importBooks(Map<String, dynamic> payload) async {
    final list = payload['books'];
    if (list is! List) return 0;

    final books = <Book>[];
    // id → 数据源原始分类，用于给早期导入的记录补回 categoryRaw
    final rawById = <String, String>{};

    for (final item in list) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      // Node 侧生成的记录里，数值字段可能是 int；Book.fromMap 已用 num 兼容，
      // 但 rating / progressPercent 在此显式归一，避免 SQLite 类型歧义。
      books.add(Book.fromMap(map).withNormalizedCategory());

      final id = map['id'] as String?;
      final raw = (map['categoryRaw'] as String?)?.trim();
      if (id != null && raw != null && raw.isNotEmpty) rawById[id] = raw;
    }

    final added = await _repo.insertMany(books);

    // insertMany 会跳过已存在的 id，所以老装机的记录不会被上面这批带上。
    // 这里按 id 精确补回 categoryRaw，并重跑一次归一化——
    // 只填空缺字段，不触碰用户自己改过的书名/评分/笔记。
    if (rawById.isNotEmpty) {
      for (final b in await _repo.all()) {
        if (b.categoryRaw != null) continue;
        final raw = rawById[b.id];
        if (raw == null) continue;
        await _repo.update(b.copyWith(
          categoryRaw: raw,
          categoryPrimary: normalizeCategory(raw),
        ));
      }
    }
    return added;
  }

  /// Notion 的 Quotes 库以书名+作者关联，没有 bookId。
  /// 这里按书名精确匹配回落到书籍 id；匹配不到则丢弃（宁缺勿错挂）。
  Future<int> _importNotes(Map<String, dynamic> payload) async {
    final list = payload['notes'];
    if (list is! List) return 0;

    // 建立 书名 → id 索引，一次查询避免逐条查库
    final all = await _repo.all();
    final byTitle = <String, String>{};
    for (final b in all) {
      byTitle.putIfAbsent(b.title.trim(), () => b.id);
    }

    int added = 0;
    for (final item in list) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final title = (m['bookTitle'] as String?)?.trim() ?? '';
      final bookId = byTitle[title];
      if (bookId == null) continue;

      final note = Note(
        id: m['id'] as String? ?? 'note_${DateTime.now().microsecondsSinceEpoch}',
        bookId: bookId,
        type: NoteTypeX.fromString(m['type'] as String?),
        content: m['content'] as String? ?? '',
        chapter: m['chapter'] as String?,
        pageAt: m['pageAt'] as int?,
        source: BookSource.fromString(m['source'] as String?),
        createdAt: m['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );
      await _repo.addNote(note);
      added++;
    }
    return added;
  }

  /// 微信读书年度统计（总时长、天数、读得最久的书）存入 settings。
  ///
  /// 这些是聚合数据，无法拆解到单本书的阅读日志，硬塞进 reading_logs
  /// 会虚构出不存在的时间序列，因此原样保存，供报告页直接展示。
  Future<void> _importStats(Map<String, dynamic> payload) async {
    final stats = payload['stats'];
    if (stats is Map) {
      await _repo.setSetting('wereadAnnualStats', jsonEncode(stats));
    }
    final meta = payload['shelfMeta'];
    if (meta is Map) {
      await _repo.setSetting('wereadShelfMeta', jsonEncode(meta));
    }
  }
}
