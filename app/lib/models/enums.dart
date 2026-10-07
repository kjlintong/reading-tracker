import '../l10n/app_loc.dart';
// 全局枚举与常量。
// 与 tools/lib/schema.mjs 中的定义一一对应，保证跨端数据一致。

/// 阅读状态。
///
/// **只有四个互斥的状态**，按「读没读完」这条单一维度划分：
///   想读（还没开始）→ 在读（读了没读完）→ 已读（读完了）
///   以及旁支的 搁置（不打算继续读了）。
///
/// 历史上这里是六个值，问题出在两个地方：
///   1. **「弃读」与「暂搁」重叠**——用户面对两个「不读了」必须二选一，
///      而这两个词的真实差别（以后还回不回来）他心里也没准数。
///      现在合并成一个 [shelved]，文案取「搁置」，中性且两种情形都装得下。
///   2. **「借阅中」根本不是一个阅读状态**。它是「这本书不是我的」这个
///      事实，可以和「在读」「已读」任意叠加——借来的书当然也在读。
///      把它塞进状态枚举，等于强迫用户在「在读」和「借阅中」之间选一个，
///      两个说的根本不是一回事。现在拆成 [Book.isBorrowed] + 应还日期。
///
/// ⚠️ [fromString] 保留对旧值的兼容映射（`borrowed` / `paused`），
/// 因为数据库里可能还有迁移前写入的行；`_onUpgrade` 会把它们改写掉，
/// 但 fromString 是最后一道防线——遇到脏数据不能静默回落到「想读」，
/// 那会让一本正在读的书从统计里消失。
enum BookStatus {
  wish,       // 想读
  reading,    // 在读
  finished,   // 已读
  shelved;    // 搁置

  static BookStatus fromString(String? s) => switch (s) {
        'wish' => wish,
        'reading' => reading,
        'finished' => finished,
        'shelved' => shelved,
        // —— 旧值兼容 ——
        // 'abandoned'（弃读）与 'paused'（暂搁）都归到 shelved
        'abandoned' => shelved,
        'paused' => shelved,
        // 'borrowed'（借阅中）本质是在读，借阅标记已拆成独立字段
        'borrowed' => reading,
        _ => wish,
      };

  String get label => switch (this) {
        BookStatus.wish => appLoc.s_5a833930,
        BookStatus.reading => appLoc.s_b9bf9b53,
        BookStatus.finished => appLoc.s_300a32bd,
        BookStatus.shelved => appLoc.s_eba88d83,
      };

  /// 落库用的稳定字符串。**不要直接用 `.name`**——[fromString] 认旧值，
  /// 但写回时要保证是当前词表里的值。
  String get storageValue => switch (this) {
        BookStatus.wish => 'wish',
        BookStatus.reading => 'reading',
        BookStatus.finished => 'finished',
        BookStatus.shelved => 'shelved',
      };

  /// 状态说明。用于选择器下方那行小字——「已读 vs 在读」的歧义
  /// 光靠两个词消不掉，得让用户知道判据是「进度到没到 100%」。
  String get hint => switch (this) {
        BookStatus.wish => appLoc.statusWishHint,
        BookStatus.reading => appLoc.statusReadingHint,
        BookStatus.finished => appLoc.statusFinishedHint,
        BookStatus.shelved => appLoc.statusShelvedHint,
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
        BookFormat.ebook => appLoc.s_b6fe7962,
        BookFormat.paper => appLoc.s_c7673d27,
        BookFormat.audio => appLoc.s_02a1a8ed,
        BookFormat.pdf => 'PDF',
        BookFormat.comic => appLoc.s_dbb1c112,
      };

  /// 手动添加时可选的载体。
  ///
  /// PDF / 漫画与「电子书 / 纸质」语义重叠（PDF 是种文件格式，漫画可电子可纸质），
  /// 摆在一起就是用户说的「有重复」。它们仍保留在枚举里：
  /// 漫画是阅读画像「漫画迷」检测的依据，存量数据里也可能有这两个值——
  /// 但手动添加只暴露三种真正互斥的形态，避免用户纠结。
  static const List<BookFormat> userVisible = [ebook, paper, audio];
}

