import 'dart:typed_data';
import '../l10n/app_loc.dart';

import '../ai/ai_client.dart';
import '../models/enums.dart';
import 'ocr_line.dart';
import 'shelf_layout.dart';
import 'shelf_ocr_parser.dart';

/// 用大模型把 OCR 文本「整理」成结构化书目。
///
/// 解决的是启发式规则最难的一块：**判断哪一行是书**。
/// 规则能挡住「筛选」「书架内搜索」这类固定文案，但挡不住
/// 「你最近在读」「共 3 人读过」「版权页」这些长尾，
/// 也分不清封面上的美术字和封面下的书名。语言模型的判断力在这里
/// 比任何正则都值钱。
///
/// 但它的短板同样明确：会**编**。所以这里只让它做两件事——
/// 挑出图中确实存在的书、把被截断的书名补全；补全结果一律标
/// [TitleCandidate.inferred]，由确认页展示给用户，能验证的再验证。
class LlmShelfParser {
  final LlmClient llm;

  LlmShelfParser(this.llm);

  bool get available => llm.available && llm.model.trim().isNotEmpty;

  /// **直接看图**：不经过端侧 OCR，让多模态模型从整张截图里读书名。
  ///
  /// 与 [structure] 是两条独立通道，各有各的短板：
  ///   - OCR 通路：几何感知能把「0.8%」归到正确的书（靠 boundingBox），
  ///     但竖排书名、封面美术字、被截断的标题它读不出来；
  ///   - 多模态通路：能理解版面（哪块是封面、哪块是书脊、哪行是 UI），
  ///     但拿不到坐标，也照样会编书名。
  ///
  /// 所以结果一律标 [TitleCandidate.inferred] 让用户确认，
  /// 并且**失败时返回 null 而不是抛异常**——调用方要能静默回落到 OCR。
  Future<List<TitleCandidate>?> readImage(
    Uint8List jpegBytes, {
    OcrMode mode = OcrMode.shelf,
    String? hint,
  }) async {
    if (!available) return null;
    if (!llm.supportsVision) return null;

    try {
      final raw = await llm.chatWithImage(
        _imagePrompt(mode, hint),
        imageBytes: jpegBytes,
        temperature: 0.1,
        maxTokens: 3072,
      );
      final arr = parseJsonArrayLoose(raw);
      if (arr.isEmpty) return null;

      final out = <TitleCandidate>[];
      for (final e in arr) {
        final title = (e['title'] ?? e['name'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        if (ShelfOcrParser.isNoise(title)) continue;

        final authorRaw = (e['author'] ?? e['authors'] ?? '').toString().trim();
        final progress = _asDouble(e['progress'] ?? e['progressPercent']);
        final status = _statusOf(e['status']);
        final confidence = _asDouble(e['confidence']);
        out.add(TitleCandidate(
          title: title,
          author: authorRaw.isEmpty ? null : authorRaw,
          score: (confidence ?? 0.7).clamp(0.3, 0.98),
          reason: appLoc.s_d2bbf7ce,
          progressPercent: progress,
          statusHint: status,
          truncated: ShelfOcrParser.isTruncated(title),
          // 没有 OCR 原文可比对，一律按「补出来的」标——
          // 模型看图比 OCR 更容易顺手把截断的标题补全，
          // 让用户知道哪个字未必在图上，比给个虚高的置信度诚实。
          inferred: true,
          rawText: title,
        ));
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  String _imagePrompt(OcrMode mode, String? hint) {
    final scene = mode == OcrMode.shelf
        ? appLoc.s_381ca835
        : appLoc.s_fce28e56;
    return appLoc.s_ba5425c5(scene: scene, n: hint == null ? '' : appLoc.s_50018e2c(hint: hint));
  }

  /// 返回 null 表示「这次没能用上大模型」，调用方应保留启发式结果
  Future<List<TitleCandidate>?> structure(
    List<OcrLine> lines, {
    OcrMode mode = OcrMode.shelf,
  }) async {
    if (!available) return null;
    final text = lines
        .map((l) => ShelfOcrParser.preClean(l.text))
        .where((t) => t.isNotEmpty)
        .join('\n');
    if (text.trim().length < 2) return null;

    try {
      final raw = await llm.chat(
        [
          {
            'role': 'system',
            'content': appLoc.s_951042c3,
          },
          {'role': 'user', 'content': _prompt(text, mode)},
        ],
        temperature: 0.1,
        jsonMode: true,
        maxTokens: 3072,
      );
      final arr = parseJsonArrayLoose(raw);
      if (arr.isEmpty) return null;

      final source = lines.map((l) => l.text).join('\n');
      final out = <TitleCandidate>[];
      for (final e in arr) {
        final title = (e['title'] ?? e['name'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        // 模型偶尔会把界面文案也吐回来，再过一遍本地噪音表兜底
        if (ShelfOcrParser.isNoise(title)) continue;

        final authorRaw = (e['author'] ?? e['authors'] ?? '').toString().trim();
        final progress = _asDouble(e['progress'] ?? e['progressPercent']);
        final status = _statusOf(e['status']);
        final truncated = e['truncated'] == true ||
            ShelfOcrParser.isTruncated(title) ||
            _looksCut(title, source);
        final confidence = _asDouble(e['confidence']);
        final rawLine = _matchRawLine(title, lines);

        out.add(TitleCandidate(
          title: title,
          author: authorRaw.isEmpty ? null : authorRaw,
          score: (confidence ?? 0.65).clamp(0.3, 0.98),
          reason: appLoc.s_29dbdb32,
          progressPercent: progress,
          statusHint: status,
          truncated: truncated,
          // 输出里找不到原文 = 这个书名是模型补出来的，必须让用户看见
          inferred: !source.contains(title),
          rawText: rawLine ?? title,
        ));
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      // 大模型不可用不应阻断导入：本地启发式的结果照样能用
      return null;
    }
  }

  static String _prompt(String ocrText, OcrMode mode) {
    final scene = mode == OcrMode.cover ? appLoc.s_9cd6567e : appLoc.s_a6db1cf4;
    return appLoc.s_43fca769(scene: scene, ocrText: ocrText);
  }

  /// 标题是否像是被截断的：原文里存在一个以该标题为前缀、且以省略号收尾的行
  static bool _looksCut(String title, String source) {
    if (title.length < 3) return false;
    final head = title.substring(0, title.length < 4 ? title.length : 4);
    for (final line in source.split('\n')) {
      if (!line.startsWith(head)) continue;
      if (ShelfOcrParser.isTruncated(line)) return true;
    }
    return false;
  }

  /// 找到这条书目对应的原文行，供确认页展示「原图 → 识别」
  static String? _matchRawLine(String title, List<OcrLine> lines) {
    String norm(String s) =>
        s.replaceAll(RegExp(appLoc.s_cbb756f7), '').toLowerCase();
    final t = norm(title);
    if (t.isEmpty) return null;
    String? best;
    for (final l in lines) {
      final n = norm(l.text);
      if (n.isEmpty) continue;
      if (n == t || t.startsWith(n) || n.startsWith(t)) {
        if (best == null || n.length > norm(best).length) best = l.text;
      }
    }
    return best;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll('%', '').trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  static BookStatus? _statusOf(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    // 不能写成 switch 的常量模式：`appLoc.*` 是运行时取值而非编译期常量，
    // 常量模式会直接编译失败（constant_pattern_with_non_constant_expression）。
    bool hits(List<String> labels) => labels.contains(s);
    if (hits([appLoc.s_95222176, appLoc.s_5a833930])) return BookStatus.wish;
    if (hits([appLoc.s_b9bf9b53, appLoc.s_be5492a5])) return BookStatus.reading;
    if (hits([appLoc.s_44c14529, appLoc.s_0872b5b7, appLoc.s_300a32bd])) {
      return BookStatus.finished;
    }
    // s_0f4d9c68（弃读）是 v2 时代的文案，模型可能仍按旧词表作答，
    // 因此继续接受；s_eba88d83 现在是「搁置」，正好是它的新归宿。
    if (s == appLoc.s_0f4d9c68 || s == appLoc.s_eba88d83) {
      return BookStatus.shelved;
    }
    return null;
  }
}
