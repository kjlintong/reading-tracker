import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_loc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/date_range.dart';
import '../data/encouragement.dart';
import '../data/stats_aggregate.dart';
import '../data/stats_prefs.dart';
import '../data/weread_annual.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'chronology_page.dart';
import 'palette.dart';
import 'range_selector.dart';

/// 统计看板。
///
/// 三块：**本期**（受时间筛选）、**当前书架**（快照，不受筛选）、
/// **结构分析**（受时间筛选的 7 张图）。
///
/// 为什么要把「快照」和「本期」分开放：总藏书、在读、想读、连续阅读
/// 本来就是「此刻」的量，硬把它们塞进时间区间会得到一个既不是期初
/// 也不是期末的三不像。分开并各自标注口径，比混在一起更可信。
///
/// 图表一律传 `duration: Duration.zero`：默认的入场动画会让界面截图
/// 抓到长到一半的柱子，也让「点进来立刻看数字」变成等动画。
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

/// 一句鼓励。放在统计页最上面而不是埋在卡片里——
/// 用户打开统计页是想被确认「我确实读了点东西」，
/// 塞在第七屏的角落里等于没有。
///
/// 文案由 `encouragementLine` 按当天日期播种，一天之内不会变。
class _EncouragementBanner extends StatelessWidget {
  final String line;