/// 来源平台
enum BookSource {
  weread,      // 微信读书
  zhangyue,    // 掌阅精选
  jdread,      // 京东读书专业版
  boox,        // 文石
  library,     // 图书馆借阅
  notion,      // Notion 历史
  goodreads,   // Goodreads（国际用户主流书库，可导出 CSV）
  openlibrary, // Open Library / Google Books 搜索导入
  applebooks,  // Apple Books（无公开导入 API，仅作来源标记）
  kobo,        // Kobo（无公开导入 API，仅作来源标记）
  manual;      // 手动

  static BookSource fromString(String? s) => switch (s) {
        'weread' => weread,
        'zhangyue' => zhangyue,
        'jdread' => jdread,
        'boox' => boox,
        'library' => library,
        'notion' => notion,
        'goodreads' => goodreads,
        'openlibrary' => openlibrary,
        'applebooks' => applebooks,
        'kobo' => kobo,
        _ => manual,
      };

  String get label => switch (this) {
        BookSource.weread => appLoc.s_fe152225,
        BookSource.zhangyue => appLoc.s_2032cbd7,
        BookSource.jdread => appLoc.s_12ed007e,
        BookSource.boox => appLoc.s_570bb7c8,
        BookSource.library => appLoc.s_36bfef2d,
        BookSource.notion => 'Notion',
        BookSource.goodreads => 'Goodreads',
        BookSource.openlibrary => 'Open Library',
        BookSource.applebooks => 'Apple Books',
        BookSource.kobo => 'Kobo',
        BookSource.manual => appLoc.s_4139f3b5,
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
        NoteType.highlight => appLoc.s_88cdd7e4,
        NoteType.thought => appLoc.s_6abc44a8,
        NoteType.review => appLoc.s_67585b8a,
      };
}

/// 默认一级分类（LLM 归类时的受控词表，防止分类爆炸）。
///
/// 这里的字符串是**规范值（canonical）**：它们会被写进数据库的
/// `categoryPrimary` 字段，所以要刻意保持为与界面语言无关的固定字面量。
/// 若把规范值本身本地化，切一次语言历史数据就会裂成两组
/// （同本书既有「文学」又有「Literature」），统计与归一化全部失效。
/// 界面显示一律走 [categoryLabel]。
const List<String> defaultCategories = [
  '文学', '社科', '历史', '哲学', '心理', '经济', '管理', '科技',
  '计算机', '艺术', '传记', '教育', '科普', '医学', '法律', '宗教',
  '童书', '漫画', '成长', '其他',
];

/// 「未分类」的规范值。
///
/// 它同时被当作 Map 的 key 使用（见 reading_profile / stats_aggregate），
/// 所以必须是常量而不是本地化文案；显示时经 [categoryLabel] 转换。
const String kUncategorized = '未分类';

/// 用户对默认词表做的修改。
///
/// 为什么是两个名单而不是「把整份词表存下来」：
/// [defaultCategories] 将来还会扩充（新分类要自动出现在老用户的可选列表里），
/// 存全量快照的话新分类永远进不来。所以默认分类用**黑名单**（隐藏了哪些），
/// 用户新增的用**白名单**（加了哪些），两者相加才是当前生效的词表。
///
/// 两个字段都为空时，[active] 与 [defaultCategories] 完全一致——
/// 即「用户没改过」和「改回了默认」是同一个状态，不需要额外迁移。
class CategoryVocabulary {
  /// 用户自己新增的分类（不属于 [defaultCategories]）。
  final List<String> custom;

  /// 用户从 [defaultCategories] 里移除的分类。
  final List<String> hidden;

  const CategoryVocabulary({this.custom = const [], this.hidden = const []});

  /// 空词表 = 用户没做过任何修改。
  static const empty = CategoryVocabulary();

  /// 当前生效的分类：默认里没被移除的，加上用户新增的。
  ///
  /// 顺序即界面上的展示顺序：默认分类保持原有次序在前，自定义追加在后。
  /// 分类下拉、AI 归类词表、归一化判定全部以它为准。
  ///
  /// 去重是必须的：把删掉的默认分类重新加回来时，它既在默认名单里
  /// （因为已从 hidden 移出）又在 custom 里，不去重会出现两个同名项。
  List<String> get active {
    final out = <String>[];
    final seen = <String>{};
    for (final c in defaultCategories) {
      if (hidden.contains(c)) continue;
      if (seen.add(c)) out.add(c);
    }
    for (final c in custom) {
      if (seen.add(c)) out.add(c);
    }
    return out;
  }

