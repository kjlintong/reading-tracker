import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// 桌面端与移动端共用 sqflite_common_ffi，其已覆盖 sqflite 的全部 API，
// 重复导入 sqflite 会触发 unnecessary_import 告警
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/book.dart';
import '../models/enums.dart';
import 'weread_annual.dart';

/// 本地 SQLite 数据库。
///
/// 本地优先架构：无需账号、无需联网即可完整使用。数据库文件位于应用
/// 私有目录，桌面端（Windows/macOS/Linux）通过 sqflite_common_ffi 走 SQLite。
class AppDatabase {
  static const _dbName = 'reading_tracker.db';
  /// v2：books 增加 categoryRaw 列，并对历史数据重跑分类归一化
  static const _version = 2;

  Database? _db;
  Database get db => _db!;

  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  /// 测试专用：直接注入一个已打开的（通常为内存）数据库，
  /// 绕开 path_provider —— 后者在 flutter_test 环境下不可用。
  AppDatabase.forTest(Database db) : _db = db;

  Future<void> init() async {
    if (_db != null) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) => createSchema(db),
      onUpgrade: _onUpgrade,
    );
  }

  /// 建表。独立于 init 暴露，供测试在内存库上复现同一套 schema，
  /// 避免测试表结构与线上出现分歧。
  Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        subtitle TEXT,
        authors TEXT,
        translators TEXT,
        publisher TEXT,
        publishedAt TEXT,
        isbn13 TEXT,
        coverUrl TEXT,
        coverLocalPath TEXT,
        categoryPrimary TEXT,
        categoryRaw TEXT,
        categoryPath TEXT,
        tags TEXT,
        description TEXT,
        language TEXT,
        pageCount INTEGER,
        wordCount INTEGER,
        format TEXT,
        source TEXT,
        sourceBookId TEXT,
        sourceUrl TEXT,
        status TEXT,
        progressPercent REAL,
        currentPage INTEGER,
        rating REAL,
        review TEXT,
        summary TEXT,
        highlights TEXT,
        startedAt TEXT,
        finishedAt TEXT,
        borrowedFrom TEXT,
        dueAt TEXT,
        rereadCount INTEGER DEFAULT 0,
        extra TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_books_status ON books(status)');
    await db.execute('CREATE INDEX idx_books_source ON books(source)');
    await db.execute('CREATE INDEX idx_books_category ON books(categoryPrimary)');
    await db.execute('CREATE INDEX idx_books_finished ON books(finishedAt)');

    await db.execute('''
      CREATE TABLE reading_logs (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        date TEXT NOT NULL,
        durationMin INTEGER DEFAULT 0,
        pagesFrom INTEGER,
        pagesTo INTEGER,
        note TEXT,
        source TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_logs_date ON reading_logs(date)');
    await db.execute('CREATE INDEX idx_logs_book ON reading_logs(bookId)');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        type TEXT,
        content TEXT,
        chapter TEXT,
        pageAt INTEGER,
        source TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_notes_book ON notes(bookId)');

    await db.execute('''
      CREATE TABLE import_batches (
        id TEXT PRIMARY KEY,
        source TEXT,
        method TEXT,
        itemCount INTEGER,
        rawRef TEXT,
        status TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE llm_reports (
        id TEXT PRIMARY KEY,
        period TEXT,
        model TEXT,
        content TEXT,
        metrics TEXT,
        generatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute('ALTER TABLE books ADD COLUMN categoryRaw TEXT');
      await renormalizeCategories(db: db);
    }
  }

  /// 把历史数据的分类重新过一遍归一化。
  ///
  /// 两类用途：
  /// 1. v1 → v2 迁移。v1 的导入链路还没接入归一化，`categoryPrimary` 里
  ///    存的其实是数据源原始分类（经济理财 / 个人成长…），与种子数据里
  ///    已归一化的值混在一起，统计口径不一致。
  /// 2. 将来受控词表或别名映射扩充后，想让历史数据跟上——那时用 `force: true`
  ///    基于 `categoryRaw` 重跑，原始分类始终留着，所以随时可重算。
  ///
  /// 默认只处理「当前值不在受控词表内」的行，即真正从没归一化过的。
  /// 已经是受控值的行一律不碰：那可能是种子数据（它自带更精确的原始分类，
  /// 由 SeedImporter 按 id 回填），也可能是用户自己改的，都不该在这里被改写。
  ///
  /// 返回实际改动的行数。
  ///
  /// [db] 用于在 openDatabase 的 onUpgrade 回调里传入正在升级的连接
  /// ——那时 `_db` 还没赋值。
  Future<int> renormalizeCategories({Database? db, bool force = false}) async {
    final target = db ?? _db;
    if (target == null) return 0;

    final rows = await target.query(
      'books',
      columns: ['id', 'categoryPrimary', 'categoryRaw'],
    );
    if (rows.isEmpty) return 0;

    final batch = target.batch();
    var changed = 0;
    for (final r in rows) {
      final cur = (r['categoryPrimary'] as String?)?.trim();
      final raw = (r['categoryRaw'] as String?)?.trim();

      final String source;
      if (force) {
        // 从原始分类重算；没有原始值的行跳过（无从重算）
        if (raw == null || raw.isEmpty) continue;
        source = raw;
      } else {
        // 已经是受控值 → 已经归一化过，交给更精确的来源处理
        if (cur != null && defaultCategories.contains(cur)) continue;
        source = (raw != null && raw.isNotEmpty) ? raw : (cur ?? '');
        if (source.isEmpty) continue;
      }

      final normalized = normalizeCategory(source);
      if (normalized == null) continue;
      if (normalized == cur && raw == source) continue;

      batch.update(
        'books',
        {'categoryRaw': source, 'categoryPrimary': normalized},
        where: 'id = ?',
        whereArgs: [r['id']],
      );
      changed++;
    }
    if (changed > 0) await batch.commit(noResult: true);
    return changed;
  }
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

/// 书籍数据访问层
class BookRepository {
  final AppDatabase _database;
  BookRepository(this._database);

  Database get _db => _database.db;

  Future<List<Book>> all({
    BookStatus? status,
    BookSource? source,
    String? category,
    String? tag,
    String? keyword,
    String orderBy = 'updatedAt DESC',
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (status != null) { where.add('status = ?'); args.add(status.name); }
    if (source != null) { where.add('source = ?'); args.add(source.name); }
    if (category != null) { where.add('categoryPrimary = ?'); args.add(category); }
    if (tag != null) { where.add('tags LIKE ?'); args.add('%"$tag"%'); }
    if (keyword != null && keyword.isNotEmpty) {
      where.add('(title LIKE ? OR authors LIKE ? OR publisher LIKE ?)');
      final k = '%$keyword%';
      args.addAll([k, k, k]);
    }

    final rows = await _db.query(
      'books',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
    );
    return rows.map(Book.fromMap).toList();
  }

  Future<Book?> byId(String id) async {
    final rows = await _db.query('books', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Book.fromMap(rows.first);
  }

  /// 按「来源平台 + 该平台自己的书籍 id」查书。
  ///
  /// 回写阅读进度时用：进度接口只认微信读书的 bookId，
  /// 得先把它映射回本地记录。
  Future<Book?> bySourceBookId(String sourceBookId, BookSource source) async {
    final rows = await _db.query(
      'books',
      where: 'sourceBookId = ? AND source = ?',
      whereArgs: [sourceBookId, source.name],
      limit: 1,
    );
    return rows.isEmpty ? null : Book.fromMap(rows.first);
  }

  /// 按指纹查重：导入时避免同一本书产生多条记录
  Future<Book?> findDuplicate(Book book) async {
    if (book.isbn13 != null && book.isbn13!.isNotEmpty) {
      final r = await _db.query('books',
          where: 'isbn13 = ?', whereArgs: [book.isbn13], limit: 1);
      if (r.isNotEmpty) return Book.fromMap(r.first);
    }
    final r = await _db.query(
      'books',
      where: 'title = ? AND authors = ?',
      whereArgs: [book.title, _encodeAuthors(book.authors)],
      limit: 1,
    );
    return r.isEmpty ? null : Book.fromMap(r.first);
  }

  Future<void> insert(Book book) async {
    await _db.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 批量写入，返回真正新增的数量（已存在则跳过）
  Future<int> insertMany(List<Book> books, {bool skipDuplicates = true}) async {
    int added = 0;
    await _db.transaction((txn) async {
      for (final b in books) {
        if (skipDuplicates) {
          final exists = await txn.query('books',
              where: 'id = ?', whereArgs: [b.id], limit: 1);
          if (exists.isNotEmpty) continue;
        }
        await txn.insert('books', b.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        added++;
      }
    });
    return added;
  }

  Future<void> update(Book book) async {
    await _db.update('books', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<void> delete(String id) async {
    await _db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  /* ------------------------- 统计 ------------------------- */

  /// 状态分布
  Future<Map<BookStatus, int>> statusCounts() async {
    final rows = await _db.rawQuery('SELECT status, COUNT(*) c FROM books GROUP BY status');
    return {
      for (final r in rows)
        BookStatus.fromString(r['status'] as String?): (r['c'] as int?) ?? 0
    };
  }

  /// 分类分布
  Future<List<Map<String, dynamic>>> categoryDistribution() async {
    return await _db.rawQuery('''
      SELECT COALESCE(categoryPrimary,'未分类') name, COUNT(*) c
      FROM books GROUP BY categoryPrimary ORDER BY c DESC
    ''');
  }

  /// 来源平台分布
  Future<List<Map<String, dynamic>>> sourceDistribution() async {
    return await _db.rawQuery(
        'SELECT source name, COUNT(*) c FROM books GROUP BY source ORDER BY c DESC');
  }

  /// 某年读完的书
  Future<List<Book>> finishedInYear(int year) async {
    final rows = await _db.query(
      'books',
      where: "status = ? AND finishedAt LIKE ?",
      whereArgs: [BookStatus.finished.name, '$year-%'],
      orderBy: 'finishedAt DESC',
    );
    return rows.map(Book.fromMap).toList();
  }

  /// 月度读完数量趋势
  Future<List<Map<String, dynamic>>> monthlyFinishedTrend(int year) async {
    return await _db.rawQuery('''
      SELECT substr(finishedAt,1,7) month, COUNT(*) c
      FROM books
      WHERE status = 'finished' AND finishedAt LIKE '$year-%'
      GROUP BY month ORDER BY month
    ''');
  }

  /// 总阅读时长（分钟）。
  ///
  /// 时长有三个来源，缺一不可：
  /// 1. 微信读书同步回来的**每本累计时长**，存在 `books.extra` 里；
  /// 2. 整包的**年度统计**（settings 里的 `wereadAnnualStats`），
  ///    含 `totalReadTime` 与逐月 `readTimes`；
  /// 3. 手工补记的 `reading_logs`（纸质书只能这么记）。
  ///
  /// 早先只统计第 3 项，而 reading_logs 一直是空的，于是统计页上
  /// 稳稳地显示「0.0 小时」——数字不是错的，是口径漏了。
  ///
  /// 1 和 2 都来自微信读书、覆盖范围互相重叠（前者是全时段按书累计，
  /// 后者是本年汇总），**相加会重复计算**，所以取较大值而不是求和。
  /// 真正独立的只有阅读日志，那一项照常叠加。
  Future<int> totalReadingMinutes() async {
    final logRow = await _db
        .rawQuery('SELECT COALESCE(SUM(durationMin),0) t FROM reading_logs');
    final logMin = (logRow.first['t'] as int?) ?? 0;

    var perBookSec = 0;
    for (final e in await _extras()) {
      final v = e['wereadReadingTimeSec'];
      if (v is num) perBookSec += v.toInt();
    }

    final annual = await wereadAnnualStats();
    final annualSec = annual?.totalReadSec ?? 0;

    final wereadSec =
        perBookSec > annualSec ? perBookSec : annualSec;
    return logMin + (wereadSec / 60).round();
  }

  /// 微信读书年度统计。没导入过或报文损坏时返回 null。
  Future<WereadAnnualStats?> wereadAnnualStats() async {
    final raw = await getSetting('wereadAnnualStats');
    return WereadAnnualStats.parse(raw);
  }

  /// 连续阅读天数。
  ///
  /// 数据来源是「有阅读痕迹的日期」：reading_logs 的 date，
  /// 以及每本书 extra 里的最近阅读/进度更新时间。
  /// 刻意不用 `books.updatedAt`——那是记录被修改的时间，
  /// 改一次评分就会把当天算成「读过」，连续天数会虚高。
  Future<int> readingStreakDays() async {
    final days = <String>{};

    final logs = await _db.rawQuery('SELECT DISTINCT date FROM reading_logs');
    for (final r in logs) {
      final d = r['date'] as String?;
      if (d != null && d.length >= 10) days.add(d.substring(0, 10));
    }

    for (final e in await _extras()) {
      for (final k in ['wereadLastReadAt', 'wereadProgressUpdatedAt']) {
        final v = e[k];
        if (v is String && v.length >= 10) days.add(v.substring(0, 10));
      }
    }
    if (days.isEmpty) return 0;

    String key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    // 用 UTC 做日期步进：本地时区在夏令时地区会让 `subtract(days:1)`
    // 落到前一天的 23:00，日期串就对不上了
    var cursor = DateTime.utc(now.year, now.month, now.day);
    // 允许「今天还没读」——否则早上打开 App 连续天数会莫名归零
    if (!days.contains(key(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(key(cursor))) return 0;
    }

    var streak = 0;
    while (days.contains(key(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 评分分布：未评分 + 1~5 星。
  ///
  /// 在 Dart 侧分桶而不是写 SQL：`rating` 是 REAL，
  /// 4.5 星该进 5 星桶、0.5 星该进 1 星桶，这种取整规则用 SQL 表达
  /// 既难读也容易写错。
  Future<List<Map<String, dynamic>>> ratingBuckets() async {
    final rows = await _db.rawQuery(
        'SELECT rating, COUNT(*) c FROM books GROUP BY rating');
    final counts = List<int>.filled(6, 0); // 0=未评分, 1..5 星
    for (final r in rows) {
      final rating = (r['rating'] as num?)?.toDouble() ?? 0;
      final c = (r['c'] as int?) ?? 0;
      final idx = rating <= 0 ? 0 : rating.ceil().clamp(1, 5);
      counts[idx] += c;
    }
    return [
      for (var i = 0; i < 6; i++)
        {'label': i == 0 ? '未评分' : '$i 星', 'count': counts[i], 'stars': i},
    ];
  }

  /// 在读图书的进度分布，看「开了多少坑没填」
  Future<List<Map<String, dynamic>>> progressBuckets() async {
    final rows = await _db.rawQuery(
        "SELECT progressPercent p FROM books WHERE status = 'reading'");
    const labels = ['0-25%', '25-50%', '50-75%', '75-100%'];
    final counts = List<int>.filled(4, 0);
    for (final r in rows) {
      final p = (r['p'] as num?)?.toDouble() ?? 0;
      final i = (p / 25).floor().clamp(0, 3);
      counts[i]++;
    }
    return [
      for (var i = 0; i < labels.length; i++)
        {'label': labels[i], 'count': counts[i]},
    ];
  }

  /// 已读书目的平均分（无评分时返回 0）
  Future<double> averageRating() async {
    final rows = await _db.rawQuery('SELECT AVG(rating) a FROM books WHERE rating > 0');
    return (rows.first['a'] as num?)?.toDouble() ?? 0;
  }

  /// 解析所有书籍的 extra JSON，供时长/连续天数这类跨行聚合使用。
  /// 让 SQL 直接读 JSON 需要 SQLite 编译进 JSON1 扩展，
  /// sqflite 各平台的编译选项并不统一，不能依赖。
  Future<List<Map<String, dynamic>>> _extras() async {
    final rows = await _db.rawQuery('SELECT extra FROM books WHERE extra IS NOT NULL');
    final out = <Map<String, dynamic>>[];
    for (final r in rows) {
      final raw = r['extra'];
      if (raw is! String || raw.isEmpty) continue;
      try {
        final m = jsonDecode(raw);
        if (m is Map) out.add(Map<String, dynamic>.from(m));
      } catch (_) {
        // 单行 extra 损坏不影响整体统计
      }
    }
    return out;
  }

  static String _encodeAuthors(List<String> authors) =>
      authors.isEmpty ? '[]' : '[${authors.map((a) => '"$a"').join(',')}]';

  /* ------------------------- 阅读日志 ------------------------- */

  Future<void> addLog(ReadingLog log) async {
    await _db.insert('reading_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ReadingLog>> logsOf(String bookId) async {
    final rows = await _db.query('reading_logs',
        where: 'bookId = ?', whereArgs: [bookId], orderBy: 'date DESC');
    return rows.map(ReadingLog.fromMap).toList();
  }

  /* ------------------------- 笔记 ------------------------- */

  Future<void> addNote(Note note) async {
    await _db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Note>> notesOf(String bookId) async {
    final rows = await _db.query('notes',
        where: 'bookId = ?', whereArgs: [bookId], orderBy: 'createdAt DESC');
    return rows.map(Note.fromMap).toList();
  }

  /* ------------------------- AI 报告 ------------------------- */

  /// 保存一次生成的报告。同周期保留最新一份即可，故用 period 作主键的一部分。
  Future<void> saveReport({
    required String period,
    required String model,
    required String content,
    Map<String, dynamic>? metrics,
  }) async {
    final id = '${period}_${DateTime.now().millisecondsSinceEpoch}';
    await _db.insert('llm_reports', {
      'id': id,
      'period': period,
      'model': model,
      'content': content,
      'metrics': metrics == null ? null : jsonEncode(metrics),
      'generatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 历史报告，最新在前
  Future<List<Map<String, dynamic>>> reports({int limit = 20}) async {
    return await _db.query('llm_reports', orderBy: 'generatedAt DESC', limit: limit);
  }

  Future<Map<String, dynamic>?> latestReportOf(String period) async {
    final r = await _db.query('llm_reports',
        where: 'period = ?', whereArgs: [period], orderBy: 'generatedAt DESC', limit: 1);
    return r.isEmpty ? null : r.first;
  }

  /* ------------------------- 设置 ------------------------- */

  Future<void> setSetting(String key, String value) async {
    await _db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final r = await _db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    return r.isEmpty ? null : r.first['value'] as String?;
  }
}
