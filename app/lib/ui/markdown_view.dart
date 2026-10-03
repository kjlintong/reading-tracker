import 'package:flutter/material.dart';

/// 极简 Markdown 渲染器 —— 专为 AI 生成的阅读报告设计。
///
/// ## 为什么自己写，而不是引 `flutter_markdown`
///
/// 1. **报告的语法面很窄。** LLM 稳定输出的无非是标题、加粗、列表、
///    偶尔一个表格。为此拉一个依赖 + 一套默认样式，再逐个覆盖到贴合
///    本 App 的排版，成本比写这两百行高得多。
/// 2. **默认样式不是我们想要的。** markdown 包的 blockquote 是一条灰条、
///    表格没有圆角、代码块没有色底，全部要改。改完之后「用依赖」这件事
///    剩下的收益只剩解析器，而解析器正是最容易写对的部分。
/// 3. **能加属于这个产品的语义。** 中文报告里的书名写在《》里，
///    这是英语世界没有的记号。自己的解析器可以在排版时把书名单独着色，
///    一份报告扫一眼就知道点了哪几本书——这才是「你的报告」该有的样子。
///
/// ## 设计原则
///
/// - **永不显示原始语法符号。** 解析失败就地降级为普通文字，
///   但绝不会把 `**` 印到屏幕上——那是「粗糙」最主要的来源。
/// - **不依赖 colorScheme 以外的东西。** 深浅两套主题由 ColorScheme 驱动，
///   没有一处硬编码颜色。
/// - **整体可长按选中。** 内部一律走 [Text.rich]，
///   外层 [SelectionArea] 就能把整篇报告选中复制。
class MarkdownView extends StatelessWidget {
  const MarkdownView(this.data, {super.key});

  /// Markdown 原文。
  final String data;

