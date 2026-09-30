import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_client.dart';
import '../data/weread_annual.dart';
import '../models/enums.dart';
import '../providers.dart';

/// 统计看板：规模、结构、节奏三块。
///
/// 图表一律传 `duration: Duration.zero`：默认的入场动画会让
/// 界面截图抓到长到一半的柱子，也让「点进来立刻看数字」变成等动画。
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  Map<BookStatus, int> _status = {};
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _trend = [];
  List<Map<String, dynamic>> _ratings = [];
  List<Map<String, dynamic>> _progress = [];
  WereadAnnualStats? _annual;
  int _minutes = 0;
  int _streak = 0;
  int _total = 0;
  double _avgRating = 0;
  bool _loading = true;
  String? _report;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final year = DateTime.now().year;
    final results = await Future.wait([
      repo.statusCounts(),
      repo.categoryDistribution(),
      repo.sourceDistribution(),
      repo.monthlyFinishedTrend(year),
      repo.totalReadingMinutes(),
      repo.readingStreakDays(),
      repo.ratingBuckets(),
      repo.progressBuckets(),
      repo.averageRating(),
      repo.all(),
      repo.wereadAnnualStats(),
    ]);
    if (!mounted) return;
    setState(() {
      _status = results[0] as Map<BookStatus, int>;
      _categories = results[1] as List<Map<String, dynamic>>;
      _sources = results[2] as List<Map<String, dynamic>>;
      _trend = results[3] as List<Map<String, dynamic>>;
      _minutes = results[4] as int;
      _streak = results[5] as int;
      _ratings = results[6] as List<Map<String, dynamic>>;
      _progress = results[7] as List<Map<String, dynamic>>;
      _avgRating = results[8] as double;
      _total = (results[9] as List).length;
      _annual = results[10] as WereadAnnualStats?;
      _loading = false;
    });
  }

  Future<void> _generateReport() async {
    final llm = ref.read(llmClientProvider);
    if (!llm.available) {
      setState(() => _report = '请先在「设置 → 大模型」配置 API Key');
      return;
    }
    setState(() {
      _generating = true;
      _report = null;
    });
    try {
      final repo = ref.read(repoProvider);
      final finished = await repo.finishedInYear(DateTime.now().year);
      final text = await llm.generateReport('本年度', {
        '读完本数': finished.length,
        '总阅读时长分钟': _minutes,
        '连续阅读天数': _streak,
        '状态分布': {for (final e in _status.entries) e.key.label: e.value},
        '分类分布': {
          for (final c in _categories) c['name'] as String: c['c'] as int
        },
        '平台分布': {for (final s in _sources) s['name'] as String: s['c'] as int},
        '平均评分': double.parse(_avgRating.toStringAsFixed(2)),
        '读完的书': finished
            .map((b) => {
                  '书名': b.title,
                  '作者': b.authors.join('、'),
                  '分类': b.categoryPrimary,
                  '评分': b.rating,
                  '完成日期': b.finishedAt,
                })
            .toList(),
      });
      if (mounted) setState(() => _report = text);
    } catch (e) {
      if (mounted) setState(() => _report = '生成失败：${describeLlmError(e)}');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cs = Theme.of(context).colorScheme;
    final finished = _status[BookStatus.finished] ?? 0;
    final reading = _status[BookStatus.reading] ?? 0;
    final wish = _status[BookStatus.wish] ?? 0;
    final abandoned = _status[BookStatus.abandoned] ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /* ----------------------------- 规模 ----------------------------- */
          Row(children: [
            _metric('总藏书', '$_total', '本'),
            const SizedBox(width: 10),
            _metric('已读完', '$finished', '本'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric('在读', '$reading', '本'),
            const SizedBox(width: 10),
            _metric('想读', '$wish', '本'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric('阅读时长',
                _minutes >= 60
                    ? (_minutes / 60).toStringAsFixed(1)
                    : '$_minutes',
                _minutes >= 60 ? '小时' : '分钟'),
            const SizedBox(width: 10),
            _metric('日均阅读', _dayAvgLabel, _dayAvgUnit),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric('年度阅读', _annual == null ? '—' : '${_annual!.readDays}', '天'),
            const SizedBox(width: 10),
            _metric('连续阅读', '$_streak', '天'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _metric('平均评分',
                _avgRating > 0 ? _avgRating.toStringAsFixed(1) : '—', '分'),
            const SizedBox(width: 10),
            _metric('弃读', '$abandoned', '本'),
          ]),
          if (_minutes == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '阅读时长来自微信读书同步（「导入 → 同步阅读进度」）与手工记录。'
                '还没同步过就会是 0。',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            )
          else if (_annual != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '阅读时长与日均取自微信读书 ${_annual!.year} 年度统计'
                '（全年 ${_annual!.readDays} 天有阅读记录）。',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 20),

          /* ----------------------------- 结构 ----------------------------- */
          _chartCard(
            '阅读状态分布',
            subtitle: '共 $_total 本',
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
          const SizedBox(height: 16),

          _chartCard(
            '分类分布 Top 8',
            subtitle: _categories.isEmpty ? null : '共 ${_categories.length} 个分类',
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
          const SizedBox(height: 16),

          _chartCard(
            '${DateTime.now().year} 年月度读完',
            subtitle: _trend.isEmpty ? null : '合计 ${_trendTotal()} 本',
            height: 180,
            child: _trend.isEmpty ? _empty('今年还没有读完的书') : _trendLine(),
          ),
          const SizedBox(height: 16),

          // 阅读节奏：这是整份年度统计里最值钱的一段数据，
          // 能一眼看出「哪几个月真的在读、哪几个月断了」
          _chartCard(
            '月度阅读时长',
            subtitle: (_annual == null || _annual!.monthly.isEmpty)
                ? null
                : '${_annual!.year} 年 · 合计 '
                    '${(_annual!.totalReadSec / 3600).toStringAsFixed(1)} 小时',
            height: 180,
            child: (_annual == null || _annual!.monthly.isEmpty)
                ? _empty('导入微信读书年度统计后显示')
                : _readingTimeBars(),
          ),
          const SizedBox(height: 16),

          _chartCard(
            '评分分布',
            subtitle: _ratedCount == 0
                ? null
                : '平均 ${_avgRating > 0 ? _avgRating.toStringAsFixed(1) : '—'} 分'
                    ' · 未评分 $_unratedCount 本',
            height: 170,
            // 判空要看「有没有评过分」，而不是「有没有书」——
            // 38 本示例书一本没评，图里会是 5 根 0 高的柱子，比空态还误导
            child: _ratedCount == 0 ? _empty('还没有评过分') : _ratingBars(),
          ),
          const SizedBox(height: 16),

          _chartCard(
            '在读进度分布',
            subtitle: '共 $reading 本在读',
            height: 170,
            child: reading == 0
                ? _empty('当前没有在读的书')
                : _progressBars(),
          ),
          const SizedBox(height: 16),

          _chartCard(
            '来源平台',
            subtitle: _sources.isEmpty ? null : '共 ${_sources.length} 个平台',
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
          const SizedBox(height: 24),

          /* ----------------------------- AI 报告 ----------------------------- */
          Text('AI 阅读报告', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _generating ? null : _generateReport,
            icon: _generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_generating ? '生成中…' : '生成分析报告'),
          ),
          if (_report != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(_report!, style: const TextStyle(fontSize: 13)),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /* ------------------------------ 图表 ------------------------------ */

  int _trendTotal() =>
      _trend.fold<int>(0, (a, b) => a + (b['c'] as int));

  /// 日均阅读：优先用微信读书给的口径；没导入过就退回「总时长 / 有记录的天数」。
  /// 绝不能拿「总时长 / 365」凑——那会把只用了三个月的用户压成一个假数字。
  /// 已评分 / 未评分的本数。`_ratings[0]` 是「未评分」档，其余 1~5 星。
  int get _unratedCount =>
      _ratings.isEmpty ? 0 : (_ratings.first['count'] as int);

  int get _ratedCount => _ratings
      .where((e) => (e['stars'] as int) > 0)
      .fold<int>(0, (a, b) => a + (b['count'] as int));

  int get _dayAvgMinutes {
    final a = _annual;
    if (a != null && a.dayAvgReadSec > 0) return a.dayAvgMinutes;
    if (a != null && a.readDays > 0) return (a.totalReadSec / a.readDays / 60).round();
    return 0;
  }

  String get _dayAvgLabel {
    final m = _dayAvgMinutes;
    if (m <= 0) return '—';
    if (m >= 60) return (m / 60).toStringAsFixed(1);
    return '$m';
  }

  String get _dayAvgUnit {
    final m = _dayAvgMinutes;
    if (m <= 0) return '';
    return m >= 60 ? '小时' : '分钟';
  }

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
              color: _palette[i % _palette.length],
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
            _legendRow(
              _palette[_statusColorIndex(BookStatus.values[i]) % _palette.length],
              BookStatus.values[i].label,
              '${_status[BookStatus.values[i]]}',
              _ratioOf(_status[BookStatus.values[i]] ?? 0),
            ),
      ],
    );
  }

  /// 颜色跟着状态走，不跟着「谁先出现」走——
  /// 否则筛选别的数据时同一个状态会换颜色
  int _statusColorIndex(BookStatus s) {
    final present = BookStatus.values.where((e) => (_status[e] ?? 0) > 0).toList();
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
    final maxY = data
        .map((e) => (e['c'] as int).toDouble())
        .fold<double>(0, math.max);
    final cs = Theme.of(context).colorScheme;

    return BarChart(
      duration: Duration.zero,
      BarChartData(
        maxY: (maxY + 1).ceilToDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final name = data[group.x]['name'] as String;
              return BarTooltipItem(
                '$name\n${rod.toY.toInt()} 本',
                TextStyle(color: cs.onInverseSurface, fontSize: 12),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY + 1) <= 4 ? 1 : ((maxY + 1) / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  color: _palette[i % _palette.length],
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
    final total =
        _categories.fold<int>(0, (a, b) => a + (b['c'] as int));
    return Column(
      children: [
        for (var i = 0; i < _categories.length && i < 8; i++)
          _legendRow(
            _palette[i % _palette.length],
            _categories[i]['name'] as String,
            '${_categories[i]['c']}',
            total == 0
                ? ''
                : '${((_categories[i]['c'] as int) * 100 / total).toStringAsFixed(1)}%',
          ),
      ],
    );
  }

  Widget _trendLine() {
    final cs = Theme.of(context).colorScheme;
    final byMonth = <int, int>{};
    for (final t in _trend) {
      final m = int.tryParse((t['month'] as String).substring(5));
      if (m != null) byMonth[m] = t['c'] as int;
    }
    final maxY = (byMonth.values.isEmpty
            ? 1
            : byMonth.values.reduce(math.max))
        .toDouble();

    return LineChart(
      duration: Duration.zero,
      LineChartData(
        minX: 1,
        maxX: 12,
        minY: 0,
        maxY: maxY + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max(1, (maxY + 1) / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant.withOpacity(0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: math.max(1, (maxY + 1) / 4).ceilToDouble(),
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
                final m = v.toInt();
                if (m < 1 || m > 12) return const SizedBox.shrink();
                // 每两个月标一次，12 个月标签全挤在手机上会糊成一团
                if (m % 2 != 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('$m月',
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.x.toInt()} 月 · ${s.y.toInt()} 本',
                      TextStyle(color: cs.onInverseSurface, fontSize: 12),
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            curveSmoothness: 0.25,
            color: _palette[0],
            barWidth: 2.5,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: _palette[0].withOpacity(0.15),
            ),
            spots: [
              for (var m = 1; m <= 12; m++)
                FlSpot(m.toDouble(), (byMonth[m] ?? 0).toDouble()),
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
    final monthly = _annual!.monthly;
    final byMonth = <int, double>{
      for (final m in monthly) m.month: m.hours,
    };
    final maxY = byMonth.values.isEmpty ? 1.0 : byMonth.values.reduce(math.max);
    // 单个高月会把其他月压成一条线，所以按「够读的刻度」取整。
    // 注意 1.0 不能写成 1：math.max 的返回类型由两个实参决定，
    // 一个 int 一个 double 会推出 num，赋值给 double? 就报类型错。
    final axisMax = maxY <= 4 ? 4.0 : (maxY * 1.15).ceilToDouble();
    final interval = math.max(1.0, (axisMax / 4).ceilToDouble());
    final emptyMonth = _palette[3].withOpacity(0.25);

    return BarChart(
      duration: Duration.zero,
      BarChartData(
        maxY: axisMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) {
              final m = group.x + 1;
              return BarTooltipItem(
                '$m 月 · ${rod.toY.toStringAsFixed(1)} 小时',
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: interval,
              getTitlesWidget: (v, meta) => Text(
                v == v.roundToDouble()
                    ? v.toInt().toString()
                    : v.toStringAsFixed(1),
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, meta) {
                final m = v.toInt();
                if (m < 1 || m > 12) return const SizedBox.shrink();
                // 12 个标签挤在手机上会糊成一团，隔一个标一次
                if (m % 2 != 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('$m月',
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var m = 1; m <= 12; m++)
            BarChartGroupData(
              x: m - 1,
              barRods: [
                BarChartRodData(
                  toY: byMonth[m] ?? 0,
                  // 没读的月份画一根淡柱，而不是留空——
                  // 留空会让「连续几个月断了」这件事彻底隐身
                  color: (byMonth[m] ?? 0) > 0
                      ? _palette[1]
                      : emptyMonth,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
    // 同轴放一起会毁掉这张图：实测种子库 100 本未评分、每档星约 7 本，
    // 未评分的柱子顶满坐标轴，1~5 星被压成看不见的细线——
    // 图还在，信息为零。「有几本没评分」属于副标题，不属于分布本身。
    final rated = _ratings.where((e) => (e['stars'] as int) > 0).toList();
    final maxY =
        rated.map((e) => (e['count'] as int).toDouble()).fold<double>(0, math.max);
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  color: _palette[i % _palette.length],
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _progressBars() {
    final cs = Theme.of(context).colorScheme;
    final maxY = _progress
        .map((e) => (e['count'] as int).toDouble())
        .fold<double>(0, math.max);
    final interval = math.max(1, (maxY + 1) / 3).ceilToDouble();

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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                if (i < 0 || i >= _progress.length) return const SizedBox.shrink();
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
                  color: _palette[(i + 4) % _palette.length],
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
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
              color: _palette[i % _palette.length],
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
          _legendRow(
            _palette[i % _palette.length],
            BookSource.fromString(src[i]['name'] as String?).label,
            '${src[i]['c']}',
            total == 0
                ? ''
                : '${((src[i]['c'] as int) * 100 / total).toStringAsFixed(1)}%',
          ),
      ],
    );
  }

  /* ------------------------------ 通用组件 ------------------------------ */

  Widget _legendRow(Color color, String label, String count, String ratio) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ),
          Text(count,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
          if (ratio.isNotEmpty) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 42,
              child: Text(ratio,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty([String text = '暂无数据']) => Center(
        child: Text(text,
            style: TextStyle(
                fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _chartCard(String title, {String? subtitle, required double height, required Widget child}) {
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (subtitle != null)
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: height, child: child),
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

/// 图表配色。取中间明度的色相环，深浅两种主题下都够清楚，
/// 不依赖 colorScheme —— 主题色只有一组，六张图会全糊成同一个绿。
const List<Color> _palette = [
  Color(0xFF5B8FF9),
  Color(0xFF61DDAA),
  Color(0xFFF6BD16),
  Color(0xFF7262FD),
  Color(0xFF78D3F8),
  Color(0xFF9661BC),
  Color(0xFFF6903D),
  Color(0xFF008685),
];
