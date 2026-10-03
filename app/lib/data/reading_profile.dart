import '../models/book.dart';
import '../l10n/app_loc.dart';
import '../models/enums.dart';
import 'bubble_pack.dart';
import 'date_range.dart';
import 'stats_aggregate.dart';

/// 一个性格标签
class ProfileTag {
  /// 标签文字，2~6 字
  final String text;

  /// 依据。界面上点一下就能看到，避免标签变成「拍脑袋的玄学」
  final String reason;

  final int weight;

  const ProfileTag({required this.text, required this.reason, this.weight = 0});
}

/// 一个分类偏好切片
class PreferenceSlice {
  final String label;
  final int count;
  final double share;

  const PreferenceSlice({
    required this.label,
    required this.count,
    required this.share,
  });
}

/// 阅读画像：性格标签 + 偏好分布。
///
/// 刻意做成**纯函数 + 可离线**：标签不是大模型猜出来的，而是从藏书结构里
/// 推出来的。理由有两条：
///   1. 没配大模型 Key 的用户也应该看得到这张页面；
///   2. 标签一旦脱离数据就变成许愿签——「你是个浪漫的人」这种话，
///      任何书单都能套上，看两遍就腻。
/// 大模型生成的是**另一版**，两者并列展示，用户自己挑。
class ReadingProfile {
  final List<ProfileTag> tags;
  final List<PreferenceSlice> preferences;
  final List<Bubble> bubbles;

  const ReadingProfile({
    this.tags = const [],
    this.preferences = const [],
    this.bubbles = const [],
  });

  static ReadingProfile build(
    List<Book> books, {
    ReadingActivity activity = ReadingActivity.empty,
    int maxTags = 12,
    int maxBubbles = 12,
  }) {
    final prefs = preferencesOf(books, max: maxBubbles);
    return ReadingProfile(
      tags: buildTags(books, activity: activity, max: maxTags),
      preferences: prefs,
      bubbles: packBubbles([
        for (final p in prefs) BubbleInput(label: p.label, value: p.count.toDouble()),
      ]),
    );
  }

  /// 分类偏好切片，数量降序
  static List<PreferenceSlice> preferencesOf(List<Book> books, {int max = 12}) {
    final dist = categoryDistributionOf(books);
    final total = dist.fold<int>(0, (a, b) => a + (b['c'] as int));
    return [
      for (final d in dist.take(max))
        PreferenceSlice(
          label: d['name'] as String,
          count: d['c'] as int,
          share: total == 0 ? 0 : (d['c'] as int) / total,
        ),
    ];
  }

  /// 由数据推导性格标签
  static List<ProfileTag> buildTags(
    List<Book> books, {
    ReadingActivity activity = ReadingActivity.empty,
    int max = 12,
  }) {
    final s = _Facts.of(books, activity);
    final out = <ProfileTag>[];
    for (final r in _rules) {
      if (!r.when(s)) continue;
      out.add(ProfileTag(text: r.tag, reason: r.reason(s), weight: r.weight));
    }
    out.sort((a, b) => b.weight.compareTo(a.weight));
    return out.take(max).toList();
  }
}

/// 规则求值用的派生指标。一次算好，避免每条规则各扫一遍书目。
class _Facts {
  final int total;
  final int finished;
  final int reading;
  final int wish;
  /// 搁置（原「弃读」+「暂搁」合并后的状态）
  final int shelved;
  final int stalled;
  final int reread;
  final int categoryKinds;
  final int ratedCount;
  final double avgRating;
  final double ratingStdDev;
  final double finishRate;
  final int minutes;
  final int? activeDays;
  final Map<String, int> categories;
  final Map<BookSource, int> sources;
  final Map<BookFormat, int> formats;

  const _Facts({
    required this.total,
    required this.finished,
    required this.reading,
    required this.wish,
    required this.shelved,
    required this.stalled,
    required this.reread,
    required this.categoryKinds,
    required this.ratedCount,
    required this.avgRating,
    required this.ratingStdDev,
    required this.finishRate,
    required this.minutes,
    required this.activeDays,
    required this.categories,
    required this.sources,
    required this.formats,
  });

