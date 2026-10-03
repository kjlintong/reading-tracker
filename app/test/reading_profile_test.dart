import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/date_range.dart';
import 'package:reading_tracker/data/reading_profile.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

/// 性格标签的规则回归。
///
/// 规则表的价值全在两点上，两点都容易被后续「加个标签」的改动破坏：
///   1. **有依据**——每个标签的理由必须落到具体数字，不能是星座运势；
///   2. **不硬凑**——书不够就不给标签，而不是降阈值硬产出。
void main() {
  const iso = '2026-01-01T00:00:00.000Z';

  Book book(
    String id, {
    String? category,
    BookStatus status = BookStatus.wish,
    double rating = 0,
    double progress = 0,
    BookSource source = BookSource.manual,
    BookFormat format = BookFormat.ebook,
    int reread = 0,
  }) =>
      Book(
        id: id,
        title: id,
        categoryPrimary: category,
        status: status,
        rating: rating,
        progressPercent: progress,
        source: source,
        format: format,
        rereadCount: reread,
        createdAt: iso,
        updatedAt: iso,
      );

  List<Book> many(
    String category,
    int n, {
    BookStatus status = BookStatus.wish,
    double rating = 0,
    BookSource source = BookSource.manual,
  }) =>
      [
        for (var i = 0; i < n; i++)
          book('$category-$i',
              category: category, status: status, rating: rating, source: source),
      ];

  List<String> tagsOf(List<Book> books,
          {ReadingActivity activity = ReadingActivity.empty, int max = 12}) =>
      ReadingProfile.buildTags(books, activity: activity, max: max)
          .map((t) => t.text)
          .toList();

  group('分类偏好推出标签', () {
    test('文学多 → 浪漫诗意', () {
      expect(tagsOf(many('文学', 3)), contains('浪漫诗意'));
    });

    test('只有一本同类书时不给标签', () {
      // 1 本不足以说明偏好。降阈值硬产出的标签等于许愿签
      expect(tagsOf(many('文学', 1)), isNot(contains('浪漫诗意')));
      expect(tagsOf(many('文学', 1)), isEmpty);
    });

    test('占比被大书库稀释后不再算偏好', () {
      // 30 本计算机 + 1 本文学：文学 1 本既不够数量也不够占比
      final books = [...many('计算机', 30), ...many('文学', 1)];
      final tags = tagsOf(books);
      expect(tags, isNot(contains('浪漫诗意')));
      expect(tags, contains('IT 精英'));
    });

    test('多个分类可以同时成立', () {
      final books = [...many('文学', 3), ...many('哲学', 3)];
      final tags = tagsOf(books);
      expect(tags, contains('浪漫诗意'));
      expect(tags, contains('孤独的智者'));
    });
  });

  group('行为特征推出标签', () {
    test('读完率高 → 有始有终', () {
      final books = [
        ...many('文学', 4, status: BookStatus.finished),
        ...many('心理', 2),
      ];
      expect(tagsOf(books), contains('有始有终'));
    });

    test('想读堆着不动 → 囤书如山', () {
      final books = [
        ...many('文学', 12),
        ...many('哲学', 2, status: BookStatus.finished),
      ];
      expect(tagsOf(books), contains('囤书如山'));
    });

    test('弃读率高 → 果断止损', () {
      final books = [
        ...many('文学', 4, status: BookStatus.shelved),
        ...many('历史', 2),
      ];
      expect(tagsOf(books), contains('果断止损'));
    });

    test('分类跨度大 → 博古通今', () {
      final books = [
        for (final c in [
          '文学', '哲学', '历史', '心理', '经济', '管理',
          '科技', '计算机', '艺术', '传记',
        ])
          ...many(c, 1),
      ];
      expect(books.length, 10);
      expect(tagsOf(books), contains('博古通今'));
    });

    test('分类集中在少数几类 → 专注深耕', () {
      final books = [...many('文学', 4), ...many('哲学', 3)];
      expect(tagsOf(books), contains('专注深耕'));
    });

    test('普遍高分与两极分化给出不同标签', () {
      final warm = [for (var i = 0; i < 5; i++) book('w$i', rating: 5)];
      expect(tagsOf(warm), contains('温柔以待'));

      final split = [
        book('a', rating: 5),
        book('b', rating: 5),
        book('c', rating: 1),
        book('d', rating: 1),
        book('e', rating: 3),
      ];
      final tags = tagsOf(split);
      expect(tags, contains('爱憎分明'));
      expect(tags, isNot(contains('温柔以待')));
    });

    test('平台集中度推出阅读载体标签', () {
      final books = [
        ...many('文学', 3, source: BookSource.weread),
        book('x', category: '哲学', source: BookSource.manual),
      ];
      expect(tagsOf(books), contains('电子书党'));
    });

    test('日均时长足够长 → 沉浸式阅读', () {
      final books = many('文学', 3);
      final long = tagsOf(books,
          activity: const ReadingActivity(minutes: 600, activeDays: 6));
      expect(long, contains('沉浸式阅读'));

      final short = tagsOf(books,
          activity: const ReadingActivity(minutes: 60, activeDays: 6));
      expect(short, isNot(contains('沉浸式阅读')));
    });
  });

  group('标签的呈现约束', () {
    test('每条标签的理由都必须落到数字上', () {
      final books = [
        ...many('文学', 4, status: BookStatus.finished, rating: 4.6),
        ...many('哲学', 3, rating: 4.6),
        ...many('历史', 2, status: BookStatus.shelved),
        ...many('计算机', 3, source: BookSource.weread),
      ];
      final tags = ReadingProfile.buildTags(books);
      expect(tags, isNotEmpty);
      for (final t in tags) {
        expect(t.reason, matches(RegExp(r'\d')),
            reason: '「${t.text}」的理由没有数字依据：${t.reason}');
      }
    });

    test('按权重降序排列，并受上限约束', () {
      final books = [
        ...many('文学', 4),
        ...many('哲学', 3),
        ...many('历史', 3),
        ...many('心理', 3),
        ...many('计算机', 3),
      ];
      final all = ReadingProfile.buildTags(books);
      expect(all.length, greaterThan(3));
      for (var i = 0; i + 1 < all.length; i++) {
        expect(all[i].weight, greaterThanOrEqualTo(all[i + 1].weight));
      }
      expect(ReadingProfile.buildTags(books, max: 3).length, 3);
    });

    test('空书库不产生任何标签', () {
      expect(ReadingProfile.buildTags(const []), isEmpty);
      expect(ReadingProfile.preferencesOf(const []), isEmpty);
    });
  });

  group('偏好分布', () {
    test('按数量降序并给出占比', () {
      final prefs = ReadingProfile.preferencesOf([
        ...many('文学', 3),
        ...many('哲学', 2),
        ...many('历史', 1),
      ]);
      expect(prefs.map((p) => p.label).toList(), ['文学', '哲学', '历史']);
      expect(prefs.first.count, 3);
      expect(prefs.first.share, closeTo(0.5, 1e-9));
    });

    test('气泡数量与分类数一致', () {
      final books = [
        ...many('文学', 3),
        ...many('哲学', 2),
        ...many('历史', 1),
      ];
      final p = ReadingProfile.build(books);
      expect(p.bubbles.length, p.preferences.length);
      expect(p.bubbles.first.value, 3);
    });

    test('气泡与图例覆盖同一批分类名', () {
      // 颜色是按「分类名 → 颜色」的映射发的，映射由图例顺序生成。
      // 两边名字对不上，图上那个圆就没有颜色可发（会退化成兜底色），
      // 用户看到的是一颗颜色对不上图例的圆。
      final books = [
        ...many('文学', 3),
        ...many('哲学', 2),
        ...many('历史', 1),
      ];
      final p = ReadingProfile.build(books);
      final legend = {for (final s in p.preferences) s.label};
      final drawn = {for (final b in p.bubbles) b.label};
      expect(drawn, legend);
    });

    test('没有分类的书归入未分类，不会被丢掉', () {
      final prefs = ReadingProfile.preferencesOf([
        book('a'),
        book('b'),
      ]);
      expect(prefs.single.label, '未分类');
      expect(prefs.single.count, 2);
    });
  });
}