  const _EncouragementBanner({required this.line});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(line,
                style: const TextStyle(fontSize: 12.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _StatsPageState extends ConsumerState<StatsPage> {
  /// 当前选中区间的**原始实例**（label 可能是上一语言的）。
  ///
  /// 只用来记住「用户选了哪一段」（靠 from/to 判定），
  /// 取 label / note 请统一走 [_range]。
  StatsRange _rangeSel = StatsRange.all;

  /// 当前区间，label / note 按**当前语言**现取。
  ///
  /// 本页是 `HomeShell._pages` 里的 `const StatsPage()`，State 跨越
  /// 语言切换一直存活。若把 label 存死在字段里，切语言后区间胶囊与
  /// 各区块标题会永远停在旧语言（英文界面下点过统计页 → 切回中文
  /// 仍显示 "All time"）。做成 getter 后每次读都重建，无需加重建 key。
  StatsRange get _range => _rangeSel.relabeled();

  List<Book> _rangeBooks = const [];
  Map<BookStatus, int> _status = {};
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _trend = [];
  List<Map<String, dynamic>> _ratings = [];
  List<Map<String, dynamic>> _progress = [];
  List<DateTime> _months = const [];
  ReadingActivity _activity = ReadingActivity.empty;
  WereadAnnualStats? _annual;

  /// 用户隐藏掉的图表 id。空 = 七张全显示。
  ///
  /// 存在 settings 表而不是内存：这是「我希望这个页面长什么样」的
  /// 长期偏好，每次进来都要从库里读回来。
  Set<String> _hiddenCharts = <String>{};

  int _allTotal = 0;
  int _allReading = 0;
  int _allWish = 0;
  int _allShelved = 0;
  /// 「本期新增藏书」按 `createdAt` 算——「什么时候加进书架」和
  /// 「什么时候读的」是两件事，不能共用 `containsBook` 那套
  /// 「读完看完成日」的口径。
  int _addedInRange = 0;
  int _streak = 0;
  int _allStalled = 0;
  double _avgRating = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final all = await repo.all();
    final books = all.where(_range.containsBook).toList();
    final activity = await repo.readingActivity(_range);
    final annual = await repo.wereadAnnualStats();
    final streak = await repo.readingStreakDays();
    final hiddenRaw = await repo.getSetting(statsHiddenChartsKey);
    // 轴上铺几十个月谁也没法看，截到最近 12 个
    final months = _range.months(maxMonths: 12);
    if (!mounted) return;

    final allStatus = statusCountsOf(all);
    setState(() {
      _rangeBooks = books;
      _activity = activity;
      _annual = annual;
      _months = months;
      _hiddenCharts = decodeHiddenCharts(hiddenRaw);
      _status = statusCountsOf(books);
      _categories = categoryDistributionOf(books);
      _sources = sourceDistributionOf(books);
      _trend = monthlyFinishedOf(books, months);
      _ratings = ratingBucketsOf(books);
      _progress = progressBucketsOf(books);
      _avgRating = averageRatingOf(books);
      _allTotal = all.length;
      _allReading = allStatus[BookStatus.reading] ?? 0;
      _allWish = allStatus[BookStatus.wish] ?? 0;
      _allShelved = allStatus[BookStatus.shelved] ?? 0;
      _addedInRange = _range.isAll
          ? all.length
          : all.where((b) => _range.containsIso(b.createdAt)).length;
      _allStalled = stalledCountOf(all);
      _streak = streak;
      _loading = false;
    });
  }

  void _changeRange(StatsRange r) {
    if (r.from == _rangeSel.from && r.to == _rangeSel.to) return;
    setState(() => _rangeSel = r);
    _load();
  }

  bool _showChart(String id) => !_hiddenCharts.contains(id);

  /// 弹图表可见性设置。保存后立刻重排页面。
  ///
  /// 用底部抽屉而不是二级设置页：这个偏好只在「此刻看着这七张图」时
  /// 才有意义，跳到设置页去找它，回来就忘了自己想藏哪张。
  ///
  /// 不开 `isScrollControlled`：七行开关自己就撑不满半屏，默认高度
  /// 完全够用。倒是它的两个极端都很难看——矮屏上限太死、高屏上
  /// 内容一股脑顶到屏幕顶。保持默认，让它贴着内容高度收起来。
  Future<void> _openChartSettings() async {
    final next = await showModalBottomSheet<Set<String>>(
      context: context,
      builder: (ctx) => _ChartSettingsSheet(hidden: _hiddenCharts),
    );
    if (next == null || !mounted) return;
    setState(() => _hiddenCharts = next);
    await ref
        .read(repoProvider)
        .setSetting(statsHiddenChartsKey, encodeHiddenCharts(next));
  }

  int get _finishedInRange => _status[BookStatus.finished] ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final readingInRange = _status[BookStatus.reading] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title:  Text(appLoc.s_0e13c16f),
        actions: [
          // 图表显示设置：这七张图的价值因人而异，藏掉不看的比留着更好用。
          IconButton(
            tooltip: appLoc.s_37361909,
            icon: const Icon(Icons.tune),
            onPressed: _openChartSettings,
          ),
          // 「阅历」入口：统计看的是「合计」，从顶部这一处进「具体哪几本」。
          // 放 AppBar 而不是页面里再插一张卡：卡片会被埋在十多屏图表之后
          // （这张页面本身有 7 张图 + 三块指标），等于没有入口。
          IconButton(
            tooltip: appLoc.chronology,
            icon: const Icon(Icons.view_kanban_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChronologyPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /* ------------------------- 鼓励语 ------------------------- */
          // 排在最前：它是打开统计页第一眼看到的东西，情绪先行。
          // 报告入口从顶部挪走了（见下），页面顶部的「第一眼」让给鼓励语。
          _EncouragementBanner(
            line: encouragementLine(
              finished: _finishedInRange,
              streak: _streak,
              minutes: _activity.minutes,
              total: _allTotal,
              now: DateTime.now(),
            ),
          ),
          const SizedBox(height: 14),

          /* ------------------------- 时间范围 ------------------------- */
          // 选择器收细：它是一行控件，不该占据和内容区一样的视觉重量。
          // 具体做法见 range_selector.dart（改成紧凑的单行胶囊）。
          StatsRangeSelector(value: _range, onChanged: _changeRange),
          const SizedBox(height: 18),

          /* ------------------------- 当前书架 ------------------------- */
          // 书架概况是「不管看哪个时间段都不变」的底数，
          // 放在随时间变化的「本期」之前，先给固定坐标再给变量。
          _sectionTitle(theme, appLoc.s_58d90b89, appLoc.s_c3bb899b),
          const SizedBox(height: 10),
          Row(children: [
            _metric(appLoc.s_563edd9d, '$_allTotal', appLoc.s_50ba5fd5),
            const SizedBox(width: 10),
            _metric(appLoc.s_b9bf9b53, '$_allReading', appLoc.s_50ba5fd5),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric(appLoc.s_5a833930, '$_allWish', appLoc.s_50ba5fd5),
            const SizedBox(width: 10),
            _metric(appLoc.s_eba88d83, '$_allShelved', appLoc.s_50ba5fd5),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric(appLoc.s_0d8d3eb3, '$_streak', appLoc.s_3509a9f8),
            const SizedBox(width: 10),
            _metric(appLoc.s_4ab30c5b, '$_allStalled', appLoc.s_50ba5fd5),
          ]),
          const SizedBox(height: 24),

          /* ------------------------- 本期 ------------------------- */
          // ⚠️ 这里刻意**不显示**「阅读时长」「阅读天数」「日均阅读」。
          //
          // 本 App 全靠用户手工录入，没有任何前台计时或行为埋点，
          // 这三个数只能来自微信读书年度统计的导入——不用微信读书的
          // 用户看到的是三个永远的「—」或 0。摆在这里不是信息，
          // 是每天提醒他「你还有个数据没填」，纯负担。
          // 想算这些的人可以在下面的「月度阅读时长」图里看到导入后的真值。
          _sectionTitle(theme, appLoc.s_7c6c253b(label: _range.label), appLoc.s_88c0b751),
          const SizedBox(height: 10),
          Row(children: [
            _metric(appLoc.s_0872b5b7, '$_finishedInRange', appLoc.s_50ba5fd5),
            const SizedBox(width: 10),
            _metric(appLoc.s_cc4556af, '$_addedInRange', appLoc.s_50ba5fd5),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric(appLoc.s_5182e58a,
                _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '—', appLoc.s_a7e9ff0f),
            const SizedBox(width: 10),
            // 与上排凑成偶数格。放「连续阅读」这个**此刻**的量在
            // 「本期」下面口径不对，所以改用区间内的低进度在读数——
            // 它确实是按当前区间算的。
            _metric(appLoc.s_4ab30c5b, '$_stalledInRange', appLoc.s_50ba5fd5),
          ]),
          const SizedBox(height: 24),

          /* ------------------------- 结构分析 ------------------------- */
          _sectionTitle(theme, appLoc.s_b563f985(label: _range.label),
              appLoc.s_a7e09561(length: _rangeBooks.length)),
          const SizedBox(height: 10),

          // 七张图各自可开关（右上角「tune」里设置）。间距不写死在每张卡
          // 后面，而是由 [_chartSlot] 统一补——否则把中间某张关掉之后，
          // 会留下两块相邻的 16px 空隙，看起来像排版坏了。
          _chartSlot(
            StatsChart.status,
            _chartCard(
              appLoc.s_c6cc650b,
              subtitle: appLoc.s_0cd6d0f8(length: _rangeBooks.length),
              height: 190,
              child: _status.isEmpty
                  ? _empty()
                  : Row(
                      children: [
                        SizedBox(width: 150, child: _statusDonut()),
                        const SizedBox(width: 8),
                        Expanded(child: _statusLegend()),
                      ],
                    ),
            ),
          ),

          _chartSlot(
            StatsChart.category,
            _chartCard(
              appLoc.s_8137585d,
              subtitle: _categories.isEmpty
                  ? null
                  : appLoc.s_f92480e2(length: _categories.length),
              height: 200,
              child: _categories.isEmpty
                  ? _empty()
                  : Column(
                      children: [
                        Expanded(child: _categoryBars()),
                        const SizedBox(height: 8),
                        _categoryLegend(),
                      ],
                    ),
            ),
          ),

          _chartSlot(
            StatsChart.trend,
            _chartCard(
              appLoc.s_50feb68a,
              subtitle: _months.isEmpty ? null : _rangeSpanLabel,
              height: 180,
              child: _trend.isEmpty ? _empty(appLoc.s_750a3b1c) : _trendLine(),
            ),
          ),

          // 阅读节奏：这是整份年度统计里最值钱的一段数据，
          // 能一眼看出「哪几个月真的在读、哪几个月断了」
          _chartSlot(
            StatsChart.readingTime,
            _chartCard(
              appLoc.s_4d7dd157,
              subtitle: _annualSubtitle,
              footnote: _annualFoot,
              height: 180,
              child: _readingTimeData == null
                  ? _empty(appLoc.s_5a78dc03)
                  : _readingTimeBars(),
            ),
          ),

          _chartSlot(
            StatsChart.rating,
            _chartCard(
              appLoc.s_5b37ad6b,
              subtitle: _ratedCount == 0
                  ? null
                  : appLoc.s_3c0e984b(
                      toStringAsFixed: _avgRating > 0
                          ? _avgRating.toStringAsFixed(1)
                          : '—',
                      unratedCount: _unratedCount),
              height: 170,
              // 判空要看「有没有评过分」，而不是「有没有书」——
              // 一本没评时图里会是 5 根 0 高的柱子，比空态还误导
              child: _ratedCount == 0 ? _empty(appLoc.s_3c1cb8ee) : _ratingBars(),
            ),
          ),

          _chartSlot(
            StatsChart.progress,
            _chartCard(
              appLoc.s_01d886c7,
              subtitle: appLoc.s_ecf53f5a(readingInRange: readingInRange),
              height: 170,
              child: readingInRange == 0
                  ? _empty(appLoc.s_faf98ba4)
                  : _progressBars(),
            ),
          ),

          _chartSlot(
            StatsChart.source,
            _chartCard(
              appLoc.s_ec977df0,
              subtitle: _sources.isEmpty
                  ? null
                  : appLoc.s_77030fdc(length: _sources.length),
              height: 190,
              child: _sources.isEmpty
                  ? _empty()
                  : Row(
                      children: [
                        SizedBox(width: 150, child: _sourceDonut()),
                        const SizedBox(width: 8),
                        Expanded(child: _sourceLegend()),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /* ------------------------------ 指标 ------------------------------ */

  /// 已评分 / 未评分的本数。`_ratings[0]` 是「未评分」档，其余 1~5 星。
  int get _unratedCount =>
      _ratings.isEmpty ? 0 : (_ratings.first['count'] as int);

  int get _ratedCount => _ratings
      .where((e) => (e['stars'] as int) > 0)
      .fold<int>(0, (a, b) => a + (b['count'] as int));

  /// 区间内在读且进度极低的本数。与「当前书架」里的 `_allStalled`
  /// 是两个口径：那个是全库快照，这个是按当前时间区间筛过的。
  int get _stalledInRange =>
      _rangeBooks.where((b) => b.status == BookStatus.reading && b.progressPercent < 15).length;

  String get _rangeSpanLabel {
    if (_months.isEmpty) return '';
    final sameYear = _months.every((m) => m.year == _months.first.year);
    String fmt(DateTime m) =>
        sameYear ? appLoc.s_1a2e873e(month: m.month) : '${m.year}/${m.month}';
    return '${fmt(_months.first)} - ${fmt(_months.last)}';
  }

  /// 落在当前区间内的年度统计月份。没有交集就返回 null，
  /// 图直接进空态而不是画一排 0——那样会让人以为「整年没读」。
  List<MonthlyReading>? get _readingTimeData {
    final a = _annual;
    if (a == null || a.monthly.isEmpty) return null;
    final hit = [
      for (final m in a.monthly)
        if (_range.overlapsMonth(m.year, m.month)) m,
    ];
    return hit.isEmpty ? null : hit;
  }

  /// 副标题必须带上年份：这张图的横轴是**年度统计所在的那个自然年**，
  /// 而上面「月度读完」用的是最近 12 个月。两个口径不一样，
  /// 不写清楚就会出现「10 月读完 7 本，下面这张图里却没有 10 月」的困惑。
  String? get _annualSubtitle {
    final data = _readingTimeData;
    if (data == null) return null;
    final sec = data.fold<int>(0, (a, m) => a + m.seconds);
    final years = {for (final m in data) m.year}.toList()..sort();
    final scope = years.length == 1
        ? appLoc.s_cea9cf70(first: years.first)
        : appLoc.s_c4e530bb(first: years.first, last: years.last);
    return appLoc.s_00fbaae1(scope: scope, toStringAsFixed: (sec / 3600).toStringAsFixed(1));
  }

  /// 「月度阅读时长」的口径脚注。只在与上方读完图轴不一致时出现。
  ///
  /// 微信读书官方只给整年的逐月数据，所以「全部时间」下这条轴没法取
  /// 「最近 12 个月」，只能锚到年度统计那一年。这不是可以藏着的事。
  String? get _annualFoot {
    final data = _readingTimeData;
    if (data == null) return null;
    if (!_range.isAll) return null;
    final years = {for (final m in data) m.year}.toList()..sort();
    return appLoc.s_e7b115df(join: years.join(' / '));
  }

  /// 月度阅读时长图的横轴。
  ///
  /// 「全部时间」下不能用最近 12 个月当轴——年度统计自己只有那一年，
  /// 轴上会有一半是空月份，看着像「整半年没读」。其余情况用区间自己的
  /// 月份，这样「连续几个月断了」会以淡柱的形式留在图上。
  List<DateTime> get _readingAxis {
    final data = _readingTimeData;
    if (data == null) return const [];
    if (!_range.isAll) return _months;
    final months = [for (final m in data) DateTime(m.year, m.month)];
    return months.length <= 12 ? months : months.sublist(months.length - 12);
  }

  /* ------------------------------ 图表 ------------------------------ */

  /// 状态环：一眼看出「想读堆了很多、读完的少」这种结构问题
  Widget _statusDonut() {
    final entries = BookStatus.values
        .map((s) => (s, _status[s] ?? 0))
        .where((e) => e.$2 > 0)
        .toList();
    final total = entries.fold<int>(0, (a, b) => a + b.$2);
    if (total == 0) return _empty();

    return PieChart(
      duration: Duration.zero,
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 34,
        sections: [
          for (var i = 0; i < entries.length; i++)
            PieChartSectionData(
              value: entries[i].$2.toDouble(),
              color: chartColorAt(i, context),
              radius: 26,
              showTitle: false,
            ),
        ],
      ),
    );
  }

  Widget _statusLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < BookStatus.values.length; i++)
          if ((_status[BookStatus.values[i]] ?? 0) > 0)
            LegendRow(
              color: chartColorAt(
                  _statusColorIndex(BookStatus.values[i]), context),
              label: BookStatus.values[i].label,
              count: '${_status[BookStatus.values[i]]}',
              ratio: _ratioOf(_status[BookStatus.values[i]] ?? 0),
            ),
      ],
    );
  }

  /// 颜色跟着状态走，不跟着「谁先出现」走——
  /// 否则筛选别的数据时同一个状态会换颜色
  int _statusColorIndex(BookStatus s) {
    final present =
        BookStatus.values.where((e) => (_status[e] ?? 0) > 0).toList();
    final i = present.indexOf(s);
    return i < 0 ? 0 : i;
  }

  String _ratioOf(int v) {
    final total = _status.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return '';
    return '${(v * 100 / total).toStringAsFixed(1)}%';
  }

  Widget _categoryBars() {
    final data = _categories.take(8).toList();
    final maxY =
        data.map((e) => (e['c'] as int).toDouble()).fold<double>(0, math.max);
    final cs = Theme.of(context).colorScheme;

    return BarChart(
      duration: Duration.zero,
      BarChartData(
        maxY: (maxY + 1).ceilToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final name = categoryLabel(data[group.x]['name'] as String);
              return BarTooltipItem(
                appLoc.s_9ef861db(name: name, toInt: rod.toY.toInt()),
                TextStyle(color: cs.onInverseSurface, fontSize: 12),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              (maxY + 1) <= 4 ? 1 : ((maxY + 1) / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: (maxY + 1) <= 4 ? 1 : ((maxY + 1) / 4).ceilToDouble(),
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${i + 1}',
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (data[i]['c'] as int).toDouble(),
                  color: chartColorAt(i, context),
                  width: 14,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 分类明细。图表画在 canvas 上，读屏与测试都取不到文字，
  /// 所以名称与数量必须另有一份文本列表——它同时也是图例。
  Widget _categoryLegend() {
    final total = _categories.fold<int>(0, (a, b) => a + (b['c'] as int));
    return Column(
      children: [
        for (var i = 0; i < _categories.length && i < 8; i++)
          LegendRow(
            color: chartColorAt(i, context),
            label: categoryLabel(_categories[i]['name'] as String),
            count: '${_categories[i]['c']}',
            ratio: total == 0
                ? ''
                : '${((_categories[i]['c'] as int) * 100 / total).toStringAsFixed(1)}%',
          ),
      ],
    );
  }

  Widget _trendLine() {
    final cs = Theme.of(context).colorScheme;
    final byMonth = <String, int>{};
    for (final t in _trend) {
      byMonth[t['month'] as String] = t['c'] as int;
    }
    final values = [
      for (final m in _months) (byMonth[monthKey(m)] ?? 0).toDouble(),
    ];
    final maxY = values.isEmpty ? 1.0 : values.reduce(math.max);
    final sameYear =
        _months.isEmpty || _months.every((m) => m.year == _months.first.year);
    // 月份多了标签会糊成一团，隔位标注
    final step = _months.length <= 6 ? 1 : (_months.length / 6).ceil();

    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minX: 0,
        maxX: math.max(1, _months.length - 1).toDouble(),
        minY: 0,
        maxY: maxY + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max(1.0, ((maxY + 1) / 4).ceilToDouble()),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: math.max(1.0, ((maxY + 1) / 4).ceilToDouble()),
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= _months.length) return const SizedBox.shrink();
                if (i % step != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      monthAxisLabel(_months[i], sameYear: sameYear),
                      style:
                          TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt().clamp(0, _months.length - 1);
              return LineTooltipItem(
                appLoc.s_2cf3ef4e(i: monthKey(_months[i]), toInt: s.y.toInt()),
                TextStyle(color: cs.onInverseSurface, fontSize: 12),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.25,
            color: chartColorAt(0, context),
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: chartColorAt(0, context).withOpacity(0.15),
            ),
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
          ),
        ],
      ),
    );
  }

  /// 月度阅读时长（小时）。
  ///
  /// 单位取小时而不是秒：微信读书原始值是秒，最大能到六位数，
  /// 直接画出来 Y 轴全是 0，一点信息都读不出来。
  Widget _readingTimeBars() {
    final cs = Theme.of(context).colorScheme;
    final data = _readingTimeData!;
    final byMonth = <String, double>{
      for (final m in data) monthKey(DateTime(m.year, m.month)): m.hours,
    };

    // 轴跟着当前区间走，而不是年度统计自己的 12 个月：
    // 否则选了「近 3 个月」，图里还是画满 12 根柱子。
    final axis = _readingAxis;
    final values = [
      for (final m in axis) byMonth[monthKey(m)] ?? 0.0,
    ];
    final maxY = values.isEmpty ? 1.0 : values.reduce(math.max);
    // 单个高月会把其他月压成一条线，所以按「够读的刻度」取整。
    // 注意 1.0 不能写成 1：math.max 的返回类型由两个实参决定，
    // 一个 int 一个 double 会推出 num，赋值给 double? 就报类型错。
    final axisMax = maxY <= 4 ? 4.0 : (maxY * 1.15).ceilToDouble();
    final interval = math.max(1.0, (axisMax / 4).ceilToDouble());
    final emptyMonth = chartColorAt(3, context).withOpacity(0.25);
    final sameYear =
        axis.isEmpty || axis.every((m) => m.year == axis.first.year);
    final step = axis.length <= 6 ? 1 : (axis.length / 6).ceil();

    return BarChart(
      duration: Duration.zero,
      BarChartData(
        maxY: axisMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final i = group.x.clamp(0, axis.length - 1);
              return BarTooltipItem(
                appLoc.s_e241a8ef(i: monthKey(axis[i]), toStringAsFixed: rod.toY.toStringAsFixed(1)),
                TextStyle(color: cs.onInverseSurface, fontSize: 12),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: interval,
              getTitlesWidget: (v, meta) => Text(
                v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1),
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= axis.length) return const SizedBox.shrink();
                if (i % step != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(monthAxisLabel(axis[i], sameYear: sameYear),
                      style:
                          TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < axis.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  // 没读的月份画一根淡柱，而不是留空——
                  // 留空会让「连续几个月断了」这件事彻底隐身
                  color: values[i] > 0 ? chartColorAt(1, context) : emptyMonth,
                  width: 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _ratingBars() {
    final cs = Theme.of(context).colorScheme;
    // 只画 1~5 星，把「未评分」摘出去。
    // 同轴放一起会毁掉这张图：实测种子库 99 本未评分、每档星约 7 本，
    // 未评分的柱子顶满坐标轴，1~5 星被压成看不见的细线——
    // 图还在，信息为零。「有几本没评分」属于副标题，不属于分布本身。
    final rated = _ratings.where((e) => (e['stars'] as int) > 0).toList();
    final maxY = rated
        .map((e) => (e['count'] as int).toDouble())
        .fold<double>(0, math.max);
    final interval = math.max(1.0, (maxY + 1) / 4).ceilToDouble();

    return BarChart(
      duration: Duration.zero,
      BarChartData(
        maxY: maxY + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: interval,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= rated.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(rated[i]['label'] as String,
                      style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < rated.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (rated[i]['count'] as int).toDouble(),
                  color: chartColorAt(i, context),
                  width: 20,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _progressBars() {
    final cs = Theme.of(context).colorScheme;
    final maxY =
        _progress.map((e) => (e['count'] as int).toDouble()).fold<double>(0, math.max);
    final interval = math.max(1.0, (maxY + 1) / 3).ceilToDouble();

    return BarChart(
      duration: Duration.zero,
      BarChartData(
        maxY: maxY + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: interval,
              getTitlesWidget: (v, meta) => Text(
                v.toInt().toString(),
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= _progress.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_progress[i]['label'] as String,
                      style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < _progress.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (_progress[i]['count'] as int).toDouble(),
                  color: chartColorAt((i + 4), context),
                  width: 22,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _sourceDonut() {
    final src = _sources.take(6).toList();
    if (src.isEmpty) return _empty();
    return PieChart(
      duration: Duration.zero,
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 34,
        sections: [
          for (var i = 0; i < src.length; i++)
            PieChartSectionData(
              value: (src[i]['c'] as int).toDouble(),
              color: chartColorAt(i, context),
              radius: 26,
              showTitle: false,
            ),
        ],
      ),
    );
  }

  Widget _sourceLegend() {
    final src = _sources.take(6).toList();
    final total = _sources.fold<int>(0, (a, b) => a + (b['c'] as int));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < src.length; i++)
          LegendRow(
            color: chartColorAt(i, context),
            label: BookSource.fromString(src[i]['name'] as String?).label,
            count: '${src[i]['c']}',
            ratio: total == 0
                ? ''
                : '${((src[i]['c'] as int) * 100 / total).toStringAsFixed(1)}%',
          ),
      ],
    );
  }

  /* ------------------------------ 通用组件 ------------------------------ */

  Widget _sectionTitle(ThemeData theme, String title, String note) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
          ),
        ],
      );

  // 默认值不能是 appLoc.xxx：可选参数的默认值必须是编译期常量，
  // 而 appLoc 是运行时取值。改成可空参数，进函数体再取。
  Widget _empty([String? text]) => Center(
        child: Text(text ?? appLoc.s_f8525cf2,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  /// 一张图的「插槽」：隐藏时返回零尺寸，可见时带上与下一张的间距。
  ///
  /// 间距放在这里而不是每张卡后面写一遍，是为了让「关掉一张」的结果
  /// 是一段连续的内容，而不是留下双份空白。用 `SizedBox.shrink()`
  /// 而不是 `Visibility`：后者会保留 16+卡片高的占位，关掉跟没关
  /// 在滚动手感上没区别。
  Widget _chartSlot(String id, Widget card) => _showChart(id)
      ? Padding(padding: const EdgeInsets.only(bottom: 16), child: card)
      : const SizedBox.shrink();

  Widget _chartCard(String title,
      {String? subtitle,
      String? footnote,
      required double height,
      required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (subtitle != null)
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
          if (footnote != null) ...[
            const SizedBox(height: 8),
            Text(footnote,
                style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value, String unit) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 3),
                Text(unit,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 页面的取色一律走 `chartColorAt(i, context)`，也就是**当前皮肤**的色板。
///
/// 为什么必须带 context：活泼皮肤的纸色被主色浸染，共用色板会出现
/// 「某个系列与背景对比不足」——那不是不好看，是**数据看不见了**。
/// 阅读画像页用的是同一个入口，两处各写一份会让同一个分类在两个页面里
/// 是两种颜色。
///
/// 取色不再写 `% chartPalette.length`：调色板越界时 [chartColorAt]
/// 自己按黄金角旋出**不重复**的颜色，比取模复用更安全。

/// 「哪些图要显示」的设置抽屉。
///
/// 自己持有草稿状态，点「应用」才 `Navigator.pop` 回一个集合——
/// 边勾边写库会让「勾错了想反悔」变成一次真实的回写，
/// 用户回退的时候还得记住原来是什么样。
class _ChartSettingsSheet extends StatefulWidget {
  final Set<String> hidden;

  const _ChartSettingsSheet({required this.hidden});

  @override
  State<_ChartSettingsSheet> createState() => _ChartSettingsSheetState();
}

class _ChartSettingsSheetState extends State<_ChartSettingsSheet> {
  late Set<String> _hidden = {...widget.hidden};

  /// id → 图上那句标题。**每次都现取**，不能用 `static final` 的表：
  /// 这些都是本地化字符串，`final` 会把第一次打开时的语言钉死
  /// （与 `reading_profile.dart` 的 `_rules` 是同一个坑）。
  String _titleOf(String id) => switch (id) {
        StatsChart.status => appLoc.s_c6cc650b,
        StatsChart.category => appLoc.s_8137585d,
        StatsChart.trend => appLoc.s_50feb68a,
        StatsChart.readingTime => appLoc.s_4d7dd157,
        StatsChart.rating => appLoc.s_5b37ad6b,
        StatsChart.progress => appLoc.s_01d886c7,
        StatsChart.source => appLoc.s_ec977df0,
        _ => id,
      };

  void _toggle(String id, bool shown) => setState(() {
        if (shown) {
          _hidden.remove(id);
        } else {
          _hidden.add(id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final allShown = _hidden.isEmpty;
    final allHidden = _hidden.length == StatsChart.all.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appLoc.s_37361909,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(appLoc.s_e91a9228,
                style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),

            // 「全部显示 / 全部隐藏」一对快捷键。七张逐个点不算长，
            // 但用户调这个偏好时心里想的经常就是「先全清掉再挑」。
            Row(
              children: [
                TextButton(
                  onPressed: allShown ? null : () => setState(() => _hidden = {}),
                  child: Text(appLoc.s_b1288e4a),
                ),
                TextButton(
                  onPressed: allHidden
                      ? null
                      : () => setState(
                          () => _hidden = StatsChart.all.toSet()),
                  child: Text(appLoc.s_6b2b7015),
                ),
              ],
            ),

            // 七行开关不需要滚动：整块内容高度是固定的几百像素，
            // 直接铺开就好。
            //
            // ⚠️ 别在这里套 `Flexible` + `ListView(shrinkWrap: true)`：
            // 外层 Column 是 `MainAxisSize.min`（高度不限），Flexible 拿到
            // 的约束因此是「无上限」，shrinkWrap 的 ListView 会顺着这个
            // 无上限把自己撑到一个荒谬的高度——实测整张抽屉 1890px 高，
            // 底部那颗「应用」直接被顶到屏幕外，用户根本点不到。
            for (final id in StatsChart.all)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                // SwitchListTile 的 onChanged 收到的是「开关现在该
                // 处于什么状态」，而 _hidden 存的是「隐藏了没」，
                // 两者语义相反——这里显式取反，别图省事直接传。
                value: !_hidden.contains(id),
                onChanged: (v) => _toggle(id, v),
                title:
                    Text(_titleOf(id), style: const TextStyle(fontSize: 14)),
              ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(appLoc.s_a0451c97),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _hidden),
                  child: Text(appLoc.s_fe93ef35),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