  factory _Facts.of(List<Book> books, ReadingActivity activity) {
    final status = statusCountsOf(books);
    final cats = <String, int>{};
    for (final b in books) {
      final k = b.categoryPrimary ?? kUncategorized;
      cats[k] = (cats[k] ?? 0) + 1;
    }
    final sources = <BookSource, int>{};
    final formats = <BookFormat, int>{};
    var reread = 0;
    for (final b in books) {
      sources[b.source] = (sources[b.source] ?? 0) + 1;
      formats[b.format] = (formats[b.format] ?? 0) + 1;
      if (b.rereadCount > 0) reread++;
    }
    final finished = status[BookStatus.finished] ?? 0;

    return _Facts(
      total: books.length,
      finished: finished,
      reading: status[BookStatus.reading] ?? 0,
      wish: status[BookStatus.wish] ?? 0,
      shelved: status[BookStatus.shelved] ?? 0,
      stalled: stalledCountOf(books),
      reread: reread,
      categoryKinds: cats.length,
      ratedCount: books.where((b) => b.rating > 0).length,
      avgRating: averageRatingOf(books),
      ratingStdDev: ratingStdDevOf(books),
      finishRate: books.isEmpty ? 0 : finished / books.length,
      minutes: activity.minutes,
      activeDays: activity.activeDays,
      categories: cats,
      sources: sources,
      formats: formats,
    );
  }

  int cat(String name) => categories[name] ?? 0;

  double catShare(String name) => total == 0 ? 0 : cat(name) / total;

  int source(BookSource s) => sources[s] ?? 0;

  double sourceShare(BookSource s) => total == 0 ? 0 : source(s) / total;

  int format(BookFormat f) => formats[f] ?? 0;

  double formatShare(BookFormat f) => total == 0 ? 0 : format(f) / total;

  /// 某个分类是否「够显眼」。
  ///
  /// 两个条件都要满足：绝对本数 ≥ 2（1 本不足以说明偏好），
  /// 占比 ≥ 5%（挡住大书库里被稀释掉的偶然几本）。
  bool strong(String name) => cat(name) >= 2 && catShare(name) >= 0.05;

  String pct(String name) => '${(catShare(name) * 100).toStringAsFixed(1)}%';
}

class _Rule {
  final String tag;
  final int weight;
  final bool Function(_Facts) when;
  final String Function(_Facts) reason;

  const _Rule({
    required this.tag,
    required this.weight,
    required this.when,
    required this.reason,
  });
}