  @override
  Widget build(BuildContext context) {
    final blocks = parseMarkdown(data);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final style = _Style.of(context);
    final children = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final gap = i == 0 ? 0.0 : _gapBefore(blocks[i - 1], b);
      Widget child;
      if (b is MdHeading) {
        child = _MdHeadingView(b, style);
      } else if (b is MdList) {
        child = _MdListView(b, style);
      } else if (b is MdQuote) {
        child = _MdQuoteView(b, style);
      } else if (b is MdCode) {
        child = _MdCodeView(b, style);
      } else if (b is MdTable) {
        child = _MdTableView(b, style);
      } else if (b is MdRule) {
        child = Divider(height: 24, thickness: 1, color: style.rule);
      } else {
        child = _Rich(text: (b as MdParagraph).text, style: style.body);
      }
      children.add(Padding(
        padding: EdgeInsets.only(top: gap),
        child: child,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// 块间距：标题前面留白要多一点，形成「分页」的层次感；
  /// 列表项之间几乎不留，保持一条流的连贯。
  static double _gapBefore(MdBlock prev, MdBlock cur) {
    if (cur is MdHeading) return cur.level <= 2 ? 18 : 12;
    if (prev is MdHeading) return 6;
    if (cur is MdList) return 8;
    if (cur is MdRule) return 8;
    if (cur is MdTable) return 10;
    if (cur is MdQuote) return 10;
    if (cur is MdCode) return 10;
    if (prev is MdList || prev is MdTable || prev is MdQuote || prev is MdCode) {
      return 10;
    }
    return 8; // 段落之间
  }
}

/* ============================ 语法树 ============================ */

/// 所有块类型的根。刻意不用 sealed：`parseMarkdown` 是库外的测试也要调的，
/// 私有类型对测试不友好，所以这里包一层公开类型做输出。
abstract class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  const MdHeading(this.level, this.text);
  final int level;
  final String text;
}

class MdParagraph extends MdBlock {
  const MdParagraph(this.text);
  final String text;
}

class MdList extends MdBlock {
  const MdList(this.ordered, this.items);
  final bool ordered;
  final List<String> items;
}

class MdQuote extends MdBlock {
  const MdQuote(this.text);
  final String text;
}

class MdRule extends MdBlock {
  const MdRule();
}

class MdCode extends MdBlock {
  const MdCode(this.text);
  final String text;
}

class MdTable extends MdBlock {
  const MdTable(this.rows);
  final List<List<String>> rows;
}

/* ============================ 解析器 ============================ */

final RegExp _headingRe = RegExp(r'^(#{1,6})\s+(.*)$');
final RegExp _bulletRe = RegExp(r'^[-*+]\s+(.*)$');
final RegExp _orderedRe = RegExp(r'^(\d+)[.)]\s+(.*)$');
final RegExp _ruleRe = RegExp(r'^(-{3,}|\*{3,}|_{3,})$');
final RegExp _tableDelimRe = RegExp(r'^\|?[\s:|-]+\|[\s:|-]*$');
// 整行加粗且很短 —— LLM 常拿它当三级标题用（「**1. 概览**」），
// 当成标题排版比当成一行加粗文字更像报告。
final RegExp _boldLineRe = RegExp(r'^\*\*(.{1,40}?)\*\*\s*$');

/// 把 Markdown 原文解析成块序列。
///
/// 公开是为了能被单元测试直接验证；渲染层不需要关心它。
List<MdBlock> parseMarkdown(String src) {
  final lines = src.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final out = <MdBlock>[];
  var i = 0;

  while (i < lines.length) {
    final line = lines[i].trim();

    if (line.isEmpty) {
      i++;
      continue;
    }

    // 围栏代码块
    if (line.startsWith('```')) {
      final buf = <String>[];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        buf.add(lines[i]);
        i++;
      }
      i++; // 吃掉收尾的 fence（缺失也无妨，到末尾而已）
      out.add(MdCode(buf.join('\n').trim()));
      continue;
    }

    // 分隔线
    if (_ruleRe.hasMatch(line)) {
      out.add(const MdRule());
      i++;
      continue;
    }

    // 「**小节**」整行加粗 → 三级标题
    final boldLine = _boldLineRe.firstMatch(line);
    if (boldLine != null) {
      out.add(MdHeading(3, _stripHeadingJunk(boldLine.group(1)!.trim())));
      i++;
      continue;
    }

    // 标题
    final h = _headingRe.firstMatch(line);
    if (h != null) {
      final text = _stripHeadingJunk(h.group(2)!.trim());
      if (text.isNotEmpty) {
        out.add(MdHeading(h.group(1)!.length, text));
        i++;
        continue;
      }
    }

    // 引用
    if (line.startsWith('>')) {
      final buf = <String>[];
      while (i < lines.length) {
        final t = lines[i].trim();
        if (!t.startsWith('>')) break;
        buf.add(t.substring(1).trimLeft());
        i++;
      }
      out.add(MdQuote(buf.join('\n')));
      continue;
    }

    // 表格：当前行含 |，且紧随其后是表头分隔行
    if (line.contains('|') &&
        i + 1 < lines.length &&
        _tableDelimRe.hasMatch(lines[i + 1].trim()) &&
        lines[i + 1].contains('-')) {
      final rows = <List<String>>[_splitRow(line)];
      i += 2;
      while (i < lines.length) {
        final t = lines[i].trim();
        if (t.isEmpty || !t.contains('|')) break;
        rows.add(_splitRow(t));
        i++;
      }
      out.add(MdTable(rows));
      continue;
    }

    // 无序列表
    final bullet = _bulletRe.firstMatch(line);
    if (bullet != null) {
      final items = <String>[];
      while (i < lines.length) {
        final m = _bulletRe.firstMatch(lines[i].trim());
        if (m == null) {
          // 续行：缩进两格以上且不是新块，归到上一项
          final t = lines[i].trim();
          if (t.isNotEmpty && items.isNotEmpty && !_startsBlock(t)) {
            items[items.length - 1] += ' ${t.trim()}';
            i++;
            continue;
          }
          break;
        }
        items.add(m.group(1)!.trim());
        i++;
      }
      out.add(MdList(false, items));
      continue;
    }

    // 有序列表
    final ordered = _orderedRe.firstMatch(line);
    if (ordered != null) {
      final items = <String>[];
      while (i < lines.length) {
        final m = _orderedRe.firstMatch(lines[i].trim());
        if (m == null) {
          final t = lines[i].trim();
          if (t.isNotEmpty && items.isNotEmpty && !_startsBlock(t)) {
            items[items.length - 1] += ' ${t.trim()}';
            i++;
            continue;
          }
          break;
        }
        items.add(m.group(2)!.trim());
        i++;
      }
      out.add(MdList(true, items));
      continue;
    }

    // 普通段落：连续的非空、非块起始行合并为一段
    final buf = <String>[];
    while (i < lines.length) {
      final t = lines[i].trim();
      if (t.isEmpty || _startsBlock(t)) break;
      buf.add(t);
      i++;
    }
    out.add(MdParagraph(_joinLines(buf)));
  }

  return out;
}

/// 标题里的编号统一去掉。
///
/// 「## 1. 概览」这种，编号本身由标题样式承担了层级感，
/// 再印一个「1.」是重复信息。
String _stripHeadingJunk(String text) {
  var t = text.trim();
  // 去掉开头的中西文序号：1. / 1、/ （一）
  t = t.replaceFirst(RegExp(r'^\d+\s*[.、)]\s*'), '');
  t = t.replaceFirst(RegExp(r'^[（(][一二三四五六七八九十]+[）)]\s*'), '');
  return t.trim();
}

bool _startsBlock(String t) =>
    _headingRe.hasMatch(t) ||
    _bulletRe.hasMatch(t) ||
    _orderedRe.hasMatch(t) ||
    _ruleRe.hasMatch(t) ||
    _boldLineRe.hasMatch(t) ||
    t.startsWith('>') ||
    t.startsWith('```');

List<String> _splitRow(String line) {
  var t = line.trim();
  if (t.startsWith('|')) t = t.substring(1);
  if (t.endsWith('|') && t.length > 1) t = t.substring(0, t.length - 1);
  return t.split('|').map((e) => e.trim()).toList();
}

/// 合并同一个段落里的多行。
///
/// Markdown 规范是换行当空格，但中文中间插空格会出现
/// 「摘要 摘录」这种裂缝。规则：只有两侧都是拉丁字母/数字时才补空格。
String _joinLines(List<String> lines) {
  if (lines.isEmpty) return '';
  final buf = StringBuffer(lines.first);
  for (var i = 1; i < lines.length; i++) {
    final prev = lines[i - 1];
    final cur = lines[i];
    if (prev.isNotEmpty && cur.isNotEmpty) {
      final p = prev[prev.length - 1];
      final c = cur[0];
      if (_isWordChar(p) && _isWordChar(c)) buf.write(' ');
    }
    buf.write(cur);
  }
  return buf.toString();
}

bool _isWordChar(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 0x30 && u <= 0x39) ||
      (u >= 0x41 && u <= 0x5A) ||
      (u >= 0x61 && u <= 0x7A);
}

