/**
 * 冒烟测试：不依赖网络，验证核心逻辑正确性
 * 运行：node test/smoke.mjs
 */

import assert from 'node:assert/strict';
import { parseCsv, parseProgress, parseRating, parseDate, parseStatus } from '../notion-import.mjs';
import { scoreMatch, MetadataEnricher, mergeMeta } from '../lib/enrich.mjs';
import { createBook, bookFingerprint, normalizeList, normalizeIsbn, BookStatus } from '../lib/schema.mjs';

let passed = 0;
function test(name, fn) {
  try { fn(); console.log(`  PASS  ${name}`); passed++; }
  catch (e) { console.error(`  FAIL  ${name}\n        ${e.message}`); process.exitCode = 1; }
}

console.log('\n[1] CSV 解析');
test('引号内含逗号不截断', () => {
  const rows = parseCsv('a,b\n1,"x,y,z"\n');
  assert.equal(rows[1][1], 'x,y,z');
});
test('引号内换行保留', () => {
  const rows = parseCsv('a,b\n1,"line1\nline2"\n');
  assert.equal(rows.length, 2);
});

console.log('\n[2] 脏值解析');
test('百分比进度', () => assert.equal(parseProgress('45%'), 45));
test('分数进度 120/300 → 40', () => assert.equal(parseProgress('120/300'), 40));
test('纯数字进度', () => assert.equal(parseProgress('62'), 62));
test('页码不误判为进度', () => assert.equal(parseProgress('302'), null));
test('星级评分 ★★★★☆ → 4', () => assert.equal(parseRating('★★★★☆'), 4));
test('分数评分 4/5 → 4', () => assert.equal(parseRating('4/5'), 4));
test('小数评分 4.5', () => assert.equal(parseRating('4.5'), 4.5));
test('ISO 日期', () => assert.equal(parseDate('2023-01-05'), '2023-01-05'));
test('斜杠日期', () => assert.equal(parseDate('2023/1/5'), '2023-01-05'));
test('空日期 → null', () => assert.equal(parseDate(''), null));
test('中文状态映射', () => {
  assert.equal(parseStatus('在读'), BookStatus.READING);
  assert.equal(parseStatus('已读'), BookStatus.FINISHED);
  assert.equal(parseStatus('弃读'), BookStatus.ABANDONED);
});

console.log('\n[3] 标题匹配');
test('完全相同 → 1', () => assert.equal(scoreMatch('三体', '三体'), 1));
test('含副标题 → 高分', () => assert.ok(scoreMatch('三体', '三体（全集）') > 0.7));
test('无关书名 → 低分', () => assert.ok(scoreMatch('三体', '置身事内') < 0.6));

console.log('\n[4] 字段合并');
test('只填空缺，不覆盖已有值', () => {
  const book = createBook({ title: '三体', authors: ['刘慈欣'], publisher: '用户手填' });
  mergeMeta(book, { publisher: '重庆出版社', description: '简介', categoryPrimary: '科幻' });
  assert.equal(book.publisher, '用户手填', '不应覆盖用户已有的出版社');
  assert.equal(book.description, '简介');
  assert.equal(book.categoryPrimary, '科幻');
});
test('标签合并去重', () => {
  const book = createBook({ title: 'A', tags: ['科幻'] });
  mergeMeta(book, { tags: ['科幻', '雨果奖'] });
  assert.deepEqual(book.tags, ['科幻', '雨果奖']);
});

console.log('\n[5] 去重指纹');
test('ISBN 优先', () => {
  const a = createBook({ title: 'X', isbn: '9787536692930' });
  assert.equal(bookFingerprint(a), 'isbn:9787536692930');
});
test('书名+作者', () => {
  const b = createBook({ title: '三体', authors: ['刘慈欣'] });
  assert.equal(bookFingerprint(b), 'ta:三体|刘慈欣');
});
test('ISBN 校验', () => {
  assert.equal(normalizeIsbn('978-7-5366-9293-0'), '9787536692930');
  assert.equal(normalizeIsbn('123'), null);
});

console.log('\n[6] 补全引擎（stub provider）');
const stub = {
  available: true,
  constructor: { name: 'StubProvider' },
  async search() {
    return [{
      title: '三体', authors: ['刘慈欣'], publisher: '重庆出版社',
      description: '文化大革命时期的科幻小说', categoryPrimary: '科幻',
      isbn13: '9787536692930', coverUrl: 'http://example.com/cover.jpg',
      pageCount: 302, tags: ['雨果奖'],
    }];
  },
};

const enricher = new MetadataEnricher({ providers: [stub], onLog: () => {} });
const target = createBook({ title: '三体' });
const result = await enricher.enrich(target);
test('命中 stub 数据源', () => assert.equal(result.hit, 'StubProvider'));
test('补全作者', () => assert.deepEqual(result.book.authors, ['刘慈欣']));
test('补全出版社', () => assert.equal(result.book.publisher, '重庆出版社'));
test('补全分类', () => assert.equal(result.book.categoryPrimary, '科幻'));
test('补全页数', () => assert.equal(result.book.pageCount, 302));

console.log('\n[7] 不可用时优雅降级');
const broken = {
  available: true,
  constructor: { name: 'BrokenProvider' },
  async search() { throw new Error('网络不可达'); },
};
const e2 = new MetadataEnricher({ providers: [broken], onLog: () => {} });
const b2 = createBook({ title: '未知书' });
const r2 = await e2.enrich(b2);
test('数据源失败不抛异常', () => assert.equal(r2.hit, null));
test('书名仍保留', () => assert.equal(r2.book.title, '未知书'));

console.log(`\n通过 ${passed} 项`);
