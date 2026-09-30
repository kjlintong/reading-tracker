// 全局枚举与常量。
// 与 tools/lib/schema.mjs 中的定义一一对应，保证跨端数据一致。

/// 阅读状态
enum BookStatus {
  wish,       // 想读
  reading,    // 在读
  finished,   // 已读
  abandoned,  // 弃读
  borrowed,   // 借阅中
  paused;     // 暂搁

  static BookStatus fromString(String? s) => switch (s) {
        'wish' => wish,
        'reading' => reading,
        'finished' => finished,
        'abandoned' => abandoned,
        'borrowed' => borrowed,
        'paused' => paused,
        _ => wish,
      };

  String get label => switch (this) {
        BookStatus.wish => '想读',
        BookStatus.reading => '在读',
        BookStatus.finished => '已读',
        BookStatus.abandoned => '弃读',
        BookStatus.borrowed => '借阅中',
        BookStatus.paused => '暂搁',
      };
}

/// 载体形态
enum BookFormat { ebook, paper, audio, pdf, comic;

  static BookFormat fromString(String? s) => switch (s) {
        'paper' => paper,
        'audio' => audio,
        'pdf' => pdf,
        'comic' => comic,
        _ => ebook,
      };

  String get label => switch (this) {
        BookFormat.ebook => '电子书',
        BookFormat.paper => '纸质',
        BookFormat.audio => '有声书',
        BookFormat.pdf => 'PDF',
        BookFormat.comic => '漫画',
      };
}

/// 来源平台
enum BookSource {
  weread,    // 微信读书
  zhangyue,  // 掌阅精选
  jdread,    // 京东读书专业版
  boox,      // 文石
  library,   // 图书馆借阅
  notion,    // Notion 历史
  manual;    // 手动

  static BookSource fromString(String? s) => switch (s) {
        'weread' => weread,
        'zhangyue' => zhangyue,
        'jdread' => jdread,
        'boox' => boox,
        'library' => library,
        'notion' => notion,
        _ => manual,
      };

  String get label => switch (this) {
        BookSource.weread => '微信读书',
        BookSource.zhangyue => '掌阅精选',
        BookSource.jdread => '京东读书',
        BookSource.boox => '文石',
        BookSource.library => '图书馆',
        BookSource.notion => 'Notion',
        BookSource.manual => '手动',
      };
}

/// 笔记类型
enum NoteType { highlight, thought, review }

extension NoteTypeX on NoteType {
  static NoteType fromString(String? s) => switch (s) {
        'thought' => NoteType.thought,
        'review' => NoteType.review,
        _ => NoteType.highlight,
      };

  String get label => switch (this) {
        NoteType.highlight => '划线',
        NoteType.thought => '想法',
        NoteType.review => '评论',
      };
}

/// 默认一级分类（LLM 归类时的受控词表，防止分类爆炸）
const List<String> defaultCategories = [
  '文学', '社科', '历史', '哲学', '心理', '经济', '管理', '科技',
  '计算机', '艺术', '传记', '教育', '科普', '医学', '法律', '宗教',
  '童书', '漫画', '成长', '其他',
];

/// 外部平台分类 → 受控词表 的归一化映射
///
/// 微信读书返回自有分类体系（经济理财 / 个人成长 / 哲学宗教 / 男生小说…），
/// 与受控词表并存会让同一语义分裂成多个标签——实测「经济理财 18 本」与
/// 「经济 9 本」并列，直接污染统计图表。此处统一归口。
const Map<String, String> categoryAliases = {
  '精品小说': '文学', '男生小说': '文学', '女生小说': '文学', '小说': '文学',
  '外国文学': '文学', '中国文学': '文学',
  '社会文化': '社科', '政治军事': '社科', '社会学': '社科', '政治': '社科',
  '哲学宗教': '哲学',
  '经济理财': '经济', '经管': '经济', '理财': '经济', '金融': '经济',
  '经管励志': '管理', '商业': '管理', '企业管理': '管理',
  // 自我提升单列，曾并入心理导致心理类占比虚高到 24%
  '个人成长': '成长', '励志': '成长', '成功学': '成长', '自我提升': '成长',
  '学习方法': '成长', '职场': '成长',
  '教育学习': '教育', '学习教育': '教育', '教材': '教育', '外语学习': '教育',
  '科学技术': '科技', '自然科学': '科普', '科普读物': '科普',
  '计算机与互联网': '计算机', '互联网': '计算机', '编程': '计算机',
  '生活百科': '其他', '生活': '其他', '育儿': '其他', '烹饪': '其他',
  '健身': '其他', '旅行': '其他', '美食': '其他',
  '医药卫生': '医学', '医学健康': '医学', '健康': '医学',
  '摄影': '艺术', '设计': '艺术', '音乐': '艺术',
  '人物传记': '传记', '回忆录': '传记',
  '法学': '法律', '儿童文学': '童书', '绘本': '童书', '绘本漫画': '漫画',
};

/// 把任意来源的分类归一化到受控词表
String? normalizeCategory(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  if (defaultCategories.contains(s)) return s;
  final exact = categoryAliases[s];
  if (exact != null) return exact;
  // 兜底：按包含关系匹配，例「经济理财-财经」→「经济」
  for (final entry in categoryAliases.entries) {
    if (s.contains(entry.key)) return entry.value;
  }
  for (final c in defaultCategories) {
    if (s.contains(c)) return c;
  }
  return '其他';
}
