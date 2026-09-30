/**
 * 大模型 Provider（OpenAI 兼容协议）
 *
 * 用于两类任务：
 * 1. 元数据兜底：书名 + 作者 → 分类、简介、标签（公开数据源查不到时启用）
 * 2. 定期阅读报告：基于结构化阅读数据生成分析与偏好画像
 *
 * 兼容任意 OpenAI 格式端点：DeepSeek / 通义 / 智谱 / 月之暗面 / 本地 Ollama 等。
 */

/**
 * 宽松 JSON 解析
 *
 * 大模型即便开启 json_object 模式，仍可能输出非规范结构，实测遇到两类：
 *   1. 多个并列对象用逗号分隔但无外层方括号：{"a":1},{"a":2}
 *   2. 前后混入说明文字
 * 逐层降级尝试，全部失败才抛错。
 */
export function parseJsonLoose(text) {
  const cleaned = String(text ?? '').replace(/^```(?:json)?\s*/i, '').replace(/```\s*$/, '').trim();
  const attempts = [
    () => JSON.parse(cleaned),
    () => JSON.parse(`[${cleaned}]`),
  ];
  for (const fn of attempts) {
    try {
      const v = fn();
      if (v != null) return v;
    } catch { /* 继续尝试下一种 */ }
  }
  // 最后兜底：抓取最外层括号包裹的最大片段
  const m = cleaned.match(/\[[\s\S]*\]/) ?? cleaned.match(/\{[\s\S]*\}/);
  if (m) {
    try { return JSON.parse(m[0]); } catch { /* 落到抛错 */ }
  }
  throw new Error('LLM 返回的不是合法 JSON');
}

export class LlmProvider {
  constructor({
    apiKey = process.env.LLM_API_KEY,
    baseUrl = process.env.LLM_BASE_URL ?? 'https://api.deepseek.com/v1',
    model = process.env.LLM_MODEL ?? 'deepseek-chat',
    fetchImpl = globalThis.fetch,
    timeoutMs = 60000,
  } = {}) {
    this.apiKey = apiKey;
    this.baseUrl = String(baseUrl).replace(/\/+$/, '');
    this.model = model;
    this.fetch = fetchImpl;
    this.timeoutMs = timeoutMs;
  }

  get available() { return Boolean(this.apiKey); }

  async chat(messages, { temperature = 0.3, jsonMode = false } = {}) {
    if (!this.available) throw new Error('缺少 LLM_API_KEY');
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), this.timeoutMs);
    try {
      const res = await this.fetch(`${this.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: this.model,
          messages,
          temperature,
          ...(jsonMode ? { response_format: { type: 'json_object' } } : {}),
        }),
        signal: ctrl.signal,
      });
      if (!res.ok) {
        const t = await res.text().catch(() => '');
        throw new Error(`LLM 调用失败: HTTP ${res.status} ${t.slice(0, 200)}`);
      }
      const data = await res.json();
      return data.choices?.[0]?.message?.content ?? '';
    } finally { clearTimeout(timer); }
  }

  async json(messages) {
    const raw = await this.chat(messages, { jsonMode: true });
    const cleaned = raw.replace(/^```(?:json)?\s*/i, '').replace(/```\s*$/, '').trim();
    return parseJsonLoose(cleaned);
  }

  /**
   * 批量元数据补全：一次请求处理多本书，显著降低请求数与总耗时。
   * @param {Array<{title:string, authors:string[]}>} books
   * @param {string[]} categoryVocab 受控分类词表
   * @returns {Promise<Array<{index:number, categoryPrimary:string, description:string, tags:string[]}>>}
   */
  async inferMetadataBatch(books, categoryVocab) {
  const sys = '你是图书编目助手。只输出 JSON，不要解释。';
  const payload = books.map((b, i) => ({
    index: i,
    title: b.title,
    authors: b.authors ?? [],
  }));
  const usr = `为以下每本书补全字段。
- categoryPrimary：必须从词表中选一个：${categoryVocab.join(' / ')}
- description：80-150 字中文内容梗概，客观陈述，不含评价
- tags：3-5 个中文关键词标签
书籍列表：
${JSON.stringify(payload, null, 1)}
输出一个 JSON 数组，每项形如 {"index":0,"categoryPrimary":"","description":"","tags":[]}，长度必须与输入一致。`;

  const raw = await this.json([{ role: 'system', content: sys }, { role: 'user', content: usr }]);
  const arr = Array.isArray(raw) ? raw : (raw.books ?? raw.items ?? raw.results ?? []);
  if (!Array.isArray(arr)) throw new Error('批量补全返回结构不是数组');
  return arr;
}
  async inferMetadata(book, categoryVocab) {
    const sys = '你是图书编目助手。只输出 JSON，不要解释。';
    const usr = `已知书名《${book.title}》${book.authors?.length ? `，作者：${book.authors.join('、')}` : ''}。
请补充以下字段：
- categoryPrimary：必须从词表中选一个：${categoryVocab.join(' / ')}
- description：80-150 字中文内容梗概，客观陈述，不含评价
- tags：3-5 个中文关键词标签
- authors：若书名能确定作者则给出数组，否则空数组
输出格式：{"categoryPrimary":"","description":"","tags":[],"authors":[]}`;
    return await this.json([
      { role: 'system', content: sys },
      { role: 'user', content: usr },
    ]);
  }

  /**
   * 生成定期阅读报告。
   * @param {object} payload { period, booksFinished, readingLogs, topCategories, ... }
   */
  async generateReport(payload) {
    const sys = '你是私人阅读顾问。基于数据做客观分析，避免空泛赞美，指出被忽视的结构性问题。';
    const usr = `以下是我${payload.period}的阅读数据（JSON）：
${JSON.stringify(payload.data, null, 2)}

请生成一份中文阅读报告，包含：
1. 概览：读完本数、总时长、日均时长
2. 结构分析：分类分布、来源平台分布、形态（电子书/纸质）占比
3. 习惯洞察：阅读节奏、连续天数、弃读率
4. 偏好画像：我可能是什么类型的读者
5. 建议：基于缺口给出 3 条具体、可执行的下一步建议
用 Markdown 输出。`;
    return await this.chat([
      { role: 'system', content: sys },
      { role: 'user', content: usr },
    ], { temperature: 0.6 });
  }
}
