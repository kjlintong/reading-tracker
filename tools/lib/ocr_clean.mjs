/**
 * 截图 OCR 文本 → 书名候选列表
 *
 * 场景：对微信读书 / 掌阅精选 / 京东读书 / 文石的书架截图做端侧 OCR，
 * 得到的是一大段夹杂 UI 文字、作者名、进度、时间戳的混合文本。
 * 本模块负责清洗出书名候选，并给出置信度，交由 UI 层让用户勾选确认。
 *
 * 设计取向：宁可多召回，不可漏召回——误判由用户在确认页一键剔除，
 * 漏掉则用户完全无感知。因此这里做"打分排序"而非"硬过滤"。
 */

/** UI 噪音词：各阅读 App 的常见界面文案 */
const UI_NOISE = [
  // 通用
  '书架', '书城', '发现', '我的', '搜索', '更多', '全部', '排序', '筛选', '编辑',
  '添加', '导入', '导入书籍', '分组', '未分组', '新建分组', '管理', '删除', '完成',
  '取消', '确定', '返回', '首页', '分类', '标签', '笔记', '书评', '目录', '设置',
  '登录', '注册', '购买', '加入书架', '开始阅读', '继续阅读', '立即阅读',
  // 微信读书
  '最近阅读', '本周阅读', '今日阅读', '阅读时长', '读完', '读过', '在读', '想读',
  '本周读完', '已读完', '全部书籍', '我的书架', '好友在读', '为你推荐',
  '无限卡', '付费卡', '体验卡', '会员', '兑换', '签到', '排行榜', '读书小队',
  // 掌阅 / 京东
  '掌阅', '精选', '京东读书', '专业版', '我的图书', '本地导入', '云书架',
  '已购', '借阅', '试读', '全书', '连载', '完结',
  // 文石
  '书库', '最近阅读', '本地', 'sdcard', 'books', 'onyx', 'boox', 'neoreader',
  'storage', 'download', '全部图书', '阅读中', '未读', '已读',
  // 状态/时间
  '今天', '昨天', '前天', '本周', '上周', '本月', '上月', '刚刚', '分钟前', '小时前',
];

/** 明显的非书名模式 */
const NOISE_PATTERNS = [
  /^\d+(\.\d+)?\s*%$/,                        // 45%
  /^(读至|已读|读到|已看到|阅读至)\s*[\d.]+%?$/, // 读至 45%
  /^\d{1,4}[-/年]\d{1,2}[-/月]\d{1,2}日?$/,   // 日期
  /^\d{1,2}:\d{2}$/,                          // 时间
  /^\d+\s*(本|册|页|章|分钟|小时|万字)$/,      // 数量
  /^(共|总计|合计)\s*\d+\s*(本|册)?$/,         // 共 128 本
  /^[\d\s.,%]+$/,                             // 纯数字符号
  /^[^\u4e00-\u9fa5a-zA-Z]+$/,                // 无任何中英文字符
  /^https?:\/\//i,                            // 链接
  /^\d+$/,                                    // 纯数字
];

