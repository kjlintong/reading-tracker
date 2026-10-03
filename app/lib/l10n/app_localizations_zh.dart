import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class SZh extends S {
  SZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Readnest';

  @override
  String get navShelf => '书架';

  @override
  String get addBookSheetTitle => '添加图书';

  @override
  String get addBookManualTitle => '手动填写';

  @override
  String get addBookManualDesc => '自己输入书名、作者等信息，不依赖任何账号或文件。';

  @override
  String get navStats => '统计';

  @override
  String get navSettings => '设置';

  @override
  String get supportDev => '支持开发者';

  @override
  String get supportDevDesc => '本应用全部功能免费开放，不含广告，也没有内购。如果它对你的阅读有帮助，欢迎请我喝杯咖啡——完全自愿，打赏与否功能完全一致。';

  @override
  String get openTipPage => '请我喝杯咖啡 · Ko-fi';

  @override
  String get openTipDomestic => '国内赞助 · 爱发电';

  @override
  String get openTipForeign => '国外赞助 · Ko-fi';

  @override
  String get about => '关于';

  @override
  String get aboutDesc => '开发者信息与相关链接。';

  @override
  String get appIntroPage => '应用介绍页';

  @override
  String get developerHomepage => '开发者主页';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get reportDeleteConfirm => '确定删除这份报告？删除后无法恢复。';

  @override
  String get reportDelete => '删除';

  @override
  String appVersionLabel({required String version}) {
    return '版本 $version';
  }

  @override
  String get goodreadsImport => 'Goodreads / 书库 CSV 导入';

  @override
  String get goodreadsImportDesc => '导入从 Goodreads 等平台导出的书库 CSV（含书名、作者、评分、书架状态）。';

  @override
  String get goodreadsImportEmpty => 'CSV 里找不到「Title」列';

  @override
  String get openLibraryImport => 'Open Library / Google Books 搜索导入';

  @override
  String get openLibraryImportDesc => '按书名或 ISBN 搜索公开书目库，直接导入并补全作者、出版社、封面等元数据。';

  @override
  String get catalogSearchTitle => '公开书目搜索';

  @override
  String get catalogSearchHint => '输入书名或 ISBN';

  @override
  String get catalogSearchAction => '搜索';

  @override
  String get catalogSearchInitial => '从 Google Books 与 Open Library 检索公共书目，选中的书会直接入库，并带齐作者、出版社、封面与页数。';

  @override
  String get catalogNoResult => '没有找到匹配的书目，换个关键词试试';

  @override
  String catalogSearchFailed({required Object e}) {
    return '搜索失败：$e';
  }

  @override
  String get imageUploadConsentTitle => '发送书架截图到 AI 服务？';

  @override
  String get imageUploadConsentBody => '为了让 AI 识别整张书架截图，这张图片会发往你在「设置 → 大模型」里填写的服务（第三方）。图片不含笔记正文，但会包含书名与封面。是否允许本次上传？';

  @override
  String get allow => '允许';

  @override
  String get cancel => '取消';

  @override
  String get s_178329ba => '未配置微信读书 API Key';

  @override
  String get s_dd204792 => '[\\s·・\\-—_:：,，。.·（）()\\[\\]【】]';

  @override
  String get s_ad86a5ca => '未配置大模型 API Key';

  @override
  String get s_8a853cbe => '到「设置 → 大模型」填写';

  @override
  String get s_7d704c88 => '未选择模型';

  @override
  String get s_4508cedd => '点「拉取模型」从账号可用列表里选一个';

  @override
  String get s_1b5140db => '只输出合法 JSON，不要输出解释文字或 markdown 代码块。';

  @override
  String s_c94c96fc({required Object apiError}) {
    return '模型服务返回错误：$apiError';
  }

  @override
  String s_3b43c7c4({required Object head}) {
    return '响应原文：$head\n先在「设置 → 大模型」用「拉取模型」核对地址与模型名，欠费或未开通该模型也会走到这里';
  }

  @override
  String get s_231cf54a => '模型返回的内容无法识别';

  @override
  String s_90747d4c({required Object head}) {
    return '响应原文：$head\n这是网关返回了非标准结构。可以换个模型或协议再试；把这段原文反馈回来也能帮助我们适配。';
  }

  @override
  String get s_9d9714af => '消息为空，无法发送';

  @override
  String get s_f44ff25c => '模型拒绝了这个请求';

  @override
  String get s_cad5bf6e => '内容被判定为不适宜，换个说法或换个模型再试';

  @override
  String get s_0f7b54a1 => '未配置 API Key';

  @override
  String get s_345e9547 => '先填 Key 再拉取模型';

  @override
  String get s_3a5d4cca => '该服务返回的模型列表为空';

  @override
  String s_cea80527({required Object apiError}) {
    return '拉取模型失败：$apiError';
  }

  @override
  String get s_4674d953 => '可以手动填写模型名';

  @override
  String s_749fc40e({required Object raw}) {
    return '响应原文：$raw';
  }

  @override
  String get s_8add575d => '该服务没有提供模型列表接口 (404)';

  @override
  String get s_53fb436d => '手动填写模型名即可，例如 deepseek-chat / claude-sonnet-5';

  @override
  String get s_438a5695 => '未填写模型名';

  @override
  String get s_1da90e20 => '先点「拉取模型」或手动填一个';

  @override
  String get s_2abb6b8a => '回复两个字：可用';

  @override
  String get s_ad736a74 => '你是图书编目助手。只输出 JSON，不要解释。';

  @override
  String s_4304f539({required Object author, required Object title, required Object vocab}) {
    return '已知书名《$title》$author。\n请补充：\n- categoryPrimary：必须从词表中选一个：$vocab\n- description：80-150 字中文内容梗概，客观陈述，不含评价\n- tags：3-5 个中文关键词标签\n- authors：若能确定作者则给出数组，否则空数组\n输出格式：{\"categoryPrimary\":\"\",\"description\":\"\",\"tags\":[],\"authors\":[]}';
  }

  @override
  String get s_cbe8aa6b => '你是阅读画像分析师。只输出 JSON，不要解释。';

  @override
  String s_3864d3b4({required Object summary}) {
    return '以下是我的阅读数据（JSON）：\n$summary\n\n请给我 10 个中文「性格标签」，每个 2-6 字，像书友会给人贴的绰号那样。\n要求：\n1. 每个标签都要能从上面的数据里找到依据，不要凭想象\n2. 风格参考：学习使我快乐 / 道法自然 / 颜值正义 / 博古通今 / 孤独的智者\n3. 不要出现「读者」「爱好者」「达人」这类没有信息量的词\n4. 不要解释，不要 markdown 代码块\n输出格式：{\"tags\":[\"标签1\",\"标签2\"]}';
  }

  @override
  String get s_735e2d59 => '6. 点名环节：从 bookList 里挑 3~5 本具体谈（哪本读完了、哪本开了头没继续、哪本评分最高），给出书名。\n报告中出现的书名必须来自 bookList，不要编造。\n';

  @override
  String get s_99acf9a4 => '你是私人阅读顾问。基于数据做客观分析，避免空泛赞美，指出被忽视的结构性问题。';

  @override
  String s_414278bd({required Object data, required Object listHint, required Object period}) {
    return '以下是我$period的阅读数据（JSON）：\n$data\n\n请生成一份中文阅读报告，包含：\n1. 概览：读完本数、总时长、日均时长\n2. 结构分析：分类分布、来源平台分布、形态占比\n3. 习惯洞察：阅读节奏、连续天数、弃读率\n4. 偏好画像：我可能是什么类型的读者\n5. 建议：基于缺口给出 3 条具体可执行的下一步建议。建议只围绕阅读本身（读什么、怎么读、读后如何记录）：不要评论书籍的来源或获取渠道，不要催促写书评、分享或打卡，不要做阅读之外的评判。\n$listHint格式要求（严格遵守，报告会在 App 里按 Markdown 排版呈现）：\n- 六个部分都用二级标题开头（例如「## 概览」），标题里不要带编号。\n- 关键数字一律加粗，例如「共读完 **12 本**」「日均 **37 分钟**」。\n- 并列要点用 - 开头的无序列表；给读者的行动建议用 1. 2. 3. 有序列表。\n- 所有书名一律用《》包裹，例如《置身事内》。\n- 不要写 HTML 标签，不要使用四级及更深的标题。';
  }

  @override
  String s_46e5ebef({required Object host}) {
    return '连接超时：无法在 20 秒内连上 $host';
  }

  @override
  String get s_3c836870 => '检查网络或 Base URL；国内直连部分海外服务需要代理';

  @override
  String get s_84264711 => '发送超时';

  @override
  String get s_225ed2e1 => '网络上行不稳定，稍后重试';

  @override
  String get s_b265cf86 => '响应超时：模型 180 秒内没有返回';

  @override
  String get s_cc12eea3 => '换一个更快的模型，或把报告周期缩短后重试';

  @override
  String get s_d711b259 => 'HTTPS 证书校验失败';

  @override
  String get s_4722b0f8 => '若使用自建/内网端点请改用可信证书';

  @override
  String get s_07a2b144 => '请求已取消';

  @override
  String s_8ae0b0e4({required Object host}) {
    return '网络不可达：连不上 $host';
  }

  @override
  String get s_0a9425b8 => '① 检查手机网络；② 确认 Base URL 写全了（含 /v1）；③ 该服务是否需要代理；④ 本地服务（Ollama）手机访问不到电脑的 localhost';

  @override
  String get s_554d5235 => '连接被中断';

  @override
  String get s_020fe21a => '常见于网络权限被拦、代理或防火墙中断连接，也可能是不支持明文 HTTP。稍后重试或换网络';

  @override
  String get s_dfde23b1 => '网络请求失败';

  @override
  String get s_2ae4f5fe => '检查 Base URL、代理设置与网络环境';

  @override
  String s_d6ac5952({required Object detail}) {
    return '请求被拒绝 (400)$detail';
  }

  @override
  String get s_cb980461 => '多半是模型名不对，或该模型不支持当前参数';

  @override
  String s_d9775d22({required Object detail}) {
    return '鉴权失败 (401)$detail';
  }

  @override
  String get s_c4198142 => 'API Key 无效或已过期，重新复制一个';

  @override
  String get s_e06ab1cc => '账户余额不足 (402)';

  @override
  String s_05b3ec8b({required Object detail}) {
    return '无权限 (403)$detail';
  }

  @override
  String get s_f00f6ff2 => 'Key 没有该模型的调用权限，或未实名/未开通';

  @override
  String s_016f7576({required Object detail}) {
    return '接口或模型不存在 (404)$detail';
  }

  @override
  String get s_a8aa2c59 => '核对 Base URL 是否填到 /v1；模型名可用「拉取模型」获取';

  @override
  String s_9688a257({required Object detail}) {
    return '参数不合法 (422)$detail';
  }

  @override
  String get s_1b3daaa3 => '触发限流 (429)';

  @override
  String get s_2a564df1 => '稍等再试，或升级套餐';

  @override
  String s_6627221e({required int? code}) {
    return '服务端错误 ($code)';
  }

  @override
  String get s_2fe391dd => '对端的问题，稍后重试';

  @override
  String s_679e6c2e({required Object code, required Object detail}) {
    return '请求失败$code$detail';
  }

  @override
  String get s_0cf0a499 => '(空响应体)';

  @override
  String get s_9ed7e745 => '网络请求失败，检查手机网络与「设置 → 大模型」里的 Base URL';

  @override
  String get s_2ad3b6ba => 'OpenAI 兼容';

  @override
  String get s_e2213e87 => 'Base URL 填到 /v1 为止，例如 https://api.deepseek.com/v1';

  @override
  String get s_17a4ba0f => 'Base URL 通常为 https://api.anthropic.com（不带 /v1）';

  @override
  String get s_f1ea3335 => '商汤 SenseNova';

  @override
  String get s_e522fe39 => '通义千问';

  @override
  String get s_7e12f8b4 => '智谱 GLM';

  @override
  String get s_c3d30bc2 => '月之暗面 Kimi';

  @override
  String get s_8e941e27 => '硅基流动';

  @override
  String get s_c800478c => 'Ollama 本地';

  @override
  String get s_0babfa89 => '任意非空字符串';

  @override
  String get s_e74f752c => '阅读天数为手工记录的阅读日';

  @override
  String s_9ea3cbae({required Object year}) {
    return '时长与天数取自微信读书 $year 年度统计（全年口径）';
  }

  @override
  String get s_f676228c => '微信读书只提供年度口径，该区间的阅读天数无法精确给出；时长按整月粒度统计';

  @override
  String get s_06225788 => '未评分';

  @override
  String s_89cfaca8({required Object i}) {
    return '$i 星';
  }

  @override
  String get s_e7a2db51 => '全部时间';

  @override
  String s_a87cfcc9({required Object y}) {
    return '$y 年';
  }

  @override
  String s_62654321({required Object n}) {
    return '近 $n 个月';
  }

  @override
  String get s_41f3af95 => '阅读时长与天数为整月/年度粒度';

  @override
  String get s_e8a43314 => '从下一本书开始，这份书单就会长出第一个数字。';

  @override
  String get s_af03278c => '书架还是空的——每段阅读史都是从这里起步的。';

  @override
  String s_f53eead8({required Object streak}) {
    return '连续阅读 $streak 天了，节奏已经长在你身上。';
  }

  @override
  String s_ff1565a3({required Object streak}) {
    return '$streak 天的连续记录，别让它断在今天。';
  }

  @override
  String s_1736f17e({required Object streak}) {
    return '连续 $streak 天，这个习惯比任何一份书单都值钱。';
  }

  @override
  String s_9a3fb5e5({required Object finished}) {
    return '已经读完 $finished 本——把速度换成节奏，你会走得更远。';
  }

  @override
  String s_9d430ad3({required Object finished}) {
    return '$finished 本读完了。偶尔回头看看哪些真正留下了东西。';
  }

  @override
  String s_597f7c05({required Object finished}) {
    return '这个区间读完 $finished 本，每一本都算数。';
  }

  @override
  String s_1c87153f({required Object finished}) {
    return '读完 $finished 本。下一本从书架里挑一本开了头的吧。';
  }

  @override
  String s_41db17b9({required Object minutes}) {
    return '这段时间读了 $minutes 分钟——把半小时变成每天的事，一年就是一百八十小时。';
  }

  @override
  String s_6a57c553({required Object minutes}) {
    return '已有 $minutes 分钟阅读记录。今天再添一小段？';
  }

  @override
  String get s_152a88d7 => '书架已经备好，从一个轻松的短篇开始今天的十分钟。';

  @override
  String get s_795806c0 => '挑一本开了头的书，读十分钟就算赢。';

  @override
  String get s_aa51bf46 => '不用一口气读很多——今天翻开任意一本就算记录在案。';

  @override
  String get s_363c6a0c => '未分类';

  @override
  String get s_420a7ac1 => '学习使我快乐';

  @override
  String get s_bcd278a6 => '成长';

  @override
  String s_3702d226({required Object cat, required Object pct}) {
    return '成长类 $cat 本 · 占 $pct';
  }

  @override
  String get s_6672b3fa => '浪漫诗意';

  @override
  String get s_d422d33c => '文学';

  @override
  String s_40ba4ecb({required Object cat, required Object pct}) {
    return '文学 $cat 本 · 占 $pct';
  }

  @override
  String get s_ea2eaec4 => '孤独的智者';

  @override
  String get s_5da32671 => '哲学';

  @override
  String s_0f80a135({required Object cat, required Object pct}) {
    return '哲学 $cat 本 · 占 $pct';
  }

  @override
  String get s_111ec0f6 => '以史为鉴';

  @override
  String get s_07f288e9 => '历史';

  @override
  String s_abeb8e3d({required Object cat, required Object pct}) {
    return '历史 $cat 本 · 占 $pct';
  }

  @override
  String get s_5e336507 => '向内探索';

  @override
  String get s_4307c7a8 => '心理';

  @override
  String s_cfce6d52({required Object cat, required Object pct}) {
    return '心理 $cat 本 · 占 $pct';
  }

  @override
  String get s_d5e26f37 => 'IT 精英';

  @override
  String get s_8612fa7f => '计算机';

  @override
  String s_d6bdf44e({required Object cat, required Object pct}) {
    return '计算机 $cat 本 · 占 $pct';
  }

  @override
  String get s_00dcb308 => '颜值正义';

  @override
  String get s_b31e932c => '艺术';

  @override
  String s_aee18737({required Object cat, required Object pct}) {
    return '艺术 $cat 本 · 占 $pct';
  }

  @override
  String get s_2ddd554c => '理性务实';

  @override
  String get s_56734d39 => '经济';

  @override
  String get s_5974bf24 => '管理';

  @override
  String s_066faf9c({required Object cat, required Object toStringAsFixed}) {
    return '经济与经营 $cat 本 · 占 $toStringAsFixed%';
  }

  @override
  String get s_d574ffeb => '世事洞明';

  @override
  String get s_086ac5bf => '社科';

  @override
  String s_5a276724({required Object cat, required Object pct}) {
    return '社科 $cat 本 · 占 $pct';
  }

  @override
  String get s_d81bab36 => '好奇心旺盛';

  @override
  String get s_41fa5c70 => '科普';

  @override
  String get s_fcc3102d => '科技';

  @override
  String s_76c118d0({required Object n}) {
    return '科普与科技 $n 本';
  }

  @override
  String get s_2b65326c => '以人为镜';

  @override
  String get s_f85fa7d4 => '传记';

  @override
  String s_b2e9db16({required Object cat, required Object pct}) {
    return '传记 $cat 本 · 占 $pct';
  }

  @override
  String get s_9e49409c => '养生有道';

  @override
  String get s_c21b69a8 => '医学';

  @override
  String s_1dd31356({required Object cat}) {
    return '医学健康 $cat 本';
  }

  @override
  String get s_77e32253 => '拿来主义';

  @override
  String get s_0323f1bb => '法律';

  @override
  String s_82364cc8({required Object cat}) {
    return '法律 $cat 本';
  }

  @override
  String get s_ea038731 => '自娱自乐';

  @override
  String get s_dbb1c112 => '漫画';

  @override
  String get s_6398a679 => '童书';

  @override
  String s_a1b1d26a({required Object cat}) {
    return '漫画与童书 $cat 本';
  }

  @override
  String get s_94f8d7c2 => '道法自然';

  @override
  String get s_30412ad5 => '宗教';

  @override
  String s_d00fbfe6({required Object cat}) {
    return '宗教 $cat 本';
  }

  @override
  String get s_52c36d65 => '懂生活';

  @override
  String get s_06e23c48 => '其他';

  @override
  String s_e3a3f18e({required Object cat, required Object pct}) {
    return '生活类 $cat 本 · 占 $pct';
  }

  @override
  String get s_dc2e94c1 => '传道受业';

  @override
  String get s_235af603 => '教育';

  @override
  String s_be73b4a0({required Object cat, required Object pct}) {
    return '教育 $cat 本 · 占 $pct';
  }

  @override
  String get s_7ea6e8a9 => '博古通今';

  @override
  String s_938fd6ec({required Object categoryKinds}) {
    return '藏书横跨 $categoryKinds 个分类，什么都读一点';
  }

  @override
  String get s_41a09d04 => '专注深耕';

  @override
  String s_c61130ac({required Object categoryKinds, required Object total}) {
    return '$total 本只落在 $categoryKinds 个分类里';
  }

  @override
  String get s_431dc47d => '有始有终';

  @override
  String s_a7b097f6({required Object finished, required Object toStringAsFixed, required Object total}) {
    return '读完率 $toStringAsFixed%（$finished/$total）';
  }

  @override
  String get s_6b51050c => '囤书如山';

  @override
  String s_55413cd8({required Object finished, required Object wish}) {
    return '想读 $wish 本，读完的只有 $finished 本';
  }

  @override
  String get s_e60e931c => '果断止损';

  @override
  String s_b3549d21({required Object abandoned, required Object toStringAsFixed}) {
    return '弃读 $abandoned 本 · 占 $toStringAsFixed%，不好看就放下的类型';
  }

  @override
  String get s_4be15f8c => '开坑能手';

  @override
  String s_b0a853cf({required Object stalled}) {
    return '$stalled 本在读但进度不到 15%';
  }

  @override
  String get s_10b9bddd => '温柔以待';

  @override
  String s_6a469e36({required Object ratedCount, required Object toStringAsFixed}) {
    return '评过分的 $ratedCount 本平均 $toStringAsFixed 分';
  }

  @override
  String get s_e67694db => '毒舌评委';

  @override
  String s_30c4cecf({required Object ratedCount, required Object toStringAsFixed}) {
    return '评过分的 $ratedCount 本平均只有 $toStringAsFixed 分';
  }

  @override
  String get s_fe4567e4 => '爱憎分明';

  @override
  String s_b1d69175({required Object toStringAsFixed}) {
    return '评分标准差 $toStringAsFixed，好与差拉得很开';
  }

  @override
  String get s_fbad19d5 => '温故知新';

  @override
  String s_8d62979c({required Object reread}) {
    return '$reread 本读了两遍以上';
  }

  @override
  String get s_54302bb2 => '沉浸式阅读';

  @override
  String s_bc9dbced({required Object round}) {
    return '有阅读记录的日子里平均每天 $round 分钟';
  }

  @override
  String get s_e9eddf51 => '电子书党';

  @override
  String s_df5bbdba({required Object toStringAsFixed, required Object weread}) {
    return '微信读书 $weread 本 · 占 $toStringAsFixed%';
  }

  @override
  String get s_ce6517f9 => '纸电双修';

  @override
  String s_75c2fd5a({required Object libraryCount, required Object paper}) {
    return '还有 $libraryCount 本借阅与 $paper 本纸质书';
  }

  @override
  String get s_8cac22b7 => '用耳朵读书';

  @override
  String s_72b826e9({required Object audio}) {
    return '有声书 $audio 本';
  }

  @override
  String get s_7caeab27 => '图文并茂';

  @override
  String s_a5a44a39({required Object comic}) {
    return '漫画 $comic 本';
  }

  @override
  String s_0e59d960({required Object m, required Object y}) {
    return '$y 年 $m 月';
  }

  @override
  String s_1a2e873e({required Object month}) {
    return '$month 月';
  }

  @override
  String s_5583162a({required Object e}) {
    return '图像预处理失败，改用原图：$e';
  }

  @override
  String s_628c2132({required Object e}) {
    return '转 JPEG 失败：$e';
  }

  @override
  String get s_ebf4bdfb => '正在解析版面结构…';

  @override
  String get s_ba1038b1 => '正在用大模型整理识别结果…';

  @override
  String get s_6292a274 => '正在核对书名…';

  @override
  String get s_427e1f0d => '[\\s《》「」『』…⋯.\\-—_:：]';

  @override
  String get s_af041a1b => '书名已补齐';

  @override
  String s_988dd5cb({required Object reason}) {
    return '$reason,书名已补齐';
  }

  @override
  String get s_a746d189 => '[、,，;/]';

  @override
  String s_a4ec75fd({required Object e, required Object title}) {
    return '《$title》：$e';
  }

  @override
  String get s_d2bbf7ce => '多模态识别';

  @override
  String get s_381ca835 => '这是一张书架/书单的截图';

  @override
  String get s_fce28e56 => '这是一张单本书的封面或详情截图';

  @override
  String s_ba5425c5({required Object n, required Object scene}) {
    return '$scene。\n\n请只输出 JSON 数组，每项形如：\n{\"title\":\"书名\",\"author\":\"作者\",\"progress\":0-100的数字或null,\"status\":\"未读/在读/已读完 之一或null\",\"confidence\":0-1的数字}\n\n要求：\n1. 只输出图中**确实能看到**的书，不要补充你以为该有的书；\n2. 忽略界面文案（筛选、搜索、排序、全部、书架、共 N 本等）；\n3. 书名按图上的原文抄，被省略号截断的照抄，不要自行补全；\n4. 读不到作者就留空字符串，不要猜；\n5. 作者确实写在图上时才填。\n$n';
  }

  @override
  String get s_951042c3 => '你是书架截图信息抽取助手。只输出 JSON 数组，不要任何解释文字。';

  @override
  String get s_29dbdb32 => '大模型整理';

  @override
  String get s_9cd6567e => '一张图书封面/书脊照片';

  @override
  String get s_a6db1cf4 => '一个电子书App的书架截图';

  @override
  String s_43fca769({required Object ocrText, required Object scene}) {
    return '下面是从$scene里 OCR 出来的文字行，顺序即页面上从上到下的顺序。\n\n请抽取其中**真实存在的书名**，忽略所有界面文字（搜索框、筛选、分类、状态栏、页码、章节标题、按钮、统计数字）。\n\n规则：\n1. 只输出图中确实出现的书。不要凭常识补充图里没有的书。\n2. 书名若被界面用省略号截断（例如「雅思口语深…」），请补全成完整书名。\n3. progress 只填 0-100 的整数百分比，读不到就填空字符串。注意「0.8%」是 0.8 不是 80。\n4. status 只填「未读 / 在读 / 已读完 / 弃读」之一，读不到填空字符串。\n5. author 只在图中明确出现时填写，否则留空。不要猜作者。\n6. 拿不准的行不要输出。宁可少一本，也不要多一本假书。\n\n只输出 JSON 数组，元素格式：\n[{\"title\":\"\",\"author\":\"\",\"progress\":\"\",\"status\":\"\",\"confidence\":0.0}]\n\nOCR 文字行：\n\"\"\"\n$ocrText\n\"\"\"';
  }

  @override
  String get s_cbb756f7 => '[\\s《》「」『』]';

  @override
  String get s_95222176 => '未读';

  @override
  String get s_5a833930 => '想看';

  @override
  String get s_b9bf9b53 => '阅读中';

  @override
  String get s_be5492a5 => '阅读中';

  @override
  String get s_44c14529 => '已读完';

  @override
  String get s_0872b5b7 => '读完';

  @override
  String get s_300a32bd => '已读完';

  @override
  String get s_0f4d9c68 => '弃读（已并入搁置）';

  @override
  String get s_7675d229 => '\\s*(著|编著|译|著译)\$';

  @override
  String get s_285bb37e => '[，。；、？！：）」』]\$';

  @override
  String get s_8f936d11 => '(著|编著|译|著译)\$';

  @override
  String get s_d0c345ec => '[（《·“]\$';

  @override
  String get s_2d3c83a7 => '[）》」』”]\$';

  @override
  String get s_0686f279 => '封面最大字号';

  @override
  String get s_5514105a => '封面次级文字';

  @override
  String get s_174faffb => '含中文';

  @override
  String get s_b13a1237 => '带进度或状态';

  @override
  String get s_24745e9d => '带作者';

  @override
  String get s_0cedc3f4 => '长度合理';

  @override
  String get s_5bdfa6ae => '过短';

  @override
  String get s_58171266 => '过长';

  @override
  String get s_1e8c236b => '列左对齐';

  @override
  String get s_89ac54fb => '封面美术字';

  @override
  String get s_132a750b => '过短英文';

  @override
  String get s_6af25a96 => '[，。；、？！]\$';

  @override
  String get s_a335b25f => '句末标点';

  @override
  String get s_885dd894 => '％';

  @override
  String get s_620b459e => '《';

  @override
  String get s_150c7508 => '》';

  @override
  String get s_67df3afd => '含书名号';

  @override
  String get s_5a09ed37 => '中文';

  @override
  String get s_6b631636 => '疑似英文 UI 词';

  @override
  String get s_1dd3f274 => '相邻行';

  @override
  String get s_f547232b => ',合并断行';

  @override
  String get s_fc39b00e => '借阅中';

  @override
  String get s_eba88d83 => '搁置';

  @override
  String get s_b6fe7962 => '电子书';

  @override
  String get s_c7673d27 => '纸质';

  @override
  String get s_02a1a8ed => '有声书';

  @override
  String get s_fe152225 => '微信读书';

  @override
  String get s_2032cbd7 => '掌阅精选';

  @override
  String get s_12ed007e => '京东读书';

  @override
  String get s_570bb7c8 => '文石';

  @override
  String get s_36bfef2d => '图书馆';

  @override
  String get s_4139f3b5 => '手动';

  @override
  String get s_88cdd7e4 => '划线';

  @override
  String get s_6abc44a8 => '想法';

  @override
  String get s_67585b8a => '评论';

  @override
  String get s_96009a7e => '阅读报告';

  @override
  String s_4343b7b3({required Object join}) {
    return '正在后台补生成：$join';
  }

  @override
  String s_a6c57a43({required Object ok}) {
    return '已自动补生成 $ok 份报告';
  }

  @override
  String s_f71dea06({required Object failed, required Object ok}) {
    return '补生成完成 $ok 份，失败 $failed 份（可手动重试）';
  }

  @override
  String s_e93308dd({required Object latencyMs, required Object model}) {
    return '连通正常 · $model · $latencyMs ms';
  }

  @override
  String get s_d2a3748e => '模型返回了空内容';

  @override
  String get s_3abdc334 => '可能是模型不支持当前参数，或触发了内容过滤，换一个模型再试';

  @override
  String get s_cc72f973 => '未配置大模型 Key，请先到「设置 → 大模型」填写并测试连通性';

  @override
  String get s_9e51ce93 => '未选择模型，请到「设置 → 大模型」点「拉取模型」选一个';

  @override
  String get s_c6e18e89 => '这个周期里没有符合条件的书，换一个周期试试';

  @override
  String get s_8bb45b34 => '报告周期';

  @override
  String get s_8bd59fb2 => '选择年报或月报';

  @override
  String get s_53bea04d => '按自然年 / 自然月归档，生成后可随时回看。当月月报要等下个月才生成。';

  @override
  String get s_1f048ed9 => '测试中…';

  @override
  String get s_38fb1115 => '测试连接';

  @override
  String get s_a14e36dc => '生成中…（长文本约需 1 分钟）';

  @override
  String get s_b36c173d => '生成报告';

  @override
  String get s_c94ade95 => '会发送本周期的书名清单（书名 / 作者 / 分类 / 评分）与聚合统计，这样报告才点得出具体的书；笔记正文与划线内容不上传。';

  @override
  String get s_5e05e92a => '纳入统计';

  @override
  String s_be9a1551({required Object total}) {
    return '$total 本';
  }

  @override
  String s_ce115766({required Object finished}) {
    return '$finished 本';
  }

  @override
  String s_8b46a11f({required Object reading}) {
    return '$reading 本';
  }

  @override
  String s_81e94993({required Object wish}) {
    return '$wish 本';
  }

  @override
  String get s_09b589b4 => '平均分';

  @override
  String s_0825e123({required Object label}) {
    return '报告内容 · $label';
  }

  @override
  String get s_049eca89 => '复制全文';

  @override
  String get s_50bf9961 => '报告已复制到剪贴板';

  @override
  String get s_772cbfcf => '自动生成';

  @override
  String get s_01955ddf => '开启后，打开本页会自动补生成缺失的年报与上月月报。';

  @override
  String get s_b2a52a3d => '自动补生成';

  @override
  String get s_b233138e => '年报';

  @override
  String get s_877b864d => '月报';

  @override
  String get s_a3dfa2a6 => '历史报告';

  @override
  String get s_66772db6 => '导出阅读数据';

  @override
  String get s_6b198f0b => '已取消导出';

  @override
  String s_a101fbdd({required Object counts, required Object saved}) {
    return '已导出到：$saved\n\n$counts';
  }

  @override
  String s_6ec2d38e({required Object e}) {
    return '导出失败：$e';
  }

  @override
  String get s_c699263b => '选择备份文件';

  @override
  String s_e34bdbcb({required Object e}) {
    return '读不到这个文件：$e';
  }

  @override
  String get s_1dedeaa2 => '这不是本 App 导出的备份文件（缺少格式标识，或版本比当前 App 新）';

  @override
  String get s_103c5811 => '文件里没有可恢复的数据';

  @override
  String get s_674a7957 => '确认恢复？';

  @override
  String s_94094e0d({required Object length}) {
    return '将用备份覆盖本机数据：\n\n$length\n\n同名记录会被整行覆盖——恢复的语义是「回到备份那一刻」，不做字段级合并。当前库里备份之后新增的书不会被删掉。';
  }

  @override
  String get s_a0451c97 => '取消';

  @override
  String get s_ec7085ab => '恢复';

  @override
  String s_2296b134({required Object counts, required Object first}) {
    return '恢复完成$first\n\n$counts';
  }

  @override
  String s_e669bac1({required Object e}) {
    return '恢复失败：$e';
  }

  @override
  String s_7c0be1cd({required int? books}) {
    return '图书 $books 本';
  }

  @override
  String s_dd2321ce({required int? notes}) {
    return '笔记 $notes 条';
  }

  @override
  String s_d48aa751({required int? reading_logs}) {
    return '阅读记录 $reading_logs 条';
  }

  @override
  String s_d044717e({required int? llm_reports}) {
    return 'AI 报告 $llm_reports 份';
  }

  @override
  String s_f4d248a7({required int? settings}) {
    return '设置项 $settings 条';
  }

  @override
  String get s_8719bf89 => '数据导出与恢复';

  @override
  String get s_8fe27f12 => '导出什么';

  @override
  String get s_5d9af0a7 => '整库 JSON 快照：图书、笔记、阅读记录、AI 报告与设置。存下来的是一个文件，换设备时用它恢复。';

  @override
  String get s_582f4cb6 => '导出为 JSON 文件';

  @override
  String get s_091ad5f4 => '从备份恢复';

  @override
  String get s_3a36f742 => '选择之前导出的 .json 文件。同名记录整行覆盖，不合并字段——这是「回到备份那一刻」而不是「取并集」。';

  @override
  String get s_6f9ab88c => '选择备份文件并恢复';

  @override
  String get s_f24f63da => '删除这条笔记？';

  @override
  String get s_ecbd7449 => '删除';

  @override
  String get s_f98a79dc => '添加笔记';

  @override
  String get s_05712ea1 => '编辑笔记';

  @override
  String get s_e3fdcb7e => '摘抄、随想或书评…';

  @override
  String get s_c8d8fada => '章节 / 页码';

  @override
  String get s_f80f4749 => '选填';

  @override
  String get s_abfe9512 => '保存';

  @override
  String get s_a647c2e0 => '这本书不存在或已被删除';

  @override
  String s_154ada37({required Object join}) {
    return '作者：$join';
  }

  @override
  String s_904feb6c({required Object join}) {
    return '译者：$join';
  }

  @override
  String s_1e4c61f8({required Object publisher}) {
    return '出版社：$publisher';
  }

  @override
  String s_bf93bf6d({required Object first}) {
    return '出版：$first';
  }

  @override
  String s_def61e8c({required Object categoryPrimary}) {
    return '分类：$categoryPrimary';
  }

  @override
  String get s_d9bdf56b => '阅读状态';

  @override
  String s_94b27e86({required Object toStringAsFixed}) {
    return '进度 $toStringAsFixed%';
  }

  @override
  String get s_8331377a => '评分';

  @override
  String get s_205eb716 => '摘要';

  @override
  String get s_b5e2aa8a => '记录这本书讲了什么';

  @override
  String get s_3ec1ca86 => '读后感';

  @override
  String get s_aa5a5d3e => '你的评价与思考';

  @override
  String s_fb47d52b({required Object length}) {
    return '笔记 · $length';
  }

  @override
  String get s_18dd30c5 => '还没有笔记。读到有意思的地方记一条，将来写年度回顾时这就是素材。';

  @override
  String get s_4b7d48f2 => '简介';

  @override
  String s_5e52b06a({required String? dueAt}) {
    return '应还日期：$dueAt';
  }

  @override
  String get s_ad207008 => '编辑';

  @override
  String get s_f5d99c16 => '、';

  @override
  String get s_65983593 => '书名不能为空';

  @override
  String get s_1f0939bc => '[,，、;；]';

  @override
  String get s_6c7a6cc5 => '编辑图书';

  @override
  String get s_31e2aa97 => '手动添加图书';

  @override
  String get s_eda73905 => '保存修改';

  @override
  String get s_71b10e99 => '加入书架';

  @override
  String get s_2dae8ba5 => '选择本地封面';

  @override
  String get s_5be7901d => '设置封面';

  @override
  String get s_a59912dd => '移除封面';

  @override
  String get s_e2b6c0de => '书名 *';

  @override
  String get s_22760472 => '作者';

  @override
  String get s_5f70e9dd => '多位作者用逗号分隔';

  @override
  String get s_759fb403 => '状态';

  @override
  String get s_da1c08d9 => '载体';

  @override
  String get s_5ce4e16d => '清除';

  @override
  String get s_b0d7b0de => '简介 / 摘要';

  @override
  String get s_d0dd45ac => '分类会归一化到受控词表，手写「经管励志」也会并进「管理」，统计里不会裂成两类。';

  @override
  String get s_b32f0afe => '分类';

  @override
  String get s_87635298 => '可留空';

  @override
  String get s_5aa23087 => '不填';

  @override
  String s_573b6694({required Object e}) {
    return '出错了：$e';
  }

  @override
  String get s_28690759 => '正在增强图像…';

  @override
  String get s_d5155b2d => '没能识别出书名，换一张图试试';

  @override
  String get s_e20dac78 => '正在用多模态模型读图…';

  @override
  String get s_5fea0487 => '多模态模型没能从这张图里读出书名。确认所选模型支持图片输入（纯文本模型会直接拒收），或把「设置 → 截图识别 → 识别方式」改回「自动」以回落到端侧 OCR。';

  @override
  String get s_cdda9381 => '多模态没结果，改用端侧 OCR…';

  @override
  String get s_b85e4cbc => '未授权图片上传，改用端侧 OCR…';

  @override
  String get s_a9698571 => '正在识别文字…';

  @override
  String get s_7ef6b42d => '这张图里没读到文字。换个角度、让文字更清晰，或直接截屏（截屏的文字比拍照更规整）。';

  @override
  String get s_319b9488 => '没读到像书名的文字。如果是书内页，书名通常不在页面上——试试点「截图导入书架」或直接拍封面。';

  @override
  String get s_37588c9c => '没能从图中识别出书名，试试裁掉多余界面元素后重试';

  @override
  String get s_04a1b347 => '书名';

  @override
  String get s_a9fe3793 => 'CSV 里找不到「书名」列';

  @override
  String get s_3db59388 => '进度';

  @override
  String get s_9e160a69 => '出版社';

  @override
  String s_d4b7c3c7({required Object length}) {
    return '解析到 $length 本书，确认导入？';
  }

  @override
  String get s_649320a3 => '正在读取微信读书书架…';

  @override
  String get s_e53774ba => '书架为空或接口未返回数据';

  @override
  String s_8151aa42({required Object length}) {
    return '微信读书书架共 $length 本，确认导入？';
  }

  @override
  String get s_9b37038a => '正在补全元数据并入库…';

  @override
  String s_c4f36bd6({required Object added, required Object duplicated, required Object failed}) {
    return '导入完成：新增 $added 本，更新 $duplicated 本$failed';
  }

  @override
  String get s_28ab46d9 => '本地还没有微信读书的书，先做一次书架同步';

  @override
  String get s_6d61442b => '正在同步阅读进度…';

  @override
  String s_a26c53db({required Object length, required Object updated}) {
    return '已更新 $updated / $length 本的阅读进度';
  }

  @override
  String get s_3a0cf870 => '网络连接被中断，检查网络后重试';

  @override
  String get s_1cbe2507 => '确认';

  @override
  String get s_1df9fbd5 => '导入';

  @override
  String get s_874053cb => '微信读书 API Key';

  @override
  String get s_58652b51 => '用微信扫码打开 weread.qq.com/r/weread-skills，\n复制页面上的 Key（wrk- 开头）。Key 只保存在本机。';

  @override
  String get s_cb2558f7 => '截图导入书架';

  @override
  String get s_24b715f3 => '从相册选一张书架截图，识别每一格的书名与进度。识别结果可能有偏差，保存前请核对。';

  @override
  String get s_4f062f79 => '拍照导入书架';

  @override
  String get s_6e464c0e => '拍封面、书脊或书页，识别书名并自动补全作者、出版社等元数据。识别结果可能有偏差，保存前请核对。';

  @override
  String get s_a5452d46 => '从渠道同步书架';

  @override
  String get s_d40e2a14 => '通过已配置渠道的官方接口读取书架与阅读状态，无需截图。目前支持微信读书，更多渠道正在接入。';

  @override
  String get s_af94a367 => '同步阅读进度';

  @override
  String get s_59d2efab => '逐本拉取阅读百分比与累计时长。部分渠道的书架接口不含进度，需单独请求。';

  @override
  String get s_fa52186c => 'CSV / Notion 导入';

  @override
  String get s_2c78f2b8 => '从 Notion 导出的 CSV 一键迁移，列名自动识别，自定义字段不丢失。';

  @override
  String get s_238b14fc => '处理中…';

  @override
  String s_ed4b0551({required Object length}) {
    return '$length 本未能导入';
  }

  @override
  String s_ec50ebde({required Object length}) {
    return '…另有 $length 条';
  }

  @override
  String get s_18307d56 => '手动添加';

  @override
  String s_cc0eef03({required Object length}) {
    return '识别到 $length 本';
  }

  @override
  String get s_0f466d7a => '全选';

  @override
  String get s_42b2fafa => '全不选';

  @override
  String s_7feb7674({required Object keptLines, required Object repairedTitles, required Object totalLines, required Object usedLlm}) {
    return '识别到 $totalLines 行文字，采用 $keptLines 本$usedLlm$repairedTitles';
  }

  @override
  String get s_4d52323f => '带「补齐」「推测」标记的条目，书名不是原图原文，请确认后再导入。标题与作者都可以点开修改。';

  @override
  String get s_0f40975c => '手动添加一本（OCR 没读到的）';

  @override
  String s_fdc0acd1({required Object length}) {
    return '导入选中的 $length 本';
  }

  @override
  String get s_4443bd2c => '原图被截断';

  @override
  String s_7af46a28({required Object progressPercent}) {
    return '进度 $progressPercent%';
  }

  @override
  String s_4737de25({required Object toStringAsFixed}) {
    return '置信度 $toStringAsFixed%';
  }

  @override
  String s_2df91ffc({required Object rawText}) {
    return '原图：$rawText';
  }

  @override
  String get s_7bbe0f10 => '作者（可留空）';

  @override
  String get s_bd13cf0b => '删掉这条';

  @override
  String get s_c048f107 => '统计区间';

  @override
  String get s_89c61e4a => '藏书总数';

  @override
  String get s_9da15a74 => '状态分布';

  @override
  String get s_130a42ae => '分类分布';

  @override
  String get s_98f42577 => '来源分布';

  @override
  String get s_5e8ebbe6 => '形态分布';

  @override
  String get s_5182e58a => '平均评分';

  @override
  String get s_50bcc778 => '评过分的本数';

  @override
  String get s_59c5e73a => '阅读时长分钟';

  @override
  String get s_48529b9f => '有阅读记录的天数';

  @override
  String get s_7be1388c => '未配置大模型 Key，到「设置 → 大模型」填写后才能生成';

  @override
  String get s_992d7786 => '模型没有返回可用的标签，换个模型再试';

  @override
  String get s_eead3bcd => '用这一组替换？';

  @override
  String s_b9da6464({required Object length, required Object length_1}) {
    return '当前 $length 个标签会被替换成这 $length_1 个。替换后仍然可以逐个编辑或删除。';
  }

  @override
  String get s_89829921 => '替换';

  @override
  String get s_0f8acec9 => '已替换为主标签';

  @override
  String get s_93aebfd1 => '这个标签已经在上面了';

  @override
  String get s_bca518fd => '已加入主标签';

  @override
  String s_284dfaab({required Object text}) {
    return '已删除「$text」';
  }

  @override
  String get s_8eb8d18d => '编辑标签';

  @override
  String get s_35c48d07 => '这是你自己写的标签，没有自动依据。';

  @override
  String get s_724386f0 => '添加标签';

  @override
  String get s_fdd8c684 => '自己写的标签不做校验，也不会被重算覆盖。';

  @override
  String get s_7b328e58 => '恢复默认标签？';

  @override
  String get s_b9a4d4ef => '你手动改过的内容会被清掉，重新按当前藏书结构推导。';

  @override
  String get s_0fcef2c8 => '已恢复为按藏书推导的标签';

  @override
  String get s_e97565e5 => '我的阅读画像';

  @override
  String s_783e43af({required Object e}) {
    return '生成分享图片失败：$e';
  }

  @override
  String get s_14f92b04 => '生成分享图片';

  @override
  String get s_a17c4e02 => '已保存到相册';

  @override
  String s_3f81d5b6({required Object e}) {
    return '保存失败：$e';
  }

  @override
  String get s_c6d1e7a3 => '图片已生成';

  @override
  String get s_b8e4c9a1 => '保存图片到本地';

  @override
  String get s_51ebc0d1 => '重新计算';

  @override
  String get s_6c64acc5 => '我的性格标签';

  @override
  String s_03bf36af({required Object length}) {
    return '$length 本藏书推出';
  }

  @override
  String get s_a789d74f => '标签都被删掉了。点下面的「添加」自己写一个，或恢复默认让系统重新推导。';

  @override
  String get s_a1d885c1 => '添加';

  @override
  String get s_64bff158 => '点标签可改文字或删除；规则推导的那些带数字依据，在编辑弹窗里能看到。';

  @override
  String get s_84bf2c49 => '生成中…';

  @override
  String get s_5a251fee => '让 AI 再生成一组';

  @override
  String get s_18be3bbe => '恢复默认';

  @override
  String get s_7ae84af3 => '阅读偏好分布';

  @override
  String s_aeed65e7({required Object length}) {
    return '共 $length 类';
  }

  @override
  String get s_f2a9e2a4 => '圆形面积与书本数量成正比（所以半径按数量的平方根算，直接拿数量当半径会把差距放大成误导）。';

  @override
  String s_abd0dab0({required Object stamp}) {
    return 'AI 生成 · $stamp';
  }

  @override
  String get s_7ea8e671 => '替换主标签';

  @override
  String get s_d1a58b2f => '点单个标签把它加进主标签，或整组替换。这一组由模型根据聚合统计生成，依据没有规则版明确。';

  @override
  String get s_a38881a0 => '这个区间里还没有书';

  @override
  String get s_20fde694 => '换一个时间范围，或者先导入一些书';

  @override
  String get s_9fe34cff => '暂无分类数据';

  @override
  String s_d9579b73({required Object bookCount, required Object rangeLabel}) {
    return '$rangeLabel · $bookCount 本藏书';
  }

  @override
  String get s_bfc50de8 => '性格标签';

  @override
  String get s_ab5cc063 => '阅读偏好';

  @override
  String get s_9de44e0f => '阅读管理 · 我的书架';

  @override
  String get s_20a63774 => '选择统计区间';

  @override
  String get s_d507abff => '确定';

  @override
  String get s_ff31410d => '自定义…';

  @override
  String get s_72cca1f6 => '配置已保存到本地';

  @override
  String s_b6477017({required Object name}) {
    return '已填入 $name，还需要填 API Key';
  }

  @override
  String get s_533f5118 => '正在拉取模型列表…';

  @override
  String s_648219b9({required Object id}) {
    return '已选择模型：$id';
  }

  @override
  String s_baf95794({required Object length}) {
    return '共 $length 个可用模型（未选择）';
  }

  @override
  String get s_e37cab47 => '正在测试连通性…';

  @override
  String s_c17c1a05({required Object latencyMs, required Object model, required Object reply}) {
    return '连通正常 · $model\n耗时 $latencyMs ms，模型回复「$reply」';
  }

  @override
  String get s_5df0d12b => '正在验证微信读书 Key…';

  @override
  String s_bd245b07({required Object n}) {
    return 'Key 有效，书架当前 $n 本';
  }

  @override
  String s_73f89115({required Object host}) {
    return '连不上 $host\n检查网络、Base URL 是否写全（含 /v1），以及该服务是否需要代理';
  }

  @override
  String get s_9038e16e => '对端响应超时（180 秒）';

  @override
  String s_e0710bf5({required Object e, required int? statusCode}) {
    return '服务返回 $statusCode：$e';
  }

  @override
  String s_24d6c7ae({required Object name}) {
    return '请求失败：$name';
  }

  @override
  String get s_4d3eb2b3 => '搜索模型';

  @override
  String s_17d94005({required Object length}) {
    return '共 $length 个';
  }

  @override
  String get s_a48ae43a => '点选即写入模型名';

  @override
  String get s_b5c7b82d => '设置';

  @override
  String get s_bc90fa59 => '用于同步书架与阅读进度。扫码打开 weread.qq.com/r/weread-skills 可获取。';

  @override
  String get s_e44e9f26 => '验证 Key';

  @override
  String get s_75bf6943 => '大模型';

  @override
  String get s_9e8f6691 => '用于元数据兜底补全、截图识别整理与阅读报告。';

  @override
  String get s_cc3c9556 => '服务商预设';

  @override
  String get s_9021b9f9 => '选择后自动填入地址与模型';

  @override
  String get s_1fd51aaa => '模型名称';

  @override
  String get s_209e1f28 => '建议点「拉取模型」从账号实际可用的列表里选';

  @override
  String get s_ab135d7c => '拉取模型';

  @override
  String get s_a46a5664 => '测试连通性';

  @override
  String get s_e4f7e107 => '显示密钥';

  @override
  String get s_b13be56e => '隐藏密钥';

  @override
  String get s_9ac01f6b => '测试与拉取都会先保存你填写的内容。';

  @override
  String get s_0001747c => '截图识别';

  @override
  String get s_3f5cbdbf => '决定拍照/截图导入的识别效果。';

  @override
  String get s_9130a4ed => '图像增强预处理';

  @override
  String get s_b79fc99c => '先放大并增强图像，小字书名识别更准。';

  @override
  String get s_9695a603 => '用大模型整理识别结果';

  @override
  String get s_267118b5 => '用大模型整理识别出的书名。需要配置大模型 Key 并消耗 token。';

  @override
  String get s_6d7e1f9f => '识别方式';

  @override
  String get s_ed144a76 => '自动（多模态优先，失败回落端侧）';

  @override
  String get s_c7bab837 => '多模态大模型直接读图';

  @override
  String get s_d8f3da2a => '端侧 OCR（离线、免费）';

  @override
  String get s_f22e4cd2 => '端侧 OCR 离线可用但可能漏读；多模态模型能理解版面，但需联网且可能编书名。「自动」两者结合最稳。';

  @override
  String get s_67677b3d => '数据';

  @override
  String get s_d596ba9b => '导出整库 JSON 用于换设备迁移。全新安装的书架是空的，看书请从「导入」页同步或添加。';

  @override
  String get s_39239742 => '一键导出 / 恢复数据';

  @override
  String get s_3c21597a => '所有改动都会自动保存到本机数据库，无需手动保存。';

  @override
  String get s_68885a92 => '密钥仅保存在本机数据库中，不会随应用分发或上传。';

  @override
  String get s_9b3c95d4 => '最近更新';

  @override
  String get s_97428491 => '最近读完';

  @override
  String get s_8f38c041 => '评分最高';

  @override
  String get s_50a7317f => '进度最深';

  @override
  String get s_b5538557 => '书名升序';

  @override
  String s_e3cd14ba({required Object title}) {
    return '已添加《$title》';
  }

  @override
  String get s_296fc9b4 => '书架';

  @override
  String get s_a444b428 => '排序';

  @override
  String get s_fa0a5cdd => '切换为列表';

  @override
  String get s_cb4a4231 => '切换为封面网格';

  @override
  String get s_78966c42 => '搜索书名 / 作者 / 出版社';

  @override
  String get s_8ed41c6c => '没有符合筛选条件的书';

  @override
  String get s_bd33274a => '还没有书，去「导入」页添加吧';

  @override
  String s_0cd6d0f8({required Object length}) {
    return '共 $length 本';
  }

  @override
  String s_ff7e02df({required Object finished, required Object reading}) {
    return '在读 $reading · 已读 $finished';
  }

  @override
  String get s_68022ee7 => '全部';

  @override
  String get s_542b67cc => '更多筛选';

  @override
  String get s_ec977df0 => '来源平台';

  @override
  String get s_50d471b2 => '重置';

  @override
  String get s_37361909 => '图表显示设置';

  @override
  String get s_b1288e4a => '全部显示';

  @override
  String get s_6b2b7015 => '全部隐藏';

  @override
  String get s_e91a9228 => '只显示你关心的图表，其余收起来。';

  @override
  String get s_fe93ef35 => '应用';

  @override
  String get s_0d65fca2 => '[《》「」]';

  @override
  String s_9380d869({required int? daysUntilDue}) {
    return '应还 $daysUntilDue 天';
  }

  @override
  String get s_0e13c16f => '统计';

  @override
  String get s_3ad4c4c8 => '阅读画像';

  @override
  String s_7c6c253b({required Object label}) {
    return '本期 · $label';
  }

  @override
  String get s_88c0b751 => '按书的完成/活动日期归属';

  @override
  String get s_50ba5fd5 => '本';

  @override
  String get s_cc4556af => '新增藏书';

  @override
  String get s_3509a9f8 => '天';

  @override
  String get s_a7e9ff0f => '分';

  @override
  String get s_58d90b89 => '当前书架';

  @override
  String get s_c3bb899b => '快照口径，不受上面的时间筛选影响';

  @override
  String get s_563edd9d => '总藏书';

  @override
  String get s_0d8d3eb3 => '连续阅读';

  @override
  String get s_4ab30c5b => '在读低进度';

  @override
  String s_b563f985({required Object label}) {
    return '结构分析 · $label';
  }

  @override
  String s_a7e09561({required Object length}) {
    return '共 $length 本纳入统计';
  }

  @override
  String get s_c6cc650b => '阅读状态分布';

  @override
  String get s_8137585d => '分类分布 Top 8';

  @override
  String s_f92480e2({required Object length}) {
    return '共 $length 个分类';
  }

  @override
  String get s_50feb68a => '月度在读';

  @override
  String get s_750a3b1c => '这个区间还没有月度在读记录';

  @override
  String get s_4d7dd157 => '月度阅读时长';

  @override
  String get s_5a78dc03 => '导入微信读书年度统计后显示';

  @override
  String get s_5b37ad6b => '评分分布';

  @override
  String s_3c0e984b({required Object toStringAsFixed, required Object unratedCount}) {
    return '平均 $toStringAsFixed 分 · 未评分 $unratedCount 本';
  }

  @override
  String get s_3c1cb8ee => '还没有评过分';

  @override
  String get s_01d886c7 => '在读进度分布';

  @override
  String s_ecf53f5a({required Object readingInRange}) {
    return '共 $readingInRange 本在读';
  }

  @override
  String get s_faf98ba4 => '这个区间没有在读的书';

  @override
  String s_77030fdc({required Object length}) {
    return '共 $length 个平台';
  }

  @override
  String s_cea9cf70({required Object first}) {
    return '$first 年';
  }

  @override
  String s_c4e530bb({required Object first, required Object last}) {
    return '$first-$last 年';
  }

  @override
  String s_00fbaae1({required Object scope, required Object toStringAsFixed}) {
    return '$scope · 合计 $toStringAsFixed 小时';
  }

  @override
  String s_e7b115df({required Object join}) {
    return '微信读书年度统计只覆盖 $join 年，所以这张图按自然年画；上面那张读完图用的是最近 12 个月。';
  }

  @override
  String s_9ef861db({required Object name, required Object toInt}) {
    return '$name\n$toInt 本';
  }

  @override
  String s_2cf3ef4e({required Object i, required Object toInt}) {
    return '$i · $toInt 本';
  }

  @override
  String s_e241a8ef({required Object i, required Object toStringAsFixed}) {
    return '$i · $toStringAsFixed 小时';
  }

  @override
  String get s_1597bc27 => 'AI 阅读报告';

  @override
  String s_5024726e({required Object reportCount}) {
    return '已存档 $reportCount 份 · 按年 / 月归档，可随时回看';
  }

  @override
  String get s_73f01b82 => '按年 / 月生成一份阅读总结，点开即可生成';

  @override
  String get s_530f5951 => '查看';

  @override
  String get s_d51cd7ae => '生成';

  @override
  String get s_f8525cf2 => '暂无数据';

  @override
  String s_854a34ca({required Object author}) {
    return '，作者：$author';
  }

  @override
  String s_edf331af({required Object detail}) {
    return '：$detail';
  }

  @override
  String s_50018e2c({required Object hint}) {
    return '\n补充：$hint\n';
  }

  @override
  String s_a537d6ac({required Object first}) {
    return '（备份于 $first）';
  }

  @override
  String s_acd7a061({required Object failed}) {
    return '，失败 $failed 本';
  }

  @override
  String get s_da4d4d27 => ' · 已用大模型整理';

  @override
  String s_af735e5a({required Object repairedTitles}) {
    return ' · 已补齐 $repairedTitles 个截断书名';
  }

  @override
  String get navNotes => '记录';

  @override
  String get notesViewByTime => '按时间';

  @override
  String get notesViewByBook => '按书';

  @override
  String get notesFilterByBook => '按书筛选';

  @override
  String get notesAllBooks => '全部书';

  @override
  String get notesBookMissing => '书籍已不存在';

  @override
  String notesOverview({required int count, required int books}) {
    return '共 $count 条 · 覆盖 $books 本书';
  }

  @override
  String notesMoreCount({required int count}) {
    return '还有 $count 条';
  }

  @override
  String get notesEmptyTitle => '还没有笔记';

  @override
  String get notesEmptyDesc => '打开任意一本书，在详情页下方记一条划线或想法，它们会自动汇总到这里。';

  @override
  String get notesEmptyFilteredTitle => '这本书还没有笔记';

  @override
  String get notesEmptyFilteredDesc => '换一本书，或者清除筛选看看其它笔记。';

  @override
  String get notesClearFilter => '清除筛选';

  @override
  String get settingsLanguage => '界面语言';

  @override
  String get settingsLanguageDesc => '选择应用显示的语言。默认跟随系统设置。';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langFr => 'Français';

  @override
  String get langEs => 'Español';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsAppearanceDesc => '选择皮肤与明暗模式。';

  @override
  String get statusWishHint => '还没开始读的书。';

  @override
  String get statusReadingHint => '正在读，还没读完。进度到 100% 会自动变成「已读完」。';

  @override
  String get statusFinishedHint => '已经读完的书。把进度拖到 100% 就会自动标成这个状态。';

  @override
  String get statusShelvedHint => '读了一部分但暂时不打算继续的书。以后想接着读，改回「阅读中」即可。';

  @override
  String get borrowTitle => '借阅';

  @override
  String get borrowDesc => '标记这本书是借来的，可以填借阅来源和应还日期。';

  @override
  String get borrowFlag => '这是借来的书';

  @override
  String get borrowFrom => '借阅来源';

  @override
  String get borrowFromHint => '例：市图书馆、某某同事';

  @override
  String get borrowDue => '应还日期';

  @override
  String get borrowDueUnset => '未设置';

  @override
  String borrowDueIn({required int days}) {
    return '还有 $days 天到期';
  }

  @override
  String borrowOverdue({required int days}) {
    return '已逾期 $days 天';
  }

  @override
  String get borrowClearDue => '清除日期';

  @override
  String get borrowReturn => '标记已归还';

  @override
  String get borrowReturnDesc => '还回后会清除借阅标记、来源与应还日期，并取消还书提醒。';

  @override
  String get borrowReturned => '已标记为归还';

  @override
  String get statusSectionTitle => '阅读状态';

  @override
  String get planSectionTitle => '阅读计划';

  @override
  String get planSectionDesc => '给自己定一个能坚持的目标。计划只存在这台设备上。';

  @override
  String get planEmpty => '还没有计划。定一个小目标，比如每天 20 分钟。';

  @override
  String get planAdd => '新建计划';

  @override
  String get planEdit => '编辑计划';

  @override
  String get planKindDaily => '每天阅读';

  @override
  String get planKindFinishBook => '读完一本书';

  @override
  String get planKindDailyDesc => '设定每天的阅读时长目标，按日均值判定达成。';

  @override
  String get planKindFinishBookDesc => '选一本书和截止日期，读到 100% 即达成。';

  @override
  String get planDailyTarget => '每天目标';

  @override
  String planMinutesUnit({required int n}) {
    return '$n 分钟';
  }

  @override
  String get planPickBook => '选择一本书';

  @override
  String get planDueLabel => '截止日期';

  @override
  String get planDueUnset => '未设置';

  @override
  String get planRemind => '到期前提醒我';

  @override
  String get planRemindOff => '开启后会请求通知权限。完成计划后提醒会自动取消。';

  @override
  String get planTitleLabel => '计划名称（可选）';

  @override
  String get planTitleHint => '留空则自动使用默认名称';

  @override
  String get planSave => '保存';

  @override
  String get planDelete => '删除计划';

  @override
  String get planDeleteConfirm => '删除这条计划？已有的阅读记录不受影响。';

  @override
  String get planMarkDone => '标记完成';

  @override
  String get planAchieved => '已达成';

  @override
  String get planMarkToday => '今天读完了';

  @override
  String get planDoneToday => '今天已完成';

  @override
  String get planDailyCycleHint => '每天都是新的一天——勾选只代表今天完成，明天照旧提醒。';

  @override
  String get planReminderUnavailable => '系统没能排上提醒（可能是省电策略拦了）。计划本身已保存。';

  @override
  String planProgressDaily({required String current, required String target}) {
    return '日均 $current / $target 分钟';
  }

  @override
  String planProgressBook({required int current}) {
    return '进度 $current% · 目标 100%';
  }

  @override
  String planDaysLeft({required int days}) {
    return '还有 $days 天';
  }

  @override
  String planOverdue({required int days}) {
    return '已逾期 $days 天';
  }

  @override
  String planStreak({required int n}) {
    return '连续打卡 $n 天';
  }

  @override
  String get planDueToday => '今天到期';

  @override
  String get planBookGone => '目标书已不在书架';

  @override
  String get planDoneSection => '已结束';

  @override
  String get planReminderDenied => '通知权限被拒绝，提醒无法送达。可在系统设置里开启。';

  @override
  String get planReminderDailyTitle => '今天的阅读目标还没完成';

  @override
  String planReminderDailyBody({required int minutes}) {
    return '目标是 $minutes 分钟，现在还来得及。';
  }

  @override
  String get planReminderBookTitle => '这本书快到期了';

  @override
  String planReminderBookBody({required int days}) {
    return '距离计划截止还有 $days 天，加油读完吧。';
  }

  @override
  String get settingsPlanReminder => '阅读提醒';

  @override
  String get reportSettings => '报告设置';

  @override
  String get reportBackfill => '补生成缺失的报告';

  @override
  String get reportNothingToBackfill => '所有该生成的报告都已存在，没有需要补的。';

  @override
  String get reportHistoryEmpty => '还没有报告。选好周期，点下面的按钮生成第一份。';

  @override
  String get reportNoKey => '还没有配置大模型，无法生成报告。请先到「设置」里填入 Key。';

  @override
  String get settingsTheme => '皮肤';

  @override
  String get settingsBrightness => '明暗模式';

  @override
  String get brightnessSystem => '跟随系统';

  @override
  String get brightnessLight => '浅色';

  @override
  String get brightnessDark => '深色';

  @override
  String get themeGreen => '绿意';

  @override
  String get themeInk => '墨韵';

  @override
  String get themeAmber => '暖阳';

  @override
  String get themeBlue => '远山';

  @override
  String get themeRose => '樱粉';

  @override
  String get settingsChannels => '第三方渠道';

  @override
  String get settingsChannelsDesc => '从其他阅读平台同步书架与进度。目前支持微信读书；其他平台开放接口后会陆续加入。';

  @override
  String get settingsChannelsHint => '密钥只保存在本机系统密钥库，不会上传到任何服务器。';

  @override
  String get settingsChannelAddHint => '更多渠道正在接入中。';

  @override
  String get importAccuracyTitle => '识别结果可能有偏差';

  @override
  String get importAccuracyDesc => '书名与作者由 OCR 与大模型推断，可能读错字或认错书，保存前请核对一遍。';

  @override
  String get importFromImageTitle => '截图导入书架';

  @override
  String get importFromImageDesc => '从相册选一张书架截图，自动识别其中的书目。';

  @override
  String get importFromCameraTitle => '拍照导入书架';

  @override
  String get importFromCameraDesc => '对着书架拍一张，自动识别其中的书目。';

  @override
  String get insights => '阅读档案';

  @override
  String get insightsDesc => '你的长期阅读画像，以及按月、按年生成的分析报告。';

  @override
  String get chronology => '阅历';

  @override
  String get chronologyDesc => '按月回看你读过的书。点一张卡片可以直接打开这本书。';

  @override
  String get chronologyEmpty => '这一年还没有读完或正在读的书。';

  @override
  String get chronologyFinished => '已读完';

  @override
  String get chronologyReading => '阅读中';

  @override
  String get chronologyShelved => '搁置';

  @override
  String get chronologyWish => '想看';

  @override
  String chronologyMore({required int n}) {
    return '另有 $n 本（点开看整月）';
  }

  @override
  String get reportStyle => '报告风格';

  @override
  String get reportStyleDesc => '选择生成报告的语气与结构，也可自定义提示词。';

  @override
  String get reportStyleRational => '理性罗列';

  @override
  String get reportStyleRationalDesc => '客观陈述数据，不评价、不煽动，条目清晰。';

  @override
  String get reportStyleWarm => '温和鼓励';

  @override
  String get reportStyleWarmDesc => '肯定你的坚持，用温和的语气给出建议。';

  @override
  String get reportStyleDirect => '直率犀利';

  @override
  String get reportStyleDirectDesc => '指出问题不留情面，适合想要实话的人。';

  @override
  String get reportStyleConcise => '简洁速览';

  @override
  String get reportStyleConciseDesc => '只讲结论，控制在最短篇幅。';

  @override
  String get reportStyleCustom => '自定义';

  @override
  String get reportStyleCustomDesc => '自己写提示词，完全掌控报告的样子。';

  @override
  String get reportStyleCustomHint => '例如：用第二人称，像朋友聊天一样点评我的阅读。';

  @override
  String get reportReadMore => '查看全文';

  @override
  String get reportNoContent => '（这份报告没有正文）';
}
