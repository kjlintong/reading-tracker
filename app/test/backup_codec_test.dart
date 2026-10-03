import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/backup.dart';

void main() {
  Map<String, List<Map<String, dynamic>>> sample() => {
        'books': [
          {'id': 'a', 'title': '置身事内'},
          {'id': 'b', 'title': '万历十五年'},
        ],
        'notes': [
          {'id': 'n1', 'bookId': 'a', 'content': '摘抄'},
        ],
        'reading_logs': const [],
        'llm_reports': const [],
        'settings': [
          {'key': 'llm_model', 'value': 'x'},
        ],
      };

  group('构建', () {
    test('带格式标识、版本与计数', () {
      final payload = BackupCodec.build(
        data: sample(),
        now: DateTime(2026, 9, 30),
      );
      expect(payload['format'], BackupCodec.formatId);
      expect(payload['formatVersion'], BackupCodec.formatVersion);
      expect((payload['counts'] as Map)['books'], 2);
      expect((payload['counts'] as Map)['notes'], 1);
    });
  });

  group('解析与校验', () {
    test('往返无损', () {
      final payload = BackupCodec.build(data: sample(), now: DateTime(2026));
      final parsed = BackupCodec.parse(jsonEncode(payload));
      expect(parsed, isNotNull);
      expect(parsed!.data['books']!.length, 2);
      expect(parsed.data['books']!.first['title'], '置身事内');
      expect(parsed.exportedAt, isNotNull);
    });

    test('不是本 App 的文件直接拒收', () {
      expect(BackupCodec.parse('{"a":1}'), isNull);
      expect(BackupCodec.parse('不是 json'), isNull);
      expect(BackupCodec.parse('[]'), isNull);
    });

    test('更高版本不认——宁可拒收也不要写坏数据', () {
      final payload = {
        'format': BackupCodec.formatId,
        'formatVersion': BackupCodec.formatVersion + 1,
        'data': {},
      };
      expect(BackupCodec.parse(jsonEncode(payload)), isNull);
    });

    test('缺表只丢那一张，其余照常恢复', () {
      final payload = {
        'format': BackupCodec.formatId,
        'formatVersion': 1,
        'data': {
          'books': [
            {'id': 'a'},
          ],
        },
      };
      final parsed = BackupCodec.parse(jsonEncode(payload));
      expect(parsed, isNotNull);
      expect(parsed!.data.keys, ['books']);
      expect(parsed.data['notes'], isNull);
    });

    test('白名单外的表不会被写回', () {
      // 这是安全措施：将来加表忘了登记，最坏是「恢复得少了点」，
      // 而不是「来路不明的 JSON 被灌进任意表」
      final payload = {
        'format': BackupCodec.formatId,
        'formatVersion': 1,
        'data': {
          'books': [
            {'id': 'a'},
          ],
          '__evil__': [
            {'x': 1},
          ],
        },
      };
      final parsed = BackupCodec.parse(jsonEncode(payload));
      expect(parsed!.data.containsKey('__evil__'), isFalse);
    });

    test('行不是 Map 时跳过而不是崩', () {
      final payload = {
        'format': BackupCodec.formatId,
        'formatVersion': 1,
        'data': {
          'books': [1, 'x', {'id': 'ok'}],
        },
      };
      final parsed = BackupCodec.parse(jsonEncode(payload));
      expect(parsed!.data['books']!.length, 1);
      expect(parsed.data['books']!.single['id'], 'ok');
    });
  });
}
