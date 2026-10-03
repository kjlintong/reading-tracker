import 'dart:convert';

/// 阅读画像页的标签持久化。
///
/// 规则推导的标签每次都从藏书重算，**用户的修改必须落在数据之外**——
/// 否则删掉一个标签，下一次重算它又回来了，删了等于没删。
///
/// 两个 KV 键（存 settings 表）：
///   - `profile_tags_main`：用户管理的主标签列表。**为 null 表示没有
///     改过**，界面展示规则推导结果；一旦用户删除/编辑/替换过，
///     就落一份完整列表，此后以它为准。
///   - `profile_tags_ai_history`：AI 生成的历史，最多 3 组，新的进来
///     旧的挤出去。用户明确要求「保留最近三次生成的结果」。
///
/// 编解码做成纯函数：这层唯一的复杂度是「旧数据格式不对时不能崩」，
/// 必须能在单测里钉住。
class ProfileTagItem {
  final String text;
  final String? reason;

  /// `rule` 从规则推导复制而来 / `ai` 来自模型 / `edited` 用户改过。
  final String source;

  const ProfileTagItem({
    required this.text,
    this.reason,
    this.source = 'rule',
  });

  ProfileTagItem withText(String t) => ProfileTagItem(
        text: t,
        reason: reason,
        source: 'edited',
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        if (reason != null) 'reason': reason,
        'source': source,
      };

  factory ProfileTagItem.fromJson(dynamic j) => ProfileTagItem(
        text: (j is Map ? j['text'] : j)?.toString() ?? '',
        reason: j is Map ? j['reason']?.toString() : null,
        source: j is Map ? (j['source']?.toString() ?? 'rule') : 'rule',
      );
}

/// 一组 AI 生成的结果 + 生成时间。
class AiTagSet {
  final List<String> tags;
  final DateTime at;

  const AiTagSet({required this.tags, required this.at});

  Map<String, dynamic> toJson() => {
        'tags': tags,
        'at': at.toIso8601String(),
      };

  factory AiTagSet.fromJson(dynamic j) {
    if (j is! Map) return AiTagSet(tags: const [], at: DateTime.now());
    final at = DateTime.tryParse('${j['at']}') ?? DateTime.now();
    return AiTagSet(
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      at: at,
    );
  }
}

const profileMainTagsKey = 'profile_tags_main';
const profileAiHistoryKey = 'profile_tags_ai_history';
const profileAiHistoryLimit = 3;

/// 主标签列表解码。解析不了就返回 null（= 回落到规则推导），
/// 绝不能因为一份损坏的 KV 让画像页打不开。
List<ProfileTagItem>? decodeMainTags(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final v = jsonDecode(raw);
    if (v is! List) return null;
    final out = v
        .map(ProfileTagItem.fromJson)
        .where((t) => t.text.trim().isNotEmpty)
        .toList();
    return out;
  } catch (_) {
    return null;
  }
}

String encodeMainTags(List<ProfileTagItem> tags) =>
    jsonEncode([for (final t in tags) t.toJson()]);

/// AI 历史解码。坏数据当没有历史处理。
List<AiTagSet> decodeAiHistory(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final v = jsonDecode(raw);
    if (v is! List) return const [];
    final out = v
        .map(AiTagSet.fromJson)
        .where((s) => s.tags.isNotEmpty)
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return out;
  } catch (_) {
    return const [];
  }
}

/// 追加一组生成结果并裁到最近 N 组。
List<AiTagSet> appendAiHistory(List<AiTagSet> current, AiTagSet next) =>
    [next, ...current].take(profileAiHistoryLimit).toList();
