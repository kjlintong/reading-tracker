#!/usr/bin/env node
/**
 * 补全缺失的作者字段。
 *
 * 背景：书库里常有作者空缺的条目——Notion 侧原本就空着、微信读书又没搜到，
 * 多为《正义论》《西西弗神话》这类知名书。
 *
 * 关键约束：**宁缺勿编**。作者是强事实字段，编造出来的名字比留空危害大得多
 * （用户会以为自己读过某人的书）。因此提示词要求「不确定就返回空字符串」，
 * 且只接受高置信结果。
 *
 * 用法：
 *   node fill-authors.mjs library.json --out library.json [--batch 6] [--dry-run]
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadEnv } from './lib/env.mjs';
import { LlmProvider, parseJsonLoose } from './lib/providers/llm.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function isMain() {
  if (!process.argv[1]) return false;
  // Windows 下 import.meta.url 是 file:///E:/...（三斜杠），
  // 只拼 file:// 会永远不相等，脚本会静默退出且无任何输出
  const self = path.resolve(process.argv[1]).replace(/\\/g, '/');
  return import.meta.url === `file:///${self}` || import.meta.url === `file://${self}`;
}

/**
 * 批量推断作者
 * @param {LlmProvider} llm
 * @param {Array<{index:number, title:string, hint:string}>} items
 */
async function inferAuthorsBatch(llm, items) {
  const sys =
    '你是图书编目助手，精通中外出版物。只输出 JSON，不要任何解释文字。';

  const lines = items
    .map((it) => `${it.index}. 书名：《${it.title}》${it.hint ? `\n   线索：${it.hint}` : ''}`)
    .join('\n');

  const usr = `请为下列书籍填写作者。

严格要求：
1. 只在你**确定**知道该书的作者时才填写，不确定一律返回空字符串 ""
2. 严禁猜测或编造作者姓名——编造比留空危害大得多
3. 中文书用中文名，外文书用通用译名（如"加缪"而非"Camus"）
4. 多作者用 "/" 分隔
5. 不要填写译者、编者、出版社

书籍清单：
${lines}

输出 JSON 数组，每项形如 {"index":0,"authors":"作者名"}，` +
    `其中 authors 为字符串（多作者用 "/" 分隔），不确定则为空字符串。`;

  const raw = await llm.chat(
    [
      { role: 'system', content: sys },
      { role: 'user', content: usr },
    ],
    { temperature: 0, jsonMode: true },
  );

  let parsed;
  try {
    parsed = parseJsonLoose(raw);
  } catch {
    return [];
  }
  const arr = Array.isArray(parsed) ? parsed : parsed.books ?? parsed.items ?? [];
  return arr.filter((x) => x && typeof x === 'object');
}

export async function fillAuthors(books, { llm, batchSize = 6, dryRun = false, onLog = console.log } = {}) {
  const targets = books
    .map((b, i) => ({ b, i }))
    .filter(({ b }) => !b.authors || b.authors.length === 0);

  if (targets.length === 0) {
    onLog('没有缺失作者的书籍');
    return { filled: 0, failed: 0, targets: 0 };
  }
  onLog(`待补全作者：${targets.length} 本`);

  if (dryRun) {
    for (const { b } of targets) onLog(`  《${b.title}》`);
    return { filled: 0, failed: 0, targets: targets.length };
  }

  let filled = 0;
  let failed = 0;

  for (let s = 0; s < targets.length; s += batchSize) {
    const chunk = targets.slice(s, s + batchSize);
    const items = chunk.map(({ b }, k) => ({
      index: k,
      title: b.title,
      // 简介里常含作者线索（"本书是法国作家加缪的哲学随笔"），一并喂给模型
      hint: (b.description ?? '').slice(0, 120),
    }));

    try {
      const res = await inferAuthorsBatch(llm, items);
      const byIndex = new Map(res.map((r) => [Number(r.index), r]));
      for (let k = 0; k < chunk.length; k++) {
        const r = byIndex.get(k);
        const raw = (r?.authors ?? '').toString().trim();
        if (!raw) { failed++; continue; }
        const names = raw
          .split(/[、,，;；]/)
          .map((x) => x.trim())
          .filter(Boolean);
        if (names.length === 0) { failed++; continue; }
        chunk[k].b.authors = names;
        filled++;
      }
      onLog(`  批 ${Math.floor(s / batchSize) + 1}/${Math.ceil(targets.length / batchSize)} 完成`);
    } catch (e) {
      failed += chunk.length;
      onLog(`  批次失败：${e.message}`);
    }
  }

  return { filled, failed, targets: targets.length };
}

if (isMain()) {
  loadEnv();
  const args = process.argv.slice(2);
  const positional = args.filter((a) => !a.startsWith('--'));
  const input = positional[0];
  const outIdx = args.indexOf('--out');
  const out = outIdx >= 0 ? args[outIdx + 1] : null;
  const batchIdx = args.indexOf('--batch');
  const batchSize = batchIdx >= 0 ? Number(args[batchIdx + 1]) : 6;
  const dryRun = args.includes('--dry-run');

  if (!input) {
    console.error('用法: node fill-authors.mjs <library.json> [--out out.json] [--batch 6] [--dry-run]');
    process.exit(1);
  }

  const payload = JSON.parse(fs.readFileSync(input, 'utf8'));
  const books = payload.books ?? payload;
  console.log(`载入 ${books.length} 本`);

  const llm = new LlmProvider();
  if (!llm.available) {
    console.error('未配置 LLM_API_KEY，请在 tools/.env 中填写');
    process.exit(1);
  }

  const t0 = Date.now();
  const stat = await fillAuthors(books, { llm, batchSize, dryRun, onLog: console.log });
  console.log(`\n耗时 ${((Date.now() - t0) / 1000).toFixed(1)}s | 成功 ${stat.filled} / 目标 ${stat.targets} | 无结果 ${stat.failed}`);

  const cover = books.filter((b) => b.authors && b.authors.length).length;
  console.log(`作者覆盖：${cover}/${books.length} (${(cover / books.length * 100).toFixed(1)}%)`);

  if (out && !dryRun) {
    fs.writeFileSync(out, JSON.stringify(payload, null, 2), 'utf8');
    console.log(`已写出：${out}`);
  }
}