/* ============================ 样式 ============================ */

/// 一套随主题变化的排版参数。
///
/// 集中定义是为了让「报告看起来是什么样」这件事只有一处口径——
/// 散在各个分支里改字号，第二次改动一定会出现某个标题比对不齐。
class _Style {
  _Style._(this.cs) {
    body = const TextStyle(fontSize: 14, height: 1.75);
    h1 = const TextStyle(fontSize: 19, height: 1.45, fontWeight: FontWeight.w700);
    h2 = const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w700);
    h3 = const TextStyle(fontSize: 14.5, height: 1.55, fontWeight: FontWeight.w600);
    bold = const TextStyle(fontWeight: FontWeight.w700);
    italic = const TextStyle(fontStyle: FontStyle.italic);
    title = TextStyle(
        color: cs.primary, fontWeight: FontWeight.w600, fontSize: 14);
    code = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.5,
      color: cs.onSurfaceVariant,
      backgroundColor: cs.surfaceContainerHighest.withOpacity(0.6),
    );
    quote = TextStyle(
        fontSize: 13.5, height: 1.7, fontStyle: FontStyle.italic,
        color: cs.onSurfaceVariant);
    rule = cs.outlineVariant;
    accentBar = cs.primary;
    bullet = cs.outline;
    tableBorder = cs.outlineVariant;
    tableHead = cs.surfaceContainerHighest.withOpacity(0.55);
    codeBlockBg = cs.surfaceContainerHighest.withOpacity(0.45);
    numberBg = cs.primaryContainer;
    numberFg = cs.onPrimaryContainer;
  }

  final ColorScheme cs;

  late final TextStyle body;
  late final TextStyle h1;
  late final TextStyle h2;
  late final TextStyle h3;
  late final TextStyle bold;
  late final TextStyle italic;
  late final TextStyle title;
  late final TextStyle code;
  late final TextStyle quote;
  late final Color rule;
  late final Color accentBar;
  late final Color bullet;
  late final Color tableBorder;
  late final Color tableHead;
  late final Color codeBlockBg;
  late final Color numberBg;
  late final Color numberFg;

  static _Style of(BuildContext context) =>
      _Style._(Theme.of(context).colorScheme);
}

/* ============================ 行内渲染 ============================ */

