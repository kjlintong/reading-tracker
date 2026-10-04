# Readnest

<p align="center">
  <img src="docs/images/app-icon.png" width="128" alt="Readnest 图标">
</p>

**Readnest**（原 reading-tracker）是一个本地优先的个人阅读管理 App：所有数据存在手机本地 SQLite 里，没有账号、没有服务器、没有云同步。首次启动自动灌入 38 本示例书，打开就是形态完整的书架、统计和阅读档案；再用自己的数据源（微信读书、Notion 导出、CSV、拍照 OCR）导入真实书单即可。

| 书架 | 统计 | 阅读档案 |
|---|---|---|
| ![书架](docs/images/01-shelf.png) | ![统计](docs/images/02-stats.png) | ![阅读档案](docs/images/03-profile.png) |

| AI 报告 | 记录（笔记 + 计划） |
|---|---|
| ![报告](docs/images/05-report.png) | ![记录](docs/images/07-notes.png) |

## 功能

- **多来源导入**：微信读书官方 Agent 网关、Notion 数据库导出（Markdown/CSV）、通用 CSV、书架照片 OCR（ML Kit 端侧离线识别，中英文）、手动录入
- **统一数据模型**：所有导入源先转成同一个 `Book` 结构，`extra` 兜底保存源系统自定义字段，迁移零丢失
- **多源合并去重**：ISBN 优先、书名+首位作者兜底；字段只补空缺，绝不覆盖你手填的评分与摘要
- **分类归一化**：127 条别名映射把各平台自有分类统一收敛到 20 类受控词表，同一语义不会在统计里分裂成两个标签
- **阅读计划**：每日型计划是周期任务（当天打卡、次日自动回到待完成，卡片面显示连续打卡天数），整体完成才归档；计划/还书提醒走本地通知
- **阅读统计**：分类分布、月度在读趋势、评分分布、在读进度、来源平台占比；每张图表都可以在「图表显示设置」里自选显隐
- **阅读档案**：偏好分布气泡图 + 性格标签（可增删改），一键分享出图或保存到相册
- **AI 阅读报告**：把本地算好的结构化统计交给大模型解读，模型不碰原文，也不会编造数字；支持年度/月度归档与多种语气风格
- **隐私与离线**：OCR 全程端侧；AI 报告只上传聚合统计、不上传书名与笔记原文；LLM 密钥用户自填，App 不代持
- **五种语言**：中 / 英 / 德 / 法 / 西全部文案，切换即时生效，设置页语言选项自动生成
- **五套主题**：green / ink / amber / blue / rose，亮暗色随系统

## 下载

前往 [Releases](https://github.com/kjlintong/reading-tracker/releases) 下载最新的 `Readnest-v*.apk`（Android）。

> iOS 版尚未上架 App Store；源码可自行构建。

## 赞助

Readnest 免费、无广告。如果它帮你记下了读过的书，可以请作者喝杯咖啡：

- 中国用户：[爱发电](https://afdian.com/a/ryanlintong)
- 国际用户：[Ko-fi](https://ko-fi.com/ryanlin65969)

## 架构

```
app/                Flutter 客户端（本地优先，无后端）
├── lib/
│   ├── models/     Book / ReadingLog / Note / ReadingPlan + 枚举与分类归一化
│   ├── data/       SQLite schema（v6）、仓储层、统计聚合、图表显示偏好
│   ├── import/     多源导入：CSV / OCR 行解析 / 书架版面检测 / LLM 兜底
│   ├── ai/         OpenAI 兼容 + Anthropic 两种协议的统一客户端
│   ├── services/   本地通知（计划/还书提醒）、分享出图
│   └── ui/         书架 / 记录 / 统计 / 阅读档案 / 设置（Riverpod 状态管理）
├── test/           426 项测试（逻辑 + widget + 截图基准）
├── assets/seed/    示例书库（合成数据，见下）
└── tool/checks/    纯 Dart 校验脚本，不依赖 Flutter 插件

store/              上架素材：42 张商店截图、512px 商店图标、文案
tools/              Node 数据工具链（离线预处理与报告生成）
scripts/            环境自检 / 截图 / 出包脚本
docs/               技术方案、数据源实测、隐私政策（中/英）等
```

## 从源码构建

要求 Flutter **3.24.x**（Dart 3.5.x），Android SDK 34。

```bash
git clone https://github.com/kjlintong/reading-tracker.git
cd reading-tracker/app
flutter pub get
flutter run                          # 真机 / 模拟器
flutter build apk --release          # 出包
```

首次跑测试需要中文字体（否则界面上中文全是空白方块）：

```bash
cp /mnt/c/Windows/Fonts/simhei.ttf test/fixtures/     # Windows 侧
cp ~/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf test/fixtures/
```

Linux / WSL 桌面调试需要 GTK 开发库（`clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`）；注意 `google_mlkit_text_recognition` 与 `image_picker` 不支持 Linux，构建时会告警跳过。

## 配置密钥（可选）

```bash
cd tools && cp .env.example .env
```

- `WEREAD_API_KEY`：扫码 https://weread.qq.com/r/weread-skills 获取（`wrk-` 开头），用于微信读书导入
- `LLM_API_KEY` / `LLM_BASE_URL` / `LLM_MODEL`：OpenAI 兼容协议的大模型，用于元数据兜底补全与 AI 报告

两者都留空也能用，只是对应的两条链路不可用。Key 等同身份凭证，建议定期重新生成替换。

## 测试

```bash
cd app && flutter test                 # 426 项，全部通过
cd tools && node test/smoke.mjs        # 28 项，CSV/解析/补全降级
cd tools && node test/category.test.mjs  # 22 项，分类归一化
cd app  && dart run tool/checks/seed_check.dart   # 种子数据完整性
cd app  && dart run tool/checks/category_check.dart # 分类词表校验
```

生成商店截图（免真机、免显示器，走 flutter_test 的 Skia 软件渲染）：

```bash
STORE_SHOTS=1 flutter test test/store_screenshots_test.dart   # 42 张，产物在 store/screenshots/
```

## 隐私

- 所有阅读数据仅存于设备本地，开发者无法接触
- AI 报告仅上传匿名化的聚合统计；模型密钥由用户自填、直连用户选择的端点，不经手任何第三方服务器
- 详见[隐私政策（中文）](docs/06-隐私政策(中文).md) / [Privacy Policy (EN)](docs/07-Privacy-Policy(EN).md)

## 文档

- [01 技术方案](docs/01-技术方案.md) — 数据模型、多源导入、分类归一化设计
- [02 数据接入与实测记录](docs/02-数据接入与实测记录.md) — 各数据源接入实测与踩坑
- [03 阅读报告-2026](docs/03-阅读报告-2026.md) — 基于真实数据的年度报告样例
- [04 WSL 开发环境与继续开发指南](docs/04-WSL开发环境与继续开发指南.md) — 环境搭建、脚本分工、已知坑位
- [05 上架审查报告](docs/05-上架审查报告.md) / [08 发布配置与清单](docs/08-发布配置与清单.md) — 商店上架材料与自检

## License

[MIT](LICENSE)
