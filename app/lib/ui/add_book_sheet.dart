import 'dart:io';
import '../l10n/app_loc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'book_form_page.dart';
import 'catalog_search_page.dart';
import 'confirm_titles_page.dart';
import '../import/image_preprocess.dart';
import '../import/import_manager.dart';
import '../import/llm_shelf_parser.dart';
import '../import/ocr_line.dart';
import '../import/shelf_layout.dart';
import '../import/shelf_ocr_parser.dart';
import 'theme.dart';

/// 添加图书：底部抽屉，列出全部入库方式。
///
/// 为什么把原来的「导入」整页收进一个抽屉：
/// 用户的心智动作只有一个——「我要把书加进来」。至于加的方式是手填、
/// 拍照、还是从渠道同步，是他点开之后才关心的事。做成独立一页意味着
/// 他要先想清楚「这算导入还是算添加」，再判断该点哪个入口；
/// 收成抽屉后，「+」是唯一入口，方式在第二层选。
///
/// 抽屉里**手动填写排第一**：它是唯一不依赖任何外部账号 / 文件 / 网络的
/// 路径，也是出错率最低的。截图与拍照紧跟其后（最常用的两条），
/// 渠道同步、CSV、公开书库搜索依次排在后面。
///
/// 返回值仅表示「抽屉是被正常关闭的」；**是否加过书不要看它**——
/// 用户可能连续加好几本再自己划掉，白名单式的判断必然漏。
/// 调用方在抽屉关闭后无条件重查一次列表即可。
Future<void> showAddBookSheet(BuildContext context) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const AddBookSheet(),
  );
}

class AddBookSheet extends ConsumerStatefulWidget {
  const AddBookSheet({super.key});

