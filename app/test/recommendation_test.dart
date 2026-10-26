import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/recommendation.dart';

/// 大模型返回的推荐条目的解析。
///
/// ## 为什么这组测试重要
///
/// 大模型的输出**形态不可控**：可能是裸数组、可能裹一层 `books`、
/// 可能把字段叫 `name` 而不是 `title`、可能给纯 Markdown 列表、
/// 可能把数字写成字符串。任何一种解析失败，用户的感受都是
/// 「推荐了 0 本」——功能完全不可用，且很难定位。
///
/// 所以这里穷举各种畸形输入，要求**能收几条收几条，绝不整批丢弃**。
void main() {
  group('裸数组', () {
    test('标准形态', () {
      final out = RecommendationDraft.parseList(
        '[{"title":"三体","author":"刘慈欣","reason":"硬科幻经典"}]',
      );
      expect(out, hasLength(1));
      expect(out.first.title, '三体');
      expect(out.first.author, '刘慈欣');
      expect(out.first.reason, '硬科幻经典');
    });

    test('缺字段也能收——只丢没有书名的那条', () {
      final out = RecommendationDraft.parseList(
        '[{"title":"活着"},{"author":"余华"},{"title":"围城"}]',
      );
      expect(out.map((e) => e.title), ['活着', '围城']);
    });

    test('title 写成 name 也能认', () {
      final out = RecommendationDraft.parseList('[{"name":"三体"}]');
      expect(out.single.title, '三体');
    });

    test('数字当字符串也能收', () {
      final out = RecommendationDraft.parseList(
        '[{"title":"三体","year":2008}]',
      );
      expect(out.single.title, '三体');
    });

    test('数组里混着裸字符串也收', () {
      final out = RecommendationDraft.parseList('["三体","活着"]');
      expect(out.map((e) => e.title), ['三体', '活着']);
    });
  });

  group('包裹形态', () {
    test('books 键', () {
      final out = RecommendationDraft.parseList(
        '{"books":[{"title":"三体"}]}',
      );
      expect(out.single.title, '三体');
    });

    test('recommendations 键', () {
      final out = RecommendationDraft.parseList(
        '{"recommendations":[{"title":"三体"}]}',
      );
      expect(out.single.title, '三体');
    });

    test('嵌套一层（data.items）', () {
      final out = RecommendationDraft.parseList(
        '{"data":{"items":[{"title":"三体"}]}}',
      );
      expect(out.single.title, '三体');
    });

    test('不认识的外层键也不该整批丢弃', () {
      final out = RecommendationDraft.parseList(
        '{"whatever":[{"title":"三体"}]}',
      );
      expect(out.single.title, '三体');
    });
  });

  group('非 JSON', () {
    test('Markdown 列表：取书名号里的内容', () {
      final out = RecommendationDraft.parseList(
        '1. 《三体》— 刘慈欣 — 硬科幻的巅峰\n'
        '2. 《活着》— 余华 — 讲透活着的意义',
      );
      expect(out.map((e) => e.title), ['三体', '活着']);
      expect(out.first.reason, contains('硬科幻'));
    });

    test('空字符串返回空列表，不抛异常', () {
      expect(RecommendationDraft.parseList(''), isEmpty);
      expect(RecommendationDraft.parseList('   '), isEmpty);
    });

    test('完全不是书单的文字不该产出条目', () {
      // 一段没有书名号的散文。若兜底无节制，它会被当成一本名叫
      // 「今天天气不错适合出门散步」的书——用户看到的是乱码书名。
      final out = RecommendationDraft.parseList(
        '今天天气不错适合出门散步',
      );
      expect(out, isEmpty,
          reason: '没有书名号的纯文本不该被当成书单');
    });

    test('整段里有一行带书名号，就按 Markdown 列表解析', () {
      final out = RecommendationDraft.parseList(
        '给你推荐几本：\n'
        '1. 《三体》— 刘慈欣 — 硬科幻经典\n'
        '2. 《活着》— 余华',
      );
      expect(out.map((e) => e.title), ['三体', '活着']);
    });
  });

  group('健壮性', () {
    test('单个条目是 null 不影响其他条目', () {
      final out = RecommendationDraft.parseList(
        '[null,{"title":"三体"},null]',
      );
      expect(out.single.title, '三体');
    });

    test('title 是空串或纯空格的条目被丢弃', () {
      final out = RecommendationDraft.parseList(
        '[{"title":""},{"title":"   "},{"title":"三体"}]',
      );
      expect(out.single.title, '三体');
    });

    test('title 是数字也能转成字符串', () {
      final out = RecommendationDraft.parseList('[{"title":12345}]');
      expect(out.single.title, '12345');
    });

    test('reason 缺失时为 null，不是空串', () {
      final out = RecommendationDraft.parseList('[{"title":"三体"}]');
      expect(out.single.reason, isNull);
    });

    test('reason 显式给空串时归一成 null', () {
      final out = RecommendationDraft.parseList('[{"title":"三体","reason":""}]');
      expect(out.single.reason, isNull);
    });
  });
}
