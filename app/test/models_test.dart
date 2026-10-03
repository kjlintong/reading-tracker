import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/models/enums.dart';

/// 统一模型是整个 App 的地基：所有导入源先转成 Book 再落库。
/// 这条链路一旦出错（字段丢失、类型退化），上层统计与 AI 报告全部失真，
/// 因此这里对序列化往返、去重指纹、枚举容错做显式断言。
void main() {
  Book sample({
    String id = 'b1',
    String title = '置身事内',
    List<String> authors = const ['兰小欢'],
    String? isbn13,
    BookStatus status = BookStatus.finished,
    double rating = 4.5,
    double progress = 100,
    Map<String, dynamic> extra = const {},
  }) {
    final now = '2026-09-29T10:00:00.000Z';
    return Book(
      id: id,
      title: title,
      authors: authors,
      isbn13: isbn13,
      status: status,
      rating: rating,
      progressPercent: progress,
      extra: extra,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('序列化往返', () {
    test('toMap → fromMap 字段无损', () {
      final b = sample(
        isbn13: '9787553681380',
        extra: {'notionColumn': '自定义属性'},
      ).copyWith(
        subtitle: '中国政府与经济发展',
        publisher: '上海人民出版社',
        tags: ['经济', '政治'],
        description: '一本讲中国经济的书',
        pageCount: 320,
        currentPage: 320,
        review: '读后感',
        format: BookFormat.paper,
      );

      final restored = Book.fromMap(b.toMap());

      expect(restored.id, b.id);
      expect(restored.title, b.title);
      expect(restored.subtitle, '中国政府与经济发展');
      expect(restored.authors, ['兰小欢']);
      expect(restored.publisher, '上海人民出版社');
      expect(restored.tags, ['经济', '政治']);
      expect(restored.pageCount, 320);
      expect(restored.isbn13, '9787553681380');
      // 数值字段：SQLite 里可能是 int，模型必须是 double，不能丢精度
      expect(restored.rating, 4.5);
      expect(restored.progressPercent, 100.0);
      // extra 兜底：Notion 自定义属性零丢失
      expect(restored.extra['notionColumn'], '自定义属性');
    });

    test('列表字段以 JSON 字符串存储后能还原', () {
      final b = sample(authors: ['兰小欢', '周黎安']);
      final row = b.toMap();
      expect(row['authors'], isA<String>());
      expect(Book.fromMap(row).authors, ['兰小欢', '周黎安']);
    });

    test('缺失字段回退为默认值而非抛异常', () {
      final b = Book.fromMap(<String, dynamic>{'id': 'x', 'title': '残缺记录'});
      expect(b.authors, isEmpty);
      expect(b.extra, isEmpty);
      expect(b.rating, 0);
      expect(b.status, BookStatus.wish);
      expect(b.language, 'zh');
    });
  });

  group('去重指纹', () {
    test('有 ISBN 时优先用 ISBN', () {
      final b = sample(isbn13: '9787553681380', authors: ['兰小欢']);
      expect(b.fingerprint, 'isbn:9787553681380');
    });

    test('无 ISBN 时退化为书名+首位作者，且忽略大小写与空格', () {
      final a = sample(title: ' 置身事内 ', authors: ['兰小欢', '其他']);
      final b = sample(title: '置身事内', authors: ['兰小欢']);
      expect(a.fingerprint, b.fingerprint);
    });

    test('同一书名不同作者不算同一本', () {
      final a = sample(title: '万历十五年', authors: ['黄仁宇']);
      final b = sample(title: '万历十五年', authors: ['另译者']);
      expect(a.fingerprint, isNot(b.fingerprint));
    });
  });

  group('枚举解析', () {
    test('已知值正确映射', () {
      expect(BookStatus.fromString('finished'), BookStatus.finished);
      expect(BookSource.fromString('weread'), BookSource.weread);
      expect(BookFormat.fromString('paper'), BookFormat.paper);
    });

    test('未知值与 null 退化为默认，不抛异常', () {
      // 外部数据源随时可能新增枚举值，静默退化好过崩溃
      expect(BookStatus.fromString('unknown'), BookStatus.wish);
      expect(BookStatus.fromString(null), BookStatus.wish);
      expect(BookSource.fromString('someNewApp'), BookSource.manual);
    });

    test('旧状态值仍能解析，不会静默回落成「想读」', () {
      // v3 把六个状态精简成四个。老库里可能残留旧值，
      // fromString 必须认它们——回落到 wish 会让正在读的书
      // 从统计里凭空消失，这比报错更难发现。
      expect(BookStatus.fromString('paused'), BookStatus.shelved);
      expect(BookStatus.fromString('abandoned'), BookStatus.shelved);
      // 「借阅中」本质是在读，借阅标记已拆成 Book.isBorrowed
      expect(BookStatus.fromString('borrowed'), BookStatus.reading);
    });

    test('storageValue 与词表一致，且可往返', () {
      for (final s in BookStatus.values) {
        expect(BookStatus.fromString(s.storageValue), s);
      }
      // 合并后的状态写回库时必须用新值，不能把 'paused' 又写回去
      expect(BookStatus.shelved.storageValue, 'shelved');
    });

    test('中文标签可用于 UI', () {
      // 标签一律走 appLoc 的 s_* 键，所以这里同时是在断言 ARB 的落字。
      // 用户明确要求这四个写法：想看 / 阅读中 / 已读完 / 搁置。
      expect(BookStatus.wish.label, '想看');
      expect(BookStatus.reading.label, '阅读中');
      expect(BookStatus.finished.label, '已读完');
      expect(BookStatus.shelved.label, '搁置');
      expect(BookSource.weread.label, '微信读书');
    });
  });

  group('借阅应还日期', () {
    test('无应还日期返回 null', () {
      expect(sample().daysUntilDue, isNull);
    });

    test('按自然日计算，逾期为负', () {
      final today = DateTime.now();
      String day(int offset) {
        final d = today.add(Duration(days: offset));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      final b1 = sample().copyWith(dueAt: day(3));
      final b2 = sample().copyWith(dueAt: day(-2));

      expect(b1.daysUntilDue, 3);
      expect(b2.daysUntilDue, -2);
    });

    test('借阅是独立标记，与阅读状态正交', () {
      // 借来的书同样在「读」——两者不该互斥
      final b = sample().copyWith(isBorrowed: true, status: BookStatus.reading);
      expect(b.isBorrowed, isTrue);
      expect(b.status, BookStatus.reading);
    });

    test('copyWith 不碰借阅标记时不会把它抹掉', () {
      final b = sample().copyWith(isBorrowed: true);
      for (final s in BookStatus.values) {
        expect(b.copyWith(status: s).isBorrowed, isTrue,
            reason: '改成 $s 后借阅标记丢了');
      }
    });
  });
}
