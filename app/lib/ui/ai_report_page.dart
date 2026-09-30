import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_client.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';

/// AI 阅读报告页。
///
/// 数据全部来自本地 SQLite，只把聚合后的统计摘要发给大模型，
/// 不上传任何书籍正文或笔记原文——阅读记录是高度私密的数据。
class AiReportPage extends ConsumerStatefulWidget {
  const AiReportPage({super.key});

  @override
  ConsumerState<AiReportPage> createState() => _AiReportPageState();
}

class _AiReportPageState extends ConsumerState<AiReportPage> {
  static const _periods = ['2026年至今', '近30天', '近90天', '全部时间'];

  String _period = _periods.first;
  bool _generating = false;
  bool _testing = false;
  String? _report;
  String? _error;
  String? _testResult;
  bool _testOk = false;
  Map<String, dynamic>? _metrics;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final rows = await ref.read(repoProvider).reports();
    if (mounted) setState(() => _history = rows);
  }

  /// 按周期过滤书目。
  ///
  /// 判定口径：读完的书看 finishedAt，未读完的看 updatedAt——
  /// 「近30天在读什么」同样是有意义的信息，不能只统计已读完的。
  List<Book> _filterByPeriod(List<Book> books) {
    final now = DateTime.now();
    DateTime? from;
    if (_period.startsWith('近')) {
      final days = int.tryParse(RegExp(r'\d+').stringMatch(_period) ?? '') ?? 30;
      from = now.subtract(Duration(days: days));
    } else if (_period.startsWith('2026')) {
      from = DateTime(2026, 1, 1);
    } else {
      return books; // 全部时间
    }

    bool inRange(String? iso) {
      if (iso == null || iso.isEmpty) return false;
      final d = DateTime.tryParse(iso);
      return d != null && !d.isBefore(from!);
    }

    return books.where((b) {
      if (b.status == BookStatus.finished) return inRange(b.finishedAt);
      return inRange(b.finishedAt) || inRange(b.updatedAt);
    }).toList();
  }

  /// 聚合本地数据为一份统计摘要。
  ///
  /// 刻意只发送统计值而非明细：既省 token，也避免把具体书名、
  /// 笔记内容传到外部服务。分布一律以**当前周期内的书**为基数，
  /// 否则「近30天」的报告里会出现全库的分类占比，前后自相矛盾。
  Future<Map<String, dynamic>> _buildSummary(List<Book> books) async {
    final repo = ref.read(repoProvider);

    final status = <String, int>{};
    for (final b in books) {
      status[b.status.label] = (status[b.status.label] ?? 0) + 1;
    }

    final categoryCount = <String, int>{};
    for (final b in books) {
      final k = b.categoryPrimary ?? '未分类';
      categoryCount[k] = (categoryCount[k] ?? 0) + 1;
    }
    final sourceCount = <String, int>{};
    for (final b in books) {
      sourceCount[b.source.label] = (sourceCount[b.source.label] ?? 0) + 1;
    }
    final categories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sources = sourceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final rated = books.where((b) => b.rating > 0).toList();
    final avgRating = rated.isEmpty
        ? 0.0
        : rated.map((b) => b.rating).reduce((a, b) => a + b) / rated.length;

    final finished = books.where((b) => b.status == BookStatus.finished).length;
    final reading = books.where((b) => b.status == BookStatus.reading).length;
    final wish = books.where((b) => b.status == BookStatus.wish).length;

    // 在读但进度极低 = 开了坑没填，是阅读结构里最值得指出的部分
    final stalled = books
        .where((b) => b.status == BookStatus.reading && b.progressPercent < 15)
        .length;

    final topRated = [...rated]..sort((a, b) => b.rating.compareTo(a.rating));

    Map<String, dynamic>? wereadStats;
    final raw = await repo.getSetting('wereadAnnualStats');
    if (raw != null) {
      try {
        wereadStats = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }

    return {
      'period': _period,
      'total': books.length,
      'finished': finished,
      'reading': reading,
      'wish': wish,
      'stalledReading': stalled,
      'statusCounts': status,
      'categoryDistribution':
          categories.map((e) => {'name': e.key, 'count': e.value}).toList(),
      'sourceDistribution':
          sources.map((e) => {'name': e.key, 'count': e.value}).toList(),
      'avgRating': double.parse(avgRating.toStringAsFixed(2)),
      'readingMinutes': await repo.totalReadingMinutes(),
      'streakDays': await repo.readingStreakDays(),
      'topRated': topRated
          .take(8)
          .map((b) => {'title': b.title, 'rating': b.rating, 'category': b.categoryPrimary})
          .toList(),
      if (wereadStats != null) 'wereadAnnual': wereadStats,
    };
  }

  /// 生成前先确认能连通。报告是长文本请求，等 3 分钟再报「连不上」
  /// 是最差的体验，不如花 1 秒先探一下。
  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final ping = await ref.read(llmClientProvider).testConnection();
      if (mounted) {
        setState(() {
          _testOk = true;
          _testResult = '连通正常 · ${ping.model} · ${ping.latencyMs} ms';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testOk = false;
          _testResult = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _generate() async {
    final llm = ref.read(llmClientProvider);
    final key = ref.read(llmKeyProvider);

    if (key == null || key.isEmpty) {
      setState(() => _error = '未配置大模型 Key，请先到「设置 → 大模型」填写并测试连通性');
      return;
    }
    if (ref.read(llmModelProvider).trim().isEmpty) {
      setState(() => _error = '未选择模型，请到「设置 → 大模型」点「拉取模型」选一个');
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
      _report = null;
    });

    try {
      final all = await ref.read(repoProvider).all();
      final books = _filterByPeriod(all);
      if (books.isEmpty) {
        if (mounted) {
          setState(() {
            _error = '该周期内没有阅读记录，换个时间范围试试';
            _generating = false;
          });
        }
        return;
      }
      final summary = await _buildSummary(books);
      final text = await llm.generateReport(_period, summary);
      if (text.trim().isEmpty) {
        throw LlmException('模型返回了空内容',
            hint: '可能是模型不支持当前参数，或触发了内容过滤，换一个模型再试');
      }

      await ref.read(repoProvider).saveReport(
            period: _period,
            model: ref.read(llmModelProvider),
            content: text,
            metrics: summary,
          );

      if (mounted) {
        setState(() {
          _report = text;
          _metrics = summary;
          _generating = false;
        });
        await _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is LlmException ? e.toString() : '生成失败：$e';
          _generating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final model = ref.watch(llmModelProvider);
    final base = ref.watch(llmBaseUrlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('阅读报告')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 周期选择
          Wrap(
            spacing: 8,
            children: _periods.map((p) {
              final sel = p == _period;
              return ChoiceChip(
                label: Text(p),
                selected: sel,
                onSelected: (_) => setState(() => _period = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 当前使用的模型，出问题时第一眼要看的就是这两行
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.memory, size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$model · $base',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
                TextButton(
                  onPressed: _testing ? null : _test,
                  child: Text(_testing ? '测试中…' : '测试连接',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          if (_testResult != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _testOk ? cs.primaryContainer : cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _testResult!,
                style: TextStyle(
                  fontSize: 12,
                  color: _testOk ? cs.onPrimaryContainer : cs.onErrorContainer,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_generating ? '生成中…（长文本约需 1 分钟）' : '生成报告'),
          ),
          const SizedBox(height: 8),

          const Text(
            '仅把聚合统计（数量、分布、平均分）发送给大模型，'
            '不上传书名清单、笔记或划线内容。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          // 本次生成所依据的统计口径，让用户知道模型看到了什么
          if (_metrics != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: '纳入统计', value: '${_metrics!['total']} 本'),
                _StatChip(label: '已读完', value: '${_metrics!['finished']} 本'),
                _StatChip(label: '在读', value: '${_metrics!['reading']} 本'),
                _StatChip(label: '想读', value: '${_metrics!['wish']} 本'),
                _StatChip(label: '平均分', value: '${_metrics!['avgRating']}'),
              ],
            ),
          ],

          if (_report != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text('报告内容', style: theme.textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: '复制全文',
                  icon: const Icon(Icons.copy_all_outlined),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _report!));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('报告已复制到剪贴板')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectionArea(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_report!, style: const TextStyle(height: 1.6, fontSize: 14)),
              ),
            ),
          ],

          if (_history.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('历史报告', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._history.map((r) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(r['period'] as String? ?? ''),
                  subtitle: Text(
                    '${r['model'] ?? ''} · ${(r['generatedAt'] as String? ?? '').replaceAll('T', ' ').split('.').first}',
                  ),
                  onTap: () => setState(() {
                    _report = r['content'] as String?;
                    _period = r['period'] as String? ?? _period;
                  }),
                )),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
