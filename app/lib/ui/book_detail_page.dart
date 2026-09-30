import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';

/// 书籍详情：元数据 + 进度 + 评分 + 摘要（Notion 原有功能）+ 笔记
class BookDetailPage extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  Book? _book;
  bool _loaded = false;
  final _summaryCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await ref.read(repoProvider).byId(widget.bookId);
    if (!mounted) return;
    setState(() {
      _book = b;
      // 必须区分「还在查」和「查到了但没有这本书」：
      // 只看 _book == null 会让被删除的书打开后永远停在加载动画。
      _loaded = true;
      _summaryCtrl.text = b?.summary ?? '';
      _reviewCtrl.text = b?.review ?? '';
    });
  }

  Future<void> _save() async {
    final b = _book;
    if (b == null) return;
    await ref.read(repoProvider).update(b.copyWith(
          summary: _summaryCtrl.text,
          review: _reviewCtrl.text,
        ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
    }
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _book;
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (b == null) {
      return const Scaffold(
        body: Center(child: Text('这本书不存在或已被删除')),
      );
    }
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [IconButton(icon: const Icon(Icons.save_outlined), onPressed: _save)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 90,
                  height: 126,
                  child: b.coverUrl != null
                      ? Image.network(b.coverUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300))
                      : Container(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    if (b.authors.isNotEmpty) Text('作者：${b.authors.join('、')}'),
                    if (b.translators.isNotEmpty) Text('译者：${b.translators.join('、')}'),
                    if (b.publisher != null) Text('出版社：${b.publisher!}'),
                    // 必须写 ${b.publishedAt}：Dart 里 "$b.publishedAt" 会被解析成
                    // "${b}.publishedAt"，界面上直接显示 "Instance of 'Book'.publishedAt"
                    // 数据源给的出版日期带完整时间戳（2026-08-28 00:00:00），
                    // 只取日期段展示，省掉界面上无意义的 00:00:00
                    if (b.publishedAt != null)
                      Text('出版：${b.publishedAt!.split(' ').first}'),
                    if (b.categoryPrimary != null) Text('分类：${b.categoryPrimary!}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        _chip(b.status.label, cs.primaryContainer, cs.onPrimaryContainer),
                        _chip(b.source.label, cs.surfaceContainerHighest, cs.onSurfaceVariant),
                        _chip(b.format.label, cs.surfaceContainerHighest, cs.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _section('阅读状态'),
          Wrap(
            spacing: 8,
            children: BookStatus.values
                .map((s) => ChoiceChip(
                      label: Text(s.label, style: const TextStyle(fontSize: 12)),
                      selected: b.status == s,
                      onSelected: (_) async {
                        final updated = b.copyWith(status: s);
                        await ref.read(repoProvider).update(updated);
                        setState(() => _book = updated);
                      },
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          _section('进度 ${b.progressPercent.toStringAsFixed(0)}%'),
          Slider(
            value: b.progressPercent.clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 20,
            label: '${b.progressPercent.toStringAsFixed(0)}%',
            onChanged: (v) => setState(() => _book = b.copyWith(progressPercent: v)),
            onChangeEnd: (v) async {
              final updated = b.copyWith(
                progressPercent: v,
                status: v >= 100 ? BookStatus.finished : BookStatus.reading,
              );
              await ref.read(repoProvider).update(updated);
              setState(() => _book = updated);
            },
          ),
          const SizedBox(height: 16),

          _section('评分'),
          Row(
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(
                  i < b.rating.round() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () async {
                  final updated = b.copyWith(rating: (i + 1).toDouble());
                  await ref.read(repoProvider).update(updated);
                  setState(() => _book = updated);
                },
              );
            }),
          ),
          const SizedBox(height: 16),

          _section('摘要'),
          TextField(
            controller: _summaryCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '记录这本书讲了什么（对应 Notion 里的摘要字段）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          _section('读后感'),
          TextField(
            controller: _reviewCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '你的评价与思考',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          if (b.description != null && b.description!.isNotEmpty) ...[
            _section('简介'),
            Text(b.description!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
          if (b.dueAt != null) ...[
            const SizedBox(height: 12),
            Text('应还日期：${b.dueAt}', style: TextStyle(color: cs.error)),
          ],
        ],
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg)),
    );
  }
}
