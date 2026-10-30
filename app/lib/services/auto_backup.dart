import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
/// **设计要点**（与 [AutoShelve] 同思路）：
/// - 纯函数 [shouldRun] / [backupFileName] / [pruneHistory] 单独抽出，便于穷举测试；
///   这类「批量改用户数据」的逻辑改错很难察觉。
/// - 真正的写盘放在 [runIfDue] 里，且对任何异常降级到 App 私有文档目录，
///   保证「至少产出一个文件」，不会让自动备份静默失败。
class AutoBackup {
  AutoBackup._();

  /// 设置键：是否启用自动备份。默认见 [defaultEnabled]。
  static const String enabledKey = 'auto_backup_enabled';

  /// 设置键：备份间隔（天）。取值见 [intervalPresets] 的键。
  static const String intervalKey = 'auto_backup_interval_days';

  /// 设置键：上次成功备份时间（ISO8601）。用于「到点才跑」的节流。
  static const String lastRunKey = 'last_auto_backup_at';

  /// 设置键：备份文件名历史（JSON 数组），用于滚动保留最近 [keepCount] 份。
  static const String historyKey = 'auto_backup_history';

  /// 默认开启：用户刚经历过一次丢数据，默认开能避免重蹈覆辙。
  static const bool defaultEnabled = true;

  /// 默认每周一次。
  static const int defaultIntervalDays = 7;

  /// 只保留最近这么多份自动备份，更早的删掉，避免 Download 越攒越多。
  static const int keepCount = 5;

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

  /// 自动备份文件名：`reading-tracker-auto-YYYYMMDD-HHMM.json`。
  @visibleForTesting
  static String backupFileName(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return 'reading-tracker-auto-$y$m$d-$hh$mm.json';
  }

  /// 从历史文件名列表里挑出「应当删除」的部分。
  ///
  /// 文件名含时间戳，字典序即时间序；按降序排，留最新 [keep] 个，其余删除。
  @visibleForTesting
  static List<String> pruneHistory(List<String> history, int keep) {
    if (history.length <= keep) return const [];
    final sorted = [...history];
    sorted.sort((a, b) => b.compareTo(a));
    return sorted.skip(keep).toList();
  }

  /// 读出当前设置（带默认值与容错解析）。
  static Future<_AutoBackupState> readState(BookRepository repo) async {
    final enabledRaw = await repo.getSetting(enabledKey);
    final intervalRaw = await repo.getSetting(intervalKey);
    final lastIso = await repo.getSetting(lastRunKey);
    final historyRaw = await repo.getSetting(historyKey);

    final enabled = enabledRaw == null ? defaultEnabled : enabledRaw == 'true';
    final intervalDays = int.tryParse(intervalRaw ?? '') ?? defaultIntervalDays;

    List<String> history = const [];
    if (historyRaw != null && historyRaw.isNotEmpty) {
      try {
        final list = jsonDecode(historyRaw);
        if (list is List) {
          history = [for (final e in list) if (e is String) e];
        }
      } catch (_) {
        history = const [];
      }
    }
    return _AutoBackupState(
      enabled: enabled,
      intervalDays: intervalDays,
      lastIso: lastIso,
      history: history,
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
    _AutoBackupState state,
  ) async {
    try {
      final data = await repo.dumpTables();
      final payload = BackupCodec.build(data: data, now: now);
      final text = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = utf8.encode(text);
      final fileName = backupFileName(now);

      String? savedPath;
      try {
        await ensureReady();
        if (_initialized) {
          final dir = await getApplicationDocumentsDirectory();
          final temp = File(p.join(dir.path, fileName));
          await temp.writeAsBytes(bytes);
          final info = await MediaStore().saveFile(
            tempFilePath: temp.path,
            dirType: DirType.download,
            dirName: DirName.download,
            relativePath: 'backups',
          );
          // 无论 MediaStore 是否真的落盘，先把临时文件清掉
          if (await temp.exists()) await temp.delete();
          savedPath = info?.uri.toString();
        }
      } catch (_) {
        savedPath = null;
      }

      // 降级：MediaStore 不可用（非 Android / 初始化失败）时写 App 私有目录。
      // 这份文件卸载即删，无法替代 Download 那份；但至少「有备份」，不会静默丢失。
      if (savedPath == null) {
        final dir = await getApplicationDocumentsDirectory();
        final f = File(p.join(dir.path, fileName));
        await f.writeAsBytes(bytes);
        savedPath = f.path;
      }

      // 更新时间戳 + 历史（用于滚动保留）
      final history = [...state.history, fileName];
      final toDelete = pruneHistory(history, keepCount);
      final kept = history.where((h) => !toDelete.contains(h)).toList();
      await repo.setSetting(lastRunKey, now.toIso8601String());
      await repo.setSetting(historyKey, jsonEncode(kept));

      // 删除超出保留数量的旧备份（best-effort，失败不阻断）
      for (final old in toDelete) {
        try {
          if (_initialized) {
            await MediaStore().deleteFile(
              fileName: old,
              dirType: DirType.download,
              dirName: DirName.download,
              relativePath: 'backups',
            );
          } else {
            final dir = await getApplicationDocumentsDirectory();
            final f = File(p.join(dir.path, old));
            if (await f.exists()) await f.delete();
          }
        } catch (_) {
          // 忽略个别删除失败
        }
      }

      return AutoBackupResult(
        status: AutoBackupStatus.done,
        path: savedPath,
        counts: {for (final e in data.entries) e.key: e.value.length},
      );
    } catch (e) {
      return AutoBackupResult(
        status: AutoBackupStatus.failed,
        error: e.toString(),
      );
    }
  }
}

class _AutoBackupState {
  final bool enabled;
  final int intervalDays;
  final String? lastIso;
  final List<String> history;
  const _AutoBackupState({
    required this.enabled,
    required this.intervalDays,
    required this.lastIso,
    required this.history,
  });
}

enum AutoBackupStatus { skipped, done, failed }

class AutoBackupResult {
  final AutoBackupStatus status;
  final String? path;
  final String? error;
  final Map<String, int>? counts;
  final String? reason;
  const AutoBackupResult({
    required this.status,
    this.path,
    this.error,
    this.counts,
    this.reason,
  });
}
