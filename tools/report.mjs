/**
 * CLI：生成定期阅读报告
 *
 * 把结构化阅读数据交给大模型做分析，产出 Markdown 报告。
 * 报告只基于真实数据，不编造：所有统计都在本地算好后再交给模型解读。
 *
 * 用法：
 *   node report.mjs samples/library-final.json --out docs/阅读报告.md
 *   node report.mjs samples/library-final.json --period "2026年至今" --year 2026
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { LlmProvider } from './lib/providers/llm.mjs';
import { loadEnv } from './lib/env.mjs';

loadEnv();

function isMain() {
  if (!process.argv[1]) return false;
  return path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
}

/** 从书库与统计中汇总出报告所需的结构化数据 */
export function buildReportData(books, { stats = {}, notes = [], year = null } = {}) {
  const byStatus = {};
  for (const b of books) byStatus[b.status] = (byStatus[b.status] ?? 0) + 1;

  const byCategory = {};
  for (const b of books) {
    if (!b.categoryPrimary) continue;
    byCategory[b.categoryPrimary] = (byCategory[b.categoryPrimary] ?? 0) + 1;
  }

  const bySource = {};
  for (const b of books) bySource[b.source] = (bySource[b.source] ?? 0) + 1;

  // 完成时间线：按年月聚合
  const finishedByMonth = {};
  for (const b of books) {
    if (!b.finishedAt) continue;
    if (year && !String(b.finishedAt).startsWith(String(year))) continue;
    const ym = String(b.finishedAt).slice(0, 7);
    finishedByMonth[ym] = (finishedByMonth[ym] ?? 0) + 1;
  }

  // 评分分布与高分书
  const ratingDist = {};
  const rated = books.filter((b) => b.rating > 0);
  for (const b of rated) ratingDist[b.rating] = (ratingDist[b.rating] ?? 0) + 1;
  const topRated = rated
    .filter((b) => b.rating >= 4)
    .sort((a, b) => b.rating - a.rating)
    .slice(0, 15)
    .map((b) => ({ title: b.title, authors: b.authors, rating: b.rating, category: b.categoryPrimary }));

  // 弃读 / 长期未推进的书（进度停滞）
  const stalled = books
    .filter((b) => b.status === 'reading' && b.progressPercent != null && b.progressPercent < 20)
    .map((b) => ({ title: b.title, progress: b.progressPercent }));

  return {
    overview: {
      totalBooks: books.length,
      byStatus,
      ratedCount: rated.length,
      avgRating: rated.length
        ? Number((rated.reduce((s, b) => s + b.rating, 0) / rated.length).toFixed(2))
        : null,
      finishedWithDate: books.filter((b) => b.finishedAt).length,
      notesCount: notes.length,
    },
    structure: {
      byCategory: sortDesc(byCategory),
      bySource,
    },
    timeline: { finishedByMonth: Object.fromEntries(sortDescPairs(finishedByMonth)) },
    ratings: { distribution: ratingDist, topRated },
    stalledReading: stalled,
    wereadStats: stats ?? {},
  };
}

function sortDesc(obj) {
  return Object.fromEntries(sortDescPairs(obj));
}
function sortDescPairs(obj) {
  return Object.entries(obj).sort((a, b) => b[1] - a[1]);
}

if (isMain()) {
  const args = process.argv.slice(2);
  const input = args[0];
  const outArg = args.includes('--out') ? args[args.indexOf('--out') + 1] : null;
  const period = args.includes('--period') ? args[args.indexOf('--period') + 1] : '近一年';
  const yearArg = args.includes('--year') ? Number(args[args.indexOf('--year') + 1]) : null;

  if (!input) {
    console.error('用法: node report.mjs <library.json> [--out 报告.md] [--period "2026年至今"] [--year 2026]');
    process.exit(1);
  }

  // 报告输出长、推理量大，实测远超默认的 60s 而触发 AbortError，放宽到 3 分钟
  const llm = new LlmProvider({ timeoutMs: 180000 });
  if (!llm.available) {
    console.error('缺少 LLM_API_KEY，请在 .env 中配置后重试');
    process.exit(1);
  }

  const parsed = JSON.parse(fs.readFileSync(input, 'utf8'));
  const books = Array.isArray(parsed) ? parsed : parsed.books;
  const data = buildReportData(books, {
    stats: parsed.stats ?? {},
    notes: parsed.notes ?? [],
    year: yearArg,
  });

  console.log(`书库 ${books.length} 本 | 大模型：${llm.model}`);
  console.log('正在生成报告…');
  const t0 = Date.now();
  const md = await llm.generateReport({ period, data });
  console.log(`生成完成，耗时 ${((Date.now() - t0) / 1000).toFixed(1)}s，${md.length} 字`);

  const header = `# 阅读报告（${period}）\n\n> 生成时间：${new Date().toLocaleString('zh-CN')}　书库规模：${books.length} 本\n\n---\n\n`;
  const full = header + md;

  if (outArg) {
    fs.mkdirSync(path.dirname(outArg), { recursive: true });
    fs.writeFileSync(outArg, full, 'utf8');
    console.log(`已写出：${outArg}`);
  } else {
    console.log('\n' + full);
  }
}
