import 'dart:math' as math;

import '../models/enums.dart';
import 'ocr_line.dart';
import 'shelf_ocr_parser.dart';

/// 识别场景
enum OcrMode {
  /// 书架截图：多列封面栅格，每格下面是书名与进度
  shelf,

  /// 封面照 / 书脊照：字号最大的那行才是书名
  cover,
}

/// 几何感知的截图解析器。
///
/// 比纯文本解析多知道一件事：**每行文字在页面上的位置**。
/// 多列书架里这一件事决定成败——纯文本流是
/// 「室内设计风格详 / 解式 / 0.8% / 西西弗神话 / 11.5%」，
/// 无法判断「0.8%」属于哪本；有了坐标就能按列切开，
/// 让进度、作者各归其位，也能把被界面截断的标题单独标出来。
///
/// 输入刻意用 [OcrLine] 而不是 ML Kit 的 `TextLine`：解析逻辑必须能在
/// 纯 Dart 单元测试里跑，而 ML Kit 插件在测试环境不可用。
class ShelfLayoutParser {
  ShelfLayoutParser._();

  /// 主入口
  static List<TitleCandidate> parse(
    List<OcrLine> input, {
    OcrMode mode = OcrMode.shelf,
    double minScore = 0.35,
  }) {
    final lines = <OcrLine>[];
    for (final raw in input) {
      final t = ShelfOcrParser.preClean(raw.text);
      if (t.isEmpty) continue;
      lines.add(raw.copyWith(text: t));
    }
    if (lines.isEmpty) return [];

    // 几何信息缺失就退回纯文本路径——没有坐标硬套布局算法，
    // 只会把整页揉成一列，反而比纯文本还差。
    final withGeometry = lines.where((l) => l.hasGeometry).length;
    if (withGeometry < lines.length * 0.7) {
      return ShelfOcrParser.extract(
        lines.map((l) => l.text).join('\n'),
        minScore: minScore,
      );
    }

    final items = mode == OcrMode.cover ? _parseCover(lines) : _parseShelf(lines);
    items.sort((a, b) => b.score.compareTo(a.score));
    return items.where((c) => c.score >= minScore).toList();
  }

  /* ------------------------------ 书架栅格 ------------------------------ */

  static List<TitleCandidate> _parseShelf(List<OcrLine> lines) {
    // 先剔除界面噪音：状态栏、搜索框、筛选栏。
    // 注意进度/状态行必须留下——它们既是归属线索，也要回填到书上。
    final body = <OcrLine>[];
    for (final l in lines) {
      if (ShelfOcrParser.metaOf(l.text) != null) {
        body.add(l);
        continue;
      }
      if (ShelfOcrParser.isNoise(l.text)) continue;
      body.add(l);
    }
    if (body.isEmpty) return [];

    final centers = _columnCenters(body);
    final byColumn = <int, List<OcrLine>>{};
    for (final l in body) {
      byColumn.putIfAbsent(_nearestIndex(centers, l.left), () => []).add(l);
    }

    final out = <TitleCandidate>[];
    for (final entry in byColumn.entries) {
      for (final item in _itemsFromColumn(_clusterRows(entry.value))) {
        final c = item.toCandidate(columnLeft: centers[entry.key]);
        if (c != null) out.add(c);
      }
    }
    return _dedupe(out);
  }

  /// 列的左边界聚类。
  ///
  /// 同一个格子里的书名行、进度行左边缘基本对齐，所以按 left 聚类
  /// 就能切出列。聚类数超过 [maxColumns] 说明这不是规整栅格
  /// （封面美术字、居中排版都会各成"列"），此时退回单列，
  /// 按阅读顺序从上到下扫——总比切错强。
  static List<double> _columnCenters(List<OcrLine> lines, {int maxColumns = 6}) {
    final sorted = lines.where((l) => l.width > 0).toList()
      ..sort((a, b) => a.left.compareTo(b.left));
    if (sorted.isEmpty) return [0];

    final tol = math.max(10.0, _medianHeight(lines) * 0.9);
    final centers = <double>[];
    final buckets = <List<double>>[];
    for (final l in sorted) {
      final x = l.left;
      if (centers.isEmpty || (x - centers.last).abs() > tol) {
        centers.add(x);
        buckets.add([x]);
      } else {
        buckets.last.add(x);
        centers[centers.length - 1] =
            buckets.last.reduce((a, b) => a + b) / buckets.last.length;
      }
    }
    if (centers.length > maxColumns) {
      return [centers.reduce(math.min)];
    }
    return centers;
  }