/** 中文常见姓氏（百家姓 + 常见复姓）。用于区分「作者名」与「被拆断的书名后半段」 */
const SURNAMES = new Set([
  ...'赵钱孙李周吴郑王冯陈褚卫蒋沈韩杨朱秦尤许何吕施张孔曹严华金魏陶姜戚谢邹喻柏水窦章云苏潘葛奚范彭郎鲁韦昌马苗凤花方俞任袁柳鲍史唐费岑薛雷贺倪汤滕殷罗毕郝安常乐于时傅皮卞齐康伍余元卜顾孟平黄和穆萧尹姚邵汪祁毛禹狄米贝明臧计伏成戴谈宋茅庞熊纪舒屈项祝董梁杜阮蓝闵席季麻强贾路娄江童颜郭梅盛林刁钟徐邱骆高夏蔡田樊胡凌霍虞万支柯管卢莫经房裘缪干解应宗丁宣邓郁单杭洪包诸左石崔吉钮龚程嵇邢滑裴陆荣翁荀羊惠甄曲家封芮储靳邴松井段富巫乌焦巴弓牧山谷车侯全班仰秋仲伊宫宁仇栾甘厉戎祖武符刘景詹束龙叶幸司郜黎薄印宿白怀蒲从鄂索咸籍赖卓蔺屠蒙池乔阴胥能苍双闻莘党翟贡劳姬申扶堵冉宰郦雍桑桂濮牛寿通边燕冀浦尚农温别庄晏柴瞿阎充慕连茹习宦艾鱼容向古易慎戈廖庾终暨居衡步都耿满弘匡国文寇广禄阙东欧沃利蔚越隆师巩聂晁冷辛阚那简饶曾毋沙养鞠须丰巢关蒯相查后荆红游权盖益桓公肖芦麦涂佟赫连商修励楚揭帅官原邢兰南覃苟亢缑隋来俸盘闭卿随兆敦答税操邸郏鹿邸冀'.split(''),
  // 常见复姓
  '欧阳', '上官', '司马', '诸葛', '东方', '独孤', '令狐', '慕容',
  '尉迟', '公孙', '皇甫', '长孙', '宇文', '司徒', '司空', '呼延', '夏侯',
]);

/**
 * 日式译名常见首字（村上春树、东野圭吾、川端康成…）
 * 仅在极短行（<=3 字）时启用，避免误伤中文书名
 */
const FOREIGN_NAME_CHARS = new Set(
  '村田山井川岛渡中野小大松竹森藤木内上下西北新原谷本'.split('')
);

/**
 * 判断一行是否像作者名（用于把作者从书名候选中剥离）
 * 典型形态：刘慈欣 / 村上春树 / [美] 贾雷德·戴蒙德 / 余华 著
 *
 * 关键设计：必须命中姓氏表才判为作者。否则像「筝的人」这类
 * 被 OCR 拆断的书名后半段会被误吞，导致书名残缺。
 */
function looksLikeAuthor(line) {
  const s = line.trim();
  if (!s) return false;
  if (/(著|编著|译|著译)$/.test(s)) return true;
  if (/^\[[^\]]{1,8}\]/.test(s)) return true; // [美] 国籍前缀

  // 音译名：含间隔号，且首字为姓氏
  if (s.includes('·')) {
    const first = s.split('·')[0];
    return SURNAMES.has(first[0]) || SURNAMES.has(first.slice(0, 2));
  }
  // 中文姓名：2-4 字，首字命中姓氏表
  if (/^[\u4e00-\u9fa5]{2,4}$/.test(s)) {
    if (SURNAMES.has(s[0]) || SURNAMES.has(s.slice(0, 2))) return true;
  }
  // 日式译名：仅 2-3 字时启用，避免误伤中文书名
  if (/^[\u4e00-\u9fa5]{2,3}$/.test(s) && FOREIGN_NAME_CHARS.has(s[0])) return true;
  return false;
}

/**
 * 清洗 OCR 文本，输出书名候选
 * @param {string} ocrText
 * @param {{minScore?: number}} [opts]
 * @returns {Array<{title:string, score:number, reason:string}>}
 */
export function extractBookTitles(ocrText, opts = {}) {
  const minScore = opts.minScore ?? 0.35;

  const lines = String(ocrText ?? '')
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter(Boolean);

  const candidates = [];
  let prevTitleIndex = -1;

  lines.forEach((line, idx) => {
    const cleaned = preClean(line);
    if (!cleaned) return;

    // 硬过滤：噪音模式
    if (NOISE_PATTERNS.some((re) => re.test(cleaned))) return;

    // 硬过滤：UI 噪音词（完全相等或以噪音词开头且很短）
    const lower = cleaned.toLowerCase();
    if (UI_NOISE.some((w) => lower === w.toLowerCase())) return;
    if (UI_NOISE.some((w) => lower.startsWith(w.toLowerCase()) && cleaned.length <= w.length + 3)) return;

    // 作者行：归入上一本候选书的作者，自身不作为书名
    if (looksLikeAuthor(cleaned) && prevTitleIndex >= 0) {
      const prev = candidates[prevTitleIndex];
      if (prev && !prev.author) {
        prev.author = cleaned.replace(/\s*(著|编著|译)$/, '');
        prev.score += 0.08;
        return;
      }
    }

    const { score, reason } = scoreTitle(cleaned, idx, prevTitleIndex, candidates);
    if (score < minScore) return;

    candidates.push({ title: cleaned, score, reason, author: null, lineIndex: idx });
    prevTitleIndex = candidates.length - 1;
  });

  // 合并被 OCR 拆断的标题：相邻候选，若前一行不以标点结尾且后行较短
  const merged = mergeBrokenTitles(candidates);

  return merged.sort((a, b) => b.score - a.score);
}

