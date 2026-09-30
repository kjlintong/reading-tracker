import '../models/book.dart';
import '../models/enums.dart';

/// 书名候选（OCR 提取结果）
class TitleCandidate {
  String title;
  String? author;
  double score;
  String reason;

  /// 图里读到的阅读进度（0-100）。读不到为 null。
  double? progressPercent;

  /// 图里读到的阅读状态（未读 / 已读完 / 在读…）。读不到为 null。
  BookStatus? statusHint;

  /// 原图这一行就是被省略号截断的（「雅思口语深…」）。
  /// 这种标题直接入库是废数据，必须联网补齐后才是真书名。
  bool truncated;

  /// 书名不是原图原文，而是补齐或推测出来的。
  /// 确认页要把它标出来——用户有权知道哪个字不是图里有的。
  bool inferred;

  /// OCR 原始文本。确认页展示「原图 xx → 识别 yy」用。
  String rawText;

  TitleCandidate({
    required this.title,
    required this.score,
    this.author,
    this.reason = '',
    this.progressPercent,
    this.statusHint,
    this.truncated = false,
    this.inferred = false,
    this.rawText = '',
  });

  /// 转成一本书的雏形（其余元数据留空，交由补全管道填充）
  Book toBook({BookSource source = BookSource.manual}) {
    final now = DateTime.now().toIso8601String();
    return Book(
      id: '${source.name}_${DateTime.now().microsecondsSinceEpoch}_${title.hashCode}',
      title: title,
      authors: author != null ? [author!] : const [],
      source: source,
      status: statusHint ?? BookStatus.wish,
      progressPercent: progressPercent ?? 0,
      createdAt: now,
      updatedAt: now,
      extra: {
        if (truncated) 'titleFromTruncatedOcr': true,
        if (inferred) 'titleInferred': true,
        if (rawText.isNotEmpty && rawText != title) 'ocrRawTitle': rawText,
      },
    );
  }
}

/// 元信息行（进度 / 状态 / 分组本数），解析出来的结果
class OcrMetaLine {
  final double? progressPercent;
  final BookStatus? status;

  /// 「共 11 本」——合集或分组卡片，不是一本具体的书
  final int? groupCount;

  const OcrMetaLine({this.progressPercent, this.status, this.groupCount});
}

/// 截图 OCR 文本 → 书名候选列表
///
/// 取向：宁可多召回不可漏召回——误判由用户在确认页一键剔除，
/// 漏掉则用户完全无感知。
///
/// 本类是**纯文本**路径（无几何信息），既能作为
/// [ShelfLayoutParser] 的降级方案，也是单元测试的主要入口。
/// 有 boundingBox 时应优先用布局解析器：多列书架里纯文本无法区分
/// 「上一本书的进度」和「下一本书的标题」。
class ShelfOcrParser {
  ShelfOcrParser._();

  /// 界面噪音词：各阅读 App 的常见文案
  static const List<String> _uiNoise = [
    '书架', '书城', '发现', '我的', '搜索', '更多', '全部', '排序', '筛选', '编辑',
    '添加', '导入', '导入书籍', '分组', '未分组', '新建分组', '管理', '删除', '完成',
    '取消', '确定', '返回', '首页', '分类', '标签', '笔记', '书评', '目录', '设置',
    '登录', '注册', '购买', '加入书架', '开始阅读', '继续阅读', '立即阅读',
    '最近阅读', '本周阅读', '今日阅读', '阅读时长', '读完', '读过', '在读', '想读',
    '本周读完', '已读完', '全部书籍', '我的书架', '好友在读', '为你推荐',
    '无限卡', '付费卡', '体验卡', '会员', '兑换', '签到', '排行榜', '读书小队',
    '掌阅', '精选', '京东读书', '专业版', '我的图书', '本地导入', '云书架',
    '已购', '借阅', '试读', '全书', '连载', '完结',
    '书库', '本地', 'SDcard', 'Books', 'ONYX', 'BOOX', 'NeoReader',
    'storage', 'download', '全部图书', '阅读中', '未读', '已读',
    '今天', '昨天', '前天', '本周', '上周', '本月', '上月', '刚刚', '分钟前', '小时前',
    // 阅读器内页 / 版本说明等容易被当成书名的高频词
    '目录', '封面', '扉页', '版权页', '后记', '序言', '前言', '推荐语', '内容简介',
  ];