  static int _nearestIndex(List<double> centers, double x) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < centers.length; i++) {
      final d = (centers[i] - x).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// 按垂直重叠把行聚成「行」。容忍同行内不同字号的基线偏差。
  static List<_Row> _clusterRows(List<OcrLine> lines) {
    final sorted = [...lines]..sort((a, b) => a.top.compareTo(b.top));
    final rows = <_Row>[];
    for (final l in sorted) {
      _Row? target;
      // 只回看最近 3 行：再往上找会把上一个格子的行吸进来
      for (var i = rows.length - 1; i >= 0 && i >= rows.length - 3; i--) {
        final r = rows[i];
        final overlap = math.min(r.bottom, l.bottom) - math.max(r.top, l.top);
        final minH = math.min(r.height, l.height);
        if (minH > 0 && overlap > minH * 0.5) {
          target = r;
          break;
        }
      }
      if (target == null) {
        rows.add(_Row(l));
      } else {
        target.add(l);
      }
    }
    rows.sort((a, b) => a.top.compareTo(b.top));
    return rows;
  }

  /// 把一列里的行串成一本本候选书
  static List<_Item> _itemsFromColumn(List<_Row> rows) {
    final items = <_Item>[];
    _Item? cur;
    var lastBottom = double.nan;

    for (final row in rows) {
      final text = row.text;
      if (text.isEmpty) continue;
      final meta = ShelfOcrParser.metaOf(text);
      final gap = lastBottom.isNaN ? 0.0 : row.top - lastBottom;
      final unit = math.max(row.height, 8.0);

      if (meta != null) {
        if (cur != null && gap <= unit * 2.4) {
          cur.progress ??= meta.progressPercent;
          cur.status ??= meta.status;
          cur.groupCount ??= meta.groupCount;
          // 进度/状态行是格子的收尾，之后的行属于下一本
          cur.ended = true;
        }
        lastBottom = row.bottom;
        continue;
      }

      // 作者行必须在「续行」判定之前排除掉：
      // 「解式」这种书名断行残片会命中姓氏表（解是真实姓氏），
      // 一旦被当作者吸走，书名就永久缺了一截，而用户无从发现。
      if (ShelfOcrParser.looksLikeAuthor(text) &&
          !_likelyContinuation(cur?.lastLineText ?? '', text) &&
          cur != null &&
          !cur.ended &&
          gap <= unit * 2.8) {
        cur.author ??= text.replaceAll(RegExp(r'\s*(著|编著|译|著译)$'), '');
        lastBottom = row.bottom;
        continue;
      }

      // 断行合并。条件刻意收紧：跨格的间距远大于格内换行，
      // 所以「间距够小 + 两行都是中式短句 + 前一行没写完」三条同时成立才合并。
      final canAppend = cur != null &&
          !cur.ended &&
          !cur.hasMeta &&
          cur.titleLines < 2 &&
          gap <= unit * 1.8 &&
          !RegExp(r'[，。；、？！：）」』]$').hasMatch(cur.text) &&
          _sameScript(cur.lastLineText, text) &&
          cur.lastLineText.length <= 12 &&
          text.length <= 10;

      if (canAppend) {
        // canAppend 里已经判过非空，Dart 会沿着这个局部 bool 做类型提升
        cur.append(row);
      } else {
        if (cur != null) items.add(cur);
        cur = _Item(row);
      }
      lastBottom = row.bottom;
    }
    if (cur != null) items.add(cur);
    return items;
  }

  /// 无「著 / 译」这类显式标记的名字行，到底是**书名的续行**还是**作者**？
  ///
  /// 书架栅格里书名常换行（「室内设计风格详」+「解式」），而作者行
  /// 通常光秃秃一个名字。两者在多列布局里长得一模一样，靠姓氏表分不开
  /// ——「解」是真姓氏，「兰小欢」也是真作者。
  ///
  /// 唯一稳的判别是**上一行有没有写满**：中文书名换行时首行会被排到
  /// 格宽附近（6 字以上才可能被迫折行），写完的书名一般 2~5 字。
  /// 所以首行够长就按续行处理，短行后面那行才归给作者。
  /// 代价是「室内设计风格」（6 字整书名）后面真跟个 2 字作者时会误并——
  /// 那种情况用户能在确认页看到「原图：xxx」并手动改回来。
  static bool _likelyContinuation(String prev, String frag) {
    // 显式作者标记：著 / 译 / 编著，以及「[美] 某某」这类译名前缀。
    // 这些出现时无论上一行多长都是作者，绝不并进书名。
    if (RegExp(r'(著|编著|译|著译)$').hasMatch(frag)) return false;
    if (RegExp(r'^\[[^\]]{1,8}\]').hasMatch(frag)) return false;
    if (prev.isEmpty) return false;
    if (RegExp(r'[（《·“]$').hasMatch(prev)) return true;
    if (RegExp(r'[）》」』”]$').hasMatch(prev)) return false;
    return prev.length >= 6;
  }

  /// 是否同一书写系统。挡住「封面美术字 + 中文书名」被粘成一行：
  /// 英文封面字在上面、中文书名在下面，脚本不同就换一本。
  static bool _sameScript(String a, String b) {
    final aCn = RegExp(r'[\u4e00-\u9fa5]').hasMatch(a);
    final bCn = RegExp(r'[\u4e00-\u9fa5]').hasMatch(b);
    return aCn == bCn;
  }

  /* ------------------------------ 封面照 ------------------------------ */

  /// 封面 / 书脊照：字号（≈行高）最大的那行是书名。
  static List<TitleCandidate> _parseCover(List<OcrLine> lines) {
    final usable = <OcrLine>[];
    for (final l in lines) {
      if (ShelfOcrParser.isNoise(l.text)) continue;
      if (ShelfOcrParser.metaOf(l.text) != null) continue;
      if (l.height <= 0) continue;
      usable.add(l);
    }
    if (usable.isEmpty) return [];

    final byHeight = [...usable]..sort((a, b) => b.height.compareTo(a.height));
    final maxH = byHeight.first.height;

    String? author;
    for (final l in byHeight.skip(1).take(7)) {
      if (ShelfOcrParser.looksLikeAuthor(l.text)) {
        author = l.text.replaceAll(RegExp(r'\s*(著|编著|译|著译)$'), '');
        break;
      }
    }

    final out = <TitleCandidate>[];
    for (var i = 0; i < byHeight.length && i < 8; i++) {
      final l = byHeight[i];
      final text = l.text;
      var score = i == 0 ? 0.75 : 0.45;
      if (l.height >= maxH * 0.8) score += 0.1;
      if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(text)) score += 0.1;
      if (text.length >= 2 && text.length <= 30) score += 0.05;

      // 封面上的作者行**只用来补 author，不再单独作为一本候选书**。
      // 放它进去等于给每张封面照凭空多出一本「兰小欢 著」——
      // 而且这个假书的置信度不低，用户很容易顺手勾上。
      if (ShelfOcrParser.looksLikeAuthor(text)) continue;

      out.add(TitleCandidate(
        title: text,
        score: score.clamp(0.0, 1.0),
        author: i == 0 ? author : null,
        reason: i == 0 ? '封面最大字号' : '封面次级文字',
        truncated: ShelfOcrParser.isTruncated(text),
        rawText: text,
      ));
    }
    return _dedupe(out.where((c) => c.score >= 0.3).toList());
  }

  /* ------------------------------ 工具 ------------------------------ */

  static double _medianHeight(List<OcrLine> lines) {
    final hs = lines.map((l) => l.height).where((h) => h > 0).toList()..sort();
    if (hs.isEmpty) return 16;
    return hs[hs.length ~/ 2];
  }

  /// 同书多候选去重（列切分偶尔会让同一本出现两次）：同标题只留最高分
  static List<TitleCandidate> _dedupe(List<TitleCandidate> input) {
    final best = <String, TitleCandidate>{};
    for (final c in input) {
      final key = c.title
          .replaceAll(RegExp(r'[\s《》「」『』]'), '')
          .toLowerCase();
      if (key.isEmpty) continue;
      final prev = best[key];
      if (prev == null || c.score > prev.score) best[key] = c;
    }
    final out = best.values.toList();
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }
}

