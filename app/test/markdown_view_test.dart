import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/ui/markdown_view.dart';

/// 一段贴近真实 LLM 输出的报告样本。
///
/// 刻意混进所有已知写法：带编号的二级标题、整行加粗的小标题、
/// 无序/有序列表、表格、引用、书名号、行内代码。
const _sample = '''
# 2026 年 9 月阅读报告

## 1. 概览

本月读完 **4 本**，累计 **18 小时 20 分钟**，日均 **37 分钟**。

## 2. 结构分析

- 社科占 **50%**，文学占 **25%**
- 来源集中在单一平台

**本周关键变化**

《置身事内》读到第 3 章停了。

## 3. 习惯洞察

| 维度 | 数值 |
| --- | --- |
| 连续天数 | 12 天 |
| 弃读率 | 22% |

> 数据是安静的，但它会说实话。

## 4. 建议

1. 把《置身事内》捡起来读完第 3 章
2. 翻翻《焦虑的人》的划线，把最触动的一句补进笔记
3. 下月给大部头配一本更轻的书

---

写在最后：本月共涉及 6 本，评分区间 3.5 到 5.0。
''';

/// 收集页面里所有可见文字（Text 与 RichText 都算）。
String _allText(WidgetTester tester) {
  final buf = StringBuffer();
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    buf.writeln(t.data ?? '');
  }
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    buf.writeln(rt.text.toPlainText());
  }
  return buf.toString();
}

bool _hasColoredSpan(WidgetTester tester, String text, Color color) {
  for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
    var hit = false;
    rt.text.visitChildren((span) {
      if (span is TextSpan && span.text == text && span.style?.color == color) {
        hit = true;
      }
      return true;
    });
    if (hit) return true;
  }
  return false;
}

Future<void> _render(WidgetTester tester, String md) async {
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 390,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownView(md),
          ),
        ),
      ),
    ),
  ));
}

void main() {
  group('解析器', () {
    test('编号型二级标题会去掉序号', () {
      final blocks = parseMarkdown('## 1. 概览\n\n正文');
      expect(blocks.first, isA<MdHeading>());
      final h = blocks.first as MdHeading;
      expect(h.level, 2);
      expect(h.text, '概览');
    });

    test('整行加粗当作三级标题', () {
      final blocks = parseMarkdown('**本周关键变化**');
      expect(blocks.single, isA<MdHeading>());
      expect((blocks.single as MdHeading).level, 3);
      expect((blocks.single as MdHeading).text, '本周关键变化');
    });

    test('无序与有序列表分别成块', () {
      final blocks = parseMarkdown('- 甲\n- 乙\n\n1. 一\n2. 二');
      expect(blocks, hasLength(2));
      final bullet = blocks[0] as MdList;
      final ordered = blocks[1] as MdList;
      expect(bullet.ordered, isFalse);
      expect(bullet.items, ['甲', '乙']);
      expect(ordered.ordered, isTrue);
      expect(ordered.items, ['一', '二']);
    });

    test('表格抽出表头与数据行', () {
      final blocks = parseMarkdown('| 维度 | 数值 |\n| --- | --- |\n| 天数 | 12 |');
      final table = blocks.single as MdTable;
      expect(table.rows, [
        ['维度', '数值'],
        ['天数', '12'],
      ]);
    });

    test('围栏代码块原样保留内容本身', () {
      final blocks = parseMarkdown('```dart\nfinal a = 1;\n```');
      final code = blocks.single as MdCode;
      expect(code.text, 'final a = 1;');
    });

    test('段落软换行：拉丁补空格，中文不补', () {
      expect(parseMarkdown('hello\nworld').single, isA<MdParagraph>());
      expect((parseMarkdown('hello\nworld').single as MdParagraph).text,
          'hello world');
      expect((parseMarkdown('中文换行\n不插空格').single as MdParagraph).text,
          '中文换行不插空格');
    });

    test('空输入给出空块列表，不会崩', () {
      expect(parseMarkdown(''), isEmpty);
      expect(parseMarkdown('   \n\n  \n'), isEmpty);
    });
  });

  group('渲染', () {
    testWidgets('语法符号不会泄漏到屏幕上', (tester) async {
      await _render(tester, _sample);

      final text = _allText(tester);
      expect(text, isNot(contains('**')));
      expect(text, isNot(contains('##')));
      expect(text, isNot(contains('|')));
      expect(text, isNot(contains('---')));
    });

    testWidgets('六个板块标题与正文都在图面上', (tester) async {
      await _render(tester, _sample);

      final text = _allText(tester);
      for (final section in ['概览', '结构分析', '习惯洞察', '建议']) {
        expect(text, contains(section), reason: '缺少板块：$section');
      }
      expect(text, contains('4 本'));
      expect(text, contains('18 小时 20 分钟'));
    });

    testWidgets('有序列表给出 1/2/3 编号徽章', (tester) async {
      await _render(tester, _sample);

      for (final n in ['1', '2', '3']) {
        expect(find.text(n), findsWidgets, reason: '缺少有序编号 $n');
      }
    });

    testWidgets('《》里的书名被着色高亮', (tester) async {
      await _render(tester, _sample);

      final primary = ThemeData(useMaterial3: true).colorScheme.primary;
      expect(_hasColoredSpan(tester, '《置身事内》', primary), isTrue);
    });

    testWidgets('表格渲染成 Table，单元格不漏竖线', (tester) async {
      await _render(tester, '| 维度 | 数值 |\n| --- | --- |\n| 天数 | 12 |');

      expect(find.byType(Table), findsOneWidget);
      final text = _allText(tester);
      expect(text, contains('维度'));
      expect(text, contains('12'));
      expect(text, isNot(contains('|')));
      expect(text, isNot(contains('---')));
    });

    testWidgets('空报告不抛异常', (tester) async {
      await _render(tester, '');
      expect(tester.takeException(), isNull);
    });

    testWidgets('残缺语法退化为普通文字，而不是丢内容', (tester) async {
      // 只有开头没有结尾的加粗符号 —— 必须原样显示，不能吞掉后面的字。
      await _render(tester, '本月 **没有闭合的加粗记号');

      expect(_allText(tester), contains('没有闭合的加粗记号'));
      expect(tester.takeException(), isNull);
    });
  });
}