  /// 中文常见姓氏（百家姓精简 + 常见复姓）
  static const String _surnames =
      '赵钱孙李周吴郑王冯陈褚卫蒋沈韩杨朱秦尤许何吕施张孔曹严华金魏陶姜戚谢邹喻'
      '柏水窦章云苏潘葛奚范彭郎鲁韦昌马苗凤花方俞任袁柳鲍史唐费岑薛雷贺倪汤滕殷'
      '罗毕郝安常乐于时傅皮卞齐康伍余元卜顾孟平黄和穆萧尹姚邵汪祁毛禹狄米贝明臧'
      '计伏成戴谈宋茅庞熊纪舒屈项祝董梁杜阮蓝闵席季麻强贾路娄江童颜郭梅盛林刁钟'
      '徐邱骆高夏蔡田樊胡凌霍虞万支柯管卢莫经房裘缪干解应宗丁宣邓郁单杭洪包诸左'
      '石崔吉钮龚程嵇邢滑裴陆荣翁荀羊惠甄曲家封芮储靳邴松井段富巫乌焦巴弓牧山谷'
      '车侯全班仰秋仲伊宫宁仇栾甘厉戎祖武符刘景詹束龙叶幸司郜黎薄印宿白怀蒲从鄂'
      '索咸籍赖卓蔺屠蒙池乔阴胥能苍双闻莘党翟贡劳姬申扶堵冉宰郦雍桑桂濮牛寿通边'
      '燕冀浦尚农温别庄晏柴瞿阎充慕连茹习宦艾鱼容向古易慎戈廖庾终暨居衡步都耿满'
      '弘匡国文寇广禄阙东欧沃利蔚越隆师巩聂晁冷辛阚那简饶曾毋沙养鞠须丰巢关蒯相'
      '查后荆红游权盖益桓公肖芦麦涂佟赫连商修励楚揭帅官原邢兰南覃苟亢缑隋来俸盘'
      '闭卿随兆敦答税操邸郏鹿冀';

  /// 日式译名常见首字（村上春树、东野圭吾…）
  static const String _foreignNameChars = '村田山井川岛渡中野小大松竹森藤木内上下西北新原谷本';

  static final Set<String> _surnameSet = {..._surnames.split('')};
  static final Set<String> _foreignSet = {..._foreignNameChars.split('')};

  /// 主入口（纯文本）：从 OCR 文本提取书名候选，按置信度降序
  static List<TitleCandidate> extract(String? ocrText, {double minScore = 0.35}) {
    if (ocrText == null || ocrText.trim().isEmpty) return [];

    final lines = ocrText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final candidates = <_Raw>[];
    var prevTitleIndex = -1;

    for (var idx = 0; idx < lines.length; idx++) {
      final cleaned = preClean(lines[idx]);
      if (cleaned.isEmpty) continue;

      // 先判进度/状态行，再判噪音。
      // 顺序很重要：'已读完' 同时在噪音词表里，若先过噪音就永远读不到状态。
      final meta = metaOf(cleaned);
      if (meta != null) {
        if (prevTitleIndex >= 0) {
          final prev = candidates[prevTitleIndex];
          prev.progressPercent ??= meta.progressPercent;
          prev.statusHint ??= meta.status;
          if (meta.progressPercent != null || meta.status != null) {
            prev.score = (prev.score + 0.08).clamp(0.0, 1.0);
          }
        }
        continue;
      }

      if (isNoise(cleaned)) continue;

      // 作者行：归入上一本候选书的作者
      if (looksLikeAuthor(cleaned) && prevTitleIndex >= 0) {
        final prev = candidates[prevTitleIndex];
        if (prev.author == null) {
          prev.author = cleaned.replaceAll(RegExp(r'\s*(著|编著|译|著译)$'), '');
          prev.score = (prev.score + 0.08).clamp(0.0, 1.0);
          continue;
        }
      }

      final s = _scoreTitle(cleaned, idx, prevTitleIndex, candidates);
      if (s.$1 < minScore) continue;

      candidates.add(_Raw(
        title: cleaned,
        score: s.$1,
        reason: s.$2,
        lineIndex: idx,
      ));
      prevTitleIndex = candidates.length - 1;
    }

    final merged = _mergeBrokenTitles(candidates);
    merged.sort((a, b) => b.score.compareTo(a.score));
    return merged
        .map((r) => TitleCandidate(
              title: r.title,
              score: r.score,
              author: r.author,
              reason: r.reason,
              progressPercent: r.progressPercent,
              statusHint: r.statusHint,
              truncated: isTruncated(r.title),
              rawText: r.title,
            ))
        .toList();
  }

