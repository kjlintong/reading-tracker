import '../l10n/app_loc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_client.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../providers.dart';
import 'theme.dart';

/// 公开书目搜索导入页。
///
/// 数据来自 Google Books + Open Library（见 [MetadataClient.search]），
/// 对国际用户是零门槛的一条路径：不需要账号、不需要 API Key，
/// 输入书名或 ISBN 就能把作者、出版社、封面、页数一次性带进来。
///
/// 这里刻意**不**做入库。选中的书回传给导入中心，由它复用既有的
/// `_run`（忙碌遮罩 + 错误提示）与 `_commit`（去重 + 元数据补全 +
/// 失败明细）——入库逻辑只应有一份收口，散成两处迟早会分叉。
class CatalogSearchPage extends ConsumerStatefulWidget {
  const CatalogSearchPage({super.key});

  @override
  ConsumerState<CatalogSearchPage> createState() => _CatalogSearchPageState();
}

class _CatalogSearchPageState extends ConsumerState<CatalogSearchPage> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  bool _searched = false;
  String? _error;
  List<MetadataResult> _results = const [];
  final Set<int> _selected = {};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _searched = true;
      _results = const [];
    });
    try {
      final r = await ref.read(metadataClientProvider).search(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _selected
          ..clear()
          // 只有一条结果时默认勾上，省用户一次点击
          ..addAll(r.length == 1 ? const {0} : const <int>{});
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _selected.clear();
        _error = appLoc.catalogSearchFailed(e: e.toString());
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit() {
    final picked = <Book>[];
    for (final i in _selected) {
      if (i < 0 || i >= _results.length) continue;
      final b = _toBook(_results[i]);
      if (b != null) picked.add(b);
    }
    Navigator.pop(context, picked);
  }

  /// MetadataResult → Book。
  ///
  /// source 统一记成 openlibrary（它同时涵盖 Google Books 这条上游），
  /// 这样统计与书架里能把「来自公开书目库」和「微信读书 / OCR」分开看。
  /// 只写 categoryRaw 而**不**写 categoryPrimary：归一化统一由
  /// ImportManager.commit 收口，这里若顺手写上就绕过了受控词表。
  static Book? _toBook(MetadataResult m) {
    final title = (m.title ?? '').trim();
    if (title.isEmpty) return null;
    return Book.create(title: title, source: BookSource.openlibrary).copyWith(
      authors: m.authors,
      publisher: m.publisher,
      publishedAt: m.publishedAt,
      isbn13: m.isbn13,
      coverUrl: m.coverUrl,
      pageCount: m.pageCount,
      description: m.description,
      tags: m.tags,
      categoryRaw: m.categoryPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogSearchTitle),
        actions: [
          if (_results.isNotEmpty) ...[
            TextButton(
              onPressed: () => setState(() =>
                  _selected.addAll(List.generate(_results.length, (i) => i))),
              child: Text(l10n.s_0f466d7a),
            ),
            TextButton(
              onPressed: () => setState(_selected.clear),
              child: Text(l10n.s_42b2fafa),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.catalogSearchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _search,
                  child: Text(l10n.catalogSearchAction),
                ),
              ],
            ),
          ),
          if (_error != null) _errorBox(context, _error!),
          Expanded(child: _body(context, l10n)),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.s_fdc0acd1(length: _selected.length)),
                ),
              ),
            ),
    );
  }

  Widget _body(BuildContext context, S l10n) {
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_searched) {
      return _hint(context, Icons.travel_explore_outlined, l10n.catalogSearchInitial);
    }
    if (_results.isEmpty) {
      return _hint(context, Icons.search_off_outlined, l10n.catalogNoResult);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _tile(ctx, i),
    );
  }

  Widget _hint(BuildContext context, IconData icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.error.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: cs.error)),
    );
  }

  Widget _tile(BuildContext context, int i) {
    final m = _results[i];
    final cs = Theme.of(context).colorScheme;
    final checked = _selected.contains(i);

    final meta = <String>[
      if (m.authors.isNotEmpty) m.authors.join(', '),
      if ((m.publisher ?? '').isNotEmpty) m.publisher!,
      if ((m.publishedAt ?? '').isNotEmpty) m.publishedAt!,
      if (m.pageCount != null) '${m.pageCount}p',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(
            () => checked ? _selected.remove(i) : _selected.add(i)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: checked,
                onChanged: (v) => setState(
                    () => v == true ? _selected.add(i) : _selected.remove(i)),
              ),
              _cover(context, m.coverUrl, cs),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (m.title ?? '').trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    if (meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ),
                    if ((m.description ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          m.description!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 封面缩略图。公开书库的封面链接经常 404 或超时，
  /// errorBuilder / loadingBuilder 都要给，否则列表会闪白块。
  static Widget _cover(BuildContext context, String? url, ColorScheme cs) {
    const w = 40.0, h = 56.0;
    final placeholder = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: panelColor(context, cs.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(Icons.menu_book_outlined, size: 18, color: cs.onSurfaceVariant),
    );
    if (url == null || url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (_, child, p) =>
            p == null ? child : placeholder,
      ),
    );
  }
}