  bool get isEmpty => custom.isEmpty && hidden.isEmpty;

  /// 是否是用户自定义分类。
  ///
  /// 默认分类**即使被用户删掉又加回来也不算自定义**：它回到了默认词表的
  /// 位置和显示名，界面上不该给它挂「自定义」的角标。
  bool isCustom(String v) => custom.contains(v) && !isDefault(v);

  bool isDefault(String v) => defaultCategories.contains(v);

  bool contains(String v) => active.contains(v);
}

/// 全局生效的分类词表。
///
/// 做成全局可变单例而不是 Riverpod provider：[normalizeCategory] 是纯函数，
/// 被数据库迁移、导入管道、AI 客户端在**没有 BuildContext 的地方**调用，
/// 拿不到 ref。启动时由 [loadSettings] 从 settings 表装载一次，
/// 设置页改动后同步更新。未装载时等于 [CategoryVocabulary.empty]，
/// 行为与改动前完全一致。
CategoryVocabulary categoryVocabulary = CategoryVocabulary.empty;

/// 外部平台分类 → 受控词表 的归一化映射
///
/// 微信读书返回自有分类体系（经济理财 / 个人成长 / 哲学宗教 / 男生小说…），
/// 与受控词表并存会让同一语义分裂成多个标签——实测「经济理财 18 本」与
/// 「经济 9 本」并列，直接污染统计图表。此处统一归口。
///
/// key 既包含国内的原始分类名，也包含 Goodreads / Open Library /
/// Google Books 等国际来源的英文分类名；value 一律是 [defaultCategories]
/// 中的规范值。
final Map<String, String> categoryAliases = {
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

  // —— 国际来源的英文分类（Goodreads / Open Library / Google Books）——
  // 注意：包含式兜底按 key 长度降序匹配，因此 'Nonfiction' 之类更具体的词
  // 不会被 'Fiction' 抢先命中。
  'Nonfiction': '社科',
  'Literary Fiction': '文学', 'Fiction': '文学', 'Novels': '文学',
  'Classics': '文学', 'Poetry': '文学', 'Drama': '文学',
  'Social Science': '社科', 'Political Science': '社科', 'Politics': '社科',
  'Sociology': '社科', 'Anthropology': '社科',
  'History': '历史', 'Historical': '历史',
  'Philosophy': '哲学',
  'Psychology': '心理',
  'Self-Help': '成长', 'Self Help': '成长', 'Personal Development': '成长',
  'Motivational': '成长', 'Career': '成长',
  'Business': '管理', 'Management': '管理', 'Leadership': '管理',
  'Economics': '经济', 'Finance': '经济', 'Investing': '经济', 'Money': '经济',
  'Education': '教育', 'Teaching': '教育', 'Language': '教育',
  'Textbook': '教育',
  'Science': '科技', 'Technology': '科技', 'Engineering': '科技',
  'Popular Science': '科普', 'Nature': '科普',
  'Computers': '计算机', 'Computer Science': '计算机', 'Programming': '计算机',
  'Internet': '计算机', 'Artificial Intelligence': '计算机', 'Machine Learning': '计算机',
  'Data Science': '计算机', 'Software Engineering': '计算机',
  'Information Technology': '计算机',
  'Art': '艺术', 'Design': '艺术', 'Music': '艺术', 'Photography': '艺术',
  'Biography & Autobiography': '传记', 'Biography': '传记',
  'Memoir': '传记', 'Autobiography': '传记',
  'Medicine': '医学', 'Medical': '医学', 'Health': '医学',
  'Law': '法律', 'Legal': '法律',
  'Religion': '宗教', 'Spirituality': '宗教',
  'Juvenile Fiction': '童书', 'Picture Books': '童书', 'Children': '童书',
  'Comics': '漫画', 'Graphic Novels': '漫画', 'Manga': '漫画',
  'Cooking': '其他', 'Food': '其他', 'Travel': '其他', 'Parenting': '其他',
  'Lifestyle': '其他', 'Sports': '其他', 'Fitness': '其他',
};

