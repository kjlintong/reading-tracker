import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/models/book.dart';
import 'package:reading_tracker/ui/book_cover.dart';

import 'support/localized_app.dart';

/// [BookCover] 的优先级与降级链。
///
/// 为什么值得单独测：这个组件是「用户选的封面显示不出来」那个 bug 的
/// 唯一修复点。当时书架与详情页各写了一份渲染、且都只判 `coverUrl`，
/// 本地封面写进了库却从没被读过。优先级一旦被改回「远程优先」，
/// 用户的换封面操作会静默失效——界面上看不出错，只是「没反应」。
void main() {
  Future<void> loadFonts() async {
    final bytes = File('test/fixtures/simhei.ttf').readAsBytesSync();
    await (FontLoader('TestLatin')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
    await (FontLoader('TestCJK')
          ..addFont(Future.value(ByteData.sublistView(bytes))))
        .load();
  }

  /// 用 `Book.create` 拿到 createdAt/updatedAt（它是唯一会补这两个时间的
  /// 工厂），再 copyWith 覆写封面字段。
  Book bookWith({String? local, String? url, String title = '一本书'}) =>
      Book.create(title: title).copyWith(
        coverUrl: url,
        coverLocalPath: local,
      );

  Widget host(Book b) => localizedApp(
        theme: ThemeData(
          fontFamily: 'TestLatin',
          fontFamilyFallback: const <String>['TestCJK'],
        ),
        home: Scaffold(
          body: SizedBox(width: 90, height: 126, child: BookCover(book: b)),
        ),
      );

  setUpAll(loadFonts);

  testWidgets('有本地封面时用本地文件，不吃远程 URL', (tester) async {
    // 写一个真实存在的临时文件，Image.file 才不会走进 errorBuilder。
    final dir = Directory.systemTemp.createTempSync('cover_test');
    final f = File('${dir.path}/cover.png');
    // 1x1 透明 PNG：最小的合法图片，Image.file 能解出来。
    f.writeAsBytesSync(const <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82,
    ]);
    addTearDown(() => dir.deleteSync(recursive: true));

    await tester.pumpWidget(host(bookWith(
      local: f.path,
      url: 'https://example.com/remote.jpg',
    )));
    await tester.pump();

    // 本地优先：两个都给了，必须走 file。
    expect(find.byType(Image), findsOneWidget);
    final img = tester.widget<Image>(find.byType(Image));
    expect(img.image, isA<FileImage>(),
        reason: '本地封面必须压过远程 URL，否则用户换封面等于没换');
  });

  testWidgets('没有本地封面时退回远程 URL', (tester) async {
    await tester.pumpWidget(host(bookWith(url: 'https://example.com/r.jpg')));
    await tester.pump();

    final img = tester.widget<Image>(find.byType(Image));
    expect(img.image, isA<NetworkImage>());
  });

  testWidgets('两个都没有时画占位块，而不是空白', (tester) async {
    await tester.pumpWidget(host(bookWith(title: '置身事内')));
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    // 占位块取书名前两字
    expect(find.text('置身'), findsOneWidget);
  });

  testWidgets('书名只有一个字时占位块也只取一个字', (tester) async {
    await tester.pumpWidget(host(bookWith(title: '书')));
    await tester.pump();
    expect(find.text('书'), findsOneWidget);
  });

  testWidgets('本地路径为空字符串时视同没有本地封面，走远程', (tester) async {
    // 表单里清空封面存的是 ''，不是 null。不把空串当「没有」的话，
    // `Image.file(File(''))` 会走进错误分支，用户看到一张破图。
    await tester.pumpWidget(host(bookWith(local: '', url: 'https://e.com/r.jpg')));
    await tester.pump();

    final img = tester.widget<Image>(find.byType(Image));
    expect(img.image, isA<NetworkImage>());
  });

  testWidgets('远程 URL 为空字符串时视同没有封面，画占位块', (tester) async {
    await tester.pumpWidget(host(bookWith(url: '', title: '置身事内')));
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.text('置身'), findsOneWidget);
  });

  // ⚠️ 「本地文件已被系统清理 → 退回远程」这条降级链**无法在 widget 测试
  // 里验证**：`Image` 的解码走真实异步 IO，widget 测试里图片加载被桩掉，
  // errorBuilder 永远不会被调用，断言只会看到那个 FileImage 本身。
  // 这条链靠代码审查与真机验证保证——见 BookCover._buildContent 的注释。
}
