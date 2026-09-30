/**
 * Notion 导出 → 统一数据模型
 *
 * 针对真实 Notion 导出（英文列名 + emoji 值）做了适配：
 * - Rating   用 ⭐️ emoji（U+2B50），不是 ★（U+2605）——两种都支持
 * - Status   英文值：Finished / Reading / Want to Read / Ready to Start
 * - Dates    支持范围格式 "March 21, 2025 → July 24, 2025"，解析出起止日期
 * - Month Finished 带 emoji 前缀（🌱March），需清洗后与 Year Finished 合成日期
 * - theme    多值逗号分隔，直接作为标签
 * - Quotes / My Library 是 Notion 关联字段，值形如 "书名 (URL编码.md)"
 *
 * 数据零丢失原则：未识别列统一收进 extra。
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  createBook, BookStatus, BookFormat, BookSource, normalizeIsbn,
} from './lib/schema.mjs';

/* --------------------------- CSV 解析 --------------------------- */

export function parseCsv(text) {
  const rows = [];
  let row = [], field = '', inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') { field += '"'; i++; }
        else inQuotes = false;
      } else field += c;
    } else if (c === '"') {
      inQuotes = true;
    } else if (c === ',') {
      row.push(field); field = '';
    } else if (c === '\n') {
      row.push(field); rows.push(row); row = []; field = '';
    } else if (c !== '\r') {
      field += c;
    }
  }
  if (field !== '' || row.length) { row.push(field); rows.push(row); }
  return rows.filter((r) => r.some((c) => c.trim() !== ''));
}

/* ---------------------- 列名自动识别 ---------------------- */

const FIELD_SYNONYMS = {
  title:        ['书名', '标题', '书籍', 'name', 'title', 'book', 'book name', '书籍名称'],
  subtitle:     ['副标题', 'subtitle', 'sub title'],
  authors:      ['作者', 'author', 'authors', '著', '作者名'],
  translators:  ['译者', 'translator', 'translators'],
  publisher:    ['出版社', '出版', 'publisher', 'press', '出版方'],
  publishedAt:  ['出版日期', '出版年', '出版时间', 'published', 'publish date'],
  isbn:         ['isbn', '书号', '国际标准书号'],
  category:     ['分类', '类别', 'category', 'categories', 'genre', '类型', '门类'],
  tags:         ['标签', 'tag', 'tags', '关键词', 'keyword', 'keywords', 'theme', '主题'],
  description:  ['简介', '内容简介', 'description', 'intro', 'synopsis', '概要'],
  status:       ['状态', '阅读状态', 'status', 'reading status', '进度状态'],
  progress:     ['进度', '阅读进度', 'progress', 'percent', '百分比'],
  rating:       ['评分', 'rating', 'score', '打分', '星级', 'stars'],
  review:       ['读后感', '书评', 'review', '心得', '评论'],
  summary:      ['摘要', 'summary', 'abstract', '笔记摘要'],
  highlights:   ['摘抄', '金句', 'highlights', '划线', '摘录', 'quotes'],
  dates:        ['日期', 'dates', 'date', '阅读日期'],
  startedAt:    ['开始日期', '开始时间', 'start', 'started', 'start date', '开读'],
  finishedAt:   ['完成日期', '读完日期', '结束日期', 'finish', 'date finished', '读完'],
  monthFinished: ['month finished', '读完月份', '完成月份'],
  yearFinished:  ['year finished', '读完年份', '完成年份'],
  pageCount:    ['页数', '总页数', 'pages', 'page count', '总页码'],
  wordCount:    ['字数', 'word count', '万字'],
  format:       ['形式', '载体', 'format', '类型载体', '媒介'],
  source:       ['来源', '平台', 'source', 'app', '阅读平台', '渠道'],
  borrowedFrom: ['借阅地', '借自', '图书馆', 'borrowed from', 'lent from'],
  dueAt:        ['应还日期', '还书日期', 'due', 'due date', '到期'],
  coverUrl:     ['封面', '封面链接', 'cover', 'cover url', '图片'],
  rereadCount:  ['重读次数', 'reread', '读过次数'],
  link:         ['link', '链接', 'url'],
  // Quotes 库专用
  quote:        ['quote', '金句内容', '内容'],
  relatedBook:  ['my library', '关联书籍', '所属书'],
  pageAt:       ['page number', '页码', 'page'],
};