/// 包含式兜底用的匹配器：长度降序，且纯 ASCII 的 key 按「词边界」匹配。
///
/// 长度降序保证更具体的分类先命中：Goodreads 的层级分类
/// "Nonfiction > Philosophy" 同时含 'Nonfiction' 与 'Philosophy'，
/// 先命中哪个取决于顺序。
///
/// 词边界是必要的而中文不需要：中文分类名不会被嵌在更长的词里，
/// 但英文会——不带边界时 'Art' 会在 'Artificial Intelligence' 里命中，
/// 把计算机类图书判成艺术类。`\b` 同时让 'Nonfiction' 不再被 'Fiction' 抢走。
final List<(RegExp, String)> _aliasMatchers = () {
  final keys = categoryAliases.keys.toList()
    ..sort((a, b) {
      // 长度降序；同长度时按字典序，保证结果可复现
      // （List.sort 不保证稳定，并列时若不设次级键，命中哪个 key 会漂移）
      final byLen = b.length.compareTo(a.length);
      return byLen != 0 ? byLen : a.compareTo(b);
    });
  return [
    for (final k in keys)
      (
        k.codeUnits.every((c) => c < 128)
            ? RegExp(r'\b' + RegExp.escape(k) + r'\b', caseSensitive: false)
            : RegExp(RegExp.escape(k)),
        k,
      ),
  ];
}();

/// 规范分类值 → 当前语言的显示名。
///
/// 未收录的值原样返回（例如尚未归一化、用户手写的自定义分类）。
String categoryLabel(String canonical) {
  if (canonical == kUncategorized) return appLoc.s_363c6a0c;
  return switch (canonical) {
    '文学' => appLoc.s_d422d33c,
    '社科' => appLoc.s_086ac5bf,
    '历史' => appLoc.s_07f288e9,
    '哲学' => appLoc.s_5da32671,
    '心理' => appLoc.s_4307c7a8,
    '经济' => appLoc.s_56734d39,
    '管理' => appLoc.s_5974bf24,
    '科技' => appLoc.s_fcc3102d,
    '计算机' => appLoc.s_8612fa7f,
    '艺术' => appLoc.s_b31e932c,
    '传记' => appLoc.s_f85fa7d4,
    '教育' => appLoc.s_235af603,
    '科普' => appLoc.s_41fa5c70,
    '医学' => appLoc.s_c21b69a8,
    '法律' => appLoc.s_0323f1bb,
    '宗教' => appLoc.s_30412ad5,
    '童书' => appLoc.s_6398a679,
    '漫画' => appLoc.s_dbb1c112,
    '成长' => appLoc.s_bcd278a6,
    '其他' => appLoc.s_06e23c48,
    _ => canonical,
  };
}

/// 把任意来源的分类归一化到**当前生效的**词表
///
/// 输入可以是国内平台的原始中文分类、国际来源的英文分类，
/// 也可以是当前语言的显示名（大模型按界面上见到的词作答时属于这种）。
/// 返回值优先是 [CategoryVocabulary.active] 中的规范值。
String? normalizeCategory(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final s = raw.trim();
  // 规范值、以及当前语言的显示名，都要能回到同一个规范值
  if (s == kUncategorized || s == categoryLabel(kUncategorized)) return kUncategorized;
  // 生效词表（含用户自定义分类）优先于别名表：
  // 用户新增「烹饪」后，不能让别名表把它折回「其他」。
  final vocab = categoryVocabulary.active;
  if (vocab.contains(s)) return s;
  final exact = categoryAliases[s];
  if (exact != null) return _guard(exact);
  // 当前语言的显示名
  for (final c in vocab) {
    if (categoryLabel(c) == s) return c;
  }
  // 兜底：按包含关系匹配，例「经济理财-财经」→「经济」
  for (final (pattern, key) in _aliasMatchers) {
    if (pattern.hasMatch(s)) return _guard(categoryAliases[key]!);
  }
  for (final c in vocab) {
    if (s.contains(c)) return c;
  }
  return _guard('其他');
}

/// 归一化结果落在已被用户移除的分类上时的兜底。
///
/// 不这么做的话会出现「删掉了『宗教』，新导入的书又把它带回来」——
/// 别名表是按语义写死的，它并不知道用户已经不要这个分类了。
String _guard(String normalized) {
  if (!categoryVocabulary.hidden.contains(normalized)) return normalized;
  return categoryVocabulary.contains('其他') ? '其他' : kUncategorized;
}
