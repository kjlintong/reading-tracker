/**
 * OCR 书名提取算法测试
 * 运行：node test/ocr.test.mjs
 */

import assert from 'node:assert/strict';
import { extractBookTitles, toTitles } from '../lib/ocr_clean.mjs';

let passed = 0, failed = 0;
function test(name, fn) {
  try { fn(); console.log(`  PASS  ${name}`); passed++; }
  catch (e) { console.error(`  FAIL  ${name}\n        ${e.message}`); failed++; process.exitCode = 1; }
}

/** 模拟微信读书书架列表页 OCR 输出 */
const WEREAD_LIST = `
书架
最近阅读
三体
刘慈欣
读至 45%
置身事内
兰小欢
已读完
万历十五年
黄仁宇
100%
人类简史
尤瓦尔·赫拉利
共 128 本
昨天
`;

console.log('\n[1] 微信读书列表页 OCR');
const r1 = extractBookTitles(WEREAD_LIST);
const titles1 = r1.map((c) => c.title);
console.log('       提取结果:', JSON.stringify(r1.map((c) => `${c.title}(${c.score.toFixed(2)})`), null, 0));

test('识别出《三体》', () => assert.ok(titles1.includes('三体')));
test('识别出《置身事内》', () => assert.ok(titles1.includes('置身事内')));
test('识别出《万历十五年》', () => assert.ok(titles1.includes('万历十五年')));
test('识别出《人类简史》', () => assert.ok(titles1.includes('人类简史')));
test('排除界面词「书架」', () => assert.ok(!titles1.includes('书架')));
test('排除界面词「最近阅读」', () => assert.ok(!titles1.includes('最近阅读')));
test('排除进度「读至 45%」', () => assert.ok(!titles1.some((t) => t.includes('45%'))));
test('排除「100%」', () => assert.ok(!titles1.includes('100%')));
test('排除「共 128 本」', () => assert.ok(!titles1.some((t) => t.includes('128'))));
test('排除时间「昨天」', () => assert.ok(!titles1.includes('昨天')));
test('作者「刘慈欣」不误判为书名', () => assert.ok(!titles1.includes('刘慈欣')));
test('作者「黄仁宇」不误判为书名', () => assert.ok(!titles1.includes('黄仁宇')));
test('音译作者「尤瓦尔·赫拉利」不误判为书名', () => assert.ok(!titles1.includes('尤瓦尔·赫拉利')));
test('作者正确关联到书名', () => {
  const sanTi = r1.find((c) => c.title === '三体');
  assert.equal(sanTi?.author, '刘慈欣');
});

console.log('\n[2] 断行合并');
const BROKEN = `
追风
筝的人
百年孤独
`;
const r2 = extractBookTitles(BROKEN);
test('被拆断的标题合并', () => {
  assert.ok(r2.some((c) => c.title.includes('追风') && c.title.length >= 4), JSON.stringify(r2.map(c=>c.title)));
});
test('完整标题保留', () => assert.ok(r2.some((c) => c.title === '百年孤独')));

console.log('\n[3] 掌阅 / 京东风格');
const ZY = `
我的图书
全部
筛选
经济学原理
曼昆
试读
万历十五年
已购
`;
const r3 = toTitles(ZY);
test('识别出《经济学原理》', () => assert.ok(r3.includes('经济学原理')));
test('排除「我的图书」', () => assert.ok(!r3.includes('我的图书')));
test('排除「筛选」', () => assert.ok(!r3.includes('筛选')));

console.log('\n[4] 文石书架');
const BOOX = `
书库
最近阅读
枪炮、病菌与钢铁.pdf
文明之光
SDcard
Books
`;
const r4 = toTitles(BOOX);
test('识别出带扩展名的书名', () => assert.ok(r4.some((t) => t.includes('枪炮'))));
test('排除「书库」', () => assert.ok(!r4.includes('书库')));
test('排除路径词「SDcard」', () => assert.ok(!r4.some((t) => /sdcard/i.test(t))));

console.log('\n[5] 边界情况');
test('空输入不报错', () => assert.deepEqual(toTitles(''), []));
test('null 输入不报错', () => assert.deepEqual(toTitles(null), []));
test('纯噪音输入返回空', () => assert.deepEqual(toTitles('书架\n搜索\n100%\n昨天\n'), []));
test('含书名号的书名高分', () => {
  const r = extractBookTitles('《置身事内》\n兰小欢');
  const b = r.find((c) => c.title.includes('置身事内'));
  assert.ok(b.score > 0.7, `实际得分 ${b?.score}`);
});

console.log(`\n通过 ${passed}，失败 ${failed}`);