/** 去除 OCR 常见杂讯字符 */
function preClean(line) {
  return line
    .replace(/[|｜]/g, '')
    .replace(/\s{2,}/g, ' ')
    .replace(/^[•·・\-\*\+]\s*/, '')
    .trim();
}

/**
 * 书名置信度打分
 * - 长度适中（2~30 字）加分
 * - 含书名号直接高分
 * - 全英文且过短（如 "OK"）降分
 * - 与上一行相邻（书架列表通常书名连续）轻微加分
 */
function scoreTitle(s, idx, prevIdx, candidates) {
  let score = 0.5;
  const reasons = [];

  const len = s.length;

  if (/[《》]/.test(s)) { score += 0.3; reasons.push('含书名号'); }
  const stripped = s.replace(/[《》]/g, '');

  if (stripped.length >= 2 && stripped.length <= 20) { score += 0.15; reasons.push('长度合理'); }
  else if (stripped.length < 2) { score -= 0.4; reasons.push('过短'); }
  else if (stripped.length > 30) { score -= 0.35; reasons.push('过长'); }

  if (/[\u4e00-\u9fa5]/.test(stripped)) { score += 0.1; reasons.push('中文'); }

  if (/^[a-zA-Z\s]+$/.test(stripped) && stripped.length <= 3) {
    score -= 0.3; reasons.push('疑似英文 UI 词');
  }

  // 含明显非书名标点（逗号句号结尾）降分
  if (/[，。；、？！]$/.test(stripped)) { score -= 0.15; reasons.push('句末标点'); }

  // 与上一候选行号相邻（列表连续）加分
  if (prevIdx >= 0 && candidates[prevIdx] && idx - candidates[prevIdx].lineIndex <= 2) {
    score += 0.05; reasons.push('相邻行');
  }

  return { score: Math.max(0, Math.min(1, score)), reason: reasons.join(',') };
}

/**
 * 合并被 OCR 换行拆断的标题
 * 例："人类简" + "史" → "人类简史"
 *
 * 触发条件刻意保守——把两本书错误粘成一本，比漏合并更糟糕：
 * 1. 两行必须紧邻
 * 2. 前一行较短（<=4 字）且不以标点结尾，像是被截断
 * 3. 后一行很短（<=3 字），像是残片
 * 4. 前一行本身未被合并过（只允许合并一次，避免链式粘连）
 */
function mergeBrokenTitles(candidates) {
  const out = [];
  for (let i = 0; i < candidates.length; i++) {
    const cur = { ...candidates[i], merged: false };
    if (out.length) {
      const prev = out[out.length - 1];
      const adjacent = cur.lineIndex - prev.lineIndex === 1;
      const prevIsFragment = prev.title.length <= 4 && !prev.merged
          && !/[，。；、？！：）」』]/.test(prev.title);
      const curIsFragment = cur.title.length <= 3;
      const mergedLen = prev.title.length + cur.title.length;
      if (adjacent && prevIsFragment && curIsFragment && mergedLen <= 30) {
        prev.title += cur.title;
        prev.score = Math.min(1, prev.score + 0.1);
        prev.reason += ',合并断行';
        prev.lineIndex = cur.lineIndex;
        prev.merged = true;
        continue;
      }
    }
    out.push(cur);
  }
  return out.map(({ merged, ...rest }) => rest);
}

/** 便捷入口：OCR 文本 → 可直接入库的书名数组（按置信度排序） */
export function toTitles(ocrText, opts = {}) {
  return extractBookTitles(ocrText, opts).map((c) => c.title);
}
