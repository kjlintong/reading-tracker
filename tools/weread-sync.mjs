/**
 * 微信读书书架同步（按官方 Skill v1.0.4 规范实现）
 *
 * 用法：
 *   node weread-sync.mjs --out shelf.json           # 导出书架
 *   node weread-sync.mjs --stats                    # 阅读统计（年度 + 总计）
 *   node weread-sync.mjs --progress                 # 逐本拉取阅读进度（较慢）
 *   node weread-sync.mjs --all --out full.json      # 书架 + 进度 + 统计
 *
 * 字段口径以官方 Skill 文档为准：
 * - progress 是 0-100 整数（1 = 1%，不是 100%）
 * - 所有时长字段单位是「秒」
 * - 书架条目总数 = books.length + albums.length + (mp 非空 ? 1 : 0)
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { loadEnv } from './lib/env.mjs';
import {
  WereadProvider, splitAuthors, parseCategory, formatDuration, formatDate,
} from './lib/providers/weread.mjs';
import { createBook, BookStatus, BookSource, BookFormat } from './lib/schema.mjs';

loadEnv();

function isMain() {
  if (!process.argv[1]) return false;
  return path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
}

/** 书架条目 → 统一 Book 结构 */
export function shelfItemToBook(b, progress = null) {
  const cat = parseCategory(b.category);
  const p = progress?.progress ?? 0;
  const finished = b.finishReading === 1 || p >= 100;

  return createBook({
    title: b.title ?? '',
    authors: splitAuthors(b.author),
    translators: splitAuthors(b.translator),
    publisher: b.publisher ?? null,
    coverUrl: b.cover ?? null,
    description: b.intro ?? null,
    categoryPrimary: cat.primary,
    categoryPath: cat.path,
    sourceBookId: b.bookId ? String(b.bookId) : null,
    sourceUrl: b.deepLink ?? null,
    status: finished ? BookStatus.FINISHED
        : (p > 0 ? BookStatus.READING : BookStatus.WISH),
    progressPercent: Math.min(100, Math.max(0, p)),
    finishedAt: progress?.finishTime ? formatDate(progress.finishTime) : null,
    format: BookFormat.EBOOK,
    source: BookSource.WEREAD,
    extra: {
      wereadReadUpdateTime: b.readUpdateTime ? formatDate(b.readUpdateTime) : null,
      wereadSecret: b.secret === 1,
      wereadReadingTimeSec: progress?.readingTimeSec ?? 0,
    },
  });
}

/** 专辑/有声书 → Book 结构 */
export function albumItemToBook(a) {
  const info = a.albumInfo ?? {};
  return createBook({
    title: info.name ?? '',
    authors: splitAuthors(info.authorName),
    coverUrl: info.cover ?? null,
    description: info.intro ?? null,
    sourceBookId: info.albumId ? String(info.albumId) : null,
    status: info.finish === 1 ? BookStatus.FINISHED : BookStatus.WISH,
    format: BookFormat.AUDIO,
    source: BookSource.WEREAD,
    extra: { wereadIsAlbum: true, trackCount: info.trackCount ?? null },
  });
}

/** 并发拉取进度，带节流避免触发限流 */
async function fetchProgress(weread, books, { concurrency = 3, delayMs = 400 } = {}) {
  const out = new Map();
  const queue = [...books];
  const workers = Array.from({ length: Math.min(concurrency, queue.length) }, async () => {
    while (queue.length) {
      const b = queue.shift();
      try {
        out.set(String(b.bookId), await weread.getProgress(String(b.bookId)));
      } catch { /* 单本失败不影响整体 */ }
      if (delayMs) await new Promise((r) => setTimeout(r, delayMs));
    }
  });
  await Promise.all(workers);
  return out;
}