const STATUS_MAP = {
  '想读': BookStatus.WISH, '未读': BookStatus.WISH, '待读': BookStatus.WISH,
  '在读': BookStatus.READING, '正在读': BookStatus.READING, '阅读中': BookStatus.READING,
  '已读': BookStatus.FINISHED, '读完': BookStatus.FINISHED, '已完成': BookStatus.FINISHED,
  '弃读': BookStatus.ABANDONED, '弃坑': BookStatus.ABANDONED, '放弃': BookStatus.ABANDONED,
  '借阅中': BookStatus.BORROWED, '借入': BookStatus.BORROWED,
  '暂搁': BookStatus.PAUSED, '暂停': BookStatus.PAUSED,
  'to read': BookStatus.WISH, 'want to read': BookStatus.WISH,
  'ready to start': BookStatus.WISH, 'wish': BookStatus.WISH, 'not started': BookStatus.WISH,
  'reading': BookStatus.READING, 'current': BookStatus.READING,
  'currently reading': BookStatus.READING, 'in progress': BookStatus.READING,
  'finished': BookStatus.FINISHED, 'done': BookStatus.FINISHED, 'read': BookStatus.FINISHED,
  'completed': BookStatus.FINISHED,
  'abandoned': BookStatus.ABANDONED, 'dnf': BookStatus.ABANDONED, 'dropped': BookStatus.ABANDONED,
  'borrowed': BookStatus.BORROWED,
  'paused': BookStatus.PAUSED, 'on hold': BookStatus.PAUSED,
};

const FORMAT_MAP = {
  '电子书': BookFormat.EBOOK, 'ebook': BookFormat.EBOOK, '电子': BookFormat.EBOOK,
  'digital': BookFormat.EBOOK, '电子版': BookFormat.EBOOK,
  '纸质': BookFormat.PAPER, '纸质书': BookFormat.PAPER, 'paper': BookFormat.PAPER,
  '实体书': BookFormat.PAPER, 'physical': BookFormat.PAPER, '印刷': BookFormat.PAPER,
  'hardcover': BookFormat.PAPER, 'paperback': BookFormat.PAPER,
  '有声': BookFormat.AUDIO, '有声书': BookFormat.AUDIO, 'audio': BookFormat.AUDIO,
  'audiobook': BookFormat.AUDIO,
  'pdf': BookFormat.PDF,
  '漫画': BookFormat.COMIC, '绘本': BookFormat.COMIC, 'comic': BookFormat.COMIC,
};

const SOURCE_MAP = {
  '微信读书': BookSource.WEREAD, 'weread': BookSource.WEREAD, '微信': BookSource.WEREAD,
  '掌阅': BookSource.ZHANGYUE, '掌阅精选': BookSource.ZHANGYUE, 'ireader': BookSource.ZHANGYUE,
  '京东读书': BookSource.JDREAD, 'jdread': BookSource.JDREAD, '京东': BookSource.JDREAD,
  '文石': BookSource.BOOX, 'boox': BookSource.BOOX, 'onyx': BookSource.BOOX,
  '图书馆': BookSource.LIBRARY, 'library': BookSource.LIBRARY, '借阅': BookSource.LIBRARY,
  'notion': BookSource.NOTION,
};

const MONTH_NAMES = {
  january: 1, february: 2, march: 3, april: 4, may: 5, june: 6,
  july: 7, august: 8, september: 9, october: 10, november: 11, december: 12,
  jan: 1, feb: 2, mar: 3, apr: 4, jun: 6, jul: 7, aug: 8,
  sep: 9, sept: 9, oct: 10, nov: 11, dec: 12,
  '一月': 1, '二月': 2, '三月': 3, '四月': 4, '五月': 5, '六月': 6,
  '七月': 7, '八月': 8, '九月': 9, '十月': 10, '十一月': 11, '十二月': 12,
};

function normKey(k) {
  return String(k).trim().toLowerCase().replace(/\s+/g, ' ');
}

/** 建立「原列名 → 标准字段」映射 */
export function buildColumnMapping(headers) {
  const mapping = {};
  const unmapped = [];
  for (const h of headers) {
    const key = normKey(h);
    let hit = null;
    // 精确匹配优先，避免 'book' 同时命中 title 与 relatedBook
    for (const [field, syns] of Object.entries(FIELD_SYNONYMS)) {
      if (syns.includes(key)) { hit = field; break; }
    }
    if (!hit) {
      for (const [field, syns] of Object.entries(FIELD_SYNONYMS)) {
        if (syns.some((s) => key.includes(s))) { hit = field; break; }
      }
    }
    if (hit) mapping[h] = hit;
    else unmapped.push(h);
  }
  return { mapping, unmapped };
}

