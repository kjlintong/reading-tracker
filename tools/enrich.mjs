/**
 * CLI：批量补全书籍元数据
 *
 * 用法：
 *   export WEREAD_API_KEY=wrk-xxx
 *   export LLM_API_KEY=sk-xxx LLM_BASE_URL=https://api.deepseek.com/v1
 *   node enrich.mjs books.json --out enriched.json
 *
 * 数据源顺序：微信读书官方网关 → Google Books → Open Library → LLM 兜底
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WereadProvider } from './lib/providers/weread.mjs';
import { GoogleBooksProvider, OpenLibraryProvider } from './lib/providers/openmetas.mjs';
import { LlmProvider } from './lib/providers/llm.mjs';
import { MetadataEnricher } from './lib/enrich.mjs';
import { loadEnv } from './lib/env.mjs';

loadEnv();

function isMain() {
  if (!process.argv[1]) return false;
  return path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
}

export function buildEnricher({
  llmFallback = false,
  onLog = console.log,
  wereadOnly = false,
} = {}) {
  // wereadOnly：境外源在部分网络不可直连，逐个超时会拖慢整批，按需跳过
  const providers = wereadOnly
    ? [new WereadProvider()]
    : [new WereadProvider(), new GoogleBooksProvider(), new OpenLibraryProvider()];
  return new MetadataEnricher({
    providers,
    llm: new LlmProvider(),
    llmFallback,
    onLog,
  });
}

if (isMain()) {
  const args = process.argv.slice(2);
  const input = args[0];
  const outArg = args.includes('--out') ? args[args.indexOf('--out') + 1] : null;
  const llmFallback = args.includes('--llm');
  const wereadOnly = args.includes('--weread-only');

  if (!input) {
    console.error('用法: node enrich.mjs <books.json> [--out enriched.json] [--llm] [--weread-only]');
    process.exit(1);
  }

  const parsed = JSON.parse(fs.readFileSync(input, 'utf8'));
  const isWrapped = !Array.isArray(parsed) && Array.isArray(parsed.books);
  const books = Array.isArray(parsed) ? parsed : parsed.books;
  console.log(`待补全：${books.length} 本`);

  const enricher = buildEnricher({ llmFallback, wereadOnly, onLog: () => {} });
  const results = await enricher.enrichAll(books, { concurrency: 2, delayMs: 700 });

  const hitCount = results.filter((r) => r.hit).length;
  console.log(`\n补全完成：命中 ${hitCount} / ${results.length}`);
  const missing = results.filter((r) => !r.book.categoryPrimary).length;
  if (missing) console.log(`仍有 ${missing} 本缺少分类，建议开启 --llm 兜底`);
  const before = books.filter((b) => b.categoryPrimary).length;
  const after = results.filter((r) => r.book.categoryPrimary).length;
  console.log(`分类覆盖：${before} → ${after} 本`);
  console.log(`简介覆盖：${books.filter((b) => b.description).length} → ${results.filter((r) => r.book.description).length} 本`);

  if (outArg) {
    const outBooks = results.map((r) => r.book);
    const payload = isWrapped ? { ...parsed, books: outBooks } : outBooks;
    fs.writeFileSync(outArg, JSON.stringify(payload, null, 2), 'utf8');
    console.log(`已写出：${outArg}`);
  }
}
