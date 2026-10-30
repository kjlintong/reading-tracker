import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/backup.dart';
import '../data/database.dart';

/// 每周自动备份：把整库导出成 JSON，写进 `Download/Readnest/backups/`。
///
/// **为什么走 MediaStore**：Android 10+ 是 scoped storage，App 不能随意往
/// `/storage/emulated/0/Readnest/` 这类任意路径写文件。MediaStore 的 Download
/// 集合**不需要任何存储权限**即可写入，且文件在「卸载 App」后仍留在 Download 里——
/// 这正是用户「删了老版本重装、数据没了」这类事故的解药：重装后从
/// 设置 → 数据 → 恢复 选这个文件即可整库还原。
///
/// **为什么不靠数据库记录来清理**：清理若只认 DB 里的文件名列表，
/// 那用户「卸载重装」后 DB 是空的、历史清单也丢了，旧的备份文件就成了
/// 孤儿——没人再认得它们，也没人删得掉，Download 里会越攒越多。
/// 所以这里改用**固定槽位轮转**：文件名只可能是 [slotFileNames] 里的那几个，
/// 每次备份挑最旧的那个槽覆盖写。文件名集合恒定 → 磁盘占用恒定，
/// 与 App 有没有被卸载过无关。
///
/// **设计要点**（与 [AutoShelve] 同思路）：
/// - 纯函数 [shouldRun] / [backupFileName] / [pickOverwriteSlot] 单独抽出，
///   便于穷举测试；这类「批量改用户数据」的逻辑改错很难察觉。
/// - 真正的写盘放在 [runIfDue] 里，且对任何异常降级到 App 私有文档目录，
///   保证「至少产出一个文件」，不会让自动备份静默失败。
class AutoBackup {
  AutoBackup._();

  /// 原生 MethodChannel（与 MainActivity.kt 里的 channelName 一致）。
  static const String _systemChannel = 'io.github.ltong9463.readnest/system';

  /// 设置键：是否启用自动备份。默认见 [defaultEnabled]。
  static const String enabledKey = 'auto_backup_enabled';

  /// 设置键：备份间隔（天）。取值见 [intervalPresets] 的键。
  static const String intervalKey = 'auto_backup_interval_days';

  /// 设置键：上次成功备份时间（ISO8601）。用于「到点才跑」的节流。
  static const String lastRunKey = 'last_auto_backup_at';

  /// 默认开启：用户刚经历过一次丢数据，默认开能避免重蹈覆辙。
  static const bool defaultEnabled = true;

  /// 默认每周一次。
  static const int defaultIntervalDays = 7;

  /// 自动备份最多保留几份。
  ///
  /// 这是**磁盘占用的硬上限**：备份文件名只取自 [slotFileNames]（固定几个），
  /// 每次备份覆盖写其中一个，所以不管备份多少次、App 有没有被卸载过，
  /// Download 里最多就这 [keepCount] 个文件。
  static const int keepCount = 4;

  /// 备份文件名里带的轮转序号，取值 1..[keepCount]。
  ///
  /// 故意**不带真实时间戳**：文件名一旦随时间变化，旧的那些就成了
  /// 「无人认领的孤儿文件」，卸载重装后没人知道它们存在，也就删不掉。
  /// 固定名字 = 固定文件集合 = 占用恒定。
  static const List<String> slotFileNames = [
    'readnest-backup-1.json',
    'readnest-backup-2.json',
    'readnest-backup-3.json',
    'readnest-backup-4.json',
  ];

  /// 槽位文件名与 [keepCount] 必须一致，否则保留策略会失准。
  @visibleForTesting
  static bool get slotCountConsistent => slotFileNames.length == keepCount;

  /// 备份文件在 MediaStore Download 里的相对目录。
  ///
  /// ⚠️ 插件把 [MediaStore.saveFile] 的 `relativePath` 参数当作 `appFolder` 传给原生，
  /// 原生再拼成 `Download/<relativePath>`。所以这里必须写**完整的两级路径**，
  /// 写成 `'backups'` 的话文件会落在 `Download/backups/` 而不是
  /// `Download/Readnest/backups/`。
  static const String backupRelativePath = 'Readnest/backups';

  /// v1.3.0 实际写到的目录（当时误传了 `relativePath: 'backups'`）。
  ///
  /// 那批文件属于本 App 的自动备份，同样要清理掉，否则会变成孤儿占着空间。
  static const String legacyRelativePath = 'backups';