/* ---------------------- 脏值解析 ---------------------- */

/** 进度："45%" / "45" / "120/300" */
export function parseProgress(v) {
  if (v == null) return null;
  const s = String(v).trim();
  if (!s) return null;
  const ratio = s.match(/(\d+(?:\.\d+)?)\s*\/\s*(\d+(?:\.\d+)?)/);
  if (ratio) {
    const [_, a, b] = ratio;
    if (Number(b) > 0) return Math.min(100, (Number(a) / Number(b)) * 100);
  }
  const pct = s.match(/(\d+(?:\.\d+)?)\s*%/);
  if (pct) return Math.min(100, Number(pct[1]));
  const num = s.match(/^(\d+(?:\.\d+)?)$/);
  if (num) {
    const n = Number(num[1]);
    return n <= 100 ? n : null;
  }
  return null;
}

/**
 * 评分：支持 ★（U+2605）、⭐️（U+2B50 + 变体选择符）、"4/5"、"4.5"、"4"
 * Notion 导出实际用的是 ⭐️ emoji
 */
export function parseRating(v) {
  if (v == null) return null;
  const s = String(v).trim();
  if (!s) return null;
  const stars = (s.match(/[\u2B50\u2605]/g) || []).length;
  if (stars) return Math.min(5, stars);
  const frac = s.match(/(\d+(?:\.\d+)?)\s*\/\s*(\d+(?:\.\d+)?)/);
  if (frac) return Number(frac[1]);
  const num = s.match(/^(\d+(?:\.\d+)?)$/);
  return num ? Math.min(5, Number(num[1])) : null;
}

