/**
 * 分类归一化测试
 *
 * 存在的意义：保证 Node 侧（tools/lib/schema.mjs）与 Dart 侧
 * （app/lib/models/enums.dart）的 normalizeCategory 行为一致，
 * 否则同一本书在导入工具和 App 里会落在不同分类下。
 * 用例与 app/test/category_check.dart 一一对应。
 */

import { normalizeCategory, DEFAULT_CATEGORIES } from '../lib/schema.mjs';

let pass = 0;
const failures = [];

function expect(input, expected, label = '') {
  const got = normalizeCategory(input);
  const name = label || String(input);
  if (got === expected) pass++;
  else failures.push(`  ${name}: 得到 ${JSON.stringify(got)}，期望 ${JSON.stringify(expected)}`);
}

// 已在受控词表内 → 原样返回
for (const c of ['经济', '心理', '哲学', '成长', '计算机']) expect(c, c);

// 微信读书自有分类 → 受控词表
expect('经济理财', '经济', '微信读书·经济理财');
expect('个人成长', '成长', '微信读书·个人成长');
expect('哲学宗教', '哲学', '微信读书·哲学宗教');
expect('精品小说', '文学', '微信读书·精品小说');
expect('男生小说', '文学', '微信读书·男生小说');
expect('女生小说', '文学', '微信读书·女生小说');
expect('社会文化', '社科', '微信读书·社会文化');
expect('政治军事', '社科', '微信读书·政治军事');
expect('教育学习', '教育', '微信读书·教育学习');
expect('科学技术', '科技', '微信读书·科学技术');
expect('生活百科', '其他', '微信读书·生活百科');

// 复合分类走包含关系兜底
expect('经济理财-财经', '经济', '复合分类');
expect('哲学宗教-哲学', '哲学', '复合分类');

// 无法归类 → 其他，而非 null
expect('完全不知道的分类', '其他', '未知分类');

// 空值 → null
expect(null, null, 'null 输入');
expect('', null, '空串输入');
expect('   ', null, '空白输入');

const total = pass + failures.length;
console.log(`分类归一化：通过 ${pass}/${total}`);
if (failures.length) {
  console.log('失败用例：');
  failures.forEach((f) => console.log(f));
  process.exit(1);
}

// 一致性自检：所有别名目标必须都在受控词表内，否则会引入新分类
const { CATEGORY_ALIASES } = await import('../lib/schema.mjs');
const bad = Object.entries(CATEGORY_ALIASES)
  .filter(([, v]) => !DEFAULT_CATEGORIES.includes(v))
  .map(([k, v]) => `${k}→${v}`);
if (bad.length) {
  console.log('别名表引用了词表外的分类：', bad.join(', '));
  process.exit(1);
}
console.log(`别名表 ${Object.keys(CATEGORY_ALIASES).length} 条，目标全部在受控词表内`);
