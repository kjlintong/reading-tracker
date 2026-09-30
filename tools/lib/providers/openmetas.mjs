/**
 * Google Books / Open Library Provider
 *
 * 作为中文书籍的补充源。注意：这两个域名在部分网络环境（含中国大陆
 * 常见办公网络）不可直连，运行时会自动降级并给出提示，不会中断导入流程。
 */

const GB = 'https://www.googleapis.com/books/v1/volumes';
const OL = 'https://openlibrary.org/search.json';

export class GoogleBooksProvider {
  constructor({ fetchImpl = globalThis.fetch, timeoutMs = 12000 } = {}) {
    this.fetch = fetchImpl;
    this.timeoutMs = timeoutMs;
  }
  get available() { return true; }

  async search(keyword, count = 5) {
    const url = `${GB}?q=${encodeURIComponent(keyword)}&maxResults=${count}`;
    const res = await this.#get(url);
    const items = res?.items ?? [];
    return items.map((it) => {
      const v = it.volumeInfo ?? {};
      return {
        title: v.title ?? null,
        subtitle: v.subtitle ?? null,
        authors: v.authors ?? [],
        publisher: v.publisher ?? null,
        publishedAt: (v.publishedDate ?? '').slice(0, 10) || null,
        coverUrl: v.imageLinks?.thumbnail ?? null,
        description: v.description ?? null,
        categoryPrimary: v.categories?.[0] ?? null,
        categoryPath: (v.categories ?? []).join('/') || null,
        pageCount: v.pageCount ?? null,
        isbn13: (v.industryIdentifiers ?? []).find((i) => i.type === 'ISBN_13')?.identifier
             ?? (v.industryIdentifiers ?? []).find((i) => i.type === 'ISBN_10')?.identifier
             ?? null,
        language: v.language ?? null,
        source: 'googlebooks',
        raw: it,
      };
    });
  }

  async #get(url) {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), this.timeoutMs);
    try {
      const res = await this.fetch(url, { signal: ctrl.signal });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } finally { clearTimeout(timer); }
  }
}

export class OpenLibraryProvider {
  constructor({ fetchImpl = globalThis.fetch, timeoutMs = 12000 } = {}) {
    this.fetch = fetchImpl;
    this.timeoutMs = timeoutMs;
  }
  get available() { return true; }

  async search(keyword, count = 5) {
    const fields = 'title,author_name,publisher,first_publish_year,subject,isbn,cover_i,number_of_pages_median';
    const url = `${OL}?q=${encodeURIComponent(keyword)}&limit=${count}&fields=${fields}`;
    const res = await this.#get(url);
    return (res?.docs ?? []).map((d) => ({
      title: d.title ?? null,
      authors: d.author_name ?? [],
      publisher: d.publisher?.[0] ?? null,
      publishedAt: d.first_publish_year ? String(d.first_publish_year) : null,
      coverUrl: d.cover_i ? `https://covers.openlibrary.org/b/id/${d.cover_i}-M.jpg` : null,
      description: null,
      categoryPrimary: d.subject?.[0] ?? null,
      categoryPath: (d.subject ?? []).slice(0, 5).join('/') || null,
      pageCount: d.number_of_pages_median ?? null,
      isbn13: (d.isbn ?? []).find((s) => s.length === 13) ?? (d.isbn ?? []).find((s) => s.length === 10) ?? null,
      source: 'openlibrary',
      raw: d,
    }));
  }

  async #get(url) {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), this.timeoutMs);
    try {
      const res = await this.fetch(url, { signal: ctrl.signal });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } finally { clearTimeout(timer); }
  }
}
