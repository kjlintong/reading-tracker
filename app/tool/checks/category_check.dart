// 分类归一化校验（纯 Dart，不依赖 Flutter 插件）
// 运行：dart run tool/checks/category_check.dart
//
// 覆盖两端一致性：Node 侧 tools/lib/schema.mjs 的 normalizeCategory
// 与 Dart 侧 lib/models/enums.dart 的同名函数必须行为一致，
// 否则同一本书在导入工具和 App 里会落在不同分类下。

// ignore_for_file: avoid_print

import 'package:reading_tracker/models/enums.dart';

int _pass = 0;
int _fail = 0;

void expect(String input, String? expected, {String label = ''}) {
  final got = normalizeCategory(input);
  final ok = got == expected;
  if (ok) {
    _pass++;
  } else {
    _fail++;
    print('FAIL  ${label.isEmpty ? input : label} → $got（期望 $expected）');
  }
}

void main() {
  // 已在受控词表内 → 原样返回
  expect('经济', '经济');
  expect('心理', '心理');
  expect('哲学', '哲学');
  expect('成长', '成长');
  expect('计算机', '计算机');

  // 微信读书自有分类 → 受控词表
  expect('经济理财', '经济', label: '微信读书·经济理财');
  expect('个人成长', '成长', label: '微信读书·个人成长');
  expect('哲学宗教', '哲学', label: '微信读书·哲学宗教');
  expect('精品小说', '文学', label: '微信读书·精品小说');
  expect('男生小说', '文学', label: '微信读书·男生小说');
  expect('女生小说', '文学', label: '微信读书·女生小说');
  expect('社会文化', '社科', label: '微信读书·社会文化');
  expect('政治军事', '社科', label: '微信读书·政治军事');
  expect('教育学习', '教育', label: '微信读书·教育学习');
  expect('科学技术', '科技', label: '微信读书·科学技术');
  expect('生活百科', '其他', label: '微信读书·生活百科');

  // 带后缀的复合分类，走包含关系兜底
  expect('经济理财-财经', '经济', label: '复合分类');
  expect('哲学宗教-哲学', '哲学', label: '复合分类');

  // 无法归类 → 其他（而非 null）
  expect('完全不知道的分类', '其他', label: '未知分类');

  // 空值 → null（区别于「无法归类」）
  if (normalizeCategory(null) != null) {
    _fail++;
    print('FAIL  null 应返回 null');
  } else {
    _pass++;
  }
  if (normalizeCategory('') != null) {
    _fail++;
    print('FAIL  空串应返回 null');
  } else {
    _pass++;
  }

  print('\n分类归一化：通过 $_pass，失败 $_fail');
  if (_fail > 0) throw StateError('存在失败用例');
}