/** 日期：ISO / "April 18, 2025" / "2024/01/31" */
export function parseDate(v) {
  if (v == null) return null;
  const s = String(v).trim();
  if (!s) return null;
  const iso = s.match(/^(\d{4})[-/](\d{1,2})[-/](\d{1,2})/);
  if (iso) return `${iso[1]}-${iso[2].padStart(2, '0')}-${iso[3].padStart(2, '0')}`;
  const d = new Date(s);
  if (!Number.isNaN(d.getTime())) {
    // 必须用本地时区字段，不能用 toISOString()——那会把本地午夜转成 UTC 前一天
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${dd}`;
  }
  const y = s.match(/^(\d{4})$/);
  return y ? `${y[1]}-01-01` : null;
}

/**
 * 日期范围：Notion 用 → 分隔起止
 * "March 21, 2025 → July 24, 2025" → {start, end}
 * "April 18, 2025"                 → {start, end: null}
 */
export function parseDateRange(v) {
  if (v == null) return { start: null, end: null };
  const s = String(v).trim();
  if (!s) return { start: null, end: null };
  const parts = s.split(/\s*(?:→|->|–|—| to )\s*/i).filter(Boolean);
  if (parts.length >= 2) {
    return { start: parseDate(parts[0]), end: parseDate(parts[parts.length - 1]) };
  }
  return { start: parseDate(parts[0] ?? s), end: null };
}

/** 去除 emoji、变体选择符与零宽连接符 */
export function stripEmoji(s) {
  return String(s ?? '')
    .replace(/[\uFE0F\u200D]/g, '')
    .replace(/[\u{1F000}-\u{1FAFF}]/gu, '')
    .replace(/[\u{2190}-\u{21FF}]/gu, '')
    .replace(/[\u{2600}-\u{27BF}]/gu, '')
    .trim();
}

/** "🌱March" → 3；"三月" → 3 */
export function parseMonth(v) {
  const s = stripEmoji(v).toLowerCase().replace(/月$/, '').trim();
  if (!s) return null;
  if (/^\d{1,2}$/.test(s)) {
    const n = Number(s);
    return n >= 1 && n <= 12 ? n : null;
  }
  return MONTH_NAMES[s] ?? null;
}

/**
 * Notion 关联字段："沉思录 (%E6%B2%89%E6%80%9D%E5%BD%95%20xxx.md)"
 * → [{ name: '沉思录', file: '沉思录 21bd...md' }]
 */
export function parseRelation(v) {
  const s = String(v ?? '').trim();
  if (!s) return [];
  const out = [];
  for (const m of s.matchAll(/([^,(]+?)\s*\(([^)]+)\)/g)) {
    let name = m[1].trim();
    let file = m[2].trim();
    try { file = decodeURIComponent(file); } catch { /* 保持原样 */ }
    name = name.replace(/\s+[0-9a-f]{16,}(\.md)?$/i, '').replace(/\.md$/i, '').trim();
    out.push({ name, file });
  }
  if (!out.length) {
    return s.split(',').map((x) => {
      let t = x.trim().replace(/\.md$/i, '');
      try { t = decodeURIComponent(t); } catch { /* noop */ }
      return { name: t.replace(/\s+[0-9a-f]{16,}$/i, '').trim(), file: null };
    }).filter((r) => r.name);
  }
  return out;
}

export function parseStatus(v) {
  const s = String(v ?? '').trim().toLowerCase();
  return STATUS_MAP[s] ?? null;
}

/* ---------------------- 转换主流程 ---------------------- */

/**
 * Notion "My Library" → 书籍数组
 */
export function convertLibrary(csvText, opts = {}) {
  const rows = parseCsv(String(csvText).replace(/^\uFEFF/, ''));
  if (!rows.length) return { books: [], mapping: {}, unmapped: [], total: 0 };

  const headers = rows[0];
  const { mapping, unmapped } = buildColumnMapping(headers);

  const books = [];
  for (const row of rows.slice(1)) {
    const raw = {};
    const extra = {};
    headers.forEach((h, i) => {
      const field = mapping[h];
      const val = row[i] ?? '';
      if (!field) { if (val.trim()) extra[h] = val.trim(); return; }
      if (val.trim()) raw[field] = val.trim();
    });

    if (!raw.title) continue;

    const status = parseStatus(raw.status) ?? BookStatus.WISH;
    const range = parseDateRange(raw.dates);
    const isRange = /\s*(?:→|->|–|—| to )\s*/i.test(raw.dates ?? '');

    // 完成日期：优先 Dates 的结束日期，其次 Year + Month Finished
    let finishedAt = range.end;

    // 开始日期语义区分：
    // - 日期范围 → 前段确为开始阅读日
    // - 已读 + 单日期 → 视为开始阅读日
    // - 其余（想读/在读）的单日期 → 实为「加入书架日」，存 extra 不污染 startedAt
    let startedAt = null;
    if (isRange || status === BookStatus.FINISHED) {
      startedAt = range.start;
    } else if (range.start) {
      extra.notionAddedAt = range.start;
    }
    if (!finishedAt && raw.yearFinished) {
      const year = raw.yearFinished.match(/^\d{4}$/) ? raw.yearFinished : null;
      if (year) {
        const mm = parseMonth(raw.monthFinished ?? '');
        finishedAt = mm ? `${year}-${String(mm).padStart(2, '0')}-01` : `${year}-01-01`;
      }
    }

    // Notion 主题 → 标签
    const tags = [];
    for (const t of String(raw.tags ?? '').split(',')) {
      const v = t.trim();
      if (v) tags.push(v);
    }

    if (raw.status) extra.notionStatus = raw.status;
    if (raw.link) extra.notionLink = raw.link;

    const book = createBook({
      title: raw.title,
      authors: raw.authors,
      translators: raw.translators,
      publisher: raw.publisher,
      publishedAt: raw.publishedAt,
      isbn: normalizeIsbn(raw.isbn),
      tags,
      description: raw.description,
      categoryPrimary: raw.category,
      review: raw.review,
      summary: raw.summary,
      status,
      progressPercent: parseProgress(raw.progress) ?? (status === BookStatus.FINISHED ? 100 : 0),
      rating: parseRating(raw.rating) ?? 0,
      startedAt,
      finishedAt,
      pageCount: raw.pageCount,
      wordCount: raw.wordCount,
      format: FORMAT_MAP[String(raw.format ?? '').trim().toLowerCase()] ?? null,
      source: SOURCE_MAP[String(raw.source ?? '').trim().toLowerCase()]
          ?? opts.source ?? BookSource.NOTION,
      borrowedFrom: raw.borrowedFrom,
      dueAt: parseDate(raw.dueAt),
      coverUrl: raw.coverUrl,
      rereadCount: raw.rereadCount,
      extra,
    });
    books.push(book);
  }
  return { books, mapping, unmapped, total: rows.length - 1 };
}

/**
 * Notion "Quotes" → 笔记数组（划线 / 金句），通过关联字段挂到书
 */
export function convertQuotes(csvText) {
  const rows = parseCsv(String(csvText).replace(/^\uFEFF/, ''));
  if (!rows.length) return { notes: [], mapping: {}, unmapped: [], total: 0 };

  const headers = rows[0];
  const { mapping, unmapped } = buildColumnMapping(headers);

  const notes = [];
  for (const row of rows.slice(1)) {
    const raw = {};
    headers.forEach((h, i) => {
      const field = mapping[h];
      const val = row[i] ?? '';
      if (field && val.trim()) raw[field] = val.trim();
    });

    const content = raw.quote ?? raw.highlights ?? raw.review;
    if (!content) continue;

    const rel = parseRelation(raw.relatedBook ?? '');
    const pageAt = raw.pageAt ? Number(String(raw.pageAt).replace(/[^\d]/g, '')) : null;

    notes.push({
      id: `quote_${notes.length}_${Math.random().toString(36).slice(2, 8)}`,
      type: 'highlight',
      content: content.replace(/\s*\n\s*/g, '\n').trim(),
      chapter: null,
      pageAt: Number.isFinite(pageAt) ? pageAt : null,
      source: 'notion',
      bookTitle: rel[0]?.name ?? null,   // 关联书名，入库前用于匹配
      bookAuthor: raw.authors ?? null,
      createdAt: new Date().toISOString(),
    });
  }
  return { notes, mapping, unmapped, total: rows.length - 1 };
}

/** 通用入口（兼容普通 CSV） */
export function convertCsv(csvText, opts = {}) {
  return convertLibrary(csvText, opts);
}

/** 解析 Notion Markdown 页的属性块 */
export function parseMdProps(mdText) {
  const props = {};
  for (const line of String(mdText).split('\n').slice(0, 40)) {
    const m = line.match(/^([A-Za-z][A-Za-z0-9 ]*)\s*:\s*(.+)$/);
    if (m) props[m[1].trim()] = m[2].trim();
  }
  return props;
}

/* ---------------------- CLI ---------------------- */

function isMain() {
  if (!process.argv[1]) return false;
  return path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
}

if (isMain()) {
  const args = process.argv.slice(2);
  const input = args[0];
  const outArg = args.includes('--out') ? args[args.indexOf('--out') + 1] : null;
  const quotesArg = args.includes('--quotes') ? args[args.indexOf('--quotes') + 1] : null;

  if (!input) {
    console.error('用法: node notion-import.mjs <My Library.csv> [--quotes Quotes.csv] [--out books.json]');
    process.exit(1);
  }

  const { books, mapping, unmapped, total } = convertLibrary(fs.readFileSync(input, 'utf8'));

  console.log(`\n解析完成：共 ${total} 行，成功转换 ${books.length} 本书`);
  console.log('\n列映射：');
  for (const [orig, std] of Object.entries(mapping)) console.log(`  ${orig} → ${std}`);
  if (unmapped.length) {
    console.log('\n未识别列（已存入 extra，不丢失）：');
    unmapped.forEach((u) => console.log(`  - ${u}`));
  }

  const byStatus = {};
  for (const b of books) byStatus[b.status] = (byStatus[b.status] ?? 0) + 1;
  console.log('\n状态分布：', byStatus);
  console.log(`有完成日期：${books.filter((b) => b.finishedAt).length} 本；`
      + `有评分：${books.filter((b) => b.rating > 0).length} 本；`
      + `有起止日期：${books.filter((b) => b.startedAt && b.finishedAt).length} 本`);

  console.log('\n示例（前 5 本）：');
  books.slice(0, 5).forEach((b) => {
    console.log(`  《${b.title}》 ${b.authors.join('、') || '-'} | ${b.status} | ${b.rating}星 `
        + `| ${b.startedAt ?? '?'} → ${b.finishedAt ?? '?'} | ${b.tags.join(',')}`);
  });

  let notes = [];
  if (quotesArg) {
    const q = convertQuotes(fs.readFileSync(quotesArg, 'utf8'));
    notes = q.notes;
    console.log(`\n金句：解析 ${q.total} 行，得到 ${notes.length} 条，`
        + `可关联到书 ${notes.filter((n) => n.bookTitle).length} 条`);
  }

  if (outArg) {
    fs.writeFileSync(outArg, JSON.stringify({ books, notes }, null, 2), 'utf8');
    console.log(`\n已写出：${outArg}`);
  }
}
