import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import '../import/image_preprocess.dart';
import '../import/import_manager.dart';
import '../import/ocr_line.dart';
import '../import/shelf_layout.dart';
import '../import/shelf_ocr_parser.dart';

/// 导入中心：截图 OCR / 拍照识别 / CSV / 微信读书官方接口
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final _picker = ImagePicker();

  /// OCR 识别器创建一次就够了。
  /// ML Kit 的 `TextRecognizer` 初始化要加载模型，每次识别都新建
  /// 会让每张图多花几百毫秒，连续导入时体验很差。
  TextRecognizer? _recognizer;

  bool _busy = false;
  String? _message;
  String? _stage;
  /// 导入进度 0-1；null 表示当前不是可计量的批量作业
  double? _progress;
  /// 失败原因。只显示「失败 3 本」用户无从判断问题出在哪，
  /// 把每条原因留在这里展开可见。
  List<String> _failures = const [];

  TextRecognizer get _ocr => _recognizer ??=
      TextRecognizer(script: TextRecognitionScript.chinese);

  @override
  void dispose() {
    _recognizer?.close();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() {
      _busy = true;
      _message = null;
      _stage = null;
      _progress = null;
      _failures = const [];
    });
    try {
      await task();
    } catch (e) {
      setState(() => _message = '出错了：${_friendly(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = null;
          _progress = null;
        });
      }
    }
  }

  /// 截图 / 拍照 → 图像增强 → 端侧 OCR → 版面解析 → 书名候选确认
  Future<void> _fromImage(ImageSource source, BookSource platform) async {
    // imageQuality 给 100：OCR 要的是笔画完整，
    // 默认的压缩会把小字的细节抹掉，识别率直接下降
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 2400,
    );
    if (file == null) return;

    await _run(() async {
      String path = file.path;
      String? enhanced;

      if (ref.read(ocrEnhanceProvider)) {
        setState(() => _stage = '正在增强图像…');
        enhanced = await ImagePreprocessor.enhanceToFile(file.path);
        if (enhanced != file.path) path = enhanced;
      }

      try {
        setState(() => _stage = '正在识别文字…');
        final input = InputImage.fromFilePath(path);
        final result = await _ocr.processImage(input);
        final lines = _toLines(result);

        if (lines.isEmpty) {
          setState(() => _message =
              '这张图里没读到文字。换个角度、让文字更清晰，或直接截屏（截屏的文字比拍照更规整）。');
          return;
        }

        // 场景判定：先把图当成书架试一遍，落出 3 本以上就按书架处理；
        // 否则当成单本图书（封面/书脊/内页），取字号最大的那行当书名。
        final shelfTry = ShelfLayoutParser.parse(lines, mode: OcrMode.shelf);
        final mode = shelfTry.length >= 3 ? OcrMode.shelf : OcrMode.cover;

        final manager = ref.read(importManagerProvider);
        final r = await manager.recognizeFromLines(
          lines,
          mode: mode,
          onStage: (s) => setState(() => _stage = s),
        );

        if (!mounted) return;
        if (r.candidates.isEmpty) {
          setState(() => _message = mode == OcrMode.cover
              ? '没读到像书名的文字。如果是书内页，书名通常不在页面上——试试点「截图导入书架」或直接拍封面。'
              : '没能从图中识别出书名，试试裁掉多余界面元素后重试');
          return;
        }

        final picked = await Navigator.push<List<TitleCandidate>>(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmTitlesPage(
              candidates: r.candidates,
              platform: platform,
              diag: r.diag,
              mode: mode,
              rawText: lines.map((l) => l.text).join('\n'),
            ),
          ),
        );
        if (picked == null || picked.isEmpty) return;
        await _commit(picked.map((c) => c.toBook(source: platform)).toList());
      } finally {
        await ImagePreprocessor.cleanup(enhanced, original: file.path);
      }
    });
  }

  /// ML Kit 结果 → 带坐标的行。
  ///
  /// 一定要用 `blocks → lines` 而不是 `result.text`：后者是纯文本，
  /// 丢了每个字的坐标，多列书架里就无法判断「0.8%」属于哪本书。
  static List<OcrLine> _toLines(RecognizedText result) {
    final out = <OcrLine>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isEmpty) continue;
        final box = line.boundingBox;
        out.add(OcrLine(
          text: t,
          left: box.left,
          top: box.top,
          right: box.right,
          bottom: box.bottom,
        ));
      }
    }
    return out;
  }

  /// CSV / Notion 导出导入
  Future<void> _fromCsv() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = res?.files.single.path;
    if (path == null) return;

    await _run(() async {
      final content = await File(path).readAsString();
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.isEmpty) return;

      final headers = rows.first.map((e) => e.toString()).toList();
      final idx = <String, int>{};
      for (var i = 0; i < headers.length; i++) {
        idx[headers[i].trim().toLowerCase()] = i;
      }

      int? col(List<String> names) {
        for (final n in names) {
          final v = idx[n.toLowerCase()];
          if (v != null) return v;
        }
        return null;
      }

      final cTitle = col(['书名', 'title', 'name']);
      if (cTitle == null) {
        setState(() => _message = 'CSV 里找不到「书名」列');
        return;
      }
      final cAuthor = col(['作者', 'author', 'authors']);
      final cStatus = col(['状态', 'status']);
      final cRating = col(['评分', 'rating']);
      final cProgress = col(['进度', 'progress']);
      final cCategory = col(['分类', 'category']);
      final cPublisher = col(['出版社', 'publisher']);

      final books = <Book>[];
      for (final row in rows.skip(1)) {
        final title = _cell(row, cTitle);
        if (title.isEmpty) continue;
        books.add(
          Book.create(title: title, source: BookSource.notion).copyWith(
            authors: cAuthor != null ? [_cell(row, cAuthor)] : const [],
            publisher: cPublisher != null ? _cell(row, cPublisher) : null,
            categoryPrimary: cCategory != null ? _cell(row, cCategory) : null,
            status: _parseStatus(_cell(row, cStatus)),
            rating: _parseRating(_cell(row, cRating)),
            progressPercent: _parseProgress(_cell(row, cProgress)),
          ),
        );
      }
      if (books.isEmpty) return;
      final ok = await _confirm('解析到 ${books.length} 本书，确认导入？');
      if (ok != true) return;
      await _commit(books);
    });
  }

  /// 微信读书官方接口同步
  Future<void> _fromWeread() async {
    final gateway = ref.read(wereadGatewayProvider);
    if (!gateway.available) {
      final key = await _askKey();
      if (key == null || key.isEmpty) return;
      await saveSetting(ref, 'weread_key', key);
    }
    await _run(() async {
      final g = ref.read(wereadGatewayProvider);
      final manager = ref.read(importManagerProvider);
      setState(() => _stage = '正在读取微信读书书架…');
      final books = await manager.fetchWereadShelf(g);
      if (books.isEmpty) {
        setState(() => _message = '书架为空或接口未返回数据');
        return;
      }
      final ok = await _confirm('微信读书书架共 ${books.length} 本，确认导入？');
      if (ok != true) return;
      await _commit(books);
    });
  }

  Future<void> _commit(List<Book> books) async {
    final manager = ref.read(importManagerProvider);
    final failures = <String>[];
    final result = await manager.commit(
      books,
      failures: failures,
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() {
          _stage = '正在补全元数据并入库…';
          _progress = total == 0 ? null : done / total;
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _failures = failures;
      _message = '导入完成：新增 ${result.added} 本，更新 ${result.duplicated} 本'
          '${result.failed > 0 ? '，失败 ${result.failed} 本' : ''}';
    });
  }

  /// 逐本拉取阅读进度。
  ///
  /// 书架接口不含百分比，只能一本本地问，所以做成显式动作而不是
  /// 每次同步都顺带跑——55 本书就是 55 次请求。
  Future<void> _syncProgress() async {
    final gateway = ref.read(wereadGatewayProvider);
    if (!gateway.available) {
      final key = await _askKey();
      if (key == null || key.isEmpty) return;
      await saveSetting(ref, 'weread_key', key);
    }

    await _run(() async {
      final repo = ref.read(repoProvider);
      final books = await repo.all(source: BookSource.weread);
      final ids = books
          .map((b) => b.sourceBookId)
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
      if (ids.isEmpty) {
        setState(() => _message = '本地还没有微信读书的书，先做一次书架同步');
        return;
      }

      final manager = ref.read(importManagerProvider);
      final updated = await manager.syncProgress(
        ids,
        gateway: ref.read(wereadGatewayProvider),
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _stage = '正在同步阅读进度…';
            _progress = total == 0 ? null : done / total;
          });
        },
      );
      if (!mounted) return;
      setState(() => _message = '已更新 $updated / ${ids.length} 本的阅读进度');
    });
  }

  static String _cell(List<dynamic> row, int? i) {
    if (i == null || i >= row.length) return '';
    return (row[i] ?? '').toString().trim();
  }

  static BookStatus _parseStatus(String s) => switch (s) {
        '在读' || 'reading' => BookStatus.reading,
        '已读' || 'finished' => BookStatus.finished,
        '弃读' || 'abandoned' => BookStatus.abandoned,
        '借阅中' || 'borrowed' => BookStatus.borrowed,
        '暂搁' || 'paused' => BookStatus.paused,
        _ => BookStatus.wish,
      };

  static double _parseRating(String s) {
    final stars = '★'.allMatches(s).length;
    if (stars > 0) return stars.toDouble();
    return double.tryParse(s) ?? 0;
  }

  static double _parseProgress(String s) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(s);
    if (m != null) return double.parse(m.group(1)!);
    return 0;
  }

  /// 把异常翻成人话。DioException 的原始字符串对用户毫无信息量。
  static String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('Software caused connection abort') ||
        s.contains('Connection reset')) {
      return '网络连接被中断，检查网络后重试';
    }
    return s;
  }

  Future<bool?> _confirm(String text) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认'),
          content: Text(text),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('导入')),
          ],
        ),
      );

  Future<String?> _askKey() => showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('微信读书 API Key'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '用微信扫码打开 weread.qq.com/r/weread-skills，\n'
                  '复制页面上的 Key（wrk- 开头）。Key 只保存在本机。',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'wrk-xxx')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  child: const Text('保存')),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_message != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_message!, style: const TextStyle(fontSize: 13)),
                ),
              if (_failures.isNotEmpty) _failureBox(context),
              _card(
                icon: Icons.screenshot_outlined,
                title: '截图导入书架',
                desc: '微信读书 / 掌阅 / 京东读书的书架截图，按版面识别每一格的书名与进度，'
                    '自动补齐被界面截断的标题。',
                onTap: () => _fromImage(ImageSource.gallery, BookSource.zhangyue),
              ),
              _card(
                icon: Icons.photo_camera_outlined,
                title: '拍照识别图书',
                desc: '拍封面或书脊，取字号最大的一行当书名，再自动补全作者、出版社、简介、分类。',
                onTap: () => _fromImage(ImageSource.camera, BookSource.library),
              ),
              _card(
                icon: Icons.cloud_sync_outlined,
                title: '微信读书同步',
                desc: '通过官方开放接口读取书架与阅读状态，无需截图。',
                onTap: _fromWeread,
              ),
              _card(
                icon: Icons.timeline_outlined,
                title: '同步阅读进度',
                desc: '逐本拉取阅读百分比与累计时长。书架接口不含进度，需单独请求。',
                onTap: _syncProgress,
              ),
              _card(
                icon: Icons.upload_file_outlined,
                title: 'CSV / Notion 导入',
                desc: '从 Notion 导出的 CSV 一键迁移，列名自动识别，自定义字段不丢失。',
                onTap: _fromCsv,
              ),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black38,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_stage ?? '处理中…'),
                        const SizedBox(height: 12),
                        if (_progress != null)
                          LinearProgressIndicator(value: _progress)
                        else
                          const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 失败明细。默认折叠，点开才展开，避免一次导入失败十几本时刷屏
  Widget _failureBox(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: cs.error.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.error_outline, color: cs.error),
        title: Text('${_failures.length} 本未能导入',
            style: TextStyle(fontSize: 13, color: cs.error)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in _failures.take(20))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $f',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ),
          if (_failures.length > 20)
            Text('…另有 ${_failures.length - 20} 条',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(desc, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        onTap: _busy ? null : onTap,
      ),
    );
  }
}

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
      final c = TitleCandidate(title: '', score: 0.7, reason: '手动添加');
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
        title: Text('识别到 ${_rows.length} 本'),
        actions: [
          TextButton(
            onPressed: () => setState(() =>
                _selected.addAll(List.generate(_rows.length, (i) => i))),
            child: const Text('全选'),
          ),
          TextButton(
            onPressed: () => setState(_selected.clear),
            child: const Text('全不选'),
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
                    '识别到 ${diag.totalLines} 行文字，采用 ${diag.keptLines} 本'
                    '${diag.usedLlm ? ' · 已用大模型整理' : ''}'
                    '${diag.repairedTitles > 0 ? ' · 已补齐 ${diag.repairedTitles} 个截断书名' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '带「补齐」「推测」标记的条目，书名不是原图原文，请确认后再导入。'
                    '标题与作者都可以点开修改。',
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
              label: const Text('手动添加一本（OCR 没读到的）'),
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
            child: Text('导入选中的 ${_selected.length} 本'),
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
      if (c.inferred) '书名已补齐',
      if (c.truncated) '原图被截断',
      if (c.progressPercent != null) '进度 ${c.progressPercent!.toStringAsFixed(c.progressPercent! < 10 ? 1 : 0)}%',
      if (c.statusHint != null) c.statusHint!.label,
      '置信度 ${(c.score * 100).toStringAsFixed(0)}%',
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
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '书名',
                      border: UnderlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (c.rawText.isNotEmpty && c.rawText != c.title)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('原图：${c.rawText}',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant)),
                    ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: row.author,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '作者（可留空）',
                      border: UnderlineInputBorder(),
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
              tooltip: '删掉这条',
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
