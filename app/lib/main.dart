import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_loc.dart';
import 'data/database.dart';
import 'providers.dart';
import 'ui/shelf_page.dart';
import 'ui/notes_page.dart';
import 'ui/stats_page.dart';
import 'ui/insights_page.dart';
import 'ui/settings_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 必须在数据库初始化之前装好本地化。
  //
  // init() 会执行 v1→v2 迁移与首启灌库，两者都会走
  // normalizeCategory → categoryLabel → appLoc。若此时 appLoc 尚未装载，
  // 会直接抛 StateError——表现为「装上就崩 / 首次启动崩」，且崩在 runApp 之前，
  // 用户看不到任何界面。
  //
  // 这里先用平台语言装一份。首帧的 MaterialApp.builder 会用解析后的 locale
  // 覆盖它，所以最终语言仍以系统设置为准；这一步只保证「启动期也能取到文案」。
  setAppLoc(await S.delegate.load(
    WidgetsBinding.instance.platformDispatcher.locale,
  ));

  await AppDatabase.instance.init();

  runApp(const ProviderScope(child: ReadingTrackerApp()));
}

class ReadingTrackerApp extends StatelessWidget {
  const ReadingTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 用 Consumer 而不是把整个 App 变成 ConsumerWidget：
    // 只有主题/语言这几项需要重建，其余部分（HomeShell 及其页面栈）
    // 不该因为换肤而丢失状态——换肤时保持在原页面、滚动位置不跳。
    return Consumer(
      builder: (context, ref, _) {
        final theme = AppTheme.byId(ref.watch(appThemeProvider));
        final brightness = ref.watch(appBrightnessProvider);
        final locale = ref.watch(appLocaleProvider);
        return MaterialApp(
          // 任务切换器 / 系统最近任务里显示的名称。用 onGenerateTitle 而不是
          // title:，是为了走 S（随 locale 变化）——title: 只能吃一个常量字符串。
          onGenerateTitle: (context) => S.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          // 语言：用户显式选过就用选的，否则 null → 由系统语言决定
          locale: locale,
          builder: (context, child) {
            // 缓存当前 locale 的 S 实例，供无 BuildContext 的代码通过 appLoc 取用
            setAppLoc(S.of(context));
            return child!;
          },
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          // 每套皮肤按当前明暗态各构造一次；具体规则见 ui/theme.dart
          theme: buildTheme(theme, Brightness.light),
          darkTheme: buildTheme(theme, Brightness.dark),
          themeMode: brightness.themeMode,
          home: const HomeShell(),
        );
      },
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

  /// 顺序：书架 → 记录 → 统计 → 阅读档案 → 设置。
  ///
  /// 「记录」放在第二位：它是「我亲手写下的东西」——笔记 + 阅读计划，
  /// 与书架的「我有什么书」是一对连贯动作。以前这一格只有笔记，
  /// 功能偏薄，且阅读计划被塞在「阅读档案」里语义不合（档案是回顾性的，
  /// 计划是前瞻性的），现已合并。
  ///
  /// 「统计」居第三，承接「输入—沉淀—回顾」的叙事。
  ///
  /// 第四位原本是「导入」，现在让给「阅读档案」：
  /// 导入的所有方式都收进了书架右上角「+」的抽屉里（见 add_book_sheet.dart），
  /// 一个入口就够，不必再占一格导航；而阅读档案是「回看自己」的独立主题，
  /// 从统计页里的一张入口卡升格为一级栏目。
  static const _pages = [
    ShelfPage(),
    NotesPage(),
    StatsPage(),
    InsightsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = S.of(context);
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.menu_book_outlined), label: l10n.navShelf),
          NavigationDestination(icon: const Icon(Icons.edit_note_outlined), label: l10n.navNotes),
          NavigationDestination(icon: const Icon(Icons.insights_outlined), label: l10n.navStats),
          NavigationDestination(icon: const Icon(Icons.auto_stories_outlined), label: l10n.insights),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.navSettings),
        ],
      ),
    );
  }
}