/// 规则表。
///
/// 「有依据」是这里唯一的设计约束：每条 [reason] 都必须能落到具体数字上，
/// 否则标签就退化成星座运势。权重决定排序，行为类标签权重略高——
/// 「你是怎样读书的」比「你读了哪一类」更像性格。
///
/// ⚠️ **必须每次现取，不能 `final` 顶层常量**。
/// `appLoc` 是「当前语言的 S 实例」，而 `_Rule.tag` / `_Rule.reason`
/// 在**构造那一刻**就把字符串求值定死了。顶层 `final` 是懒初始化、
/// 只算一次：用户第一次打开画像页时是哪种语言，这张表就永远停在
/// 那种语言——中文模式下显示英文的根因就在这里。
/// 做成 getter 后每次调用重新构造，语言切换立刻生效。
List<_Rule> get _rules => [
  /* ------------------------- 分类偏好 ------------------------- */
  _Rule(
    tag: appLoc.s_420a7ac1,
    weight: 58,
    when: (s) => s.strong('成长'),
    reason: (s) => appLoc.s_3702d226(cat: s.cat('成长'), pct: s.pct('成长')),
  ),
  _Rule(
    tag: appLoc.s_6672b3fa,
    weight: 56,
    when: (s) => s.strong('文学'),
    reason: (s) => appLoc.s_40ba4ecb(cat: s.cat('文学'), pct: s.pct('文学')),
  ),
  _Rule(
    tag: appLoc.s_ea2eaec4,
    weight: 54,
    when: (s) => s.strong('哲学'),
    reason: (s) => appLoc.s_0f80a135(cat: s.cat('哲学'), pct: s.pct('哲学')),
  ),
  _Rule(
    tag: appLoc.s_111ec0f6,
    weight: 52,
    when: (s) => s.strong('历史'),
    reason: (s) => appLoc.s_abeb8e3d(cat: s.cat('历史'), pct: s.pct('历史')),
  ),
  _Rule(
    tag: appLoc.s_5e336507,
    weight: 52,
    when: (s) => s.strong('心理'),
    reason: (s) => appLoc.s_cfce6d52(cat: s.cat('心理'), pct: s.pct('心理')),
  ),
  _Rule(
    tag: appLoc.s_d5e26f37,
    weight: 52,
    when: (s) => s.strong('计算机'),
    reason: (s) => appLoc.s_d6bdf44e(cat: s.cat('计算机'), pct: s.pct('计算机')),
  ),
  _Rule(
    tag: appLoc.s_00dcb308,
    weight: 50,
    when: (s) => s.strong('艺术'),
    reason: (s) => appLoc.s_aee18737(cat: s.cat('艺术'), pct: s.pct('艺术')),
  ),
  _Rule(
    tag: appLoc.s_2ddd554c,
    weight: 50,
    when: (s) => s.cat('经济') + s.cat('管理') >= 3 && s.catShare('经济') + s.catShare('管理') >= 0.08,
    reason: (s) =>
        appLoc.s_066faf9c(cat: s.cat('经济') + s.cat('管理'), toStringAsFixed: ((s.catShare('经济') + s.catShare('管理')) * 100).toStringAsFixed(1)),
  ),
  _Rule(
    tag: appLoc.s_d574ffeb,
    weight: 48,
    when: (s) => s.strong('社科'),
    reason: (s) => appLoc.s_5a276724(cat: s.cat('社科'), pct: s.pct('社科')),
  ),
  _Rule(
    tag: appLoc.s_d81bab36,
    weight: 48,
    when: (s) => s.strong('科普') || s.strong('科技'),
    reason: (s) {
      final n = s.cat('科普') + s.cat('科技');
      return appLoc.s_76c118d0(n: n);
    },
  ),
  _Rule(
    tag: appLoc.s_2b65326c,
    weight: 46,
    when: (s) => s.strong('传记'),
    reason: (s) => appLoc.s_b2e9db16(cat: s.cat('传记'), pct: s.pct('传记')),
  ),
  _Rule(
    tag: appLoc.s_9e49409c,
    weight: 46,
    when: (s) => s.strong('医学'),
    reason: (s) => appLoc.s_1dd31356(cat: s.cat('医学')),
  ),
  _Rule(
    tag: appLoc.s_77e32253,
    weight: 44,
    when: (s) => s.strong('法律'),
    reason: (s) => appLoc.s_82364cc8(cat: s.cat('法律')),
  ),
  _Rule(
    tag: appLoc.s_ea038731,
    weight: 46,
    when: (s) => s.strong('漫画') || s.strong('童书'),
    reason: (s) => appLoc.s_a1b1d26a(cat: s.cat('漫画') + s.cat('童书')),
  ),
  _Rule(
    tag: appLoc.s_94f8d7c2,
    weight: 46,
    when: (s) => s.strong('宗教'),
    reason: (s) => appLoc.s_d00fbfe6(cat: s.cat('宗教')),
  ),
  _Rule(
    tag: appLoc.s_52c36d65,
    weight: 42,
    when: (s) => s.strong('其他'),
    reason: (s) => appLoc.s_e3a3f18e(cat: s.cat('其他'), pct: s.pct('其他')),
  ),
  _Rule(
    tag: appLoc.s_dc2e94c1,
    weight: 42,
    when: (s) => s.strong('教育'),
    reason: (s) => appLoc.s_be73b4a0(cat: s.cat('教育'), pct: s.pct('教育')),
  ),

  /* ------------------------- 行为特征 ------------------------- */
  _Rule(
    tag: appLoc.s_7ea6e8a9,
    weight: 62,
    when: (s) => s.categoryKinds >= 10,
    reason: (s) => appLoc.s_938fd6ec(categoryKinds: s.categoryKinds),
  ),
  _Rule(
    tag: appLoc.s_41a09d04,
    weight: 58,
    when: (s) => s.total >= 6 && s.categoryKinds <= 3,
    reason: (s) => appLoc.s_c61130ac(total: s.total, categoryKinds: s.categoryKinds),
  ),
  _Rule(
    tag: appLoc.s_431dc47d,
    weight: 64,
    when: (s) => s.total >= 5 && s.finishRate >= 0.6,
    reason: (s) =>
        appLoc.s_a7b097f6(toStringAsFixed: (s.finishRate * 100).toStringAsFixed(0), finished: s.finished, total: s.total),
  ),
  _Rule(
    tag: appLoc.s_6b51050c,
    weight: 60,
    when: (s) => s.wish >= 10 && s.wish >= s.finished * 2,
    reason: (s) => appLoc.s_55413cd8(wish: s.wish, finished: s.finished),
  ),
  _Rule(
    tag: appLoc.s_e60e931c,
    weight: 60,
    when: (s) => s.total >= 5 && s.shelved / s.total >= 0.15,
    reason: (s) =>
        appLoc.s_b3549d21(abandoned: s.shelved, toStringAsFixed: (s.shelved * 100 / s.total).toStringAsFixed(0)),
  ),
  _Rule(
    tag: appLoc.s_4be15f8c,
    weight: 56,
    when: (s) => s.stalled >= 4,
    reason: (s) => appLoc.s_b0a853cf(stalled: s.stalled),
  ),
  _Rule(
    tag: appLoc.s_10b9bddd,
    weight: 54,
    when: (s) => s.ratedCount >= 5 && s.avgRating >= 4.3,
    reason: (s) => appLoc.s_6a469e36(ratedCount: s.ratedCount, toStringAsFixed: s.avgRating.toStringAsFixed(1)),
  ),
  _Rule(
    tag: appLoc.s_e67694db,
    weight: 54,
    when: (s) => s.ratedCount >= 5 && s.avgRating <= 2.9,
    reason: (s) => appLoc.s_30c4cecf(ratedCount: s.ratedCount, toStringAsFixed: s.avgRating.toStringAsFixed(1)),
  ),
  _Rule(
    tag: appLoc.s_fe4567e4,
    weight: 52,
    when: (s) => s.ratedCount >= 5 && s.ratingStdDev >= 1.1,
    reason: (s) => appLoc.s_b1d69175(toStringAsFixed: s.ratingStdDev.toStringAsFixed(2)),
  ),
  _Rule(
    tag: appLoc.s_fbad19d5,
    weight: 52,
    when: (s) => s.reread >= 2,
    reason: (s) => appLoc.s_8d62979c(reread: s.reread),
  ),
  _Rule(
    tag: appLoc.s_54302bb2,
    weight: 50,
    when: (s) {
      final d = s.activeDays;
      return d != null && d >= 5 && s.minutes / d >= 60;
    },
    reason: (s) =>
        appLoc.s_bc9dbced(round: (s.minutes / s.activeDays!).round()),
  ),
  _Rule(
    tag: appLoc.s_e9eddf51,
    weight: 44,
    when: (s) => s.sourceShare(BookSource.weread) >= 0.5,
    reason: (s) =>
        appLoc.s_df5bbdba(weread: s.source(BookSource.weread), toStringAsFixed: (s.sourceShare(BookSource.weread) * 100).toStringAsFixed(0)),
  ),
  _Rule(
    tag: appLoc.s_ce6517f9,
    weight: 44,
    when: (s) =>
        s.sourceShare(BookSource.library) + s.formatShare(BookFormat.paper) >= 0.25,
    reason: (s) => appLoc.s_75c2fd5a(libraryCount: s.source(BookSource.library), paper: s.format(BookFormat.paper)),
  ),
  _Rule(
    tag: appLoc.s_8cac22b7,
    weight: 46,
    when: (s) => s.format(BookFormat.audio) >= 2,
    reason: (s) => appLoc.s_72b826e9(audio: s.format(BookFormat.audio)),
  ),
  _Rule(
    tag: appLoc.s_7caeab27,
    weight: 42,
    when: (s) => s.format(BookFormat.comic) >= 2,
    reason: (s) => appLoc.s_a5a44a39(comic: s.format(BookFormat.comic)),
  ),
];
