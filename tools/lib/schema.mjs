/**
 * 统一数据模型（Canonical Data Model）
 *
 * 这是整个阅读管理系统的"地基"。所有导入源（微信读书 / 掌阅 / 京东读书 /
 * 文石 / 纸质书拍照 / Notion 历史 / CSV）都必须先转换成这个结构，
 * 再写入本地数据库。新增导入源时只需写一个 adapter，不动上层。
 *
 * 设计原则：
 * 1. 字段尽量可空，导入阶段允许"残缺记录"，后续由元数据补全管道补齐。
 * 2. extra 字段兜底，保证 Notion 里的自定义属性不会在迁移中丢失。
 * 3. 枚举值使用稳定字符串常量，便于跨端（Flutter / Node）共享。
 */

/** 阅读状态 */
export const BookStatus = {
  WISH: 'wish',           // 想读
  READING: 'reading',     // 在读
  FINISHED: 'finished',   // 已读
  ABANDONED: 'abandoned', // 弃读
  BORROWED: 'borrowed',   // 借阅中（图书馆）
  PAUSED: 'paused',       // 暂搁
};

export const BOOK_STATUS_LABEL = {
  wish: '想读',
  reading: '在读',
  finished: '已读',
  abandoned: '弃读',
  borrowed: '借阅中',
  paused: '暂搁',
};

/** 载体形态 */
export const BookFormat = {
  EBOOK: 'ebook',
  PAPER: 'paper',
  AUDIO: 'audio',
  PDF: 'pdf',
  COMIC: 'comic',
};

/** 来源平台 */
export const BookSource = {
  WEREAD: 'weread',       // 微信读书
  ZHANGYUE: 'zhangyue',   // 掌阅精选
  JDREAD: 'jdread',       // 京东读书专业版
  BOOX: 'boox',           // 文石本地阅读
  LIBRARY: 'library',     // 图书馆借阅
  NOTION: 'notion',       // Notion 历史数据
  MANUAL: 'manual',       // 手动录入
};

export const BOOK_SOURCE_LABEL = {
  weread: '微信读书',
  zhangyue: '掌阅精选',
  jdread: '京东读书',
  boox: '文石',
  library: '图书馆',
  notion: 'Notion',
  manual: '手动',
};

/** 笔记类型 */
export const NoteType = {
  HIGHLIGHT: 'highlight', // 划线
  THOUGHT: 'thought',     // 想法
  REVIEW: 'review',       // 书评
};

/** 默认一级分类（用于 LLM 归类时的受控词表） */
export const DEFAULT_CATEGORIES = [
  '文学', '社科', '历史', '哲学', '心理', '经济', '管理', '科技',
  '计算机', '艺术', '传记', '教育', '科普', '医学', '法律', '宗教',
  '童书', '漫画', '成长', '其他',
];

/**
 * 外部分类 → 受控词表 的归一化映射
 *
 * 问题由来：微信读书返回自有分类体系（经济理财 / 个人成长 / 哲学宗教 / 男生小说…），
 * 与受控词表（经济 / 心理 / 哲学 / 文学…）并存。若不归一，同一语义会分裂成多个
 * 标签——实测出现「经济理财 18 本」与「经济 9 本」并列，直接污染统计图表。
 *
 * 映射原则：按内容主题归并，宁可粗不可细；无法归类的落入「其他」。
 */
