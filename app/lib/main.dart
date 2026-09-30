import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database.dart';
import 'data/seed_import.dart';
import 'providers.dart';
import 'ui/shelf_page.dart';
import 'ui/import_page.dart';
import 'ui/stats_page.dart';
import 'ui/ai_report_page.dart';
import 'ui/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.init();

  // 首次启动灌入示例书库（38 本合成数据）。幂等，已导入则跳过。
  int seeded = 0;
  try {
    seeded = await SeedImporter(BookRepository(AppDatabase.instance)).importIfNeeded();
  } catch (e) {
    // 种子数据损坏不应阻断启动——用户仍可正常使用导入功能
    debugPrint('种子数据导入失败: $e');
  }
  if (seeded > 0) debugPrint('已导入种子书库 $seeded 本');

  runApp(const ProviderScope(child: ReadingTrackerApp()));
}

class ReadingTrackerApp extends StatelessWidget {
  const ReadingTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '阅读管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B6D11),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF97C459),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadSettings(ref);
      if (mounted) setState(() => _loaded = true);
    });
  }

  static const _pages = [ShelfPage(), ImportPage(), StatsPage(), AiReportPage(), SettingsPage()];

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: '书架'),
          NavigationDestination(icon: Icon(Icons.file_upload_outlined), label: '导入'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: '统计'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: '报告'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '设置'),
        ],
      ),
    );
  }
}
