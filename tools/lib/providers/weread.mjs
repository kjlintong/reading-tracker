/**
 * 微信读书官方 Agent 网关 Provider
 *
 * 端点：POST https://i.weread.qq.com/api/agent/gateway
 * 鉴权：Authorization: Bearer <WEREAD_API_KEY>（wrk-xxx 格式）
 * 获取 key：微信扫码打开 https://weread.qq.com/r/weread-skills 后复制
 *
 * 这是官方开放的 Skill 网关，可覆盖：书架、阅读进度、笔记划线、阅读统计、
 * 书城搜索。相比社区流传的 cookie 抓取方案，稳定性与合规性都更好。
 */

const GATEWAY = 'https://i.weread.qq.com/api/agent/gateway';
// 官方要求上报版本号；低于最新版时回包会带 upgrade_info 提示升级
const SKILL_VERSION = '1.0.4';

export class WereadProvider {
  constructor({ apiKey, fetchImpl = globalThis.fetch, timeoutMs = 15000 } = {}) {
    this.apiKey = apiKey ?? process.env.WEREAD_API_KEY ?? null;
    this.fetch = fetchImpl;
    this.timeoutMs = timeoutMs;
  }

  get available() {
    return Boolean(this.apiKey);
  }

  async call(apiName, payload = {}) {
    if (!this.available) throw new Error('缺少 WEREAD_API_KEY');
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), this.timeoutMs);
    try {
      const res = await this.fetch(GATEWAY, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ api_name: apiName, skill_version: SKILL_VERSION, ...payload }),
        signal: ctrl.signal,
      });
      if (!res.ok) {
        throw new Error(`weread ${apiName} 失败: HTTP ${res.status}`);
      }
      return await res.json();
    } finally {
      clearTimeout(timer);
    }
  }

  /** 书城搜索 → 用于元数据补全 */
  async search(keyword, count = 5) {
    const raw = await this.call('/store/search', { keyword, scope: 10, count });
    return (this.#extractBooks(raw) ?? []).map((b) => this.toMeta(b));
  }

  /**
   * 书架。返回 { books, albums, archive, mp, total }
   * 官方口径：书架条目总数 = books.length + albums.length + (mp 非空 ? 1 : 0)
   * albums 是专辑/有声书，archive 是书单（含 bookIds）
   */
  async shelf() {
    const raw = await this.call('/shelf/sync');
    const books = this.#extractBooks(raw) ?? [];
    const albums = Array.isArray(raw.albums) ? raw.albums : [];
    const archive = Array.isArray(raw.archive) ? raw.archive : [];
    const mp = raw.mp ?? null;
    return {
      books,
      albums,
      archive,
      mp,
      total: books.length + albums.length + (mp ? 1 : 0),
    };
  }

  /**
   * 阅读进度。progress 是 0-100 整数（1 表示 1%，不是 100%）
   * recordReadingTime 是累计阅读时长，单位「秒」
   */
  async getProgress(bookId) {
    const raw = await this.call('/book/getprogress', { bookId });
    const b = raw.book ?? raw.data?.book ?? raw;
    return {
      bookId,
      progress: Number(b.progress ?? 0),
      chapterUid: b.chapterUid ?? null,
      readingTimeSec: Number(b.recordReadingTime ?? 0),
      finishTime: b.finishTime ?? null,
      isStartReading: b.isStartReading ?? null,
      updateTime: b.updateTime ?? null,
    };
  }

  /** 章节目录 */
  async chapterInfo(bookId) {
    const raw = await this.call('/book/chapterinfo', { bookId });
    return raw.chapters ?? raw.data?.chapters ?? [];
  }

  /** 笔记本概览（每本书的笔记/划线/想法计数） */
  async notebooks(count = 100) {
    const raw = await this.call('/user/notebooks', { count });
    return raw.books ?? raw.data?.books ?? [];
  }

  /** 某本书的划线 */
  async bookmarks(bookId) {
    const raw = await this.call('/book/bookmarklist', { bookId });
    return raw.updated ?? raw.data?.updated ?? [];
  }

  /** 书籍详情 → 统一元数据（搜索接口是精简字段，完整字段要走这里） */
  async detail(bookId) {
    const raw = await this.call('/book/info', { bookId });
    const b = raw.data ?? raw;
    return this.toMeta({ ...b, bookId: b.bookId ?? bookId });
  }

  /** 阅读统计 */
  async readingStats(mode = 'overall') {
    return await this.call('/readdata/detail', { mode });
  }

  /** 书籍详情（含目录与阅读进度） */
  async bookInfo(bookId) {
    return await this.call('/book/info', { bookId });
  }

  #extractBooks(raw) {
    // 网关响应外层结构可能变动，这里做宽松探测
    if (!raw || typeof raw !== 'object') return [];
    const data = raw.data ?? raw;

    // 书城搜索结构：results[] → books[] → bookInfo（三层嵌套）
    if (Array.isArray(data.results)) {
      const out = [];
      for (const r of data.results) {
        if (!Array.isArray(r.books)) continue;
        for (const b of r.books) out.push(b.bookInfo ?? b);
      }
      if (out.length) return out;
    }

    const candidates = [
      data.books, data.bookList, data.list, data.items,
      data.searchBooks, data.data?.books,
    ];
    for (const c of candidates) if (Array.isArray(c)) return c;
    if (Array.isArray(data)) return data;
    return [];
  }

  toMeta(b) {
    const cat = parseCategory(b.category);
    return {
      title: b.title ?? null,
      subtitle: b.subTitle ?? b.subtitle ?? null,
      authors: splitAuthors(b.author ?? b.authors),
      translators: splitAuthors(b.translator ?? b.translators),
      publisher: b.publisher ?? b.publishingHouse ?? null,
      publishedAt: b.publishTime ?? b.publishDate ?? null,
      coverUrl: b.cover ?? b.coverUrl ?? b.picUrl ?? null,
      description: b.intro ?? b.description ?? b.bookInfo?.intro ?? null,
      categoryPrimary: cat.primary,
      categoryPath: cat.path,
      isbn13: b.isbn ?? null,
      wordCount: b.wordCount ?? null,
      source: 'weread',
      sourceBookId: b.bookId ? String(b.bookId) : null,
      raw: b,
    };
  }
}

