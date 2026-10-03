import 'dart:convert';

/// 备份 / 恢复的数据编排。
///
/// 全部走整库 JSON 快照：表结构里 `extra`、`tags`、`authors` 这些列
/// 本身存的就是 JSON 串，逐字段做结构化转换只会引入「哪个字段忘了
/// 编解码」这类低级错误。快照里直接放原始行（`row` 原样），恢复时
/// 原样写回—— schema 由 App 自带的建表逻辑保证，快照不背这个责任。
///
/// 所以这份文件里几乎没有逻辑，**但格式校验必须在这里做**：
/// 恢复是把外部文件写进本地库的唯一入口，来路不明的 JSON 不能直接灌。
class BackupCodec {
  static const formatId = 'reading-tracker-backup';
  static const formatVersion = 1;

  /// 恢复时允许写回的表。白名单而不是黑名单：
  /// 将来加新表忘了登记，只会「恢复得少了点」而不是「写进了任意表」。
  static const tables = [
    'books',
    'reading_logs',
    'notes',
    'llm_reports',
    'settings',
  ];

  static Map<String, dynamic> build({
    required Map<String, List<Map<String, dynamic>>> data,
    required DateTime now,
  }) =>
      {
        'format': formatId,
        'formatVersion': formatVersion,
        'exportedAt': now.toIso8601String(),
        'counts': {for (final e in data.entries) e.key: e.value.length},
        'data': data,
      };

  /// 解析并校验备份文件。返回 null 表示格式不认；
  /// 挑得动的表照常返回——部分恢复好过全部拒绝。
  static ({Map<String, List<Map<String, dynamic>>> data, String? exportedAt})?
      parse(String raw) {
    Object? v;
    try {
      v = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (v is! Map) return null;
    if (v['format'] != formatId) return null;

    final version = (v['formatVersion'] as num?)?.toInt() ?? 0;
    if (version > formatVersion) return null; // 新版本格式，本 App 不认识

    final data = v['data'];
    if (data is! Map) return null;

    final out = <String, List<Map<String, dynamic>>>{};
    for (final t in tables) {
      final rows = data[t];
      if (rows is! List) continue;
      out[t] = [
        for (final r in rows)
          if (r is Map) Map<String, dynamic>.from(r),
      ];
    }
    return (
      data: out,
      exportedAt: v['exportedAt']?.toString(),
    );
  }
}