export const CATEGORY_ALIASES = {
  // 小说类统一归入文学
  '精品小说': '文学', '男生小说': '文学', '女生小说': '文学', '小说': '文学',
  '文学艺术': '文学', '外国文学': '文学', '中国文学': '文学',
  // 社科大类
  '社会文化': '社科', '政治军事': '社科', '社会学': '社科', '政治': '社科',
  // 哲学宗教 → 哲学（宗教在词表内但实测此类多为哲学著作，保留原值亦可通过别名调整）
  '哲学宗教': '哲学',
  // 经济类
  '经济理财': '经济', '经管': '经济', '经管励志': '管理', '理财': '经济', '金融': '经济',
  // 自我提升类单列。曾有版本并入「心理」，导致心理类占比虚高到 24%，
  // 掩盖了真实的阅读结构（学习方法 / 习惯养成与心理学并非同一主题）。
  '个人成长': '成长', '励志': '成长', '成功学': '成长', '自我提升': '成长',
  '学习方法': '成长', '职场': '成长',
  // 教育
  '教育学习': '教育', '学习教育': '教育', '教材': '教育', '外语学习': '教育',
  // 科技
  '科学技术': '科技', '自然科学': '科普', '科普读物': '科普', '计算机与互联网': '计算机',
  '互联网': '计算机', '编程': '计算机',
  // 生活类在受控词表中无对应项，落入其他
  '生活百科': '其他', '生活': '其他', '育儿': '其他', '烹饪': '其他', '健身': '其他',
  '旅行': '其他', '美食': '其他',
  // 其余常见
  '医药卫生': '医学', '医学健康': '医学', '健康': '医学',
  '艺术': '艺术', '摄影': '艺术', '设计': '艺术', '音乐': '艺术',
  '传记': '传记', '人物传记': '传记', '回忆录': '传记',
  '法律': '法律', '法学': '法律',
  '童书': '童书', '儿童文学': '童书', '绘本': '童书',
  '漫画': '漫画', '绘本漫画': '漫画',
  '管理': '管理', '商业': '管理', '企业管理': '管理',
};

/**
 * 把任意来源的分类归一化到受控词表。
 * 已在词表内的原样返回；命中别名表的映射后返回；都不命中则按包含关系兜底，
 * 仍无法判定则返回「其他」——保证下游统计口径始终一致。
 *
 * @param {string|null|undefined} raw
 * @returns {string|null} 输入为空时返回 null（区别于「无法归类」的「其他」）
 */
export function normalizeCategory(raw) {
  if (raw == null || raw === '') return null;
  const s = String(raw).trim();
  if (!s) return null;
  if (DEFAULT_CATEGORIES.includes(s)) return s;
  if (CATEGORY_ALIASES[s]) return CATEGORY_ALIASES[s];
  // 兜底：按包含关系匹配，例「经济理财-财经」→「经济」
  for (const [alias, target] of Object.entries(CATEGORY_ALIASES)) {
    if (s.includes(alias)) return target;
  }
  for (const c of DEFAULT_CATEGORIES) {
    if (s.includes(c)) return c;
  }
  return '其他';
}

/**
 * 创建一条规范化的书籍记录。
 * @param {Partial<Book>} raw
 * @returns {Book}
 */
export function createBook(raw = {}) {
  const now = new Date().toISOString();
  return {
    id: raw.id ?? crypto.randomUUID(),
    title: (raw.title ?? '').trim(),
    subtitle: raw.subtitle ?? null,
    authors: normalizeList(raw.authors),
    translators: normalizeList(raw.translators),
    publisher: raw.publisher ?? null,
    publishedAt: raw.publishedAt ?? null,
    isbn13: normalizeIsbn(raw.isbn13 ?? raw.isbn),
    coverUrl: raw.coverUrl ?? null,
    coverLocalPath: raw.coverLocalPath ?? null,

    categoryPrimary: raw.categoryPrimary ?? null,
    categoryPath: raw.categoryPath ?? null,
    tags: normalizeList(raw.tags),
    description: raw.description ?? null,
    language: raw.language ?? 'zh',

    pageCount: toInt(raw.pageCount),
    wordCount: toInt(raw.wordCount),

    format: raw.format ?? BookFormat.EBOOK,
    source: raw.source ?? BookSource.MANUAL,
    sourceBookId: raw.sourceBookId ?? null,
    sourceUrl: raw.sourceUrl ?? null,

    status: raw.status ?? BookStatus.WISH,
    progressPercent: clamp(raw.progressPercent ?? 0, 0, 100),
    currentPage: toInt(raw.currentPage),
    rating: clamp(raw.rating ?? 0, 0, 5),

    review: raw.review ?? null,      // 读后感
    summary: raw.summary ?? null,    // 摘要（Notion 原有功能）
    highlights: raw.highlights ?? null,

    startedAt: raw.startedAt ?? null,
    finishedAt: raw.finishedAt ?? null,
    borrowedFrom: raw.borrowedFrom ?? null,
    dueAt: raw.dueAt ?? null,        // 图书馆应还日期
    rereadCount: toInt(raw.rereadCount) ?? 0,

    extra: raw.extra ?? {},          // 兜底：保留源系统自定义字段
    createdAt: raw.createdAt ?? now,
    updatedAt: now,
  };
}