  /// 清洗：去掉 OCR 常见的框线、项目符号与多余空白
  static String preClean(String line) => line
      .replaceAll(RegExp(r'[|｜]'), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(RegExp(r'^[•·・\-\*\+]\s*'), '')
      .trim();

  /// 标题是否被界面截断（「雅思口语深…」）。
  ///
  /// 只认行尾的省略号——这是唯一可靠、可解释的信号。
  /// 想用「文字贴到列右边缘」来判断会误伤：单本书独占一列时
  /// 它永远贴边，那样每本都成了截断。
  static bool isTruncated(String s) =>
      RegExp(r'(…|⋯|\.\.\.|\.\.)\s*$').hasMatch(s);

  /// 进度 / 状态 / 分组本数行。
  ///
  /// 返回 null 表示这行不是元信息，应当按标题或作者继续判断。
  static OcrMetaLine? metaOf(String s) {
    final t = s.replaceAll('％', '%').trim();
    if (t.isEmpty) return null;

    // 「共 11 本」「总计 3 册」
    final g = RegExp(r'^(?:共|总计|合计)\s*(\d+)\s*(?:本|册)?$').firstMatch(t);
    if (g != null) {
      return OcrMetaLine(groupCount: int.tryParse(g.group(1)!));
    }
    // 「已读完 共 11 本」——状态面板里最常见的合并写法
    final fg = RegExp(r'^(?:已)?读完\s*(?:共)?\s*(\d+)\s*(?:本|册)$').firstMatch(t);
    if (fg != null) {
      return OcrMetaLine(
        status: BookStatus.finished,
        progressPercent: 100,
        groupCount: int.tryParse(fg.group(1)!),
      );
    }
    // 「0.8%」「11.5%」
    final p1 = RegExp(r'^(\d+(?:\.\d+)?)\s*%$').firstMatch(t);
    if (p1 != null) {
      return OcrMetaLine(progressPercent: double.tryParse(p1.group(1)!));
    }
    // 「已读 8%」「读至 45%」「进度 30%」
    final p2 = RegExp(r'^(?:已读|读至|读到|阅读至|进度|完成|阅读)\s*(\d+(?:\.\d+)?)\s*%$')
        .firstMatch(t);
    if (p2 != null) {
      return OcrMetaLine(progressPercent: double.tryParse(p2.group(1)!));
    }
    // 纯状态词
    const statusWords = <String, BookStatus>{
      '未读': BookStatus.wish,
      '想读': BookStatus.wish,
      '已读': BookStatus.finished,
      '读完': BookStatus.finished,
      '已读完': BookStatus.finished,
      '读过': BookStatus.finished,
      '在读': BookStatus.reading,
      '阅读中': BookStatus.reading,
      '正在读': BookStatus.reading,
      '弃读': BookStatus.abandoned,
      '放弃': BookStatus.abandoned,
      '暂搁': BookStatus.paused,
    };
    final st = statusWords[t];
    if (st != null) {
      return OcrMetaLine(
        status: st,
        progressPercent: st == BookStatus.finished ? 100 : null,
      );
    }
    return null;
  }

  static bool isNoise(String s) {
    final lower = s.toLowerCase();
    // 明显的非书名模式
    if (RegExp(r'^\d+(\.\d+)?\s*%$').hasMatch(s)) return true;
    if (RegExp(r'^(读至|已读|读到|已看到|阅读至)\s*[\d.]+%?$').hasMatch(s)) return true;
    if (RegExp(r'^\d{1,4}[-/年]\d{1,2}[-/月]\d{1,2}日?$').hasMatch(s)) return true;
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) return true;
    if (RegExp(r'^\d+\s*(本|册|页|章|分钟|小时|万字)$').hasMatch(s)) return true;
    if (RegExp(r'^(共|总计|合计)\s*\d+\s*(本|册)?$').hasMatch(s)) return true;
    if (RegExp(r'^[\d\s.,%]+$').hasMatch(s)) return true;
    if (RegExp(r'^\d+$').hasMatch(s)) return true;
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(s)) return true;
    // 阅读器页码「4/249」
    if (RegExp(r'^\d{1,4}\s*/\s*\d{1,4}$').hasMatch(s)) return true;
    // 章节标题。「第一章 法国室内设计发展史」是内页页眉，不是书名——
    // 截图一张内页就冒出一本不存在的书，是识别里最容易骗到人的噪音。
    if (RegExp(r'^第\s*[0-9一二三四五六七八九十百千零两]+\s*[章节回篇卷]').hasMatch(s)) {
      return true;
    }
    if (RegExp(r'^chapter\s+\d+', caseSensitive: false).hasMatch(s)) return true;
    // 状态栏网速
    if (RegExp(r'^\d+(\.\d+)?\s*(kb|mb)/s$', caseSensitive: false).hasMatch(s)) {
      return true;
    }
    // 无任何中英文字符
    if (!RegExp(r'[\u4e00-\u9fa5a-zA-Z]').hasMatch(s)) return true;

