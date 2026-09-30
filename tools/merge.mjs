/**
 * 多源合并：Notion 历史 + 微信读书 → 统一本地书库
 *
 * 合并要点：
 * 1. 去重指纹 ISBN > 书名+首位作者（跨源同一本书只保留一条）
 * 2. 字段合并只补空缺，绝不覆盖已有值——Notion 里你手填的评分/摘要优先
 * 3. 微信读书补充 Notion 缺失的封面、简介、分类、阅读进度
 * 4. 冲突字段（如两侧都有 status）以「信息更新」的一方为准，并在 extra 留痕
 *
 * 用法：node merge.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { bookFingerprint, BookStatus } from './lib/schema.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function readJson(p) {
  return JSON.parse(fs.readFileSync(path.join(__dirname, p), 'utf8'));
}

/** 只填补空缺的字段合并 */
function mergeFields(base, incoming) {
  const out = { ...base };
  for (const [k, v] of Object.entries(incoming)) {
    if (v == null || v === '') continue;
    if (Array.isArray(v) && v.length === 0) continue;
    const cur = out[k];
    const curEmpty = cur == null || cur === '' || (Array.isArray(cur) && cur.length === 0);
    if (curEmpty) { out[k] = v; continue; }
    // 数组字段取并集
    if (Array.isArray(cur) && Array.isArray(v)) {
      out[k] = [...new Set([...cur, ...v])];
    }
  }
  return out;
}

/** 状态优先级：更「深入」的状态胜出 */
const STATUS_RANK = {
  [BookStatus.WISH]: 0,
  [BookStatus.PAUSED]: 1,
  [BookStatus.BORROWED]: 2,
  [BookStatus.READING]: 3,
  [BookStatus.FINISHED]: 4,
  [BookStatus.ABANDONED]: 2,
};

function main() {
  const notion = readJson('samples/my-library.json');
  const weread = readJson('samples/weread-full.json');

  const notionBooks = notion.books ?? [];
  const wereadBooks = weread.books ?? [];

  const merged = new Map();     // fingerprint → book
  const origin = new Map();     // fingerprint → Set<来源>
  let dupCount = 0;

  const add = (book, tag) => {
    const fp = bookFingerprint(book);
    const existing = merged.get(fp);
    if (!existing) {
      merged.set(fp, book);
      origin.set(fp, new Set([tag]));
      return;
    }
    dupCount++;
    origin.get(fp).add(tag);

    // 状态取更靠后的；进度取更大值；其余只补空缺
    const winner = STATUS_RANK[book.status] > STATUS_RANK[existing.status] ? book : existing;
    const loser = winner === book ? existing : book;
    const combined = mergeFields(winner, loser);
    combined.status = winner.status;
    combined.progressPercent = Math.max(existing.progressPercent ?? 0, book.progressPercent ?? 0);
    // 来源：保留信息更丰富的一侧，并记录双来源
    combined.extra = { ...existing.extra, ...book.extra, sources: [...origin.get(fp)] };
    merged.set(fp, combined);
  };

  notionBooks.forEach((b) => add(b, 'notion'));
  wereadBooks.forEach((b) => add(b, 'weread'));

  const all = [...merged.values()];
  const both = [...origin.entries()].filter(([, s]) => s.size > 1).length;

  // 统计
  const byStatus = {};
  for (const b of all) byStatus[b.status] = (byStatus[b.status] ?? 0) + 1;
  const byCategory = {};
  for (const b of all) {
    const k = b.categoryPrimary ?? '未分类';
    byCategory[k] = (byCategory[k] ?? 0) + 1;
  }
  const withCover = all.filter((b) => b.coverUrl).length;
  const withDesc = all.filter((b) => b.description).length;
  const withTags = all.filter((b) => b.tags?.length).length;

  console.log(`\n合并结果：Notion ${notionBooks.length} 本 + 微信读书 ${wereadBooks.length} 本`
      + ` → 去重后 ${all.length} 本（重复 ${dupCount} 本，两源共有 ${both} 本）`);
  console.log('\n状态分布：', byStatus);
  console.log('\n分类分布：', Object.entries(byCategory)
    .sort((a, b) => b[1] - a[1]).slice(0, 12));
  console.log(`\n有封面 ${withCover} 本 | 有简介 ${withDesc} 本 | 有标签 ${withTags} 本`);

  const outPath = path.join(__dirname, 'samples/library-merged.json');
  fs.writeFileSync(outPath, JSON.stringify({
    books: all,
    notes: notion.notes ?? [],
    stats: weread.stats ?? null,
    shelfMeta: weread.shelfMeta ?? null,
  }, null, 2), 'utf8');
  console.log(`\n已写出：${outPath}`);
}

main();
