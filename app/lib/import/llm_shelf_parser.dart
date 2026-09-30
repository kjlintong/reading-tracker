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
            'content': '你是书架截图信息抽取助手。只输出 JSON 数组，不要任何解释文字。',
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
          reason: '大模型整理',
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
    final scene = mode == OcrMode.cover ? '一张图书封面/书脊照片' : '一个电子书App的书架截图';
    return '''下面是从$scene里 OCR 出来的文字行，顺序即页面上从上到下的顺序。

请抽取其中**真实存在的书名**，忽略所有界面文字（搜索框、筛选、分类、状态栏、页码、章节标题、按钮、统计数字）。

规则：
1. 只输出图中确实出现的书。不要凭常识补充图里没有的书。
2. 书名若被界面用省略号截断（例如「雅思口语深…」），请补全成完整书名。
3. progress 只填 0-100 的整数百分比，读不到就填空字符串。注意「0.8%」是 0.8 不是 80。
4. status 只填「未读 / 在读 / 已读完 / 弃读」之一，读不到填空字符串。
5. author 只在图中明确出现时填写，否则留空。不要猜作者。
6. 拿不准的行不要输出。宁可少一本，也不要多一本假书。

只输出 JSON 数组，元素格式：
[{"title":"","author":"","progress":"","status":"","confidence":0.0}]

OCR 文字行：
"""
$ocrText
"""''';
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
        s.replaceAll(RegExp(r'[\s《》「」『』]'), '').toLowerCase();
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
    return switch (s) {
      '未读' || '想读' => BookStatus.wish,
      '在读' || '阅读中' => BookStatus.reading,
      '已读完' || '读完' || '已读' => BookStatus.finished,
      '弃读' => BookStatus.abandoned,
      _ => null,
    };
  }
}
