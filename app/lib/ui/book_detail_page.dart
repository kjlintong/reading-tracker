import 'dart:async';
import '../l10n/app_loc.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/reading_plan.dart';
import '../providers.dart';
import 'book_form_page.dart';
import 'book_cover.dart';
import 'status_editor.dart';

/// 书籍详情：元数据 + 进度 + 评分 + 摘要 + 读后感 + 笔记
class BookDetailPage extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  Book? _book;
  bool _loaded = false;
  List<Note> _notes = const [];
  final _summaryCtrl = TextEditingController();
  final _reviewCtrl = TextEditingController();

  /// 摘要 / 读后感的自动保存防抖。用户停下打字 800ms 才落库，
  /// 边打边存既费 I/O 又会让「已保存」提示疯狂闪。
  Timer? _saveDebounce;

  /// 借阅来源输入框的防抖，与上面同理。
  Timer? _borrowDebounce;

  /// 缓存 repo：dispose 阶段不能再碰 ref（widget 正被卸载），
  /// 但离开页面前要补存一次还没落库的编辑，所以得留个引用。
  BookRepository? _repo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    _repo = repo;
    final b = await repo.byId(widget.bookId);
    final notes = await repo.notesOf(widget.bookId);
    if (!mounted) return;
    setState(() {
      _book = b;
      // 必须区分「还在查」和「查到了但没有这本书」：
      // 只看 _book == null 会让被删除的书打开后永远停在加载动画。
      _loaded = true;
      _notes = notes;
      _summaryCtrl.text = b?.summary ?? '';
      _reviewCtrl.text = b?.review ?? '';
    });
  }

  Future<void> _reloadNotes() async {
    final notes = await ref.read(repoProvider).notesOf(widget.bookId);
    if (!mounted) return;
    setState(() => _notes = notes);
  }

  /// 防抖触发一次落库。用户按住打字时不写，停下来才写。
  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), _persist);
  }

  Future<void> _persist({bool duringDispose = false}) async {
    final b = _book;
    final repo = _repo;
    if (b == null || repo == null) return;
    final next = b.copyWith(
      summary: _summaryCtrl.text,
      review: _reviewCtrl.text,
    );
    // 先在内存里更新，避免同一次编辑期间再次触发时用旧值覆盖
    if (!duringDispose && mounted) setState(() => _book = next);
    await repo.update(next);
  }

  /* ------------------------- 笔记 ------------------------- */

  Future<void> _addNote() async {
    final saved = await _editNoteDialog(null);
    if (saved == null) return;
    await ref.read(repoProvider).addNote(saved);
    await _reloadNotes();
  }

  Future<void> _updateNote(Note n) async {
    final saved = await _editNoteDialog(n);
    if (saved == null) return;
    await ref.read(repoProvider).updateNote(saved);
    await _reloadNotes();
  }

  Future<void> _removeNote(Note n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:  Text(appLoc.s_f24f63da),
        content:
            Text(n.content.length > 40 ? '${n.content.substring(0, 40)}…' : n.content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:  Text(appLoc.s_a0451c97)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:  Text(appLoc.s_ecbd7449)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(repoProvider).deleteNote(n.id);
    await _reloadNotes();
  }

  /// 笔记编辑弹窗：类型 + 正文。返回 null 表示取消。
  Future<Note?> _editNoteDialog(Note? initial) async {
    final ctrl = TextEditingController(text: initial?.content ?? '');
    final chapterCtrl = TextEditingController(text: initial?.chapter ?? '');
    var type = initial?.type ?? NoteType.thought;

    final result = await showDialog<({String content, NoteType type, String? chapter})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(initial == null ? appLoc.s_f98a79dc : appLoc.s_05712ea1),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in NoteType.values)
                      ChoiceChip(
                        label: Text(t.label, style: const TextStyle(fontSize: 12)),
                        selected: type == t,
                        onSelected: (_) => setLocal(() => type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrl,
                  autofocus: initial == null,
                  maxLines: 6,
                  minLines: 4,
                  decoration:  InputDecoration(
                    hintText: appLoc.s_e3fdcb7e,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: chapterCtrl,
                  decoration:  InputDecoration(
                    labelText: appLoc.s_c8d8fada,
                    hintText: appLoc.s_f80f4749,
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child:  Text(appLoc.s_a0451c97)),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                (
                  content: ctrl.text.trim(),
                  type: type,
                  chapter: chapterCtrl.text.trim().isEmpty
                      ? null
                      : chapterCtrl.text.trim(),
                ),
              ),
              child:  Text(appLoc.s_abfe9512),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.content.isEmpty) return null;
    final now = DateTime.now().toIso8601String();
    if (initial != null) {
      return Note(
        id: initial.id,
        bookId: initial.bookId,
        type: result.type,
        content: result.content,
        chapter: result.chapter,
        source: initial.source,
        createdAt: initial.createdAt,
      );
    }
    return Note(
      id: 'note_${DateTime.now().microsecondsSinceEpoch}',
      bookId: widget.bookId,
      type: result.type,
      content: result.content,
      chapter: result.chapter,
      createdAt: now,
    );
  }

  /* ------------------------- 编辑 ------------------------- */

  /// 打开全屏表单编辑这本书。
  ///
  /// 表单返回的是一个**新构造的 Book**（见 [showBookForm]），不是 patch。
  /// 所以这里不能拿它直接覆盖——它只承载表单里那几个字段，
  /// 摘要/读后感/笔记这些由详情页自己维护的内容不在表单范围内，
  /// 直接覆盖会把用户刚写的东西抹掉。改为把表单管的字段搬回当前对象上。
  Future<void> _edit() async {
    final b = _book;
    if (b == null) return;
    final edited = await showBookForm(context, initial: b);
    if (edited == null || !mounted) return;

    final merged = b.copyWith(
      title: edited.title,
      authors: edited.authors,
      categoryPrimary: edited.categoryPrimary,
      categoryRaw: edited.categoryRaw,
      description: edited.description,
      coverLocalPath: edited.coverLocalPath,
      format: edited.format,
      status: edited.status,
      rating: edited.rating,
      progressPercent: edited.progressPercent,
      finishedAt: edited.finishedAt,
    );
    await ref.read(repoProvider).update(merged);
    if (!mounted) return;
    setState(() => _book = merged);
  }

  /// 改一个字段并落库。状态/借阅这类离散操作共用。
  ///
  /// 先 setState 再写库：状态切换要立刻反馈，等一次 SQLite 往返
  /// 会让点击看起来像没反应。DB 很快，失败概率可以忽略，
  /// 真失败了下次进页面也能看到真实值。
  Future<void> _patch(Book next) async {
    setState(() => _book = next);
    await ref.read(repoProvider).update(next);
  }

  void _setStatus(BookStatus s) {
    final b = _book;
    if (b == null) return;
    // 标成「已读」顺手把进度补到 100%、完成时间补上，与表单口径一致：
    // 不补的话「今年读完」的统计会漏掉这本
    final iso = DateTime.now().toIso8601String();
    _patch(b.copyWith(
      status: s,
      progressPercent: s == BookStatus.finished ? 100 : b.progressPercent,
      finishedAt: s == BookStatus.finished ? (b.finishedAt ?? iso) : b.finishedAt,
    ));
  }

  void _setBorrowed(bool v) {
    final b = _book;
    if (b == null) return;
    // 关掉借阅时顺手清掉来源与应还日期：留着会出现
    // 「没标借阅但还显示应还日期」的矛盾状态。
    _patch(v
        ? b.copyWith(isBorrowed: true)
        : Book.fromMap({
            ...b.toMap(),
            'isBorrowed': 0,
            'borrowedFrom': null,
            'dueAt': null,
          }));
  }

  /// 借阅来源是文本框，走防抖，别每敲一个字写一次库。
  void _setBorrowedFrom(String v) {
    final b = _book;
    if (b == null) return;
    final next = b.copyWith(borrowedFrom: v.trim().isEmpty ? null : v.trim());
    _borrowDebounce?.cancel();
    _borrowDebounce =
        Timer(const Duration(milliseconds: 700), () => _patch(next));
  }

  void _setDueAt(String? iso) {
    final b = _book;
    if (b == null) return;
    // copyWith 用 `?? this.x` 兜底，传 null 清不掉字段，清除日期要走 fromMap
    _patch(iso == null
        ? Book.fromMap({...b.toMap(), 'dueAt': null})
        : b.copyWith(dueAt: iso));
  }

  /// 标记已归还。
  ///
  /// 三件事，缺一不可：
  ///  1. 清空借阅三件套（isBorrowed / borrowedFrom / dueAt）；
  ///  2. **撤销这本书的还书提醒**——只清数据不撤通知的话，
  ///     书明明已经还了，手机过几天还会准时响一句「这本书快到期了」；
  ///  3. 给一句确认反馈。这一步没有可见的状态跳转（开关只是关掉），
  ///     不给提示用户会怀疑到底有没有点中。
  ///
  /// 提醒是挂在「阅读计划」上的（[PlanKind.finishBook]，id 为计划 id），
  /// 所以撤提醒要先找出指向这本书、且开着提醒的计划，再逐条 cancel。
  /// 放在落库**之后**：数据先存住，通知撤不掉也只是多响一声，
  /// 反过来则是数据丢了提醒还在，问题更大。
  Future<void> _markReturned() async {
    final b = _book;
    if (b == null) return;
    _borrowDebounce?.cancel();
    await _patch(Book.fromMap({
      ...b.toMap(),
      'isBorrowed': 0,
      'borrowedFrom': null,
      'dueAt': null,
    }));
    await _cancelReturnReminders(b.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(appLoc.borrowReturned)));
  }

  /// 撤销指向 [bookId] 的还书提醒。任何一步失败都不影响归还本身。
  Future<void> _cancelReturnReminders(String bookId) async {
    try {
      final repo = ref.read(repoProvider);
      final reminders = ref.read(planReminderProvider);
      for (final p in await repo.plans()) {
        if (p.kind != PlanKind.finishBook || p.bookId != bookId) continue;
        if (!p.reminderEnabled) continue;
        await reminders.cancel(p.id);
      }
    } catch (_) {
      // 通知通道在测试 / 未授权平台本就不可用，静默即可
    }
  }

  @override
  void dispose() {
    // 离开页面前把还没落库的编辑补存一次，否则「打完字立刻返回」
    // 会因为防抖计时器被取消而丢内容。
    // 这里走 duringDispose：不能再 setState，也不能碰 ref。
    if (_saveDebounce?.isActive ?? false) {
      _saveDebounce!.cancel();
      _persist(duringDispose: true);
    }
    _borrowDebounce?.cancel();
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
      return  Scaffold(
        body: Center(child: Text(appLoc.s_a647c2e0)),
      );
    }
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          // 编辑入口放在这里而不是页面底部：添加完一本书之后想改封面/分类
          // 是很自然的需求，但在旧版界面里**根本没有入口**——
          // 只能删掉重加，等于把已经写下的笔记和进度一起丢掉。
          IconButton(
            tooltip: appLoc.s_6c7a6cc5,
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                height: 126,
                // 走共用 BookCover：本地封面优先于远程 URL。
                // 以前这里只判 coverUrl，用户在表单里选的本地封面
                // 保存后永远显示不出来，看起来像「保存没生效」。
                child: BookCover(book: b, radius: 6, placeholderFontSize: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    if (b.authors.isNotEmpty) Text(appLoc.s_154ada37(join: b.authors.join(appLoc.s_f5d99c16))),
                    if (b.translators.isNotEmpty) Text(appLoc.s_904feb6c(join: b.translators.join(appLoc.s_f5d99c16))),
                    if (b.publisher != null) Text(appLoc.s_1e4c61f8(publisher: b.publisher!)),
                    // 必须写 ${b.publishedAt}：Dart 里 "$b.publishedAt" 会被解析成
                    // "${b}.publishedAt"，界面上直接显示 "Instance of 'Book'.publishedAt"
                    // 数据源给的出版日期带完整时间戳（2026-08-28 00:00:00），
                    // 只取日期段展示，省掉界面上无意义的 00:00:00
                    if (b.publishedAt != null)
                      Text(appLoc.s_bf93bf6d(first: b.publishedAt!.split(' ').first)),
                    // 分类：以前只在有值时显示一行纯文本，且混在作者/出版社
                    // 那一堆里很不起眼。现在做成带标签的行，没有分类时
                    // 显示「未分类」而不是整行消失——否则用户会以为
                    // 这本书的分类丢了，而不是「还没填」。
                    Text(
                      appLoc.s_def61e8c(
                        categoryPrimary: categoryLabel(
                            b.categoryPrimary ?? kUncategorized),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _chip(b.status.label, cs.primaryContainer,
                            cs.onPrimaryContainer),
                        // 借阅标记：和状态并排。它是「书不是我的」这件事，
                        // 与状态正交，所以是额外一枚而不是替换状态那枚
                        if (b.isBorrowed)
                          _chip(
                            appLoc.borrowTitle,
                            cs.tertiaryContainer,
                            cs.onTertiaryContainer,
                          ),
                        _chip(b.source.label, cs.surfaceContainerHighest,
                            cs.onSurfaceVariant),
                        _chip(b.format.label, cs.surfaceContainerHighest,
                            cs.onSurfaceVariant),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          StatusEditor(
            status: b.status,
            isBorrowed: b.isBorrowed,
            borrowedFrom: b.borrowedFrom,
            dueAt: b.dueAt,
            onStatusChanged: _setStatus,
            onBorrowedChanged: _setBorrowed,
            onBorrowedFromChanged: _setBorrowedFrom,
            onDueAtChanged: _setDueAt,
            // 只有借阅中的书才有「归还」这个动作；传 null 时控件自己会
            // 把按钮藏起来，不用在这里包一层 if。
            onReturned: b.isBorrowed ? _markReturned : null,
          ),
          const SizedBox(height: 16),

          _section(appLoc.s_94b27e86(toStringAsFixed: b.progressPercent.toStringAsFixed(0))),
          Slider(
            value: b.progressPercent.clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 20,
            label: '${b.progressPercent.toStringAsFixed(0)}%',
            onChanged: (v) => setState(() => _book = b.copyWith(progressPercent: v)),
            onChangeEnd: (v) async {
              // 进度与状态联动：到 100% 视为读完，不满 100% 视为在读。
              // 但**不能覆盖用户明确选过的「搁置」**——他可能就是读到一半
              // 决定不读了，此时动一下进度滑块就把状态改回「在读」，
              // 等于把用户的判断抹掉了。「想读」同理：拖进度说明已经开始读，
              // 所以它会被升成「在读」，这是期望行为。
              final BookStatus next;
              if (v >= 100) {
                next = BookStatus.finished;
              } else if (b.status == BookStatus.shelved) {
                next = BookStatus.shelved;
              } else {
                next = BookStatus.reading;
              }
              await _patch(b.copyWith(
                progressPercent: v,
                status: next,
                // 自动标已读时补完成时间，否则统计里「今年读完」会漏
                finishedAt: next == BookStatus.finished
                    ? (b.finishedAt ?? DateTime.now().toIso8601String())
                    : b.finishedAt,
              ));
            },
          ),
          const SizedBox(height: 16),

          _section(appLoc.s_8331377a),
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

          _section(appLoc.s_205eb716),
          TextField(
            controller: _summaryCtrl,
            maxLines: 5,
            onChanged: (_) => _scheduleSave(),
            decoration:  InputDecoration(
              hintText: appLoc.s_b5e2aa8a,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          _section(appLoc.s_3ec1ca86),
          TextField(
            controller: _reviewCtrl,
            maxLines: 5,
            onChanged: (_) => _scheduleSave(),
            decoration:  InputDecoration(
              hintText: appLoc.s_aa5a5d3e,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          _section(appLoc.s_fb47d52b(length: _notes.length)),
          if (_notes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(appLoc.s_18dd30c5,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ),
          for (final n in _notes)
            _NoteTile(
              note: n,
              onEdit: () => _updateNote(n),
              onDelete: () => _removeNote(n),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addNote,
              icon: const Icon(Icons.note_add_outlined, size: 16),
              label:  Text(appLoc.s_f98a79dc),
            ),
          ),
          const SizedBox(height: 16),

          if (b.description != null && b.description!.isNotEmpty) ...[
            _section(appLoc.s_4b7d48f2),
            Text(b.description!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
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

/// 一条笔记。类型标签 + 正文 + 时间，右上角菜单做编辑/删除。
class _NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteTile({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final at = DateTime.tryParse(note.createdAt);
    final stamp = at == null
        ? ''
        : '${at.year}-${at.month.toString().padLeft(2, '0')}-'
            '${at.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(note.type.label,
                    style:
                        TextStyle(fontSize: 10, color: cs.onPrimaryContainer)),
              ),
              if (note.chapter != null && note.chapter!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(note.chapter!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ),
              ],
              const Spacer(),
              if (stamp.isNotEmpty)
                Text(stamp,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              PopupMenuButton<String>(
                iconSize: 18,
                padding: EdgeInsets.zero,
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) =>  [
                  PopupMenuItem(value: 'edit', child: Text(appLoc.s_ad207008)),
                  PopupMenuItem(value: 'delete', child: Text(appLoc.s_ecbd7449)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(note.content, style: const TextStyle(fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }
}
