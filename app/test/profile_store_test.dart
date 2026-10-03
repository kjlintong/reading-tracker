import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/profile_store.dart';

void main() {
  group('主标签编解码', () {
    test('未改过 = null（回落到规则推导）', () {
      expect(decodeMainTags(null), isNull);
      expect(decodeMainTags(''), isNull);
      expect(decodeMainTags('   '), isNull);
    });

    test('往返一致', () {
      final tags = [
        const ProfileTagItem(text: '博古通今', reason: '历史 12 本', source: 'rule'),
        const ProfileTagItem(text: '自己写的', source: 'edited'),
      ];
      final back = decodeMainTags(encodeMainTags(tags));
      expect(back, isNotNull);
      expect(back!.length, 2);
      expect(back.first.text, '博古通今');
      expect(back.first.reason, '历史 12 本');
      expect(back.last.source, 'edited');
    });

    test('空列表是被尊重的，不能和「没改过」混为一谈', () {
      // 用户把所有标签删光了，再进页面不该自动长回来
      final back = decodeMainTags(encodeMainTags(const []));
      expect(back, isNotNull);
      expect(back, isEmpty);
    });

    test('损坏的 JSON 返回 null 而不是抛异常', () {
      expect(decodeMainTags('{不是 json'), isNull);
      expect(decodeMainTags('123'), isNull);
    });

    test('老格式（裸字符串数组）也能读', () {
      final back = decodeMainTags('["专注深耕","电子书党"]');
      expect(back!.map((t) => t.text).toList(), ['专注深耕', '电子书党']);
      expect(back.first.source, 'rule');
    });

    test('空文本的条目被丢掉', () {
      final back = decodeMainTags('[{"text":"  "},{"text":"有效"}]');
      expect(back!.length, 1);
      expect(back.single.text, '有效');
    });

    test('withText 标记为已编辑', () {
      final t = const ProfileTagItem(text: 'a', reason: 'r');
      final e = t.withText('b');
      expect(e.text, 'b');
      expect(e.reason, 'r');
      expect(e.source, 'edited');
    });
  });

  group('AI 历史', () {
    AiTagSet setOf(String tag, DateTime at) =>
        AiTagSet(tags: [tag], at: at);

    test('新的在前，最多保留 3 组', () {
      var h = <AiTagSet>[];
      for (var i = 1; i <= 5; i++) {
        h = appendAiHistory(h, setOf('第$i组', DateTime(2026, 1, i)));
      }
      expect(h.length, 3);
      expect(h.first.tags.single, '第5组');
      expect(h.last.tags.single, '第3组');
    });

    test('坏数据当没有历史', () {
      expect(decodeAiHistory(null), isEmpty);
      expect(decodeAiHistory('不是 json'), isEmpty);
      expect(decodeAiHistory('{"a":1}'), isEmpty);
    });

    test('往返一致且按时间倒序', () {
      final raw = jsonEncodeSafe([
        setOf('老的', DateTime(2026, 1, 1)),
        setOf('新的', DateTime(2026, 3, 1)),
      ]);
      final back = decodeAiHistory(raw);
      expect(back.length, 2);
      expect(back.first.tags.single, '新的');
    });

    test('空标签组不进历史', () {
      final h = appendAiHistory(const [], AiTagSet(tags: const [], at: DateTime(2026)));
      // 写入时还没过滤，但读回来会被丢掉——保证界面不会渲染出空白组
      expect(decodeAiHistory(jsonEncodeSafe(h)), isEmpty);
    });
  });
}

String jsonEncodeSafe(List<AiTagSet> sets) =>
    '[${sets.map((s) => '{"tags":${_q(s.tags)},"at":"${s.at.toIso8601String()}"}').join(',')}]';

String _q(List<String> tags) =>
    '[${tags.map((t) => '"$t"').join(',')}]';