/** 阅读日志：一次阅读行为（用于时长统计、连续天数） */
export function createReadingLog(raw = {}) {
  return {
    id: raw.id ?? crypto.randomUUID(),
    bookId: raw.bookId,
    date: raw.date ?? new Date().toISOString().slice(0, 10),
    durationMin: toInt(raw.durationMin) ?? 0,
    pagesFrom: toInt(raw.pagesFrom),
    pagesTo: toInt(raw.pagesTo),
    note: raw.note ?? null,
    source: raw.source ?? BookSource.MANUAL,
    createdAt: new Date().toISOString(),
  };
}

/** 笔记 / 划线 / 想法 */
export function createNote(raw = {}) {
  return {
    id: raw.id ?? crypto.randomUUID(),
    bookId: raw.bookId,
    type: raw.type ?? NoteType.HIGHLIGHT,
    content: raw.content ?? '',
    chapter: raw.chapter ?? null,
    pageAt: toInt(raw.pageAt),
    source: raw.source ?? BookSource.MANUAL,
    createdAt: raw.createdAt ?? new Date().toISOString(),
  };
}

/** 导入批次：可回溯，便于出错时整批回滚 */
export function createImportBatch(raw = {}) {
  return {
    id: raw.id ?? crypto.randomUUID(),
    source: raw.source,
    method: raw.method ?? null,      // screenshot_ocr | photo_ocr | api | csv | manual
    itemCount: toInt(raw.itemCount) ?? 0,
    rawRef: raw.rawRef ?? null,      // 原始文件路径或接口响应标识
    status: raw.status ?? 'pending', // pending | done | failed
    createdAt: new Date().toISOString(),
  };
}

/* ------------------------------ 工具函数 ------------------------------ */

export function normalizeList(v) {
  if (v == null) return [];
  if (Array.isArray(v)) {
    return [...new Set(v.map((x) => String(x).trim()).filter(Boolean))];
  }
  // 支持 "A、B / A,B / A；B" 等分隔符
  return [...new Set(
    String(v).split(/[,，、;；\/|]/).map((s) => s.trim()).filter(Boolean)
  )];
}

export function normalizeIsbn(raw) {
  if (!raw) return null;
  const s = String(raw).replace(/[-\s]/g, '');
  return /^\d{10}$|^\d{13}$/.test(s) ? s : null;
}

export function toInt(v) {
  if (v == null || v === '') return null;
  const n = Number.parseInt(String(v).replace(/[^\d-]/g, ''), 10);
  return Number.isNaN(n) ? null : n;
}

export function clamp(n, min, max) {
  const v = Number(n);
  if (Number.isNaN(v)) return min;
  return Math.min(max, Math.max(min, v));
}

/**
 * 书籍指纹：用于跨源去重。
 * 优先级 ISBN > 书名+首位作者 > 书名。
 */
export function bookFingerprint(book) {
  if (book.isbn13) return `isbn:${book.isbn13}`;
  const t = (book.title ?? '').trim().toLowerCase();
  const a = (book.authors?.[0] ?? '').trim().toLowerCase();
  return `ta:${t}|${a}`;
}
