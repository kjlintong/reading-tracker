import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/data/database.dart';
import 'package:reading_tracker/providers.dart';
import 'package:reading_tracker/ui/settings_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/localized_app.dart';

/// 设置页「第三方渠道 → 搜索服务」效果图。
///
/// ## 为什么单独出图
///
/// 推荐书单第 4 档「联网搜索」要一个可配置的搜索服务（endpoint + Key），
/// 三个输入框加一个「测试连接」按钮挤在第三方渠道那一节的末尾。
/// 这一节本身还有微信读书与大模型两段，搜索服务是**第三块**——
/// 排在第几、跟上面的分隔线之间留了多少空、按钮在不在视野里，
/// 这些只能看图。
///
/// 截图要滚到那一段：整页很长，只拍首屏等于没验收这次改动。
///
/// ## 用法
///
/// ```bash
/// SHOTS=1 flutter test test/settings_search_shots_test.dart
/// 产物：store/shots/settings-search-service.png
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  final enabled = Platform.environment['SHOTS'] == '1';
  const outRoot = '../store/shots';

  late Database raw;
  late BookRepository repo;

  Future<ByteData> bytesOf(String path) async =>
      ByteData.view((await File(path).readAsBytes()).buffer);

  setUpAll(() async {
    if (!enabled) return;
    await (FontLoader('TestLatin')..addFont(bytesOf('test/fixtures/simhei.ttf')))
        .load();
    await (FontLoader('TestCJK')..addFont(bytesOf('test/fixtures/simhei.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(bytesOf('test/fixtures/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() async {
    raw = await databaseFactory.openDatabase(inMemoryDatabasePath);
    final appDb = AppDatabase.forTest(raw);
    await appDb.createSchema(raw);
    repo = BookRepository(appDb);
  });

  tearDown(() async => raw.close());

  testWidgets('设置页-搜索服务配置', (tester) async {
    if (!enabled) return;

    // 必须在 pumpWidget 之前设尺寸：布局一旦定完，
    // 再改 physicalSize 只会改采样密度，不会重新布局。
    tester.view.physicalSize = const Size(390, 844) * 3.0;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [repoProvider.overrideWithValue(repo)],
      child: localizedApp(
        locale: const Locale('zh'),
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'TestLatin',
          fontFamilyFallback: const <String>['TestCJK'],
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xFF3B6D11)),
        ),
        home: const RepaintBoundary(
          key: ValueKey<String>('settings-shot'),
          child: SettingsPage(),
        ),
      ),
    ));

    // 设置页要读库（存的用户设置），跨几轮微任务才落地。
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }

    // 找到「搜索服务」这一段，滚到它刚好在画面里。
    //
    // ⚠️ 不能靠「拖 N 次」定位：设置页很长，拖多了滚过头（滚到
    // 「数据」那一节去了），拖少了够不着，而且**拖过头不会报错**，
    // 截出来的图看着正常但根本没拍到目标。
    //
    // 用 `dragUntilVisible`：每次迭代重新求值 finder，
    // 懒构建的 ListView 也能命中。滚过头了会先回到顶部重来。
    final list = find.byType(ListView).first;
    await tester.drag(list, const Offset(0, 4000));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('搜索服务'),
      list,
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();

    // 「搜索服务」是第三块的标题，dragUntilVisible 停在它刚入镜的位置，
    // 标题在屏幕顶边。再往**回**退一点（手指下滑 = 内容下移），
    // 让标题和三个输入框一起入镜。
    await tester.drag(list, const Offset(0, 150));
    await tester.pumpAndSettle();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey<String>('settings-shot')),
    );
    final file = File('$outRoot/settings-search-service.png');
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('导出 PNG 失败');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    });
  });
}
