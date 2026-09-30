import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/models/enums.dart';

/// 分类归一化是数据治理的核心约束：微信读书、掌阅、京东各有自己的分类体系，
/// 不归口就会让「经济理财」和「经济」分裂成两类，直接污染统计图表。
/// 本文件与 Node 侧 tools/lib/schema.mjs 的 normalizeCategory 保持用例一致。
void main() {
  group('受控词表', () {
    test('词表规模固定为 20，且含「成长」', () {
      expect(defaultCategories.length, 20);
      expect(defaultCategories, contains('成长'));
    });

    test('已在词表内的原样返回', () {
      expect(normalizeCategory('经济'), '经济');
      expect(normalizeCategory('心理'), '心理');
      expect(normalizeCategory('哲学'), '哲学');
      expect(normalizeCategory('成长'), '成长');
      expect(normalizeCategory('计算机'), '计算机');
    });
  });

  group('外部平台分类归口', () {
    test('微信读书自有分类', () {
      expect(normalizeCategory('经济理财'), '经济');
      expect(normalizeCategory('个人成长'), '成长');
      expect(normalizeCategory('哲学宗教'), '哲学');
      expect(normalizeCategory('精品小说'), '文学');
      expect(normalizeCategory('男生小说'), '文学');
      expect(normalizeCategory('女生小说'), '文学');
      expect(normalizeCategory('社会文化'), '社科');
      expect(normalizeCategory('政治军事'), '社科');
      expect(normalizeCategory('教育学习'), '教育');
      expect(normalizeCategory('科学技术'), '科技');
      expect(normalizeCategory('生活百科'), '其他');
    });

    test('复合分类走包含关系兜底', () {
      expect(normalizeCategory('经济理财-财经'), '经济');
      expect(normalizeCategory('哲学宗教-哲学'), '哲学');
    });

    test('自我提升不并入心理', () {
      // 曾并入心理导致心理类占比虚高到 24%
      expect(normalizeCategory('励志'), '成长');
      expect(normalizeCategory('成功学'), '成长');
      expect(normalizeCategory('自我提升'), '成长');
    });
  });

  group('边界', () {
    test('无法归类落到「其他」', () {
      expect(normalizeCategory('完全不知道的分类'), '其他');
    });

    test('null 与空串返回 null，区别于「无法归类」', () {
      expect(normalizeCategory(null), isNull);
      expect(normalizeCategory(''), isNull);
      expect(normalizeCategory('   '), isNull);
    });

    test('归一化结果必在受控词表内', () {
      for (final raw in categoryAliases.keys) {
        expect(defaultCategories, contains(normalizeCategory(raw)));
      }
    });
  });
}