    for (final w in _uiNoise) {
      final lw = w.toLowerCase();
      if (lower == lw) return true;
      if (lower.startsWith(lw) && s.length <= w.length + 3) return true;
    }
    return false;
  }

  /// 必须命中姓氏表才判为作者，否则「筝的人」这类断行残片会被误吞
  static bool looksLikeAuthor(String s) {
    if (RegExp(r'(著|编著|译|著译)$').hasMatch(s)) return true;
    if (RegExp(r'^\[[^\]]{1,8}\]').hasMatch(s)) return true;

    if (s.contains('·')) {
      final first = s.split('·').first;
      if (first.isEmpty) return false;
      return _surnameSet.contains(first[0]) ||
          (first.length >= 2 && _surnameSet.contains(first.substring(0, 2)));
    }
    if (RegExp(r'^[\u4e00-\u9fa5]{2,4}$').hasMatch(s)) {
      if (_surnameSet.contains(s[0])) return true;
      if (s.length >= 2 && _surnameSet.contains(s.substring(0, 2))) return true;
    }
    // 日式译名：仅 2-3 字时启用
    if (RegExp(r'^[\u4e00-\u9fa5]{2,3}$').hasMatch(s) &&
        _foreignSet.contains(s[0])) {
      return true;
    }
    return false;
  }

  static (double, String) _scoreTitle(
      String s, int idx, int prevIdx, List<_Raw> candidates) {
    var score = 0.5;
    final reasons = <String>[];

    if (s.contains('《') || s.contains('》')) {
      score += 0.3;
      reasons.add('含书名号');
    }
    final stripped = s.replaceAll(RegExp(r'[《》]'), '');

    if (stripped.length >= 2 && stripped.length <= 20) {
      score += 0.15;
      reasons.add('长度合理');
    } else if (stripped.length < 2) {
      score -= 0.4;
      reasons.add('过短');
    } else if (stripped.length > 30) {
      score -= 0.35;
      reasons.add('过长');
    }

    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(stripped)) {
      score += 0.1;
      reasons.add('中文');
    }
    if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(stripped) && stripped.length <= 3) {
      score -= 0.3;
      reasons.add('疑似英文 UI 词');
    }
    if (RegExp(r'[，。；、？！]$').hasMatch(stripped)) {
      score -= 0.15;
      reasons.add('句末标点');
    }
    if (prevIdx >= 0 &&
        candidates.length > prevIdx &&
        idx - candidates[prevIdx].lineIndex <= 2) {
      score += 0.05;
      reasons.add('相邻行');
    }

    return (score.clamp(0.0, 1.0), reasons.join(','));
  }

  /// 合并被 OCR 换行拆断的标题。条件刻意保守——把两本书粘成一本，
  /// 比漏合并更糟糕。只允许合并一次，避免链式粘连。
  static List<_Raw> _mergeBrokenTitles(List<_Raw> input) {
    final out = <_Raw>[];
    for (final cur in input) {
      if (out.isNotEmpty) {
        final prev = out.last;
        final adjacent = cur.lineIndex - prev.lineIndex == 1;
        final prevIsFragment = prev.title.length <= 4 &&
            !prev.merged &&
            !RegExp(r'[，。；、？！：）」』]$').hasMatch(prev.title);
        final curIsFragment = cur.title.length <= 3;
        final mergedLen = prev.title.length + cur.title.length;
        if (adjacent && prevIsFragment && curIsFragment && mergedLen <= 30) {
          prev.title += cur.title;
          prev.score = (prev.score + 0.1).clamp(0.0, 1.0);
          prev.reason += ',合并断行';
          prev.lineIndex = cur.lineIndex;
          prev.merged = true;
          continue;
        }
      }
      out.add(_Raw(
        title: cur.title,
        score: cur.score,
        reason: cur.reason,
        author: cur.author,
        lineIndex: cur.lineIndex,
      ));
    }
    return out;
  }
}

class _Raw {
  String title;
  double score;
  String reason;
  String? author;
  double? progressPercent;
  BookStatus? statusHint;
  int lineIndex;
  bool merged = false;

  _Raw({
    required this.title,
    required this.score,
    required this.reason,
    this.author,
    required this.lineIndex,
  });
}