/**
 * 拆分作者字段。
 * 微信读书把多个作者拼在一个字符串里，例如
 *   "[美]保罗·海恩 [美]彼得·勃特克 [美]大卫·普雷契特科"
 * 需要拆成三个作者，并去掉国籍前缀；同时不能把 "瑞·达利欧"、
 * "Craig M. WRIGHT" 这类含间隔号或英文缩写的单个人名拆坏。
 */
export function splitAuthors(v) {
  if (v == null) return [];
  if (Array.isArray(v)) return [...new Set(v.flatMap(splitAuthors))];
  const s = String(v).trim();
  if (!s) return [];

  const out = [];
  for (const part of String(s).split(/[\s,，、;；]+/).filter(Boolean)) {
    // 剥离国籍/朝代前缀 [美] 与 著/译 后缀
    const name = part
      .replace(/^\[[^\]]{1,8}\]/, '')
      .replace(/(著|编著|译|著译)$/, '')
      .trim();
    if (!name) continue;
    // 英文中间名缩写（"M."）并入前一个名字，避免把 Craig M. WRIGHT 拆成三个人
    if (/^[A-Za-z]\.$/.test(name) && out.length) {
      out[out.length - 1] += ` ${name}`;
      continue;
    }
    out.push(name);
  }
  return [...new Set(out)];
}

/**
 * 分类拆分："经济理财-财经" → { primary: '经济理财', path: '经济理财-财经' }
 */
export function parseCategory(v) {
  if (!v) return { primary: null, path: null };
  const s = String(v).trim();
  if (!s) return { primary: null, path: null };
  const parts = s.split(/[-–—]/).map((x) => x.trim()).filter(Boolean);
  return { primary: parts[0] ?? null, path: s };
}

/** 秒 → "X小时Y分钟" */
export function formatDuration(sec) {
  const s = Number(sec) || 0;
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  if (h === 0) return `${m}分钟`;
  return m === 0 ? `${h}小时` : `${h}小时${m}分钟`;
}

/** Unix 秒 → YYYY-MM-DD */
export function formatDate(ts) {
  if (!ts) return null;
  const d = new Date(Number(ts) * 1000);
  if (Number.isNaN(d.getTime())) return null;
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${dd}`;
}