/// 一「行」：垂直方向重叠的一组 OcrLine
class _Row {
  final List<OcrLine> lines;
  late double top;
  late double bottom;
  late double left;

  _Row(OcrLine first) : lines = [first] {
    top = first.top;
    bottom = first.bottom;
    left = first.left;
  }

  void add(OcrLine l) {
    lines.add(l);
    top = math.min(top, l.top);
    bottom = math.max(bottom, l.bottom);
    left = math.min(left, l.left);
  }

  double get height => bottom - top;

  /// 同一行内的多段文字按 x 排序拼接，用空格分隔，
  /// 避免「书名作者」黏成一个词
  String get text {
    final sorted = [...lines]..sort((a, b) => a.left.compareTo(b.left));
    return sorted.map((e) => e.text).join(' ').trim();
  }
}

/// 一列里串起来的一本候选书
class _Item {
  final List<_Row> rows;
  String? author;
  double? progress;
  BookStatus? status;
  int? groupCount;
  bool ended = false;

  _Item(_Row first) : rows = [first];

  void append(_Row r) => rows.add(r);

  String get text => rows.map((r) => r.text).join();

  String get lastLineText => rows.isEmpty ? '' : rows.last.text;

  int get titleLines => rows.length;

  bool get hasMeta => progress != null || status != null || groupCount != null;

