import 'dart:convert';
import '../l10n/app_loc.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// 桌面端与移动端共用 sqflite_common_ffi，其已覆盖 sqflite 的全部 API，
// 重复导入 sqflite 会触发 unnecessary_import 告警
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/reading_plan.dart';
import 'backup.dart';
import 'category_prefs.dart';
import 'date_range.dart';
import 'weread_annual.dart';

/// 本地 SQLite 数据库。
///
/// 本地优先架构：无需账号、无需联网即可完整使用。数据库文件位于应用
/// 私有目录，桌面端（Windows/macOS/Linux）通过 sqflite_common_ffi 走 SQLite。
class AppDatabase {
  static const _dbName = 'reading_tracker.db';
  /// v2：books 增加 categoryRaw 列，并对历史数据重跑分类归一化
  /// v3：状态精简为四个（弃读+暂搁 → shelved，借阅中 → reading），
  ///     books 增加 isBorrowed 列，借阅拆成独立标记
  /// v4：新增 reading_plans 表（阅读计划 + 提醒）
  /// v5：reading_plans 增加 lastDoneOn（每日型计划的「今天已完成」打点）
  /// v6：reading_plans 增加 checkins（每日型计划的逐日打卡记录，用于连续天数）
  static const _version = 6;

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
        isBorrowed INTEGER DEFAULT 0,
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
      CREATE TABLE reading_plans (
        id TEXT PRIMARY KEY,
        kind TEXT,
        title TEXT,
        dailyMinutes INTEGER,
        bookId TEXT,
        dueDate TEXT,
        reminderEnabled INTEGER DEFAULT 0,
        done INTEGER DEFAULT 0,
        doneAt TEXT,
        lastDoneOn TEXT,
        checkins TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_plans_done ON reading_plans(done)');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  /// 把用户对分类词表的修改读进全局词表。
  ///
  /// 直接吃 Database 而不是 [BookRepository]：迁移期间拿不到 repository，
  /// 而迁移恰恰是最需要它的场合。
  Future<void> _loadCategoryVocabulary(Database db) async {
    try {
      Future<String?> read(String key) async {
        final r = await db.query('settings',
            where: 'key = ?', whereArgs: [key], limit: 1);
        return r.isEmpty ? null : r.first['value'] as String?;
      }
      applyCategoryVocabulary(
        custom: await read(kCustomCategoriesKey),
        hidden: await read(kHiddenCategoriesKey),
      );
    } catch (_) {
      // settings 表还不存在或读失败：用默认词表继续，
      // 总好过让一次版本升级卡在这里打不开 App。
    }
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // 先把用户改过的分类词表装进来。
    //
    // 顺序要紧：v1→v2 这类迁移会重跑 normalizeCategory，而它读的是
    // 全局词表。晚一步装载，用户自定义分类下的书就会被默认词表判成
    // 「其他」——一次版本升级静默改掉几百本书的归类，且无从恢复。
    await _loadCategoryVocabulary(db);
    if (oldV < 2) {
      await db.execute('ALTER TABLE books ADD COLUMN categoryRaw TEXT');
      await renormalizeCategories(db: db);
    }
    if (oldV < 3) {
      await db.execute('ALTER TABLE books ADD COLUMN isBorrowed INTEGER DEFAULT 0');
      await migrateBorrowedStatus(db);
    }
    if (oldV < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reading_plans (
          id TEXT PRIMARY KEY,
          kind TEXT,
          title TEXT,
          dailyMinutes INTEGER,
          bookId TEXT,
          dueDate TEXT,
          reminderEnabled INTEGER DEFAULT 0,
          done INTEGER DEFAULT 0,
          doneAt TEXT,
          lastDoneOn TEXT,
          createdAt TEXT
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_plans_done ON reading_plans(done)');
    }
    if (oldV < 5) {
      // 每日型计划从「一次性完成任务」改成「周期任务」，需要一个
      // 「今天已完成」的打点字段。存量行填 NULL：等于「今天还没打卡」，
      // 用户下次打开就能重新勾——这正是我们想要的行为，不需要回填数据。
      await db.execute(
          'ALTER TABLE reading_plans ADD COLUMN lastDoneOn TEXT');
    }
    if (oldV < 6) {
      // 每日型计划的逐日打卡记录，用于「连续打卡 N 天」。
      // 存量行填 NULL：还没开始打卡，连续天数为 0，无需回填。
      await db.execute(
          'ALTER TABLE reading_plans ADD COLUMN checkins TEXT');
    }
  }

  /// v2 → v3：把「借阅中」从一个状态拆成「在读 + 借阅标记」。
  ///
  /// 为什么必须搬数据而不是只改读取逻辑：`fromString` 虽然会把
  /// 'borrowed' 认成 reading（兜底兼容），但**统计是直接查询
  /// `status = 'reading'` 的 SQL**，不会走 Dart 的 fromString。
  /// 留在库里的 'borrowed' 行会在所有按状态聚合的地方凭空消失——
  /// 用户的在读书目会静默少几本，这比报错更难发现。
  ///
  /// 'paused' 与 'abandoned' 同理：合并成 'shelved'。
  /// `borrowedFrom` / `dueAt` 原样保留，它们本来就是借阅的附属信息。
  /// 公开是为了让测试能直接验证这一步（v2→v3 的真实迁移路径）。
  Future<void> migrateBorrowedStatus(Database db) async {
    // 借阅中 → 在读，并打上借阅标记
    await db.execute(
      "UPDATE books SET status = 'reading', isBorrowed = 1 "
      "WHERE status = 'borrowed'",
    );
    // 没标借阅但填了借阅来源/应还日期的行，也认作借阅，
    // 免得用户明明填过信息、界面却不显示标记
    await db.execute(
      'UPDATE books SET isBorrowed = 1 '
      'WHERE isBorrowed = 0 AND (borrowedFrom IS NOT NULL OR dueAt IS NOT NULL)',
    );
    // 弃读 / 暂搁 → 搁置
    await db.execute(
      "UPDATE books SET status = 'shelved' WHERE status IN ('paused', 'abandoned')",
    );
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
        // 已经是**当前生效词表**里的值 → 已经归一化过，交给更精确的来源处理。
        // 用生效词表而不是 defaultCategories：用户移除某个默认分类后，
        // 存量书得有机会被重新归到别的分类，而不是一直留在已删除的分类里。
        if (cur != null && categoryVocabulary.contains(cur)) continue;
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

    if (status != null) { where.add('status = ?'); args.add(status.storageValue); }
    if (source != null) { where.add('source = ?'); args.add(source.name); }
    if (category != null) {
      // 「未分类」要同时接住两拨书：字段为 NULL 的（分布里被 COALESCE
      // 算成未分类），和字面存了 '未分类' 的。只按等值查的话前者
      // 永远筛不出来——分布显示 39 本、筛出来只剩十几本，就是这里。
      if (category == kUncategorized) {
        where.add('(categoryPrimary IS NULL OR categoryPrimary = ?)');
        args.add(category);
      } else {
        where.add('categoryPrimary = ?');
        args.add(category);
      }
    }
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

  /// 删除一本书，连同它的阅读记录与阅读计划。
  ///
  /// ⚠️ **笔记刻意不删**。笔记是用户一个字一个字写下的内容，
  /// 比书籍记录更不该被一次删除顺手清掉——书可能是误导入的重复条目，
  /// 但写在它下面的想法不能跟着蒸发。于是必然出现「笔记还在、书没了」
  /// 的数据，[allNotes] 会把 book 置 null，界面显示占位书名。
  ///
  /// 阅读记录与计划则相反：它们是为这本书服务的派生态，
  /// 留着会让「总阅读时长」继续统计一本已经不存在的书。
  ///
  /// 放在一个事务里：中途失败时宁可整条回滚，也不要留下半截状态。
  Future<void> delete(String id) async {
    await _db.transaction((txn) async {
      await txn.delete('reading_logs', where: 'bookId = ?', whereArgs: [id]);
      await txn.delete('reading_plans', where: 'bookId = ?', whereArgs: [id]);
      await txn.delete('books', where: 'id = ?', whereArgs: [id]);
    });
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
    // '未分类' 用常量插值而非本地化文案：categoryDistributionOf 在 Dart 侧
    // 也用同一个 key，两套实现必须完全一致。
    // GROUP BY 也必须按 COALESCE 后的表达式：NULL 与字面 '未分类' 是
    // 两个分组，却都会被标成「未分类」——chip 区会出现两个「未分类」
    // 且计数各算一半。
    return await _db.rawQuery(
      "SELECT COALESCE(categoryPrimary,'$kUncategorized') name, COUNT(*) c "
      "FROM books GROUP BY COALESCE(categoryPrimary,'$kUncategorized') "
      'ORDER BY c DESC');
  }

  /// 来源平台分布
  Future<List<Map<String, dynamic>>> sourceDistribution() async {
    return await _db.rawQuery(
        'SELECT source name, COUNT(*) c FROM books GROUP BY source ORDER BY c DESC');
  }

  /// 标签分布
  ///
  /// `tags` 在库里是 JSON 数组文本（`["a","b"]`），SQLite 拆不开，
  /// 所以只把这一列取回来在 Dart 侧计数。书架的行数量级（几百到几千）
  /// 下这点开销可以忽略，换来的是不用维护一张单独的标签表——
  /// 标签是每本书的自由文本，建表反而要处理「改一个标签要改几行」的问题。
  Future<List<Map<String, dynamic>>> tagDistribution() async {
    final rows = await _db.query(
      'books',
      columns: ['tags'],
      where: "tags IS NOT NULL AND tags != '' AND tags != '[]'",
    );
    final counts = <String, int>{};
    for (final r in rows) {
      final raw = r['tags'];
      if (raw is! String) continue;
      List<dynamic> list;
      try {
        list = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        continue;
      }
      for (final e in list) {
        final s = e.toString().trim();
        if (s.isEmpty) continue;
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    final out = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in out) {'name': e.key, 'c': e.value}];
  }

  /// 某个分类下有多少本书。
  ///
  /// 删除/改名分类前用它告诉用户这次改动会影响多少条数据——
  /// 「删除『宗教』」和「删除『宗教』（12 本书将归入未分类）」
  /// 是完全不同的两个决定。
  Future<int> categoryCount(String name) async {
    final r = await _db.rawQuery(
        'SELECT COUNT(*) c FROM books WHERE categoryPrimary = ?', [name]);
    return (r.first['c'] as int?) ?? 0;
  }

  /// 把某个分类下的书整体迁到另一个分类，返回受影响的行数。
  ///
  /// 改名和删除分类都走这里：删分类时传入 [kUncategorized]。
  Future<int> recategorize(String from, String to) async {
    return await _db.rawUpdate(
        'UPDATE books SET categoryPrimary = ? WHERE categoryPrimary = ?',
        [to, from]);
  }

  /// 某年读完的书
  Future<List<Book>> finishedInYear(int year) async {
    final rows = await _db.query(
      'books',
      where: "status = ? AND finishedAt LIKE ?",
      whereArgs: [BookStatus.finished.storageValue, '$year-%'],
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

  /// 区间内的阅读活动。
  ///
  /// 三个来源的时间粒度**不同**，混在一起处理会算出一个「看起来很确定」
  /// 的错误数字，所以逐个交代：
  ///
  /// | 来源 | 位置 | 粒度 | 能否按区间筛 |
  /// |---|---|---|---|
  /// | 手工日志 | `reading_logs.date` | 天 | 能，精确 |
  /// | 年度统计 | `readTimes`（逐月秒数） | **月** | 只能按月重叠 |
  /// | 每本累计 | `extra.wereadReadingTimeSec` | 无日期 | 只有「全部时间」能用 |
  ///
  /// 年度统计与每本累计覆盖范围重叠（同一段阅读被记了两遍），
  /// 所以取较大值而**不是**相加。手工日志是独立来源，照常叠加。
  ///
  /// 「有阅读记录的天数」只在两种情况下给得出：区间是完整自然年
  /// （年度统计里有 `readDays`），或者压根没有年度统计（退回手工日志）。
  /// 其余情况返回 null——塞 0 会让「这段时间没读过」和「这段时间的
  /// 天数无从统计」长得一模一样。
  Future<ReadingActivity> readingActivity(StatsRange range) async {
    final logs =
        await _db.rawQuery('SELECT date, durationMin FROM reading_logs');
    var logMin = 0;
    final logDays = <String>{};
    for (final r in logs) {
      final d = r['date'] as String?;
      if (!range.containsIso(d)) continue;
      logMin += (r['durationMin'] as int?) ?? 0;
      if (d != null && d.length >= 10) logDays.add(d.substring(0, 10));
    }

    final annual = await wereadAnnualStats();
    var annualSec = 0;
    if (annual != null) {
      for (final m in annual.monthly) {
        if (range.overlapsMonth(m.year, m.month)) annualSec += m.seconds;
      }
    }

    // 每本累计时长没有日期字段，只能用在「全部时间」口径下
    var perBookSec = 0;
    if (range.isAll) {
      for (final e in await _extras()) {
        final v = e['wereadReadingTimeSec'];
        if (v is num) perBookSec += v.toInt();
      }
    }

    final wereadSec = perBookSec > annualSec ? perBookSec : annualSec;
    final minutes = logMin + (wereadSec / 60).round();

    int? activeDays;
    String? note;

    if (annual == null) {
      activeDays = logDays.isEmpty ? null : logDays.length;
      if (logDays.isNotEmpty) note = appLoc.s_e74f752c;
    } else if (range.isAll) {
      activeDays = annual.readDays > 0 ? annual.readDays : null;
      note = appLoc.s_9ea3cbae(year: annual.year);
    } else if (range.coversWholeYear(annual.year)) {
      activeDays = annual.readDays > 0 ? annual.readDays : null;
    } else {
      note = appLoc.s_f676228c;
    }

    return ReadingActivity(minutes: minutes, activeDays: activeDays, note: note);
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

  /* --------------------------- 阅读计划 --------------------------- */

  /// 全部计划，未完成的排前面（用户每天要看的是进行中的）。
  Future<List<ReadingPlan>> plans() async {
    final rows = await _db.query(
      'reading_plans',
      orderBy: 'done ASC, createdAt DESC',
    );
    return rows.map(ReadingPlan.fromMap).toList();
  }

  /// 仅进行中的计划。报告与提醒都只关心这些。
  Future<List<ReadingPlan>> activePlans() async {
    final rows = await _db.query('reading_plans',
        where: 'done = 0', orderBy: 'createdAt DESC');
    return rows.map(ReadingPlan.fromMap).toList();
  }

  Future<void> upsertPlan(ReadingPlan p) async {
    await _db.insert('reading_plans', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePlan(String id) async {
    await _db.delete('reading_plans', where: 'id = ?', whereArgs: [id]);
  }

  /// 按天聚合的阅读分钟数（yyyy-MM-dd → 分钟）。
  ///
  /// 只统计有确切日期的来源：手工日志与每本书的最近阅读日。
  /// 年度统计是**按月**的，拆不到天，所以算日均时不能把它掺进来
  /// ——否则每个月的每天都会被均摊出一个假数字。
  Future<Map<String, int>> minutesByDay() async {
    final out = <String, int>{};
    final logs =
        await _db.rawQuery('SELECT date, durationMin FROM reading_logs');
    for (final r in logs) {
      final d = r['date'] as String?;
      if (d == null || d.length < 10) continue;
      final k = d.substring(0, 10);
      out[k] = (out[k] ?? 0) + ((r['durationMin'] as int?) ?? 0);
    }
    return out;
  }

  /// 算出某条计划当前的完成情况。
  ///
  /// 这是**唯一**的判定入口：计划卡片、提醒调度、报告数据都调它。
  /// 任何一处自己另算一遍，就会出现「卡片说达成、报告说没达成」。
  Future<PlanProgress> planProgress(ReadingPlan p) async {
    switch (p.kind) {
      case PlanKind.dailyMinutes:
        final target = (p.dailyMinutes ?? 0).toDouble();
        final perDay = await minutesByDay();
        if (target <= 0 || perDay.isEmpty) {
          return PlanProgress(plan: p, target: target, current: 0, achieved: false);
        }
        // 从计划创建那天算起，已经过去的天数（含今天，今天还没读完也算进来）
        final start = DateTime.tryParse(p.createdAt) ?? DateTime.now();
        final today = DateTime.now();
        var days = DateTime.utc(today.year, today.month, today.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays + 1;
        if (days < 1) days = 1;
        // 过去的完整天数 + 今天已读的部分，都计入分子
        var sum = 0;
        for (final e in perDay.entries) {
          final d = DateTime.tryParse(e.key);
          if (d == null) continue;
          if (d.isBefore(DateTime(start.year, start.month, start.day))) continue;
          sum += e.value;
        }
        final current = sum / days; // 日均
        // ⚠️ 达成必须看**今天**，不能看日均。
        //
        // 日均是「创建至今」的平均值，只增不减：一旦某天读得多把日均拉过
        // 目标，这个达成就永远为真，卡片上的「今天读完了」按钮会永久消失
        // ——对一个每天都要做的周期任务来说，这等于「打满一周就再也不用点了」。
        // 用户看到的就是「按钮不见了，计划没法打卡」。
        //
        // 达成口径 = 今天读满了 **或** 今天已手动打卡。
        // 键的形状由 [minutesByDay] 决定（取 date 前 10 位），
        // 这里必须用同一套截断，否则查不到今天的键。
        final now = DateTime.now();
        final todayKey =
            '${now.year.toString().padLeft(4, '0')}-'
            '${now.month.toString().padLeft(2, '0')}-'
            '${now.day.toString().padLeft(2, '0')}';
        final todayMin = perDay[todayKey] ?? 0;
        return PlanProgress(
          plan: p,
          target: target,
          current: current,
          achieved: todayMin >= target || p.doneToday(),
        );

      case PlanKind.finishBook:
        final bookId = p.bookId;
        if (bookId == null) {
          // 计划指向的书被删了。不当作达成，也不崩——
          // 界面会显示「目标书已不在书架」，由用户自己决定删不删这条计划。
          return PlanProgress(plan: p, target: 100, current: 0, achieved: false);
        }
        final rows = await _db.query('books',
            columns: ['progressPercent', 'status'],
            where: 'id = ?',
            whereArgs: [bookId]);
        if (rows.isEmpty) {
          return PlanProgress(plan: p, target: 100, current: 0, achieved: false);
        }
        final status = BookStatus.fromString(rows.first['status'] as String?);
        // 已读完直接算 100%，不看 progressPercent：用户可能勾了完成
        // 但没把进度条拖到底，此时以状态为准更符合直觉
        final cur = status == BookStatus.finished
            ? 100.0
            : ((rows.first['progressPercent'] as num?)?.toDouble() ?? 0);
        return PlanProgress(
          plan: p,
          target: 100,
          current: cur,
          achieved: status == BookStatus.finished,
        );
    }
  }

  /// 所有进行中计划的完成快照。报告数据与提醒都吃这个。
  Future<List<PlanProgress>> activePlanProgress() async {
    final all = await activePlans();
    final out = <PlanProgress>[];
    for (final p in all) {
      out.add(await planProgress(p));
    }
    return out;
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
        {'label': i == 0 ? appLoc.s_06225788 : appLoc.s_89cfaca8(i: i), 'count': counts[i], 'stars': i},
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

  Future<void> updateNote(Note note) async {
    await _db.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> deleteNote(String id) async {
    await _db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  /// 全库笔记数。统计页要展示「写了几条笔记」——有产出才谈得上鼓励。
  Future<int> noteCount() async {
    final r = await _db.rawQuery('SELECT COUNT(*) c FROM notes');
    return (r.first['c'] as int?) ?? 0;
  }

  /// 全库笔记（按时间倒序），每条都带上所属书籍。
  ///
  /// 传 [bookId] 则只看某一本书的笔记。
  ///
  /// 为什么不用 SQL JOIN：书名作者要经 `Book.fromMap` 还原（authors 是
  /// JSON 数组），而 sqflite 的 `rawQuery` 只会给我平铺的列。
  /// 与其在 Dart 侧再解析一遍，不如分两次查询 + 内存建索引——
  /// 书架规模是几十到几百本，一次全表扫描比 JOIN 后的重复解析更快也更好读。
  ///
  /// 书籍可能缺失（书被删、或笔记来自导入时的书名匹配），此时
  /// [NoteWithBook.book] 为 null，界面要能正常显示。
  Future<List<NoteWithBook>> allNotes({String? bookId}) async {
    final rows = await _db.query(
      'notes',
      where: bookId == null ? null : 'bookId = ?',
      whereArgs: bookId == null ? null : <Object?>[bookId],
      orderBy: 'createdAt DESC',
    );
    if (rows.isEmpty) return const <NoteWithBook>[];

    final notes = rows.map(Note.fromMap).toList();
    final byId = <String, Book>{};
    for (final b in await all()) {
      byId.putIfAbsent(b.id, () => b);
    }
    return notes
        .map((n) => NoteWithBook(note: n, book: byId[n.bookId]))
        .toList();
  }

  /// 写过笔记的书（按最近笔记时间倒序），供笔记页的「按书筛选」下拉使用。
  ///
  /// 只返回**有笔记**的书：下拉里塞进 38 本一本笔记都没有的书，
  /// 点进去全是空态，等于给用户造了一个会失望的入口。
  Future<List<Book>> booksWithNotes() async {
    final rows = await _db.rawQuery('''
      SELECT DISTINCT bookId FROM notes
    ''');
    if (rows.isEmpty) return const <Book>[];

    final byId = <String, Book>{};
    for (final b in await all()) {
      byId.putIfAbsent(b.id, () => b);
    }
    final out = <Book>[];
    for (final r in rows) {
      final b = byId[r['bookId'] as String?];
      if (b != null) out.add(b);
    }
    // 按书名排序，让下拉是可扫读的，而不是按 SQLite 的行顺序乱跳。
    out.sort((a, b) => a.title.compareTo(b.title));
    return out;
  }

  /* ------------------------- 备份与恢复 ------------------------- */

  /// 整库导出为 JSON 快照。
  ///
  /// 直接取原始行而不经过 Book.fromMap/toMap 往返：模型转换是有损的
  /// （未知字段被丢弃、类型被规整），备份的意义恰恰是零丢失。
  Future<Map<String, List<Map<String, dynamic>>>> dumpTables() async {
    final out = <String, List<Map<String, dynamic>>>{};
    for (final t in BackupCodec.tables) {
      out[t] = (await _db.query(t)).map(Map<String, dynamic>.from).toList();
    }
    return out;
  }

  /// 从备份快照恢复。返回各表写入的行数。
  ///
  /// 用 `ConflictAlgorithm.replace` 整行覆盖而不是合并：
  /// 恢复的语义是「回到备份那一刻」，半推半就的合并会造出
  /// 「备份里删掉的书在本地复活」这种拆东补西的怪状态。
  Future<Map<String, int>> restoreTables(
      Map<String, List<Map<String, dynamic>>> data) async {
    final counts = <String, int>{};
    await _db.transaction((txn) async {
      for (final t in BackupCodec.tables) {
        final rows = data[t];
        if (rows == null) continue;
        for (final r in rows) {
          await txn.insert(t, r, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        counts[t] = rows.length;
      }
    });
    return counts;
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

  /// 删除单条历史报告。
  ///
  /// 按主键 [id] 删，而不是按 period：历史列表里同一周期可能有多份
  /// 生成记录（每次生成都插一条新行、period 相同），按 period 删会把
  /// 同一周期的其他生成一并清掉，表现为「删一个全没了」。
  Future<void> deleteReport(String id) async {
    await _db.delete('llm_reports', where: 'id = ?', whereArgs: [id]);
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