  @override
  ConsumerState<AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends ConsumerState<AddBookSheet> {
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

  /// 识别准确性提示默认收起。
  ///
  /// 这句话只在用户**准备用**截图/拍照时才需要，而手动填写是抽屉里的
  /// 第一项、也是最高频的一项——常驻展开会让它在每次添加时都占掉一行。
  /// 做成可展开的一条，需要的人点一下，不需要的人不受打扰。
  bool _noticeOpen = false;

  TextRecognizer get _ocr => _recognizer ??=
      TextRecognizer(script: TextRecognitionScript.chinese);

  @override
  void dispose() {
    _recognizer?.close();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() task) async {
    // 入口先问一句还在不在。这里是六条导入路径（截图 / 拍照 / CSV /
    // Notion / 备份 JSON / 批量导入）的公共入口，而每条路径进来之前都有
    // 一个 await（选图、选文件、跳子页面）——那些 await 期间页面可能
    // 已经被销毁（转屏、切后台被回收、用户直接滑掉抽屉）。
    // 在这里统一挡一道，比在六个调用点各补一次可靠。
    if (!mounted) return;
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
      if (mounted) {
        setState(() => _message = appLoc.s_573b6694(e: _friendly(e)));
      }
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

  /// 手动填写。走原有的全屏表单，成功后立即收抽屉——
  /// 用户添完一本多半就是完事了，让他自己再点一次关闭是多余的。
  Future<void> _manual() async {
    final book = await showBookForm(context);
    if (book == null || !mounted) return;
    await ref.read(repoProvider).insert(book);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// 截图 / 拍照 → 识别 → 书名候选确认
  ///
  /// 两条通道（见 `_recognize`）：端侧 OCR 与多模态大模型。
  /// 选哪条由设置里的「识别方式」决定，默认 `auto` = 多模态优先、
  /// 拿不到结果就回落到端侧——两条路的失败模式完全不同，
  /// 叠加使用比单用任何一条都稳。
  Future<void> _fromImage(ImageSource source, BookSource platform) async {
    // imageQuality 给 100：OCR 要的是笔画完整，
    // 默认的压缩会把小字的细节抹掉，识别率直接下降
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 2400,
    );
    // 系统相册/相机是全屏 Activity，且这条路径第一次调用时会触发
    // 权限申请——Android 在权限变更时可能重建甚至回收本 Activity。
    // await 回来若页面已销毁，下面的 file.path 与 setState 都会抛
    // 「setState() called after dispose()」。
    if (!mounted) return;
    if (file == null) return;

    await _run(() async {
      String path = file.path;
      String? enhanced;

      if (ref.read(ocrEnhanceProvider)) {
        setState(() => _stage = appLoc.s_28690759);
        enhanced = await ImagePreprocessor.enhanceToFile(file.path);
        if (enhanced != file.path) path = enhanced;
      }

      try {
        final r = await _recognize(path);
        if (r == null || r.candidates.isEmpty) {
          if (mounted) setState(() => _message = r?.emptyReason ?? appLoc.s_d5155b2d);
          return;
        }

        if (!mounted) return;
        final picked = await Navigator.push<List<TitleCandidate>>(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmTitlesPage(
              candidates: r.candidates,
              platform: platform,
              diag: r.diag,
              mode: r.mode,
              rawText: r.rawText,
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

  /// 按设置的识别方式跑一条或两条通道，返回候选与诊断信息。
  ///
  /// [emptyReason] 一定要区分通道：多模态失败和 OCR 失败给用户的
  /// 建议完全不同（前者是「模型不支持看图」，后者是「图里没文字」），
  /// 混成一句等于没说。
  Future<_RecognizeResult?> _recognize(String path) async {
    final visionMode = ref.read(ocrVisionModeProvider);
    final manager = ref.read(importManagerProvider);

    if (visionMode != 'device') {
      // 上传整张书架截图到用户自填的多模态大模型属于数据出机，
      // 必须先获得一次性明示同意（隐私政策 §数据出境）。
      final consented = await _ensureImageConsent();
      if (consented) {
        setState(() => _stage = appLoc.s_e20dac78);
        final bytes = await ImagePreprocessor.toJpegBytes(path);
        if (bytes != null) {
          final parser = LlmShelfParser(ref.read(llmClientProvider));
          final vision = await parser.readImage(bytes);
          if (vision != null && vision.isNotEmpty) {
            return _RecognizeResult(
              candidates: vision,
              mode: OcrMode.shelf,
              rawText: vision.map((c) => c.rawText).join('\n'),
              emptyReason: null,
            );
          }
        }
        if (visionMode == 'vision') {
          return _RecognizeResult(
            candidates: [],
            mode: OcrMode.shelf,
            rawText: '',
            emptyReason: appLoc.s_5fea0487,
          );
        }
        // auto：静默回落到端侧，不弹错误——用户要的是结果，不是通道名
        setState(() => _stage = appLoc.s_cdda9381);
      } else {
        // 用户拒绝：直接走端侧 OCR，不再尝试上传
        setState(() => _stage = appLoc.s_b85e4cbc);
      }
    }

    setState(() => _stage = appLoc.s_a9698571);
    final input = InputImage.fromFilePath(path);
    final result = await _ocr.processImage(input);
    final lines = _toLines(result);

    if (lines.isEmpty) {
      return _RecognizeResult(
        candidates: [],
        mode: OcrMode.shelf,
        rawText: '',
        emptyReason: appLoc.s_7ef6b42d,
      );
    }

    // 场景判定：先把图当成书架试一遍，落出 3 本以上就按书架处理；
    // 否则当成单本图书（封面/书脊/内页），取字号最大的那行当书名。
    final shelfTry = ShelfLayoutParser.parse(lines, mode: OcrMode.shelf);
    final mode = shelfTry.length >= 3 ? OcrMode.shelf : OcrMode.cover;

    final r = await manager.recognizeFromLines(
      lines,
      mode: mode,
      onStage: (s) => setState(() => _stage = s),
    );

    return _RecognizeResult(
      candidates: r.candidates,
      diag: r.diag,
      mode: mode,
      rawText: lines.map((l) => l.text).join('\n'),
      emptyReason: mode == OcrMode.cover
          ? appLoc.s_319b9488
          : appLoc.s_37588c9c,
    );
  }

  /// 上传书架截图到多模态大模型前，确认用户已明示同意。
  ///
  /// 同意状态持久化（image_llm_consent），同一安装只需确认一次。
  /// 返回 false 时调用方应回落到端侧 OCR，不离开本机。
  Future<bool> _ensureImageConsent() async {
    if (ref.read(imageLlmConsentProvider)) return true;
    if (!mounted) return false;
    final l10n = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.imageUploadConsentTitle),
        content: Text(l10n.imageUploadConsentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.allow),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(imageLlmConsentProvider.notifier).state = true;
      await saveSetting(ref, 'image_llm_consent', 'true');
      return true;
    }
    return false;
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

      final cTitle = col([appLoc.s_04a1b347, 'title', 'name']);
      if (cTitle == null) {
        setState(() => _message = appLoc.s_a9fe3793);
        return;
      }
      final cAuthor = col([appLoc.s_22760472, 'author', 'authors']);
      final cStatus = col([appLoc.s_759fb403, 'status']);
      final cRating = col([appLoc.s_8331377a, 'rating']);
      final cProgress = col([appLoc.s_3db59388, 'progress']);
      final cCategory = col([appLoc.s_b32f0afe, 'category']);
      final cPublisher = col([appLoc.s_9e160a69, 'publisher']);

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
      final ok = await _confirm(appLoc.s_d4b7c3c7(length: books.length));
      if (ok != true) return;
      await _commit(books);
    });
  }

  /// Goodreads / 通用书库 CSV 导入
  ///
  /// 复用既有 CSV 读取骨架，但按 Goodreads 导出的列名做映射
  /// （Title / Author / My Rating / Exclusive Shelf / ISBN13 / Number of Pages…）。
  /// 这是面向国际市场最稳健的导入路径——Goodreads 允许用户导出整库 CSV，
  /// 而 Apple Books / Kobo 没有公开导入 API，暂只作来源标记。
  Future<void> _fromGoodreadsCsv() async {
    final l10n = S.of(context);
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

      final cTitle = col(['title']);
      if (cTitle == null) {
        setState(() => _message = l10n.goodreadsImportEmpty);
        return;
      }
      final cAuthor = col(['author', 'authors']);
      final cRating = col(['my rating']);
      final cShelf = col(['exclusive shelf']);
      final cIsbn = col(['isbn13', 'isbn']);
      final cPages = col(['number of pages']);
      final cPublisher = col(['publisher']);
      final cYear = col(['year published', 'original publication year']);
      final cShelves = col(['bookshelves']);

      final books = <Book>[];
      for (final row in rows.skip(1)) {
        final title = _cell(row, cTitle);
        if (title.isEmpty) continue;
        final isbn = cIsbn != null ? _cell(row, cIsbn) : '';
        books.add(
          Book.create(title: title, source: BookSource.goodreads).copyWith(
            authors: cAuthor != null
                ? _cell(row, cAuthor).split(RegExp(r'\s+and\s+|;')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : const [],
            publisher: cPublisher != null ? _cell(row, cPublisher) : null,
            isbn13: isbn.isNotEmpty ? isbn : null,
            pageCount: cPages != null ? int.tryParse(_cell(row, cPages)) : null,
            publishedAt: cYear != null ? _cell(row, cYear) : null,
            rating: cRating != null ? _parseRating(_cell(row, cRating)) : 0,
            status: cShelf != null ? _shelfToStatus(_cell(row, cShelf)) : BookStatus.wish,
            tags: cShelves != null
                ? _cell(row, cShelves).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : const [],
          ),
        );
      }
      if (books.isEmpty) return;
      final ok = await _confirm(appLoc.s_d4b7c3c7(length: books.length));
      if (ok != true) return;
      await _commit(books);
    });
  }

  /// 公开书目搜索导入（Google Books / Open Library）
  ///
  /// 面向国际用户：无需账号与 Key，搜到即入库。搜索页只负责检索与挑选，
  /// 入库仍走本处的 `_commit`，保证去重 / 归一化 / 失败明细与其它导入路径一致。
  Future<void> _fromCatalogSearch() async {
    final picked = await Navigator.push<List<Book>>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogSearchPage()),
    );
    if (picked == null || picked.isEmpty) return;
    await _run(() => _commit(picked, enrichMetadata: false));
  }

  /// Goodreads 「Exclusive Shelf」→ 阅读状态
  static BookStatus _shelfToStatus(String s) => switch (s.trim().toLowerCase()) {
        'read' => BookStatus.finished,
        'currently-reading' => BookStatus.reading,
        'to-read' => BookStatus.wish,
        _ => BookStatus.wish,
      };

  /// 渠道官方接口同步书架
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
      setState(() => _stage = appLoc.s_649320a3);
      final books = await manager.fetchWereadShelf(g);
      if (books.isEmpty) {
        setState(() => _message = appLoc.s_e53774ba);
        return;
      }
      final ok = await _confirm(appLoc.s_8151aa42(length: books.length));
      if (ok != true) return;
      await _commit(books);
    });
  }

  /// 入库。
  ///
  /// [enrichMetadata] 默认为 true：OCR / CSV 这类来源字段残缺，需要再补一轮。
  /// 公开书目搜索（[CatalogSearchPage]）传 false——那条路径的元数据本来就是
  /// 从权威书库里取回、且由用户亲自挑的版本，再补一轮既浪费一次网络往返，
  /// 也没有任何字段可补。
  Future<void> _commit(List<Book> books, {bool enrichMetadata = true}) async {
    final manager = ref.read(importManagerProvider);
    final failures = <String>[];
    final result = await manager.commit(
      books,
      enrichMetadata: enrichMetadata,
      failures: failures,
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() {
          _stage = appLoc.s_9b37038a;
          _progress = total == 0 ? null : done / total;
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _failures = failures;
      _message = appLoc.s_c4f36bd6(added: result.added, duplicated: result.duplicated, failed: result.failed > 0 ? appLoc.s_acd7a061(failed: result.failed) : '');
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
        setState(() => _message = appLoc.s_28ab46d9);
        return;
      }

      final manager = ref.read(importManagerProvider);
      final updated = await manager.syncProgress(
        ids,
        gateway: ref.read(wereadGatewayProvider),
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _stage = appLoc.s_6d61442b;
            _progress = total == 0 ? null : done / total;
          });
        },
      );
      if (!mounted) return;
      setState(() => _message = appLoc.s_a26c53db(updated: updated, length: ids.length));
    });
  }

  static String _cell(List<dynamic> row, int? i) {
    if (i == null || i >= row.length) return '';
    return (row[i] ?? '').toString().trim();
  }

  static BookStatus _parseStatus(String s) {
    final t = s.trim();
    // appLoc.* 是运行时取值，不能用在 switch 的常量模式里。
    // 同时接受当前语言的显示名与英文原值（Notion 导出常见英文状态列）。
    bool hits(List<String> labels) => labels.contains(t);
    if (hits([appLoc.s_b9bf9b53, 'reading', 'currently-reading'])) {
      return BookStatus.reading;
    }
    if (hits([appLoc.s_300a32bd, 'finished', 'read'])) return BookStatus.finished;
    // 旧词表（弃读 / 暂搁）与英文 dropped/paused 一并归到「搁置」；
    // 「借阅中」不再是状态，按「在读」处理（借阅标记另有字段承载）
    if (hits([
      appLoc.s_0f4d9c68, 'abandoned', 'dropped',
      appLoc.s_eba88d83, 'shelved', 'paused',
    ])) {
      return BookStatus.shelved;
    }
    if (hits([appLoc.s_fc39b00e, 'borrowed'])) return BookStatus.reading;
    return BookStatus.wish;
  }

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
      return appLoc.s_3a0cf870;
    }
    return s;
  }

  Future<bool?> _confirm(String text) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(appLoc.s_1cbe2507),
          content: Text(text),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(appLoc.s_a0451c97)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(appLoc.s_1df9fbd5)),
          ],
        ),
      );

  Future<String?> _askKey() => showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: Text(appLoc.s_874053cb),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLoc.s_58652b51,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'wrk-xxx')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(appLoc.s_a0451c97)),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  child: Text(appLoc.s_abfe9512)),
            ],
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = S.of(context);

    // 抽屉高度必须**显式收敛**。
    //
    // `showModalBottomSheet(isScrollControlled: true)` 的 builder 拿到的是
    // 松约束（maxHeight = 整屏），内容多高就排多高。八项入口 + 提示条
    // 加起来约 1800px，远超常见机型视口——超出的部分不会裁剪、也不可滚动，
    // 命中测试全落在视口外。真机表现是「抽屉只剩前几项，下面点了没反应」。
    //
    // ⚠️ 只写 `ConstrainedBox(maxHeight:)` **不够**：它给子节点仍是松约束，
    // Stack / ListView 照旧按内容自然高度排版，问题原封不动。
    // 必须用 `SizedBox` 给出**紧**高度，再让 Stack `StackFit.expand`
    // 把这道高度压给 ListView，滚动才真的发生在抽屉内部。
    final maxH = MediaQuery.sizeOf(context).height * 0.92;

    return PopScope(
      // 抽屉里可能有正在跑的导入。此时吞掉返回手势，避免用户在
      // 写库写到一半时划走抽屉——任务本身还在跑，但没了进度反馈，
      // 用户会以为卡死或失败。
      canPop: !_busy,
      child: SizedBox(
        height: maxH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.addBookSheetTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_message != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: panelColor(context, cs.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_message!, style: const TextStyle(fontSize: 13)),
                  ),
                if (_failures.isNotEmpty) _failureBox(context),

                /* ---------------------- 手动填写 ---------------------- */
                _entry(
                  icon: Icons.edit_outlined,
                  title: l10n.addBookManualTitle,
                  desc: l10n.addBookManualDesc,
                  onTap: _manual,
                ),

                /* ---------------------- 识别准确性提示 ---------------------- */
                _noticeBar(context),

                const SizedBox(height: 4),

                /* ---------------------- 截图 / 拍照 ---------------------- */
                _entry(
                  icon: Icons.screenshot_outlined,
                  title: appLoc.s_cb2558f7,
                  desc: appLoc.s_24b715f3,
                  onTap: () => _fromImage(ImageSource.gallery, BookSource.manual),
                ),
                _entry(
                  icon: Icons.photo_camera_outlined,
                  title: appLoc.s_4f062f79,
                  desc: appLoc.s_6e464c0e,
                  onTap: () => _fromImage(ImageSource.camera, BookSource.manual),
                ),

                /* ---------------------- 渠道 / 文件 / 书库 ---------------------- */
                _entry(
                  icon: Icons.cloud_sync_outlined,
                  title: appLoc.s_a5452d46,
                  desc: appLoc.s_d40e2a14,
                  onTap: _fromWeread,
                ),
                _entry(
                  icon: Icons.timeline_outlined,
                  title: appLoc.s_af94a367,
                  desc: appLoc.s_59d2efab,
                  onTap: _syncProgress,
                ),
                _entry(
                  icon: Icons.upload_file_outlined,
                  title: appLoc.s_fa52186c,
                  desc: appLoc.s_2c78f2b8,
                  onTap: _fromCsv,
                ),
                _entry(
                  icon: Icons.menu_book_outlined,
                  title: l10n.goodreadsImport,
                  desc: l10n.goodreadsImportDesc,
                  onTap: _fromGoodreadsCsv,
                ),
                _entry(
                  icon: Icons.travel_explore_outlined,
                  title: l10n.openLibraryImport,
                  desc: l10n.openLibraryImportDesc,
                  onTap: _fromCatalogSearch,
                ),
              ],
            ),
            if (_busy)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 48),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_stage ?? appLoc.s_238b14fc),
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
              ),
          ],
        ),
      ),
    );
  }

  /// 「识别可能不准」的提示条。
  ///
  /// 默认只显示一行标题 + 展开箭头，点开才补上说明正文。
  /// 放在截图 / 拍照两项的**上方**：用户是在动手之前需要知道这件事，
  /// 而不是保存完了才看到。
  Widget _noticeBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = S.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: panelColor(context, cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _noticeOpen = !_noticeOpen),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.importAccuracyTitle,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(
                    _noticeOpen ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
              if (_noticeOpen)
                Padding(
                  padding: const EdgeInsets.only(left: 23, top: 4, right: 4),
                  child: Text(
                    l10n.importAccuracyDesc,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 失败明细。默认折叠，点开才展开，避免一次导入失败十几本时刷屏
  Widget _failureBox(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.error.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.error_outline, color: cs.error),
        title: Text(appLoc.s_ed4b0551(length: _failures.length),
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
            Text(appLoc.s_ec50ebde(length: _failures.length - 20),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _entry({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: cs.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(desc, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        onTap: _busy ? null : onTap,
      ),
    );
  }
}

/// 一次识别的结果。
///
/// 把 `diag`（OCR 诊断）与 `emptyReason`（给用户的空态解释）一起带出来，
/// 是因为识别有两条通道，空结果的原因必须能区分——
/// 「模型不支持看图」和「图里没有文字」是两件完全不同的事。
class _RecognizeResult {
  final List<TitleCandidate> candidates;
  final OcrDiagnostics? diag;
  final OcrMode mode;
  final String rawText;
  final String? emptyReason;

  const _RecognizeResult({
    required this.candidates,
    required this.mode,
    required this.rawText,
    this.diag,
    this.emptyReason,
  });
}
