import 'package:flutter/material.dart';

/// 阅读报告的风格预设。
///
/// 背景：报告正文完全由大模型生成，而**同一个人的数据可以有完全不同
/// 的读法**——有人想看冷静的数字罗列，有人需要被肯定，有人就想要
/// 不留情面的实话。把风格做成用户可选项，比替他决定一种语气更合适。
///
/// 每个预设只描述两部分：
///  - [persona]：系统提示词，定义模型的角色与基本立场；
///  - [instruction]：附加到用户提示词末尾的写作要求。
///
/// 结构化要求（Markdown 标题、书名《》等）**不属于风格**，它们由
/// [kReportFormatRules] 统一附加——否则「简洁」风格一改就可能把
/// 渲染器依赖的标记改没了，页面排版直接散架。
@immutable
class ReportStyle {
  /// 持久化标识，发布后不可改。
  final String id;

  /// 图标，帮用户在列表里快速认出风格。
  final IconData icon;

  /// 系统提示词（角色设定）。
  final String persona;

  /// 附在用户提示词末尾的额外写作要求。自定义风格时为 null。
  final String? instruction;

  const ReportStyle({
    required this.id,
    required this.icon,
    required this.persona,
    this.instruction,
  });

  /// 是否为「自定义」项（由用户自己写提示词）。
  bool get isCustom => id == 'custom';

  static ReportStyle byId(String? id) {
    for (final s in reportStyles) {
      if (s.id == id) return s;
    }
    return reportStyles.first;
  }
}

/// 所有风格的显示名。与主题同理：不走 ARB，避免在面板里传递 context。
/// 新增风格时在这里补三种语言的文案。
const Map<String, String> reportStyleNames = {
  'rational': '理性罗列 · Plain facts',
  'warm': '温和鼓励 · Warm encouragement',
  'direct': '直率犀利 · Straight talk',
  'concise': '简洁速览 · Brief',
  'custom': '自定义 · Custom',
};

String reportStyleName(String id) => reportStyleNames[id] ?? id;

/// 预设风格列表，顺序即展示顺序。第一个是默认。
const List<ReportStyle> reportStyles = [
  ReportStyle(
    id: 'rational',
    icon: Icons.table_chart_outlined,
    persona: '你是阅读数据分析师。你的职责是把数据讲清楚，不做情绪化的评判，'
        '也不需要鼓励或安慰读者。陈述事实、指出结构，语气克制、专业。',
    instruction: '语气：客观、克制。用数据本身说明问题，'
        '不要使用感叹号，不要写「加油」「继续保持」这类鼓励语，'
        '也不要对读者的选择做价值判断。',
  ),
  ReportStyle(
    id: 'warm',
    icon: Icons.favorite_outline,
    persona: '你是读者身边一位懂书的朋友。你关心他读了什么、读得累不累，'
        '会真诚地肯定他的坚持，也会温和地提醒需要休息或调整的地方。'
        '你的语气亲切、有温度，但不空洞、不奉承。',
    instruction: '语气：温和、鼓励。先肯定读者真实的努力（要有数据支撑，'
        '不要空泛地说「你真棒」），再委婉地提出建议。'
        '建议要让人看完觉得被支持，而不是被指责。',
  ),
  ReportStyle(
    id: 'direct',
    icon: Icons.bolt_outlined,
    persona: '你是直言不讳的阅读教练。你不粉饰、不打太极，'
        '看到问题就直接说出来——弃读率高就说弃读率高，'
        '读得太碎就说读得太碎。你的尖锐是为了让读者真的改变，'
        '而不是为了显得聪明。',
    instruction: '语气：直接、犀利。开头就说最关键的问题，不要铺垫。'
        '允许批评，但每一条批评都必须有数据依据，'
        '并且给出明确的改进方向——指出问题不等于让人难堪。',
  ),
  ReportStyle(
    id: 'concise',
    icon: Icons.short_text,
    persona: '你是极简主义的数据播报员。你的信条是「能一句话说清就不写两句」，'
        '只讲结论和最关键的数字。',
    instruction: '语气：极简。全文控制在 300 字以内。'
        '每个部分只保留 1~2 个最关键的结论，用短句，不要展开论述。'
        '宁可不完整，也不要啰嗦。',
  ),
  ReportStyle(
    id: 'custom',
    icon: Icons.edit_outlined,
    // 用户自己写时，角色由他的提示词决定，这里给一个中性兜底
    persona: '你是阅读数据分析师，按用户给出的要求撰写阅读报告。',
  ),
];

/// 报告的结构化格式要求。
///
/// **必须逐字保留**：`markdown_view.dart` 依赖这些标记来排版——
/// 二级标题决定分节、`《》` 决定书名高亮、`-` 决定列表样式。
/// 风格可以换语气，但换不掉结构。
const String kReportFormatRules = '''
格式要求（严格遵守，报告会在 App 里按 Markdown 排版呈现）：
- 各部分的标题都用二级标题开头（例如「## 概览」），标题里不要带编号。
- 关键数字一律加粗，例如「共读完 **12 本**」「日均 **37 分钟**」。
- 并列要点用 - 开头的无序列表；给读者的行动建议用 1. 2. 3. 有序列表。
- 所有书名一律用《》包裹，例如《置身事内》。
- 不要写 HTML 标签，不要使用四级及更深的标题。''';

/// 内容边界。**与风格无关**，所有风格都必须遵守——
/// 这些是用户明确反馈过的「越界」内容，不能因为换了种语气就放出来。
const String kReportContentBoundary = '''
内容边界（任何风格都必须遵守）：
建议只围绕阅读本身（读什么、怎么读、读后如何记录）。
不要评论书籍的来源或获取渠道，不要催促写书评、分享或打卡，
不要做阅读之外的评判。''';

/// 阅读计划的分析要求。**同样与风格无关**。
///
/// 只有当数据里带了 `readingPlans` 时才会被附加——用户没设计划时，
/// 这段提示词只会变成一段无内容的空要求，纯粹浪费 token。
///
/// 底线：计划是用户自己定的，**没完成不等于失败**。模型可以指出
/// 差距与规律（比如「每周三都断档」），但不许把未达成写成道德问题。
const String kReportPlanRules = '''
关于阅读计划：数据里的 readingPlans 是读者自己设下的目标及其完成情况。
- 逐项说明每个计划的达成情况，用具体数字（目标 vs 实际）。
- 已经达成的要给到明确的肯定；未达成的，分析**规律**而不是下判断
  （例如「连续三周的周三都没读」比「你不够自律」有用得多）。
- 不要因为没完成计划就贬低读者，也不要把计划失败拔高成人生问题。
- 如果没有任何计划，就完全不提这一节。''';