  TitleCandidate? toCandidate({double? columnLeft}) {
    final title = text.trim();
    if (title.isEmpty) return null;

    var score = 0.5;
    final reasons = <String>[];

    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(title)) {
      score += 0.12;
      reasons.add('含中文');
    }
    if (hasMeta) {
      score += 0.1;
      reasons.add('带进度或状态');
    }
    if (author != null && author!.isNotEmpty) {
      score += 0.08;
      reasons.add('带作者');
    }
    if (title.length >= 2 && title.length <= 24) {
      score += 0.06;
      reasons.add('长度合理');
    } else if (title.length < 2) {
      score -= 0.35;
      reasons.add('过短');
    } else if (title.length > 32) {
      score -= 0.3;
      reasons.add('过长');
    }
    // 左对齐到所在列 = 这是格子的正文块，而不是封面里的美术字
    if (columnLeft != null && (rows.first.left - columnLeft).abs() <= 12) {
      score += 0.05;
      reasons.add('列左对齐');
    }
    // 无中文但有拉丁字母：封面上最常见的美术字（"SMALL GARDEN HANDBOOK"），
    // 并不是印在封面下方的书名。降权而非直接丢弃——真有英文原版书
    // 就该由用户在确认页勾回来。
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(title);
    final hasChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(title);
    if (hasLatin && !hasChinese) {
      final letters = title.replaceAll(RegExp(r'[^A-Za-z]'), '');
      if (letters.length >= 5 && letters == letters.toUpperCase()) {
        score -= 0.3;
        reasons.add('封面美术字');
      } else if (title.length <= 3) {
        score -= 0.2;
        reasons.add('过短英文');
      }
    }
    if (RegExp(r'[，。；、？！]$').hasMatch(title)) {
      score -= 0.15;
      reasons.add('句末标点');
    }

    return TitleCandidate(
      title: title,
      score: score.clamp(0.0, 1.0),
      author: author,
      reason: reasons.join(','),
      progressPercent: progress,
      statusHint: status,
      truncated: ShelfOcrParser.isTruncated(title),
      rawText: title,
    );
  }
}
