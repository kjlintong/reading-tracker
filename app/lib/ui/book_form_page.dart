import 'dart:io';
import '../l10n/app_loc.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/book.dart';
import '../models/enums.dart';
import 'status_editor.dart';

/// 手动添加 / 编辑一本书。
///
/// 做成**全屏页**而不是底部弹层：这个表单有六个字段，
/// 底部弹层在键盘弹起时只剩一条缝，而且提交按钮会被顶出视口。
///
/// 只收集用户**愿意填**的字段：书名必填，其余全可空。
/// 要求把 ISBN、页数、出版社都补齐的结果只有一个——他放弃添加，
/// 书架里就永远少了这本。残缺记录由元数据补全管道后续处理。
///
/// 保存时一律过 `Book.withNormalizedCategory()`：手填的「经管励志」
/// 与库里的「管理」是两个分类，不归一化就会在统计里裂成两格。
Future<Book?> showBookForm(BuildContext context, {Book? initial}) {
  return Navigator.of(context).push<Book>(
    MaterialPageRoute(builder: (_) => BookFormPage(initial: initial)),
  );
}

class BookFormPage extends StatefulWidget {
  final Book? initial;

  const BookFormPage({super.key, this.initial});

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _category;
  late final TextEditingController _desc;
  late BookStatus _status;
  late BookFormat _format;
  late double _rating;
  String? _coverLocalPath;

  /// 借阅信息。编辑已存在的书时要带进来，否则一进表单就被重置成「未借阅」，
  /// 保存后应还日期就丢了。
  bool _isBorrowed = false;
  String? _dueAt;
  String? _error;