/// 富文本片段。整篇报告的选中复制依赖 [Text.rich]，
/// 所以行内样式一律落成 TextSpan，而不是改用 WidgetSpan。
TextSpan _inline(String text, TextStyle base, _Style s, {int depth = 0}) {
  final children = <InlineSpan>[];
  final buf = StringBuffer();

  void flush() {
    if (buf.isNotEmpty) {
      children.add(TextSpan(text: buf.toString()));
      buf.clear();
    }
  }

  var i = 0;
  while (i < text.length) {
    final c = text[i];

    // 行内代码：`xxx`
    if (c == '`') {
      final end = text.indexOf('`', i + 1);
      if (end > i + 1) {
        flush();
        children.add(TextSpan(text: text.substring(i + 1, end), style: s.code));
        i = end + 1;
        continue;
      }
    }

    // 书名号：《置身事内》—— 中文报告里点名书目的记号，单独着色。
    if (c == '《') {
      final end = text.indexOf('》', i + 1);
      if (end > i + 1) {
        flush();
        children.add(TextSpan(text: text.substring(i, end + 1), style: s.title));
        i = end + 1;
        continue;
      }
    }

    // 强调：**粗体** / __粗体__ / *斜体* / _斜体_
    if (c == '*' || c == '_') {
      final isDouble = i + 1 < text.length && text[i + 1] == c;
      final mark = isDouble ? c * 2 : c;
      final end = text.indexOf(mark, i + mark.length);
      if (end > i + mark.length) {
        final inner = text.substring(i + mark.length, end);
        flush();
        children.add(TextSpan(
          style: isDouble ? s.bold : s.italic,
          children: <InlineSpan>[
            if (depth < 3)
              _inline(inner, base, s, depth: depth + 1)
            else
              TextSpan(text: inner),
          ],
        ));
        i = end + mark.length;
        continue;
      }
    }

    buf.write(c);
    i++;
  }
  flush();

  return TextSpan(style: base, children: children);
}

class _Rich extends StatelessWidget {
  const _Rich({required this.text, required this.style, this.spansStyle});

  final String text;
  final TextStyle style;
  final _Style? spansStyle;

  @override
  Widget build(BuildContext context) {
    final s = spansStyle ?? _Style.of(context);
    return Text.rich(_inline(text, style, s), style: style);
  }
}

/* ============================ 块渲染 ============================ */

class _MdHeadingView extends StatelessWidget {
  const _MdHeadingView(this.block, this.style);
  final MdHeading block;
  final _Style style;

  @override
  Widget build(BuildContext context) {
    final base = switch (block.level) {
      1 => style.h1,
      2 => style.h2,
      _ => style.h3,
    };

    // 一级标题被调用方当作报告主标题（见报告页的日期行），
    // 二级是板块标题：左侧一条主题色竖条，把「这是新一节」标示出来。
    if (block.level == 1) {
      return _Rich(text: block.text, style: base, spansStyle: style);
    }

    if (block.level == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 17,
            decoration: BoxDecoration(
              color: style.accentBar,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _Rich(text: block.text, style: base, spansStyle: style)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: _Rich(
        text: block.text,
        style: base.copyWith(color: style.cs.primary),
        spansStyle: style,
      ),
    );
  }
}

class _MdListView extends StatelessWidget {
  const _MdListView(this.block, this.style);
  final MdList block;
  final _Style style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < block.items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == block.items.length - 1 ? 0 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.ordered)
                  Container(
                    width: 21,
                    height: 21,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: style.numberBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: style.numberFg,
                      ),
                    ),
                  )
                else
                  Padding(
                    // 垂直对齐到第一行文字的中线：行高 14×1.75≈24.5，
                    // 中线约 12，圆点 5px，于是 top≈9.5。
                    padding: const EdgeInsets.only(top: 9, left: 7, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: style.bullet,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Expanded(
                  child: _Rich(
                    text: block.items[i],
                    style: style.body,
                    spansStyle: style,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MdQuoteView extends StatelessWidget {
  const _MdQuoteView(this.block, this.style);
  final MdQuote block;
  final _Style style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: style.accentBar.withOpacity(0.55), width: 3),
        ),
      ),
      child: _Rich(text: block.text, style: style.quote, spansStyle: style),
    );
  }
}

class _MdCodeView extends StatelessWidget {
  const _MdCodeView(this.block, this.style);
  final MdCode block;
  final _Style style;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: style.codeBlockBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        block.text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          height: 1.55,
          color: style.cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MdTableView extends StatelessWidget {
  const _MdTableView(this.block, this.style);
  final MdTable block;
  final _Style style;

  @override
  Widget build(BuildContext context) {
    final cols =
        block.rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    final clip = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        border: TableBorder.all(
          color: style.tableBorder,
          width: 1,
          borderRadius: BorderRadius.circular(8),
        ),
        columnWidths: <int, TableColumnWidth>{
          for (var c = 0; c < cols; c++) c: const FlexColumnWidth(),
        },
        children: [
          for (var r = 0; r < block.rows.length; r++)
            TableRow(
              decoration: r == 0
                  ? BoxDecoration(color: style.tableHead)
                  : null,
              children: [
                for (var c = 0; c < cols; c++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 7),
                    child: Text.rich(
                      _inline(
                        c < block.rows[r].length ? block.rows[r][c] : '',
                        TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          fontWeight:
                              r == 0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                        style,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );

    // 列多了等宽会挤成一团，改为按内容宽度并允许横向滚动。
    if (cols > 4) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(child: clip),
      );
    }
    return clip;
  }
}
