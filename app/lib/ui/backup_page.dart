import 'dart:convert';
import '../l10n/app_loc.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/backup.dart';
import '../providers.dart';

/// 数据导出与恢复。
///
/// 一键导出是**跨平台迁移**的唯一保障：换手机、换系统、App 重装，
/// 没有它就只能从头再导一遍书。所以导出的一定是整库快照
/// （books / reading_logs / notes / llm_reports / settings），
/// 不是「能看的一份报表」。
///
/// 用系统另存为对话框（SAF / NSSavePanel）而不是写死一个目录：
/// 写进 App 私有目录用户根本取不出来，等于没导出。
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;
  String? _note;
  bool _noteOk = true;

  void _set(bool ok, String msg) => setState(() {
        _noteOk = ok;
        _note = msg;
      });

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(repoProvider);
      final data = await repo.dumpTables();
      final payload = BackupCodec.build(data: data, now: DateTime.now());
      final text = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = utf8.encode(text);

      final now = DateTime.now();
      final stamp = '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final name = 'reading-tracker-$stamp.json';

      String? saved;
      try {
        saved = await FilePicker.platform.saveFile(
          dialogTitle: appLoc.s_66772db6,
          fileName: name,
          bytes: Uint8List.fromList(bytes),
        );
      } catch (_) {
        // 桌面端少数版本没实现 saveFile，退回 App 文档目录，
        // 并把路径明确告诉用户——总比静默失败强
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/$name');
        await f.writeAsBytes(bytes);
        saved = f.path;
      }

      if (saved == null) {
        _set(true, appLoc.s_6b198f0b);
        return;
      }
      final counts = {
        for (final e in data.entries) e.key: e.value.length,
      };
      _set(true, appLoc.s_a101fbdd(saved: saved, counts: _fmtCounts(counts)));
    } catch (e) {
      _set(false, appLoc.s_6ec2d38e(e: e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final res = await FilePicker.platform.pickFiles(
      dialogTitle: appLoc.s_c699263b,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;

    final path = res.files.first.path;
    String raw;
    try {
      // 优先用 withData 带回来的字节：Android 上 content:// 的 path
      // 可能是临时副本，直接 File(path) 读会拿到空文件
      final bytes = res.files.first.bytes;
      raw = bytes != null
          ? utf8.decode(bytes)
          : await File(path!).readAsString();
    } catch (e) {
      _set(false, appLoc.s_e34bdbcb(e: e));
      return;
    }

    final parsed = BackupCodec.parse(raw);
    if (parsed == null) {
      _set(false, appLoc.s_1dedeaa2);
      return;
    }
    if (parsed.data.isEmpty) {
      _set(false, appLoc.s_103c5811);
      return;
    }

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text(appLoc.s_674a7957),
        content: Text(
          appLoc.s_94094e0d(length: _fmtCounts({for (final e in parsed.data.entries) e.key: e.value.length})),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:  Text(appLoc.s_a0451c97)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:  Text(appLoc.s_ec7085ab)),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final counts = await ref.read(repoProvider).restoreTables(parsed.data);
      _set(true,
          appLoc.s_2296b134(first: parsed.exportedAt == null ? '' : appLoc.s_a537d6ac(first: parsed.exportedAt!.split('T').first), counts: _fmtCounts(counts)));
    } catch (e) {
      _set(false, appLoc.s_e669bac1(e: e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtCounts(Map<String, int> c) => [
        if ((c['books'] ?? 0) > 0) appLoc.s_7c0be1cd(books: c['books']),
        if ((c['notes'] ?? 0) > 0) appLoc.s_dd2321ce(notes: c['notes']),
        if ((c['reading_logs'] ?? 0) > 0) appLoc.s_d48aa751(reading_logs: c['reading_logs']),
        if ((c['llm_reports'] ?? 0) > 0) appLoc.s_d044717e(llm_reports: c['llm_reports']),
        if ((c['settings'] ?? 0) > 0) appLoc.s_f4d248a7(settings: c['settings']),
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title:  Text(appLoc.s_8719bf89)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(appLoc.s_8fe27f12, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            appLoc.s_5d9af0a7,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.ios_share_outlined),
            label:  Text(appLoc.s_582f4cb6),
          ),
          const SizedBox(height: 24),

          Text(appLoc.s_091ad5f4, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            appLoc.s_3a36f742,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.settings_backup_restore_outlined),
            label:  Text(appLoc.s_6f9ab88c),
          ),

          if (_busy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_note != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _noteOk ? cs.primaryContainer : cs.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                _note!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: _noteOk ? cs.onPrimaryContainer : cs.onErrorContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