  /// 借阅来源。与详情页同理，controller 必须有稳定生命周期。
  late final TextEditingController _borrowedFrom;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final b = widget.initial;
    _title = TextEditingController(text: b?.title ?? '');
    _author = TextEditingController(text: b?.authors.join(appLoc.s_f5d99c16) ?? '');
    _category = TextEditingController(text: b?.categoryPrimary ?? '');
    _desc = TextEditingController(text: b?.description ?? '');
    _borrowedFrom = TextEditingController(text: b?.borrowedFrom ?? '');
    _status = b?.status ?? BookStatus.wish;
    // 已存的书若载体是 PDF / 漫画这类非可选值，保留原值但回退到纸质显示，
    // 不让下拉框选不中；保存时仍以 _format 为准
    _format = BookFormat.userVisible.contains(b?.format) ? b!.format : BookFormat.paper;
    _rating = b?.rating ?? 0;
    _coverLocalPath = b?.coverLocalPath;
    _isBorrowed = b?.isBorrowed ?? false;
    _dueAt = b?.dueAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _category.dispose();
    _desc.dispose();
    _borrowedFrom.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // 封面不需要原图那么大，限制一下避免存库文件过大
      maxWidth: 600,
      maxHeight: 840,
      imageQuality: 85,
    );
    // 相册是一个全屏 Activity，中途可能因为转屏、切后台被回收等原因
    // 销毁本页面。await 回来时 setState 会抛
    // 「setState() called after dispose()」——表现为选完图回���时闪退。
    // 跨 await 回到 UI 前一律先问一句还在不在。
    if (!mounted) return;
    if (picked == null) return;
    setState(() => _coverLocalPath = picked.path);
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = appLoc.s_65983593);
      return;
    }
    final now = DateTime.now();
    final iso = now.toIso8601String();
    final authors = _author.text
        .split(RegExp(appLoc.s_1f0939bc))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final base = widget.initial;
    final book = Book(
      id: base?.id ?? 'manual_${now.microsecondsSinceEpoch}',
      title: title,
      authors: authors,
      categoryPrimary:
          _category.text.trim().isEmpty ? null : _category.text.trim(),
      description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      format: _format,
      source: base?.source ?? BookSource.manual,
      status: _status,
      rating: _rating,
      // 封面：本地选的优先；编辑时不要因为没重选就把原来的封面抹掉
      coverLocalPath: _coverLocalPath ?? base?.coverLocalPath,
      // 借阅：关掉开关时来源与日期一并清空，不留「没标借阅却带着应还日期」
      // 的自相矛盾状态
      isBorrowed: _isBorrowed,
      borrowedFrom: _isBorrowed
          ? (_borrowedFrom.text.trim().isEmpty ? null : _borrowedFrom.text.trim())
          : null,
      dueAt: _isBorrowed ? _dueAt : null,
      // 标成已读就得给完成时间，否则统计里「今年读完」永远少一本
      finishedAt: _status == BookStatus.finished
          ? (base?.finishedAt ?? iso)
          : base?.finishedAt,
      progressPercent:
          _status == BookStatus.finished ? 100 : (base?.progressPercent ?? 0),
      createdAt: base?.createdAt ?? iso,
      updatedAt: iso,
    ).withNormalizedCategory();

    Navigator.of(context).pop(book);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? appLoc.s_6c7a6cc5 : appLoc.s_31e2aa97)),
      // 提交按钮做成固定底栏，不随表单滚动——滚到下面找不到提交入口
      // 是长表单最常见的流失点
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _save,
            child: Text(_editing ? appLoc.s_eda73905 : appLoc.s_71b10e99),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          /* ------------------------- 封面 ------------------------- */
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 92,
                    height: 128,
                    child: _coverLocalPath != null
                        ? Image.file(File(_coverLocalPath!), fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.book_outlined,
                                size: 36, color: Colors.white70),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: FloatingActionButton.small(
                    heroTag: 'cover',
                    tooltip: appLoc.s_2dae8ba5,
                    onPressed: _pickCover,
                    child: const Icon(Icons.add_a_photo_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _coverLocalPath == null
                  ? _pickCover
                  : () => setState(() => _coverLocalPath = null),
              child: Text(_coverLocalPath == null ? appLoc.s_5be7901d : appLoc.s_a59912dd,
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: appLoc.s_e2b6c0de,
              isDense: true,
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _author,
            textInputAction: TextInputAction.next,
            decoration:  InputDecoration(
              labelText: appLoc.s_22760472,
              hintText: appLoc.s_5f70e9dd,
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _CategoryField(controller: _category),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BookFormat>(
                  value: _format,
                  isDense: true,
                  decoration:  InputDecoration(
                      labelText: appLoc.s_da1c08d9,
                      isDense: true,
                      border: OutlineInputBorder()),
                  items: [
                    for (final f in BookFormat.userVisible)
                      DropdownMenuItem(value: f, child: Text(f.label)),
                  ],
                  onChanged: (v) => setState(() => _format = v ?? _format),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 状态与借阅用与详情页**同一个组件**。状态语义刚统一过，
          // 两处各写一份 UI 必然漂移；借阅也从状态里拆出来了，
          // 这里必须能设置它，否则新建的书只能去详情页补。
          //
          // **不给 onReturned**：归还针对的是「已经在书架上的书」，
          // 而这个页面可能正在新建一本书，归还无从谈起。
          StatusEditor(
            status: _status,
            isBorrowed: _isBorrowed,
            borrowedFrom: _borrowedFrom.text,
            dueAt: _dueAt,
            onStatusChanged: (s) => setState(() => _status = s),
            onBorrowedChanged: (v) => setState(() => _isBorrowed = v),
            onBorrowedFromChanged: (v) => setState(() {}),
            onDueAtChanged: (v) => setState(() => _dueAt = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(appLoc.s_8331377a,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(width: 8),
              for (var i = 1; i <= 5; i++)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    i <= _rating.round() ? Icons.star : Icons.star_border,
                    color: i <= _rating.round()
                        ? Colors.amber.shade700
                        : cs.onSurfaceVariant,
                  ),
                  onPressed: () => setState(
                      () => _rating = _rating == i.toDouble() ? 0 : i.toDouble()),
                ),
              const Spacer(),
              if (_rating > 0)
                TextButton(
                  onPressed: () => setState(() => _rating = 0),
                  child:  Text(appLoc.s_5ce4e16d, style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 3,
            minLines: 2,
            decoration:  InputDecoration(
              labelText: appLoc.s_b0d7b0de,
              alignLabelWithHint: true,
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            appLoc.s_d0dd45ac,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 分类选择：下拉选受控词表。
///
/// 自由输入会导致分类爆炸（「经管」「经济学」「经济」三个都出现过）。
/// 受控词表覆盖不到的场景留「其他」兜底。
class _CategoryField extends StatelessWidget {
  final TextEditingController controller;

  const _CategoryField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      // 生效词表而不是 defaultCategories：用户在设置里新增/删除过的分类
      // 要立刻反映在这里，否则「改了分类却选不到」。
      value: categoryVocabulary.contains(controller.text) ? controller.text : null,
      isDense: true,
      decoration:  InputDecoration(
        labelText: appLoc.s_b32f0afe,
        hintText: appLoc.s_87635298,
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        // 不能用 const：appLoc 是运行时 getter，const 构造要求编译期常量
        DropdownMenuItem<String>(value: null, child: Text(appLoc.s_5aa23087)),
        // value 存规范值，child 显示当前语言：选中后落库的仍是规范值
        for (final c in categoryVocabulary.active)
          DropdownMenuItem(value: c, child: Text(categoryLabel(c))),
      ],
      onChanged: (v) => controller.text = v ?? '',
    );
  }
}