if (isMain()) {
  const args = process.argv.slice(2);
  const outArg = args.includes('--out') ? args[args.indexOf('--out') + 1] : null;
  const wantAll = args.includes('--all');
  const wantStats = wantAll || args.includes('--stats');
  const wantProgress = wantAll || args.includes('--progress');

  const weread = new WereadProvider();
  if (!weread.available) {
    console.error('未配置 WEREAD_API_KEY，请在 tools/.env 中填写');
    process.exit(1);
  }

  const payload = { books: [], stats: null, shelfMeta: null };

  try {
    const shelf = await weread.shelf();
    console.log(`\n书架条目总数 ${shelf.total}`
        + `（电子书 ${shelf.books.length} + 专辑 ${shelf.albums.length}`
        + `${shelf.mp ? ' + 文章收藏 1' : ''}）`);
    if (shelf.archive?.length) {
      console.log(`书单 ${shelf.archive.length} 个：`
          + shelf.archive.map((a) => `${a.name}(${a.bookIds?.length ?? 0}本)`).join('、'));
    }

    let progressMap = new Map();
    if (wantProgress) {
      console.log(`\n正在拉取 ${shelf.books.length} 本的阅读进度…`);
      progressMap = await fetchProgress(weread, shelf.books);
    }

    const books = shelf.books
      .map((b) => shelfItemToBook(b, progressMap.get(String(b.bookId)) ?? null))
      .filter((b) => b.title);
    const albums = shelf.albums.map(albumItemToBook).filter((b) => b.title);

    payload.books = [...books, ...albums];
    payload.shelfMeta = {
      total: shelf.total,
      ebookCount: shelf.books.length,
      albumCount: shelf.albums.length,
      hasMp: Boolean(shelf.mp),
      collections: (shelf.archive ?? []).map((a) => ({
        name: a.name, bookIds: (a.bookIds ?? []).map(String),
      })),
    };

    const byStatus = {};
    for (const b of payload.books) byStatus[b.status] = (byStatus[b.status] ?? 0) + 1;
    console.log('\n状态分布：', byStatus);
    console.log('\n在读的书：');
    payload.books.filter((b) => b.status === 'reading')
      .sort((a, b) => b.progressPercent - a.progressPercent)
      .slice(0, 10)
      .forEach((b) => console.log(`  ${b.progressPercent.toString().padStart(3)}%  《${b.title}》`));

    if (wantStats) {
      const year = new Date().getFullYear();
      const [annual, overall] = await Promise.all([
        weread.readingStats('annually').catch(() => null),
        weread.readingStats('overall').catch(() => null),
      ]);
      payload.stats = { year, annual, overall };

      if (annual) {
        console.log(`\n─── ${year} 年阅读统计 ───`);
        console.log(`  总时长：${formatDuration(annual.totalReadTime)}（${annual.totalReadTime} 秒）`);
        console.log(`  阅读天数：${annual.readDays} 天`);
        if (annual.readStat?.length) {
          console.log('  ' + annual.readStat.map((s) => `${s.stat} ${s.counts}`).join(' | '));
        }
        if (annual.preferCategory?.length) {
          console.log('  偏好分类：' + annual.preferCategory
            .slice(0, 6)
            .map((c) => `${c.categoryTitle}(${formatDuration(c.readingTime)})`)
            .join('、'));
        }
        if (annual.preferAuthor?.length) {
          console.log('  偏好作者：' + annual.preferAuthor
            .slice(0, 5).map((a) => `${a.name}(${a.count}本)`).join('、'));
        }
        if (annual.readLongest?.length) {
          console.log('  读得最多：' + annual.readLongest
            .slice(0, 5)
            .map((r) => `${r.book?.title ?? r.albumInfo?.name ?? '?'} ${formatDuration(r.readTime)}`)
            .join('、'));
        }
      }
    }

    if (outArg) {
      fs.writeFileSync(outArg, JSON.stringify(payload, null, 2), 'utf8');
      console.log(`\n已写出：${outArg}`);
    }
  } catch (e) {
    console.error('调用失败：', e.message);
    process.exit(1);
  }
}
