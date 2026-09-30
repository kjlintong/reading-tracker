/**
 * 元数据补全引擎
 *
 * 职责：把"残缺的书籍记录"补全为"可用的书籍记录"。
 * 链式调用多个数据源，任一命中即合并；全部落空时可启用 LLM 兜底。
 *
 * 补全优先级：weread（中文覆盖最好）→ googlebooks → openlibrary → llm
 */

import { DEFAULT_CATEGORIES } from './schema.mjs';

/** 归一化比较用：去空格、标点、大小写、繁简差异（简易） */
function norm(s) {
  return String(s ?? '')
    .toLowerCase()
    .replace(/[《》【】\[\]()（）:：,，.。!！?？\s\-—_/\\'"]/g, '');
}

/** 标题相似度打分 0~1 */
export function scoreMatch(target, candidate) {
  const a = norm(target);
  const b = norm(candidate);
  if (!a || !b) return 0;
  if (a === b) return 1;
  if (a.includes(b) || b.includes(a)) {
    return 0.75 + 0.2 * (Math.min(a.length, b.length) / Math.max(a.length, b.length));
  }
  // 简易 2-gram 重合度
  const grams = (s) => {
    const set = new Set();
    for (let i = 0; i < s.length - 1; i++) set.add(s.slice(i, i + 2));
    return set;
  };
  const ga = grams(a), gb = grams(b);
  let hit = 0;
  for (const g of ga) if (gb.has(g)) hit++;
  return hit === 0 ? 0 : (2 * hit) / (ga.size + gb.size);
}

export class MetadataEnricher {
  /**
   * @param {object} opts
   * @param {Array} opts.providers 按优先级排列的 provider 实例
   * @param {import('./providers/llm.mjs').LlmProvider} [opts.llm]
   * @param {boolean} [opts.llmFallback] 公开源全部落空时是否调用 LLM
   * @param {number} [opts.minScore] 判定为"命中"的最低相似度
   * @param {(msg:string)=>void} [opts.onLog]
   */
  constructor({
    providers = [],
    llm = null,
    llmFallback = false,
    minScore = 0.6,
    onLog = () => {},
  } = {}) {
    this.providers = providers;
    this.llm = llm;
    this.llmFallback = llmFallback;
    this.minScore = minScore;
    this.onLog = onLog;
  }

  /**
   * 补全单本书（原地修改并返回自身）
   * @param {object} book
   * @returns {Promise<{book:object, hit:string|null, score:number}>}
   */
  async enrich(book) {
    const query = [book.title, book.authors?.[0]].filter(Boolean).join(' ');
    let best = null;

    for (const p of this.providers) {
      if (p.available === false) {
        this.onLog(`跳过 ${p.constructor.name}（不可用）`);
        continue;
      }
      let results = [];
      try {
        results = await p.search(query, 5);
      } catch (e) {
        this.onLog(`${p.constructor.name} 查询失败：${e.message}`);
        continue;
      }
      for (const r of results) {
        const s = scoreMatch(book.title, r.title);
        if (s >= this.minScore && (!best || s > best.score)) {
          best = { score: s, meta: r, provider: p.constructor.name, providerRef: p };
        }
      }
      if (best && best.score > 0.9) break;
    }

    // 搜索接口返回的是精简字段（无分类/简介），命中后按官方规范
    // 再用 bookId 调 /book/info 取完整元数据
    if (best && best.meta.sourceBookId && typeof best.providerRef?.detail === 'function'
        && (!book.description || !book.categoryPrimary)) {
      try {
        const detail = await best.providerRef.detail(best.meta.sourceBookId);
        for (const [k, v] of Object.entries(detail)) {
          if (v == null || v === '' || (Array.isArray(v) && v.length === 0)) continue;
          if (best.meta[k] == null || best.meta[k] === '') best.meta[k] = v;
        }
      } catch { /* 详情失败不影响已命中的基础字段 */ }
    }

    if (best) {
      this.onLog(`命中 ${best.provider}（相似度 ${best.score.toFixed(2)}）：${best.meta.title}`);
      mergeMeta(book, best.meta);
    } else {
      this.onLog(`未命中任何公开数据源：${book.title}`);
    }

    const needLlm =
      this.llmFallback && this.llm?.available &&
      (!book.categoryPrimary || !book.description);
    if (needLlm) {
      try {
        const inferred = await this.llm.inferMetadata(book, DEFAULT_CATEGORIES);
        mergeMeta(book, { ...inferred, source: book.source });
        this.onLog(`LLM 兜底补全成功：${book.title}`);
      } catch (e) {
        this.onLog(`LLM 兜底失败：${e.message}`);
      }
    }

    return { book, hit: best?.provider ?? null, score: best?.score ?? 0 };
  }

  /**
   * 批量补全，带并发控制与节流。
   * 微信读书网关有频率限制（超限返回 HTTP 499 / errcode -2014），
   * 因此默认在每本书之间插入间隔，宁可慢也不能被限流。
   */
  async enrichAll(books, { concurrency = 2, delayMs = 700 } = {}) {
    const out = [];
    const queue = [...books];
    const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
    const workers = Array.from({ length: Math.min(concurrency, queue.length) }, async () => {
      while (queue.length) {
        const b = queue.shift();
        out.push(await this.enrich(b));
        if (delayMs) await sleep(delayMs);
      }
    });
    await Promise.all(workers);
    return out;
  }
}

/** 字段合并：只填补空缺，不覆盖已有值（已有值通常来自用户，更可信） */
export function mergeMeta(book, meta) {
  const fill = (k, v) => {
    if (v == null || v === '' || (Array.isArray(v) && v.length === 0)) return;
    if (book[k] == null || book[k] === '' || (Array.isArray(book[k]) && book[k].length === 0)) {
      book[k] = v;
    }
  };
  fill('subtitle', meta.subtitle);
  fill('authors', meta.authors);
  fill('translators', meta.translators);
  fill('publisher', meta.publisher);
  fill('publishedAt', meta.publishedAt);
  fill('isbn13', meta.isbn13);
  fill('coverUrl', meta.coverUrl);
  fill('description', meta.description);
  fill('categoryPrimary', meta.categoryPrimary);
  fill('categoryPath', meta.categoryPath);
  fill('language', meta.language);
  fill('pageCount', meta.pageCount);
  fill('wordCount', meta.wordCount);
  fill('sourceBookId', meta.sourceBookId);
  if (Array.isArray(meta.tags) && meta.tags.length) {
    book.tags = [...new Set([...(book.tags ?? []), ...meta.tags])];
  }
  return book;
}
