/**
 * CLI：大模型批量兜底补全
 *
 * 职责单一：对公开数据源（微信读书 / Google Books / Open Library）补不全的书，
 * 用大模型一次性批量补全分类、简介、标签。
 *
 * 与 enrich.mjs 的分工：
 *   enrich.mjs    —— 查权威数据源，逐本精确匹配（免费、准确，但有覆盖盲区）
 *   llm-enrich.mjs —— 对盲区做语义推断（收费，但覆盖率接近 100%）
 *
 * 用法：
 *   node llm-enrich.mjs library-enriched.json --out library-llm.json
 *   node llm-enrich.mjs library-enriched.json --batch 6 --concurrency 3 --dry-run
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LlmProvider } from './lib/providers/llm.mjs';
import { DEFAULT_CATEGORIES, normalizeCategory } from './lib/schema.mjs';
import { mergeMeta } from './lib/enrich.mjs';
import { loadEnv } from './lib/env.mjs';

loadEnv();

function isMain() {
  if (!process.argv[1]) return false;
  return path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
}

/** 判断一本书是否需要 LLM 兜底 */
export function needsEnrichment(book) {
  return !book.categoryPrimary || !book.description;
}

/**
 * 批量补全
 * @param {object[]} books 待补全的书（原地修改）
 * @param {object} opts
 * @param {number} opts.batchSize 每批本数
 * @param {number} opts.concurrency 并批数
 * @param {boolean} opts.dryRun 只统计不调用
 * @param {(msg:string)=>void} opts.onLog
 */
export async function llmEnrichAll(books, {
  llm,
  batchSize = 5,
  concurrency = 3,
  dryRun = false,
  onLog = () => {},
} = {}) {
  const targets = books.map((b, i) => ({ book: b, index: i })).filter((t) => needsEnrichment(t.book));
  if (!targets.length) {
    onLog('没有需要补全的书');
    return { filled: 0, failed: 0, targets: 0 };
  }
  onLog(`待补全：${targets.length} 本，分 ${Math.ceil(targets.length / batchSize)} 批（每批 ${batchSize} 本，并发 ${concurrency}）`);

  if (dryRun) {
    for (const t of targets.slice(0, 10)) onLog(`  例：${t.book.title}`);
    return { filled: 0, failed: 0, targets: targets.length };
  }

  // 切批
  const batches = [];
  for (let i = 0; i < targets.length; i += batchSize) batches.push(targets.slice(i, i + batchSize));

  let filled = 0;
  let failed = 0;
  let cursor = 0;
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  const worker = async () => {
    while (cursor < batches.length) {
      const batch = batches[cursor++];
      const idx = batches.indexOf(batch) + 1;
      try {
        const res = await llm.inferMetadataBatch(batch.map((t) => t.book), DEFAULT_CATEGORIES);
        const byIndex = new Map(res.map((r) => [Number(r.index), r]));
        // 模型返回的 index 是批内序号（0-based），需按批内位置对应回原书
        batch.forEach((t, i) => {
          const r = byIndex.get(i);
          if (r) { applyInferred(t.book, r); filled++; }
          else failed++;
        });
        onLog(`  批 ${idx}/${batches.length} 完成（${res.length}/${batch.length} 条）`);
      } catch (e) {
        failed += batch.length;
        onLog(`  批 ${idx} 失败：${e.message.slice(0, 120)}`);
      }
      if (cursor < batches.length) await sleep(300);
    }
  };

  await Promise.all(Array.from({ length: Math.min(concurrency, batches.length) }, worker));
  return { filled, failed, targets: targets.length };
}

/** 把 LLM 推断结果写回书籍（只补空缺，不覆盖已有值） */
export function applyInferred(book, r) {
  // 分类必须落在受控词表内，否则丢弃——避免污染统计口径
  const cat = DEFAULT_CATEGORIES.includes(r.categoryPrimary) ? r.categoryPrimary : null;
  mergeMeta(book, {
    categoryPrimary: cat,
    description: typeof r.description === 'string' ? r.description.trim() : null,
    tags: Array.isArray(r.tags) ? r.tags.filter(Boolean).slice(0, 5) : [],
    authors: Array.isArray(r.authors) ? r.authors.filter(Boolean) : [],
  });
  if (cat) book.__llmFilled = true;
  return book;
}

if (isMain()) {
  const args = process.argv.slice(2);
  const input = args[0];
  const outArg = args.includes('--out') ? args[args.indexOf('--out') + 1] : null;
  const batchSize = Number(args.includes('--batch') ? args[args.indexOf('--batch') + 1] : 5);
  const concurrency = Number(args.includes('--concurrency') ? args[args.indexOf('--concurrency') + 1] : 3);
  const dryRun = args.includes('--dry-run');
  // 已调用过 LLM、只想重跑分类归一化时用，避免重复消耗 token
  const normalizeOnly = args.includes('--normalize-only');

  if (!input) {
    console.error('用法: node llm-enrich.mjs <books.json> [--out out.json] [--batch 5] [--concurrency 3] [--dry-run]');
    process.exit(1);
  }

  const llm = new LlmProvider();
  if (!llm.available) {
    console.error('缺少 LLM_API_KEY，请在 .env 中配置后重试');
    process.exit(1);
  }
  console.log(`大模型：${llm.model} @ ${llm.baseUrl}`);

  const parsed = JSON.parse(fs.readFileSync(input, 'utf8'));
  const isWrapped = !Array.isArray(parsed) && Array.isArray(parsed.books);
  const books = Array.isArray(parsed) ? parsed : parsed.books;

  const catBefore = books.filter((b) => b.categoryPrimary).length;
  const descBefore = books.filter((b) => b.description).length;

  let stat = { filled: 0, failed: 0, targets: 0 };
  let cost = '0.0';
  if (!normalizeOnly) {
    const t0 = Date.now();
    stat = await llmEnrichAll(books, { llm, batchSize, concurrency, dryRun, onLog: console.log });
    cost = ((Date.now() - t0) / 1000).toFixed(1);
  }

  // 统一分类口径：微信读书自有体系 → 受控词表。
  // 不归一会让「经济理财」与「经济」在统计图上分裂成两类。
  let remapped = 0;
  for (const b of books) {
    // 优先以原始分类为输入，保证归一化可重复执行且结果稳定
    const src = b.categoryRaw ?? b.categoryPrimary;
    if (!src) continue;
    const norm = normalizeCategory(src);
    if (norm && norm !== src) b.categoryRaw = src;
    if (norm && norm !== b.categoryPrimary) {
      b.categoryPrimary = norm;
      remapped++;
    }
  }

  console.log(`\n耗时 ${cost}s | 成功 ${stat.filled} / 目标 ${stat.targets} | 失败 ${stat.failed}`);
  console.log(`分类归一化：${remapped} 本归入受控词表`);
  console.log(`分类覆盖：${catBefore} → ${books.filter((b) => b.categoryPrimary).length} 本`);
  console.log(`简介覆盖：${descBefore} → ${books.filter((b) => b.description).length} 本`);

  if (outArg && !dryRun) {
    const payload = isWrapped ? { ...parsed, books } : books;
    fs.writeFileSync(outArg, JSON.stringify(payload, null, 2), 'utf8');
    console.log(`已写出：${outArg}`);
  }
}
