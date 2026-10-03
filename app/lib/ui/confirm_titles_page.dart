import '../l10n/app_loc.dart';
import 'package:flutter/material.dart';

import '../import/import_manager.dart';
import '../import/shelf_layout.dart';
import '../import/shelf_ocr_parser.dart';
import '../models/enums.dart';

/// 书名候选确认页。
///
/// OCR 一定会有错——问题不在于消灭错误，而在于**让错误可见且可改**。
/// 所以每一条都能就地编辑标题与作者，能删掉误判的行，也能手动补一本
/// OCR 完全没读到的书。默认只勾选置信度到线的，其余留给用户判断。
class ConfirmTitlesPage extends StatefulWidget {
  final List<TitleCandidate> candidates;
  final BookSource platform;
  final OcrDiagnostics? diag;
  final OcrMode? mode;
  final String? rawText;

  const ConfirmTitlesPage({
    super.key,
    required this.candidates,
    required this.platform,
    this.diag,
    this.mode,
    this.rawText,
  });

  @override
  State<ConfirmTitlesPage> createState() => _ConfirmTitlesPageState();
}

class _ConfirmTitlesPageState extends State<ConfirmTitlesPage> {
  late List<_RowCtrl> _rows;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _rows = widget.candidates.map(_RowCtrl.new).toList();
    for (var i = 0; i < _rows.length; i++) {
      if (_rows[i].source.score >= 0.6) _selected.add(i);
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addManual() {
    setState(() {
      final c = TitleCandidate(title: '', score: 0.7, reason: appLoc.s_18307d56);
      _rows.add(_RowCtrl(c));
      _selected.add(_rows.length - 1);
    });
  }

  void _remove(int i) {
    setState(() {
      _rows[i].dispose();
      _rows.removeAt(i);
      final next = <int>{};
      for (final s in _selected) {
        if (s == i) continue;
        next.add(s > i ? s - 1 : s);
      }
      _selected
        ..clear()
        ..addAll(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diag = widget.diag;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLoc.s_cc0eef03(length: _rows.length)),
        actions: [
          TextButton(
            onPressed: () => setState(() =>
                _selected.addAll(List.generate(_rows.length, (i) => i))),
            child: Text(appLoc.s_0f466d7a),
          ),
          TextButton(
            onPressed: () => setState(_selected.clear),
            child: Text(appLoc.s_42b2fafa),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (diag != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLoc.s_7feb7674(totalLines: diag.totalLines, keptLines: diag.keptLines, usedLlm: diag.usedLlm ? appLoc.s_da4d4d27 : '', repairedTitles: diag.repairedTitles > 0 ? appLoc.s_af735e5a(repairedTitles: diag.repairedTitles) : ''),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appLoc.s_4d52323f,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ...List.generate(_rows.length, _tile),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _addManual,
              icon: const Icon(Icons.add, size: 18),
              label: Text(appLoc.s_0f40975c),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    final out = <TitleCandidate>[];
                    for (final i in _selected) {
                      final c = _rows[i].toCandidate();
                      if (c.title.trim().isEmpty) continue;
                      out.add(c);
                    }
                    Navigator.pop(context, out);
                  },
            child: Text(appLoc.s_fdc0acd1(length: _selected.length)),
          ),
        ),
      ),
    );
  }

  Widget _tile(int i) {
    final row = _rows[i];
    final c = row.source;
    final cs = Theme.of(context).colorScheme;
    final checked = _selected.contains(i);

    final tags = <String>[
      if (c.inferred) appLoc.s_af041a1b,
      if (c.truncated) appLoc.s_4443bd2c,
      if (c.progressPercent != null) appLoc.s_7af46a28(progressPercent: c.progressPercent!.toStringAsFixed(c.progressPercent! < 10 ? 1 : 0)),
      if (c.statusHint != null) c.statusHint!.label,
      appLoc.s_4737de25(toStringAsFixed: (c.score * 100).toStringAsFixed(0)),
      if (c.reason.isNotEmpty) c.reason,
    ];

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              onChanged: (v) => setState(
                  () => v == true ? _selected.add(i) : _selected.remove(i)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: row.title,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: appLoc.s_04a1b347,
                      border: const UnderlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (c.rawText.isNotEmpty && c.rawText != c.title)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(appLoc.s_2df91ffc(rawText: c.rawText),
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: row.author,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: appLoc.s_7bbe0f10,
                      border: const UnderlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: c.inferred || c.truncated
                                    ? cs.errorContainer
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: c.inferred || c.truncated
                                        ? cs.onErrorContainer
                                        : cs.onSurfaceVariant,
                                  )),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: appLoc.s_bd13cf0b,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => _remove(i),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一行候选的编辑控制器
class _RowCtrl {
  final TitleCandidate source;
  final TextEditingController title;
  final TextEditingController author;

  _RowCtrl(this.source)
      : title = TextEditingController(text: source.title),
        author = TextEditingController(text: source.author ?? '');

  void dispose() {
    title.dispose();
    author.dispose();
  }

  TitleCandidate toCandidate() {
    final t = title.text.trim();
    final a = author.text.trim();
    final edited = t != source.title;
    return TitleCandidate(
      title: t,
      author: a.isEmpty ? null : a,
      score: source.score,
      reason: source.reason,
      progressPercent: source.progressPercent,
      statusHint: source.statusHint,
      truncated: source.truncated,
      // 用户手改过的书名就是原文，不该再被标成「推测」
      inferred: edited ? false : source.inferred,
      rawText: source.rawText,
    );
  }
}