  /// 可选周期：每天 / 每 3 天 / 每周 / 每 2 周 / 每月。
  ///
  /// 键是天数（存进 [intervalKey]），值仅作代码内参考；界面展示的文案走 ARB。
  static const Map<int, String> intervalPresets = {
    1: '每天',
    3: '每 3 天',
    7: '每周',
    14: '每 2 周',
    30: '每月',
  };

  static bool _initialized = false;

  /// 写盘前必须调用一次（获取平台 SDK 版本并设定子目录名）。多次调用无害。
  ///
  /// 非 Android 或插件不可用时静默降级（置 `_initialized=false`），
  /// 后续会回退到 App 私有文档目录写文件。
  static Future<void> ensureReady() async {
    if (_initialized) return;
    try {
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'Readnest';
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  /// 是否该执行一次备份。
  ///
  /// [lastIso] 为 null（从未备份过）或距现在已超过 [intervalDays] 天 → true。
  @visibleForTesting
  static bool shouldRun(DateTime now, String? lastIso, int intervalDays) {
    if (lastIso == null) return true;
    final last = DateTime.tryParse(lastIso);
    if (last == null) return true;
    final days = now.difference(last).inDays;
    return days >= intervalDays;
  }

  /// 自动备份文件名：固定槽位名，形如 `readnest-backup-1.json`。
  ///
  /// 刻意不含时间戳——见 [slotFileNames] 的说明。
  @visibleForTesting
  static String backupFileName(int slot) {
    final idx = slot < 1 ? 1 : (slot > keepCount ? keepCount : slot);
    return 'readnest-backup-$idx.json';
  }

  /// 挑一个要被覆盖写的槽位号（1..[keepCount]）。
  ///
  /// 规则：优先挑**最旧**的那份（[slotOrder] 里最靠前且已存在），
  /// 全部不存在时用最老的槽位（1）开始写。
  ///
  /// [existing] 是当前已存在的备份文件名（可含本 App 不认识的旧版文件名，
  /// 它们会被忽略——不认识就不动，宁可多留一个也不误删用户文件）。
  /// [slotOrder] 是槽位按「最旧 → 最新」排列的顺序；
  /// 调用方需要自己维护这个顺序（依据各槽位备份内容里的时间戳），
  /// 传空则退化为「挑编号最小的」。
  @visibleForTesting
  static int pickOverwriteSlot(
    List<String> existing,
    List<String> slotOrder, {
    int keep = keepCount,
  }) {
    if (keep <= 0) return 1;
    final names = slotFileNames.take(keep).toList();
    final order = slotOrder.where(names.contains).toList();
    // 补齐：slotOrder 里没提到的槽位，按编号从小到大排在后面
    for (final n in names) {
      if (!order.contains(n)) order.add(n);
    }
    for (final n in order) {
      if (!existing.contains(n)) return _slotIndex(n);
    }
    // 全都存在 → 覆盖最旧的那个
    return _slotIndex(order.first);
  }

  /// 从 `readnest-backup-N.json` 里取出 N；不是本 App 的文件名则返回 1。
  static int _slotIndex(String fileName) {
    final m = RegExp(r'^readnest-backup-(\d+)\.json$').firstMatch(fileName);
    if (m == null) return 1;
    final n = int.tryParse(m.group(1)!) ?? 1;
    if (n < 1 || n > keepCount) return 1;
    return n;
  }

  /// 挑出「不属于本 App 的自动备份命名规范」的文件名。
  ///
  /// 这些是旧版本留下的带时间戳的文件（如 `reading-tracker-auto-20261030-1200.json`）。
  /// 它们同样会堆积，所以列出来交给调用方删掉——但**只删本 App 自己的旧格式**，
  /// 不碰用户手动导出的 `reading-tracker-YYYYMMDD.json`（那个名字没有 `auto`）。
  @visibleForTesting
  static List<String> legacyAutoBackupNames(List<String> existing) {
    final legacy = RegExp(r'^reading-tracker-auto-\d{8}-\d{4}\.json$');
    return existing.where(legacy.hasMatch).toList();
  }

  /// 读出当前设置（带默认值与容错解析）。
  static Future<AutoBackupState> readState(BookRepository repo) async {
    final enabledRaw = await repo.getSetting(enabledKey);
    final intervalRaw = await repo.getSetting(intervalKey);
    final lastIso = await repo.getSetting(lastRunKey);

    final enabled = enabledRaw == null ? defaultEnabled : enabledRaw == 'true';
    final intervalDays = int.tryParse(intervalRaw ?? '') ?? defaultIntervalDays;

    return AutoBackupState(
      enabled: enabled,
      intervalDays: intervalDays,
      lastIso: lastIso,
    );
  }

  /// 应用启动时调用：若开启且到点（或 [force]），则静默备份一次。
  ///
  /// 不向外抛异常（失败仅记入结果），避免拖慢启动或引发崩溃。
  static Future<AutoBackupResult> runIfDue(
    BookRepository repo, {
    bool force = false,
  }) async {
    final state = await readState(repo);
    if (!state.enabled) {
      return const AutoBackupResult(status: AutoBackupStatus.skipped,
          reason: 'disabled');
    }
    final now = DateTime.now();
    if (!force && !shouldRun(now, state.lastIso, state.intervalDays)) {
      return const AutoBackupResult(status: AutoBackupStatus.skipped,
          reason: 'not-due');
    }
    return _perform(repo, now, state);
  }

  static Future<AutoBackupResult> _perform(
    BookRepository repo,
    DateTime now,
    AutoBackupState state,
  ) async {
    try {
      final data = await repo.dumpTables();
      final payload = BackupCodec.build(data: data, now: now);
      final text = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = utf8.encode(text);

      await ensureReady();
      final useMediaStore = _initialized;

      // 列出盘上真实存在的文件：用来识别旧格式垃圾、并确认槽位现状。
      // 这一步刻意**不依赖数据库**：即使 App 被卸载重装（数据库清空），
      // 也能从 MediaStore 索引里认出实际有哪些文件。
      final onDisk = await _listOnDisk(useMediaStore);

      // 探测已存在的槽位备份，读出各自的时间戳以排新旧顺序。
      final existing = <String, DateTime?>{};
      for (final name in slotFileNames) {
        if (!onDisk.contains(name)) continue;
        final ts = await _readSlotTimestamp(name, useMediaStore);
        if (ts != null) existing[name] = ts;
      }
      // 旧版本（带时间戳命名）留下的文件，一并清掉，避免越攒越多。
      await _deleteLegacyFiles(useMediaStore, onDisk);

      // 挑一个槽位覆盖写：优先挑最旧且已存在的那份。
      final order = existing.keys.toList()
        ..sort((a, b) {
          final ta = existing[a] ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tb = existing[b] ?? DateTime.fromMillisecondsSinceEpoch(0);
          return ta.compareTo(tb);
        });
      final slot = pickOverwriteSlot(existing.keys.toList(), order);
      final fileName = backupFileName(slot);

      String? savedPath;
      if (useMediaStore) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final temp = File(p.join(dir.path, fileName));
          await temp.writeAsBytes(bytes);
          final info = await MediaStore().saveFile(
            tempFilePath: temp.path,
            dirType: DirType.download,
            dirName: DirName.download,
            relativePath: backupRelativePath,
          );
          // 无论 MediaStore 是否真的落盘，先把临时文件清掉
          if (await temp.exists()) await temp.delete();
          savedPath = info?.uri.toString();
        } catch (_) {
          savedPath = null;
        }
      }

      // 降级：MediaStore 不可用（非 Android / 初始化失败）时写 App 私有目录。
      // 这份文件卸载即删，无法替代 Download 那份；但至少「有备份」，不会静默丢失。
      if (savedPath == null) {
        final dir = await getApplicationDocumentsDirectory();
        final f = File(p.join(dir.path, fileName));
        await f.writeAsBytes(bytes);
        savedPath = f.path;
      }

      await repo.setSetting(lastRunKey, now.toIso8601String());

      return AutoBackupResult(
        status: AutoBackupStatus.done,
        path: savedPath,
        counts: {for (final e in data.entries) e.key: e.value.length},
        slot: slot,
      );
    } catch (e) {
      return AutoBackupResult(
        status: AutoBackupStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// 读某个槽位备份的导出时间；文件不存在或读不出来时返回 null。
  ///
  /// 用文件内容里的 `exportedAt` 而不是文件名——文件名是固定的，
  /// 只有内容里的时间戳才能区分新旧。
  static Future<DateTime?> _readSlotTimestamp(
    String fileName,
    bool useMediaStore,
  ) async {
    try {
      if (!useMediaStore) {
        final dir = await getApplicationDocumentsDirectory();
        final f = File(p.join(dir.path, fileName));
        if (!await f.exists()) return null;
        final parsed = BackupCodec.parse(await f.readAsString());
        return _parseExportedAt(parsed?.exportedAt);
      }
      // MediaStore：先探测存在性，再读内容。
      final exists = await MediaStore().isFileExist(
        fileName: fileName,
        dirType: DirType.download,
        dirName: DirName.download,
        relativePath: backupRelativePath,
      );
      if (!exists) return null;
      final dir = await getApplicationDocumentsDirectory();
      final temp = File(p.join(dir.path, 'slot-read-$fileName'));
      final ok = await MediaStore().readFile(
        tempFilePath: temp.path,
        fileName: fileName,
        dirType: DirType.download,
        dirName: DirName.download,
        relativePath: backupRelativePath,
      );
      if (!ok || !await temp.exists()) return null;
      final raw = await temp.readAsString();
      if (await temp.exists()) await temp.delete();
      return _parseExportedAt(BackupCodec.parse(raw)?.exportedAt);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseExportedAt(String? iso) {
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// 删除旧版本命名（带时间戳）的自动备份文件。
  ///
  /// 旧格式是 `reading-tracker-auto-YYYYMMDD-HHMM.json`，每备份一次多一个，
  /// 会无限堆积。现在改成固定槽位后这些就是纯垃圾，必须清掉。
  ///
  /// 只能删**本 App 自己的旧格式**——用户手动导出的
  /// `reading-tracker-YYYYMMDD.json` 不含 `auto`，不在匹配范围内。
  ///
  /// [onDisk] 是新目录下的文件名；旧目录（v1.3.0 误落的 `Download/backups/`）
  /// 单独再查一次，一并清掉。
  static Future<void> _deleteLegacyFiles(
    bool useMediaStore,
    List<String> onDisk,
  ) async {
    final legacy = legacyAutoBackupNames(onDisk);
    List<String> legacyDir = const [];
    if (useMediaStore) {
      legacyDir = await _listDownloadFiles(legacyRelativePath);
    }
    final targets = <String, String>{
      for (final n in legacy) n: backupRelativePath,
      for (final n in legacyAutoBackupNames(legacyDir)) n: legacyRelativePath,
    };
    for (final entry in targets.entries) {
      try {
        if (useMediaStore) {
          await MediaStore().deleteFile(
            fileName: entry.key,
            dirType: DirType.download,
            dirName: DirName.download,
            relativePath: entry.value,
          );
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final f = File(p.join(dir.path, entry.key));
          if (await f.exists()) await f.delete();
        }
      } catch (_) {
        // 忽略个别删除失败
      }
    }
  }

  /// 列出 Download 下某个相对目录的真实文件名（走原生查 MediaStore）。
  static Future<List<String>> _listDownloadFiles(String relativePath) async {
    try {
      final res = await const MethodChannel(_systemChannel)
          .invokeListMethod<String>('listDownloadFiles', {
        'relativePath': relativePath,
      });
      if (res != null) return res.where((e) => e.isNotEmpty).toList();
    } catch (_) {
      // 原生不可用（单元测试环境 / 非 Android）→ 空列表
    }
    return const [];
  }

  /// 列出备份目录下的真实文件名。
  ///
  /// 优先用原生查 MediaStore（拿得到系统媒体库的完整索引）；
  /// 拿不到时退化为「只认得槽位文件名」，此时至少不会误删。
  static Future<List<String>> _listOnDisk(bool useMediaStore) async {
    if (useMediaStore) {
      final res = await _listDownloadFiles(backupRelativePath);
      if (res.isNotEmpty) return res;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final d = Directory(dir.path);
      if (!await d.exists()) return const [];
      return d
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class AutoBackupState {
  final bool enabled;
  final int intervalDays;
  final String? lastIso;
  const AutoBackupState({
    required this.enabled,
    required this.intervalDays,
    required this.lastIso,
  });
}

enum AutoBackupStatus { skipped, done, failed }

class AutoBackupResult {
  final AutoBackupStatus status;
  final String? path;
  final String? error;
  final Map<String, int>? counts;
  final String? reason;

  /// 本次写入的槽位号（1..[AutoBackup.keepCount]）。
  final int? slot;
  const AutoBackupResult({
    required this.status,
    this.path,
    this.error,
    this.counts,
    this.reason,
    this.slot,
  });
}
