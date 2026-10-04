import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 阅读报告的风格预设。
///
/// 背景：报告正文由大模型撰写，而**同一份数据可以有完全不同的读法**——
/// 有人想看冷静的数字罗列，有人需要被肯定，有人就想要不留情面的实话。
/// 把风格做成用户可选项，比替他决定一种语气更合适。
///
/// 每个预设只描述两部分：
///  - [persona]：系统提示词，定义模型的角色与基本立场；
///  - [instruction]：附加到用户提示词末尾的写作要求。
///
/// ⚠️ 这里的文案**刻意写英文且不走 ARB**：它们是给模型看的指令，不是给
/// 用户看的界面。模型对英文指令的遵循度明显高于中文；而且 App 支持 5 种
/// 界面语言，若把 persona 本地化，每加一种语言就要多译 8 段提示词，
/// 翻译质量还会直接决定语气强度。输出语言由提示词末尾的 `LANGUAGE:` 段
/// 单独锁定——英文 persona + "write in Deutsch" 出来的就是德语报告。
///
/// 结构（JSON 字段、书名《》、分节）**不属于风格**，由 `report_pipeline.dart`
/// 的 `buildInsightsPrompt` 与 `renderReport` 固定：风格能换语气，换不掉结构。
/// 内容边界（不评来源渠道、不催分享打卡）同理，写死在提示词的 RULES 段，
/// 任何风格都绕不过去。
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

/// 预设风格列表，顺序即展示顺序。第一个是默认。
///
/// 展示名与描述都在 ARB 里（`reportStyleRational` / `reportStyleRationalDesc`
/// 等）——界面上的文字必须跟随界面语言，和给模型看的 [persona] 是两回事。
const List<ReportStyle> reportStyles = [
  ReportStyle(
    id: 'rational',
    icon: Icons.table_chart_outlined,
    persona: 'You are a reading-data analyst. Your job is to make the numbers '
        'legible. No emotion, no praise, no consolation. State facts, point at '
        'structure, and keep the tone measured.',
    instruction: 'TONE: detached and factual. Let the data carry the point. '
        'No exclamation marks. No encouragement ("keep going", "well done"). '
        'Never judge what the reader chose to read.',
  ),
  ReportStyle(
    id: 'warm',
    icon: Icons.favorite_outline,
    persona: 'You are a friend who knows this reader\'s books. You care about '
        'what they read and whether it wore them out. You acknowledge real '
        'effort and raise problems gently. Warm, but never flattery.',
    instruction: 'TONE: warm and encouraging. Name a real effort first — and '
        'back it with a number, never a vague "you are doing great" — then '
        'make the suggestion. The reader should finish feeling supported, '
        'not scolded.',
  ),
  ReportStyle(
    id: 'direct',
    icon: Icons.bolt_outlined,
    persona: 'You are a blunt reading coach. You do not soften or hedge: if '
        'the abandonment rate is high you say so, if reading is scattered you '
        'say so. Your sharpness exists to make the reader actually change, '
        'not to make you sound clever.',
    instruction: 'TONE: direct. Open with the single biggest problem, no '
        'warm-up. Criticism is allowed, but every criticism must cite a number '
        'and must end with a concrete way out — naming a problem is not the '
        'same as making the reader feel bad.',
  ),
  ReportStyle(
    id: 'concise',
    icon: Icons.short_text,
    persona: 'You are a minimalist data announcer. Your rule: if one sentence '
        'says it, never write two. Conclusions and the key number only.',
    instruction: 'TONE: minimal. At most ONE item per section. Every sentence '
        'under 25 words. Keep "profile" and "rhythm" to a single sentence. '
        'Better to leave something out than to elaborate.',
  ),
  ReportStyle(
    id: 'custom',
    icon: Icons.edit_outlined,
    // 用户自己写时，角色由他的提示词决定，这里给一个中性兜底
    persona: 'You are a reading-data analyst. Follow the reader\'s own '
        'instructions for how the report should read.',
  ),
];

/// 风格显示名（跟随界面语言）。
///
/// 之前这里是一张 `'rational': '理性罗列 · Plain facts'` 的硬编码表，界面
/// 只用 `.split(' · ').first` 取中文那段——英文界面下照样显示「理性罗列」。
/// 名字本来就在 ARB 里（设置页的描述用的就是 ARB），没有理由再留一份。
String reportStyleName(String id, S l10n) => switch (id) {
      'warm' => l10n.reportStyleWarm,
      'direct' => l10n.reportStyleDirect,
      'concise' => l10n.reportStyleConcise,
      'custom' => l10n.reportStyleCustom,
      _ => l10n.reportStyleRational,
    };
