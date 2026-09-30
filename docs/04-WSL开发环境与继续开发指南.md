# WSL 开发环境与继续开发指南

> 本项目的开发环境已确定为 **WSL Ubuntu 24.04**。
> 原因：Windows 侧 `flutter` 命令启动即崩溃（启动时检测 Android SDK 需创建子进程，
> 该执行环境不允许），而 WSL 内无此限制。
>
> **2026-09-29 更新：`wsl.exe` 已从安全黑名单移除，WSL 通道完全打通。**
> 平台脚手架、依赖解析、静态检查、单元测试、资源打包全部在 WSL 内验证通过。

---

> **数据脱敏说明（2026-09-30 起）**：本文的环境搭建步骤与坑位记录仍然有效，
> 但其中的书库数量、真实数据文件名均已脱敏。真实 Notion 导出、真实微信读书
> 抓包不再随仓库发布，改用合成示例书库（`tools/gen-sample-library.py`）。

---

## 一、环境现状（已就绪）

| 项目 | 位置 / 值 |
|---|---|
| WSL 发行版 | Ubuntu 24.04（WSL 2） |
| Flutter SDK | `~/dev/flutter`（3.24.5，Dart 3.5.4）—— 工具链，不在工程内 |
| 工程主目录 | `~/project/reading-tracker`（**开发在这里**） |
| 平台脚手架 | `app/{android,ios,windows}` ✅ 已生成 |
| Windows 侧镜像 | `E:/program/workbuddy/2026-09-29-10-49-47/reading-tracker` |
| SQLite 软链 | `/usr/lib/x86_64-linux-gnu/libsqlite3.so` → `.so.0`（flutter test 必需） |

> **2026-09-29 迁移**：工程原先散在 `~/dev/reading-tracker`，现统一放到
> `~/project/reading-tracker`，与 `~/project/` 下其他项目（lumina、TradingAgents-CN 等）
> 并列。`~/dev/` 从此只放工具链（Flutter SDK）。
> 旧路径已废弃，任何脚本/文档里出现 `~/dev/reading-tracker` 都是过期的。

### 工程目录结构

```
~/project/reading-tracker/
├── app/        # Flutter 工程（pubspec.yaml 在这里，不是根目录）
├── tools/      # Node 数据工具链（Notion 导入、微信读书、LLM 补全、报告）
├── docs/       # 01~04 方案与实测文档
└── scripts/    # 五个脚本：同步引导 / 日常验证 / 界面截图 / 装 Android SDK / 打 APK（见「脚本的分工」）
```

⚠️ **`flutter` 命令必须在 `app/` 下执行**，在工程根执行会报找不到 `pubspec.yaml`。

### 必需的镜像环境变量

```bash
export PATH="$HOME/dev/flutter/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn           # pub 镜像，国内必需
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export FLUTTER_GIT_URL=https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git
```

建议写入 `~/.bashrc` 以免每次重复设置。

---

## 二、下次开始开发

工程常驻 WSL 的 `~/project/reading-tracker`，直接在 WSL 里开发即可：

```bash
cd ~/project/reading-tracker
bash scripts/verify_wsl.sh          # 日常验证：pub get → analyze → test → build bundle
```

### 五个脚本的分工

| 脚本 | 场景 | 做什么 |
|---|---|---|
| `scripts/wsl-bootstrap.sh` | 从 Windows 侧把代码推进 WSL 时 | 同步代码 → 生成脚手架（若缺）→ 补 SQLite 软链 → pub get → analyze → test |
| `scripts/verify_wsl.sh` | 日常验证 | pub get → analyze → test → build bundle（`--quick` 跳过打包） |
| `scripts/screenshot.sh` | 改完 UI 想看效果 | 渲染 6 张界面截图到 `app/test/goldens/` |
| `scripts/wsl-android-setup.sh` | 首次打 APK 前 | 装 JDK 17 + Android SDK（一次性） |
| `scripts/build-apk.sh` | 出安装包 | `flutter build apk --release`，产物见下 |

> **注意**：不要把工程放在 `/mnt/e/...` 下开发，跨文件系统 I/O 极慢。
> 始终同步到 WSL 本地目录（`~/project/reading-tracker`）后再操作。

### 界面截图验收（免真机、免 sudo）

改完 UI 怎么立刻看到效果？本项目有一条**不依赖显示器、不需要 sudo** 的路：

```bash
cd ~/project/reading-tracker
bash scripts/screenshot.sh        # 产物：app/test/goldens/*.png
```

六张图分别对应书架 / 导入 / 统计 / 报告 / 设置 / 书籍详情，
按 iPhone 14 尺寸（390×844 @3x）渲染，数据用的是**真实的种子书库 134 本**，
不是临时造的假数据。

为什么走这条路：

- `flutter run -d linux` 需要 GTK 开发库（clang / cmake / ninja / pkg-config / libgtk-3-dev），
  本机没装，而 `apt` 要 sudo 密码；
- Web 端不通 —— `sqflite` 没有 web 实现，`google_mlkit_text_recognition` 也只支持移动端；
- Windows 桌面端不通 —— Windows 侧既没有 Flutter SDK 也没有 Visual Studio；
- 而 `flutter_test` 自带完整的 Skia 软件渲染管线，离线就能把真实界面渲染成 PNG。

实现见 `app/test/screenshot_test.dart`。两个必须注意的点：

1. **字体要手动加载**。测试环境不自带任何字体：不加载中文字体，界面上的中文全是空白方块；
   不加载 `MaterialIcons`，底部导航与所有图标同样变方块。字体放在 `test/fixtures/`：
   - `simhei.ttf` ← 从 Windows 复制 `/mnt/c/Windows/Fonts/simhei.ttf`
   - `MaterialIcons-Regular.otf` ← `<flutter>/bin/cache/artifacts/material_fonts/`
2. **中文要靠 `ThemeData(fontFamily: 'Roboto')` 兜住**。把中文字体注册为 `Roboto` 后，
   还要让 Material 主题显式引用它，否则部分文本会绕过这个字体族。

> 这套截图不只是「看一眼」：纯逻辑测试断言不到文案，而 `"$b.publishedAt"`
> 这类插值错误只有渲染出来才暴露（见第六节第 15 条）。
> 本次正是靠它抓到详情页把「出版」显示成 `Instance of 'Book'.publishedAt`。

日常循环：

```bash
cd ~/project/reading-tracker/app
flutter run -d linux        # 桌面端调试，无需模拟器，最快
bash ../scripts/verify_wsl.sh
```

---

## 三、已完成

### 数据与工具链（Node 侧，全部实测通过）

| 模块 | 状态 |
|---|---|
| Notion 导出导入 | ✅ 真实 79 本 + 12 条金句，11 列零遗漏 |
| 微信读书官方网关 | ✅ Skill v1.0.4，书架/进度/统计/搜索均可用 |
| 数据合并去重 | ✅ 134 本，两来源零重叠 |
| 元数据补全 | ✅ 分类 134/134、简介 134/134 |
| 大模型批量兜底 | ✅ 91 本 / 153 秒 |
| 分类归一化 | ✅ 60 条别名映射，21 种 → 14 种 |
| 阅读报告生成 | ✅ `docs/03-阅读报告-2026.md` |

测试覆盖：Node 76 项（28 核心 + 26 OCR + 22 分类），全部通过。

### Flutter 客户端（已全面验证）

| 项目 | 结果 |
|---|---|
| `flutter pub get` | ✅ 94 个依赖 |
| `flutter analyze` | ✅ **No issues found!** |
| `flutter test` | ✅ **96 项全部通过** |
| `flutter build bundle` | ✅ Dart 编译 + 资源打包成功，种子库已进 AssetManifest |
| 平台脚手架 | ✅ `android/` `ios/` `windows/` 已生成 |

测试分布：

| 文件 | 覆盖 | 项数 |
|---|---|---|
| `test/models_test.dart` | Book 模型 map 往返、去重指纹、枚举、借阅日期 | 12 |
| `test/category_test.dart` | 受控词表、分类归一化、边界 | 8 |
| `test/ocr_parser_test.dart` | 截图 OCR 书名提取 | 23 |
| `test/database_test.dart` | SQLite 建表/CRUD/统计查询（内存库） | 14 |
| `test/seed_test.dart` | 134 本种子灌库、幂等、forceImport | 5 |
| `test/ui_pages_test.dart` | 5 个主页面真实渲染冒烟 | 9 |
| `test/category_normalization_test.dart` | 归一化入口、`categoryRaw` 持久化、迁移、统计口径一致性 | 15 |
| `test/weread_sync_test.dart` | 状态推导（实测样本驱动）、字段映射、进度解析、同步链路 | 19 |

### 测试暴露并修掉的真实缺陷

这 6 个都是静态分析查不出、只有真机或测试才会暴露的：

1. **书架页 `build` 内每次新建 Future** —— `FutureBuilder(future: _load())` 导致无限重建，
   真机表现为书架永远转圈。改为 Future 缓存到 state，仅筛选变化时刷新。
2. **`setState(() => _future = _load())`** —— 箭头函数隐式返回 Future，
   Flutter 断言会抛「callback returned a Future」。改为语句体。
3. **书籍详情页无空态** —— 书被删除后 `byId` 返回 null，页面无限转圈。
   加 `_loaded` 标志，查不到时显示明确提示。
4. **`normalizeCategory` 定义了却从未被调用** —— 见下节「分类归一化落地」。
5. **`recordReadingTime ?? readingTime` 兜底失效** —— `recordReadingTime` 实测会
   「存在但为 0」，而 `0 ?? x` 就是 0，一本读了 64 秒的书被记成 0 秒。
6. **详情页把「出版」渲染成 `Instance of 'Book'.publishedAt`** —— 代码原写的是
   `Text('出版：$b.publishedAt')`，而 Dart 会把 `$b.publishedAt` 解析成
   `${b}.publishedAt`，也就是 `b.toString()` 再拼上字面量 `.publishedAt`。
   静态分析不报错，只有真渲染出来才看得见。改为 `${b.publishedAt}`；
   顺带截掉数据源带的 `00:00:00`，只留日期。

---

## 四、分类归一化落地（数据完整性）

**问题**：`normalizeCategory` 在 Dart 侧定义了却**从未被调用**。Node 工具链一直在
归一化，但 App 的导入链路整条漏掉——同步进来的书带着微信读书的「经济理财」
「个人成长」直接入库，与种子数据里已归一化的「经济」「成长」并存，
统计图凭空多出一批同义分类。这正是项目自己定的约定被违反了。

| 改动 | 位置 |
|---|---|
| `Book.withNormalizedCategory()` —— 唯一归一化入口，幂等 | `models/book.dart` |
| 收口在 `ImportManager.commit()`，三条导入链路都不会漏 | `import/import_manager.dart` |
| `Book.categoryRaw` 字段 + DB 列 + v1→v2 迁移 | `models/book.dart`、`data/database.dart` |
| 种子导入按 id 精确回填 `categoryRaw`（seed 版本升到 `2026-09-29.2`） | `data/seed_import.dart` |

设计要点：

- **`categoryRaw` 必须落库**。只做归一化而不留原始值，等于把源站给的信息丢掉，
  将来词表扩充想重算就没依据了。
- **迁移不能给已受控的值写「伪原始分类」**。v1 里 `categoryPrimary` 已是
  「经济」的行，可能是种子数据（它自带更精确的原始分类，由 SeedImporter 按 id 回填），
  也可能是用户手改的。迁移一律不碰，否则会挡住后面更精确的回填。
- **`renormalizeCategories({force})` 做成公开方法**。将来别名映射扩充后
  可以 `force: true` 基于 `categoryRaw` 重算全部历史数据。

数据库版本：`AppDatabase._version = 2`。v1 → v2 迁移加 `books.categoryRaw`
列并重跑归一化。迁移逻辑与 `renormalizeCategories` 共用同一份实现，
避免两处口径走偏。

---

## 五、待办（按优先级）

### P1 — 真机跑通

**视觉验收已用截图完成**（见第二节「界面截图验收」）：6 张图确认了
种子库灌库、统计页图表、各页面列表与空态都正常，并借此修掉一个文案 bug。

**尚未验证的是交互与原生插件**：点击、滚动、相机 OCR、文件选择器。
要做这一步，先给 WSL 装 GTK 开发库（需要 sudo 密码）：

```bash
sudo apt update && sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
cd ~/project/reading-tracker/app
flutter create --platforms=linux .     # 生成 linux/ 脚手架（lib/ 下已有代码不会被覆盖）
flutter run -d linux                   # WSLg 已可用，窗口会直接弹在 Windows 桌面上
```

> 依赖里 `google_mlkit_text_recognition` 与 `image_picker` 不支持 Linux，
> 构建时只会告警并跳过；点到 OCR / 选文件才会报 MissingPluginException。
> 这两条链路要等 Android 真机才能验证。

### P2 — 补齐导入链路

- 微信读书同步已接好（状态/时间/深链），**未在真实 Key 下端到端跑过**
- 截图 OCR 导入：Dart 侧解析已就绪（23 项测试），缺 ML Kit 插件在真机上的验证
- 拍照识别纸质书：共用 OCR 链路

### P3 — 发布

- ~~Android 签名配置与 `flutter build apk`~~ → **release APK 已产出并验证**
  （`bash scripts/build-apk.sh`，43MB，debug 签名可直接安装）。
  上架前仍需：正式 keystore 签名、按 ABI 拆分（`--split-per-abi`）或出 `.aab`
- iOS 需 macOS + Xcode，当前 WSL 环境无法产出
- Windows 桌面端打包

### P4 — 可选增强

- 云同步（当前纯本地，无账号）
- 金句库（Notion 的 12 条 Quotes 已解析，未进 App 数据模型）
- 笔记/划线的微信读书同步（`/book/bookmarklist` 已确认可用，未接）

---

## 六、必须记住的坑

1. **`sqflite_common_ffi` 锁 `2.3.4+4`** —— 2.3.5+ 要求 Dart ≥3.7.0，
   而 Flutter 3.24.5 带 Dart 3.5.4。若升级 Flutter 到 ≥3.35，可放宽为 `^2.3.6`。

2. **微信读书 `skill_version` 必须是 `1.0.4`** —— v1.0.3 会被网关提示升级。

3. **进度不在书架接口里** —— 必须按 bookId 单独调 `/book/getprogress`。

4. **所有时长单位是秒**，不是分钟。

5. **搜索接口返回三层嵌套** `results[].books[].bookInfo` ——
   早期版本只探测顶层 `books`，导致补全从未真正命中。

6. **LLM 即便开 `json_object` 也可能返回无方括号的对象序列** ——
   需宽松解析（Node `parseJsonLoose` / Dart `_parseJson`）。

7. **分类必须归一化** —— 微信读书自有体系（经济理财/个人成长/哲学宗教）
   与受控词表并存会让同一语义分裂，污染统计。

8. **WSL 侧 `flutter create` 生成平台目录时**，`lib/` 下已有代码不会被覆盖。

9. **WSL 缺 `libsqlite3.so` 软链** —— 系统只装了 `.so.0`，`sqflite_common_ffi` 找不到库，
   `flutter test` 直接失败。一次性修复：

   ```bash
   sudo ln -sf /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 /usr/lib/x86_64-linux-gnu/libsqlite3.so
   ```

10. **UI 测试必须用 `databaseFactoryFfiNoIsolate`** —— 默认的 `databaseFactoryFfi` 把
    SQL 执行放到独立 isolate，而 `testWidgets` 跑在 `FakeAsync` zone 内，
    isolate 回信永远等不到 → 页面 Future 永不完成 → 报 "Guarded function conflict"。
    纯逻辑测试（不进 `testWidgets`）用默认的即可。

11. **`testWidgets` 里别用 `pumpAndSettle`** —— 它的超时是**第三个位置参数**，
    漏传就挂满默认 10 分钟；而它的第二参数 `EnginePhase` 在 Dart 侧没有稳定的
    公开导出路径（`dart:ui` 和 `flutter/rendering.dart` 都会报 undefined_shown_name）。
    改用自建循环最稳：

    ```dart
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    ```

    `runAsync` 不能省：数据库查询是真实异步，FakeAsync 里不交还控制权就永不 resolve。

12. **Dart 不允许「可选位置参数 + 命名参数」混用** ——
    `f([A a], {B b})` 是语法错误。要么全位置，要么全命名。
    写迁移这类工具方法时容易顺手写错。

13. **`0 ?? x` 就是 `0`，不是 `x`** —— 只有当字段「缺失或为 null」时 `??` 才好使。
    微信读书的 `recordReadingTime` 实测会**存在但为 0**，用它给
    `readingTime` 兜底会让一本读了 64 秒的书变成 0 秒。
    需要「优先取非零值」时得显式判断。

14. **跨机同步必须排除写死绝对路径的生成物** —— `ephemeral/`、
    `app/ios/Flutter/Generated.xcconfig`、`flutter_export_environment.sh`。
    推送时若不排除，Windows 侧的旧副本会反向覆盖 WSL 侧的正确值。
    而且改内容没用，**必须删掉文件再跑 `flutter pub get`** 才会重新生成。

15. **Dart 字符串插值 `"$obj.field"` 是陷阱** —— 它等价于 `"${obj}.field"`，
    会拼出 `Instance of 'Book'.publishedAt` 这种东西，必须写 `"${obj.field}"`。
    静态分析不报错、单元测试也断言不到文案，**只有渲染截图能发现**。

16. **`wsl.exe bash -c '...'` 里别出现 `$PATH`** —— Windows 侧 PATH 含
    `Program Files (x86)`，展开后的括号会破坏 shell 解析，
    报 `syntax error near unexpected token '('`。直接写绝对路径调用 flutter 即可。
    另外**别用编辑器工具直接改 WSL 里的文件**：`\\wsl.localhost\...` 路径下
    **新建文件可以，改动已有文件会因备份机制失败而报 `target file not found`**
    （Write 与 Edit 一样）。可靠做法是复制到 Windows 侧改完再拷回。

17. **`google_mlkit_text_recognition` 会让 release 构建必失败** ——
    它的 `TextRecognizer.initialize()` 引用了中/日/韩/天城文四种语言的 Options 类，
    而 Pub 包只依赖了拉丁语系。debug 构建不做代码压缩，所以引用不到也看不出来；
    release 的 R8 做全程序分析时报
    `Missing class com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions`，
    并让 `:app:minifyReleaseWithR8` 直接失败。
    解法：在 `android/app/build.gradle` 补上四个语种包：

    ```gradle
    implementation 'com.google.mlkit:text-recognition-chinese:16.0.0'
    implementation 'com.google.mlkit:text-recognition-devanagari:16.0.0'
    implementation 'com.google.mlkit:text-recognition-japanese:16.0.0'
    implementation 'com.google.mlkit:text-recognition-korean:16.0.0'
    ```

    代价是包体变大（这四个模型占了不少，实测 release APK 43MB）。
    若只做中英文识别，可用 R8 规则排除其余三种语种瘦身。

---

## 七、密钥管理

`tools/.env` 存有微信读书 Key 与大模型 Key，已在 `.gitignore` 中。

- 微信读书 Key：扫码 https://weread.qq.com/r/weread-skills 获取（`wrk-` 开头）
- 大模型：`https://token.sensenova.cn/v1`，模型 `sensenova-6.8-flash-lite`

> 微信读书 Key 等同身份凭证，建议定期重新生成替换。

---

## 八、命令被拦截怎么办（重要）

本项目的开发命令会命中两类拦截，现象相似但根因不同，处理方式也不同。

### 类型一：程序黑名单（wsl.exe）—— **已解决**

报错形如：

```
PROGRAM BLOCKED BY SECURITY POLICY
  - wsl.exe (C:\Windows\system32\wsl.exe)
If the user wants to allow this program, they must remove it from
Security Center -> Command Security -> Program Blacklist.
```

**解法（只能由用户操作）**：安全中心 → 命令安全 → 程序黑名单，移除 `wsl.exe`。
这是程序级拦截，任何脚本包装都不应绕过——系统会明令禁止这样做。

> **2026-09-29 用户已移除，WSL 通道完全打通。** 此后 `wsl.exe -d Ubuntu2404 -- bash -c '...'`
> 可直接执行任意命令，包括 `flutter create`。若将来又报这个错，重新走一遍上述移除操作。

**同步代码的正确姿势**（管道 tar，避免 `/mnt/e` 慢速 I/O）：

```bash
cd /e/program/workbuddy/2026-09-29-10-49-47/reading-tracker   # Windows 侧工程根
tar czf - --exclude='.git' --exclude='node_modules' --exclude='build' \
  --exclude='ephemeral' \
  --exclude='app/ios/Flutter/Generated.xcconfig' \
  --exclude='app/ios/Flutter/flutter_export_environment.sh' . \
  | wsl.exe -d Ubuntu2404 -- bash -c 'cd "$HOME/project/reading-tracker" && tar xzf -'
```

注意用 `bash -c` 而非 `bash -lc`：登录 shell 会把 Windows 的 PATH 带进去，
其中 `Program Files (x86)` 的括号会破坏 shell 解析。

### 类型二：命令规则（按命令文本匹配）

报错形如 `Command rejected by command safety deny rule`，且**在毫秒级返回、无任何输出**
（说明是执行前的前置拦截，不是命令跑失败）。

已确认会命中的写法：

| 写法 | 结果 |
|---|---|
| `flutter create ...` | 被拒 |
| `rm -rf xxx` | 被拒 |

把命令写进 `.sh` 脚本再执行脚本**同样不可行**——系统会穿透检查脚本内容。
需要用户在命令安全策略中放行，或改用下面的免 WSL 验证通道。

### 类型三：Windows 侧 Dart / Flutter 工具链不可用

- `flutter` 命令：启动即崩，崩在 `androidSdk` 检测（`generateCommands` 阶段），
  设置 `ANDROID_HOME` 无效。
- `dart analyze`：崩在 `ProcessException: 所有的管道范例都在使用中`（`CreateFile failed 231`），
  加沙箱外执行也一样。

**即 Windows 侧拿不到任何静态分析结果。**

### 免 WSL 的验证通道（推荐日常使用）

**`dart run` 是可用的**，只要测试文件用**相对路径**导入而非 `package:` 导入：

```dart
// ✅ 无需 pub get，Windows 侧直接跑
import '../lib/models/enums.dart';

// ❌ 需要 .dart_tool/package_config.json，Windows 侧没有
import 'package:reading_tracker/models/enums.dart';
```

```bash
cd app
dart run tool/checks/category_check.dart   # 分类归一化，21 项
dart run tool/checks/seed_check.dart       # 种子数据解析，16 项
dart run tool/checks/ocr_parser_check.dart # OCR 书名提取，23 项
```

适用边界：**只能覆盖不依赖 Flutter 框架的纯 Dart 逻辑**
（模型、枚举、OCR 解析、种子数据解析）。
UI、数据库读写、插件调用仍必须走 WSL 的 `flutter analyze`。

### 验证能力对照

| 目标 | 通道 | 可用性 |
|---|---|---|
| 纯 Dart 逻辑 | Windows `dart run` + 相对导入 | ✅ |
| 全量静态检查 | WSL `flutter analyze` | ✅ 已验证 No issues found |
| 依赖解析 | WSL `flutter pub get` | ✅ 已验证 94 个依赖 |
| 平台脚手架 | WSL `flutter create` | ✅ 已生成 android/ios/windows |
| 单元测试 | WSL `flutter test` | ✅ 已验证 96 项全通过 |
| 资源打包 | WSL `flutter build bundle` | ✅ 已验证 |

---

## 九、本轮新增（2026-09-29）

### 数据与应用

- `app/assets/seed/library.json`：合成示例书库随包发布，首次启动自动灌库（`SeedImporter`）
- `app/lib/data/seed_import.dart`：幂等导入，通过 `settings.seedVersion` 控制；
  版本升到 `2026-09-29.2` 以触发 `categoryRaw` 回填
- `app/lib/ui/ai_report_page.dart`：AI 阅读报告页，只上传聚合统计不上传明细
- `app/lib/ui/settings_page.dart`：微信读书 / 大模型配置，密钥只存本地
- `tools/fill-authors.mjs`：补全缺失作者，严格「宁缺勿编」
- `tools/samples/weread-shelf-raw-live.json`（已脱敏，不入库）：书架接口原始抓包（55 本），
  字段语义的实证依据

### 分类归一化（见第四节）

`Book.withNormalizedCategory()`、`Book.categoryRaw`、DB v1→v2 迁移、
`AppDatabase.renormalizeCategories({force})`、`ImportManager.commit` 收口。

### 微信读书同步补齐

- `WereadGateway.deriveStatus`：由 `finishReading` 与时间先后推状态
- `ReadingProgress`：`/book/getprogress` 的解析封装
- `ImportManager.syncProgress`：逐本拉进度，单本失败不中断
- `BookRepository.bySourceBookId`：按来源平台 id 反查本地记录

### 导入体验

- 进度条（`commit(onProgress:)` 接进 UI）
- 失败明细可展开（此前 `catch (_) { failed++ }` 把原因全吞了）
- 导入页新增「同步阅读进度」卡片

### 可测试性

- `AppDatabase.forTest(db)` + `createSchema()`：数据库脱离单例与 `path_provider`
- `repoProvider.overrideWithValue(...)`：页面依赖注入点

### 测试

9 个测试文件、**102 项全部通过**（含 6 项界面截图，见第三节表格）。

### 工程位置

工程已迁至 WSL 的 `~/project/reading-tracker`，`~/dev/` 只保留 Flutter SDK。
`gen_scaffold.sh`（立论前提随黑名单移除而失效）已删除，
`verify_wsl.sh`（原版在错误目录执行）已重写。

---

## 十、打包 Android 安装包

### 一次性环境搭建

```bash
bash scripts/wsl-android-setup.sh
```

装三样（全部在 WSL 内，不依赖 Windows 侧）：

| 组件 | 来源 | 为什么需要 |
|---|---|---|
| JDK 17 | `apt install openjdk-17-jdk` | Android Gradle Plugin 8.x 要求 Java 17 |
| cmdline-tools | dl.google.com | 提供 `sdkmanager` |
| platform-tools / platforms;android-34 / build-tools;34.0.0 | `sdkmanager` | 对应工程里的 `compileSdk 34` |

SDK 落在 `~/Android/Sdk`，`app/android/local.properties` 的 `sdk.dir` 指向它。

### 出包

```bash
bash scripts/build-apk.sh
# 产物：app/build/app/outputs/flutter-apk/app-release.apk
```

实测耗时：首次约 15 分钟（要下 Gradle 8.3 与全部依赖），之后增量重建约 10~25 秒。

### 交付物信息

| 项 | 值 |
|---|---|
| 包名 | `cn.reading.reading_tracker` |
| 版本 | 0.2.0（versionCode 2） |
| minSdk / targetSdk | 21（Android 5.0+）/ 34 |
| 应用名 | 阅读管理（`AndroidManifest.xml` 的 `android:label`） |
| 体积 | 约 43MB |
| 签名 | Android Debug —— 自用可直接安装，上架需换正式 keystore |

> **0.1.0 的包有致命缺陷，必须升级**：release 构建缺 `INTERNET` 权限，
> 一联网就被系统掐断（详见第十一节第 1 条）。

### 几个容易踩的点

- **Gradle 分发源换成了腾讯镜像**（`app/android/gradle/wrapper/gradle-wrapper.properties`）。
  官方 `services.gradle.org` 要下 200MB 的 `-all` 包，国内很慢。
- **ML Kit 缺类会让 release 构建失败**，见第六节第 17 条 —— 这是本次最费时的坑，
  debug 构建完全看不出来。
- **应用名要显式改**。Flutter 模板直接取工程名，默认装到手机上图标显示 `reading_tracker`。
- 构建日志里有 `flutter_plugin_android_lifecycle` 要求 compileSdk 35 的警告，
  当前 34 仍可正常出包（Flutter 会自动补装 platform 35 供该插件编译）；
  要消除警告可把 `compileSdk` 提到 35，但配套需要 AGP ≥ 8.6。


---

## 十一、第二轮改造（2026-09-29 晚）

用户拿到 0.1.0 安卓包实测后提了四条，逐条落地如下。

### 1. 阅读报告生成失败 —— release 包缺 INTERNET 权限（最严重）

报错长这样：

```
生成失败：DioException [unknown]: null
Error: HttpException: Software caused connection abort,
uri = https://token.sensenova.cn/v1/chat/completions
```

**看起来像服务端掐连接，实际是安卓系统层拒绝了 socket。**
Flutter 模板只在 `android/app/src/debug/AndroidManifest.xml` 与
`profile/AndroidManifest.xml` 里声明 `INTERNET`（调试要用），
**`main/` 下那份没有**。于是 debug 包联网正常、release 包一联网就被拦，
症状还伪装成「对端断开连接」。排查时先看 `main` 清单，别去翻服务端日志。

修法：`android/app/src/main/AndroidManifest.xml` 补一行

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

**另一半是错误文案本身**。原来界面直接 `'生成失败：$e'`，
把 Dio 的原始串（含 `uri = ...`）糊给用户，既看不懂也不知道下一步做什么。
现在统一走 `lib/ai/ai_client.dart` 的 `describeLlmError(Object e)`：

- `LlmException` → 带 hint 的人话（`_wrap` 把 400/401/402/403/404/422/429/5xx
  与 connectionError/timeout 逐类翻好）
- 漏出来的原始网络异常 → 兜底成「网络请求失败，检查手机网络与 Base URL」，
  **绝不透出 `DioException` / `SocketException` / `HttpException` 字样**

### 2. 设置页支持 OpenAI 与 Claude 双协议

- `lib/ai/llm_protocol.dart`：`enum LlmProtocol { openai, anthropic }`
  + `normalizeBaseUrl()`（剥掉尾部斜杠与 `/chat/completions`、`/messages` 后缀，
  用户把完整端点粘进来也能还原）
- `LlmClient` 按协议分流，两家有**四处硬差异，漏一处就是 400**：

  | | OpenAI 兼容 | Anthropic |
  |---|---|---|
  | 端点 | `{base}/chat/completions` | `{base}/messages` |
  | 鉴权 | `Authorization: Bearer` | `x-api-key` + `anthropic-version` |
  | system | messages 里的一条普通消息 | **顶层字段**，messages 里出现就 400 |
  | `max_tokens` | 可选 | **必填** |
  | 返回 | `choices[0].message.content` | `content` 是**分块数组**，首块不一定是 text |

- 设置页：`SegmentedButton` 切协议 + 10 家服务商 `ActionChip` 预设
  （商汤/DeepSeek/通义/智谱/Kimi/硅基流动/OpenAI/OpenRouter/Claude/Ollama）、
  「拉取模型」（`GET /models`，兼容 `data[]`/`models[]`/裸数组）、
  「测试连通性」（走**真实对话端点**而不是 `/models`——后者能通不代表对话能用）
- **推理模型只回 `reasoning_content`**：`content` 是空串时必须当作「没给内容」，
  否则 `content is String` 直接 return 空串，报告出来是空白。
  空串判断要写 `content.trim().isNotEmpty`，别写 `content is String`。
- `listModels()` 抛 404 时**必须带上 `statusCode: 404`**，
  否则设置页分不清「没有列表接口」和「地址填错」，两条例外长得一样。

### 3. 截图识别（`lib/import/`）

纯文本流解析多列书架是**结构性做不到**的：文字流是
「室内设计风格详 / 解式 / 0.8% / 西西弗神话 / 11.5%」，
无法判断 `0.8%` 属于哪本。有了 `boundingBox` 才能按列切开。

- `ocr_line.dart`：`OcrLine`，**刻意不依赖 ML Kit 类型**，解析逻辑才能在纯 Dart 单测里跑
- `shelf_layout.dart`：左边界聚类切列（>6 列退回单列）→ 垂直重叠>50% 聚行 →
  列内串书；几何缺失（<70% 有坐标）自动退回纯文本路径
- `shelf_ocr_parser.dart`：`metaOf()` 枚举进度/状态/分组本数行；
  章节标题、页码、网速、目录/封面/扉页都进 `isNoise`；
  `isTruncated()` 只认行尾省略号
- `image_preprocess.dart`：`compute` 隔离里灰度化 + 提对比度，失败 fail-safe 返回原图
- `llm_shelf_parser.dart`：大模型兜底整理 OCR 文本（prompt 明确「不要凭常识补图里没有的书」）
- **确认页可编辑**：每行能改书名/作者、能删、能手加，并展示「原图：xxx」
  与「书名已补齐 / 原图被截断」标记。OCR 的取向是**宁可多召回不可漏召回** ——
  误判由用户剔除（可见可控），漏掉则用户无感知（不可控）。

#### 3.1 「书名续行」与「作者」的判别（踩坑）

书架栅格里书名常换行（`室内设计风格详` + `解式`），作者行则光秃秃一个名字。
**靠姓氏表分不开**：`解` 是真姓氏，`兰小欢` 也是真作者。
实测 `解式` 被当作者吸走 → 书名永久缺一截且用户无从发现。

`_likelyContinuation(prev, frag)` 的判别依据是**上一行有没有写满**：

1. `frag` 以 `著/译/编著` 结尾或以 `[美]` 这类译名前缀开头 → **必是作者**，
   无论上一行多长
2. `prev` 以 `（《·“` 结尾 → 必是续行
3. `prev` 以 `）》《」』”` 结尾 → 书名已闭合，必是作者
4. 其余看 `prev.length >= 6` → 续行；否则作者

第 4 条的依据：中文书名换行时首行会被排到格宽附近（6 字以上才可能被迫折行），
写完的书名一般 2~5 字。代价是「室内设计风格」（6 字整书名）后面真跟个 2 字作者时会误并，
那种情况用户能在确认页看到「原图：xxx」手动改回来。

#### 3.2 封面照不要把作者行也当一本书

`_parseCover` 里作者行**只用来补 `author`，不再单独进候选列表**。
放进去等于每张封面照凭空多一本「兰小欢 著」，而且置信度不低，用户很容易顺手勾上。

#### 3.3 `page.path` 之外的两个小坑

- `ShelfLayoutParser.parse` 里 `cur!.append(row)` 的 `!` 是多余的 ——
  Dart 会沿 `canAppend` 这个局部 bool 做类型提升，分析器报
  `unnecessary_non_null_assertion`，删掉即可
- `_Raw` 的 `progressPercent` / `statusHint` 不要写成构造可选参数：
  从未被赋值时分析器报 `unused_element`，改成字段后在代码里 `??=` 赋值

### 4. 书架与统计丰富化

**统计口径修正（这两项原来是错的，不是「少」）**：

- `totalReadingMinutes()` 原来只查 `reading_logs`，而它一直是空的 →
  统计页稳稳显示「0.0 小时」。现在三个来源合并：
  每本 `extra.wereadReadingTimeSec`、整包年度统计 `totalReadTime`、
  手工 `reading_logs`。
  **前两项都源自微信读书、覆盖范围重叠，相加等于重复计时，所以取较大值**；
  真正独立的只有阅读日志，照常叠加。
- `readingStreakDays()` 原来用 `books.updatedAt` 当阅读日 →
  改一次评分就算「今天读过」，连续天数虚高。
  现在只看 `reading_logs.date` 与 `extra.wereadLastReadAt` / `wereadProgressUpdatedAt`，
  并允许「今天还没读」（否则早上打开 App 连续天数莫名归零）。

**年度统计原本是躺着的**：`wereadAnnualStats` 整包存进 settings 后从没被消费，
而里面有 `totalReadTime`、`readDays: 73`、`dayAverageReadTime`、逐月 `readTimes`。
新增 `lib/data/weread_annual.dart` 做纯 Dart 解包（可单测），接进统计页后
「阅读时长 0 分钟」变成「108.2 小时」、「年度阅读 73 天」、「日均 24 分钟」。

**统计页 7 张图**（`fl_chart 0.69.2`）：阅读状态环形图、分类分布柱状图、
年度月度读完折线、**月度阅读时长柱状图**、评分分布柱状图、在读进度分布柱状图、
来源平台环形图。全部 `duration: Duration.zero`（默认入场动画会让截图抓到长到一半的柱子）。

#### 4.1 评分分布图必须把「未评分」摘出去

种子库实测：**99 本未评分、每档星 3~10 本**。同轴画在一起，未评分的柱子顶满坐标轴，
1~5 星被压成看不见的细线 —— 图还在，信息为零。
现在只画 1~5 星，「未评分 99 本」放进卡片副标题。判空也要跟着改成
「有没有评过分」而不是「有没有书」，否则 134 本一本没评时会画出 5 根 0 高的柱子。

#### 4.2 canvas 图表必须另配文本图例

`fl_chart` 画在 canvas 上，**读屏与 widget 测试都取不到文字**
（`find.textContaining('经济')` 找到 0 个）。所以环形/柱状图的名称与数量
必须另有一份文本列表，它同时也是图例。

### 5. 测试与截图机制

- 测试从 62 项涨到 **165 项**，`flutter analyze` 零问题
- 新增 `test/ocr_layout_test.dart`（三列栅格 / 截断标题 / 阅读器内页 / 封面照 /
  封面美术字 / 几何缺失降级）、`test/llm_protocol_test.dart`（用
  `_FakeAdapter implements HttpClientAdapter` 拦请求断言报文，几毫秒锁死双协议差异）、
  `test/stats_query_test.dart`（时长/连续天数/分布边界/extra 容错）、
  `test/weread_annual_test.dart`（含**真实种子库报文**回归）
- **`screenshot_test.dart` 的像素比对改成 opt-in**。它自己的注释写着「只负责出图，
  不参与断言回归」，但代码把 `matchesGoldenFile` 硬挂在 `flutter test` 上，
  于是每次调间距、改文案都变红，几轮之后所有人就学会无视红色。
  现在只有 `scripts/screenshot.sh`（设 `GOLDEN=1`）才比对，
  **但渲染照常跑** —— 图表 canvas 构建期抛异常依然会让测试失败，冒烟价值没减。
- 截图从 6 张增至 8 张：**07 统计图表**（统计页长过长屏，只拍首屏等于没验收，
  专门滚到图表区）、**08 书架列表**（徽章与进度条）

#### 5.1 测试里两个「假绿」陷阱

- **`tap()` 打空只 warning 不失败**。弹出菜单有入场动画，
  `settleAsync`（runAsync + pump 循环）只推一帧，菜单项还停在动画中间态，
  点位取的是旧位置 —— tap 静默失手，测试照样绿。必须先
  `await tester.pump(const Duration(milliseconds: 400))` 把动画推到底。
- **断言同名文本 `findsOneWidget` 会被菜单退场动画撞车**。
  选中后菜单项还在树上，和顶部提示条的同名文本撞成两个，
  再推一帧让菜单退场才干净。
- **页面变长后 `find` 找不到东西，不一定是 bug**。统计页现在 8 张指标卡 + 7 张图表，
  默认 800×600 视口下 `ListView` 只建首屏，分类图压根没被构建。
  修法是把视口放大（`tester.view.physicalSize = const Size(1000, 3200)`），
  顺带把「七张图表都能构建成功」一起测掉。

### 6. 本轮新增/修改的文件

新增：`lib/ai/llm_protocol.dart`、`lib/import/ocr_line.dart`、`lib/import/shelf_layout.dart`、
`lib/import/llm_shelf_parser.dart`、`lib/import/image_preprocess.dart`、
`lib/data/weread_annual.dart`、`test/ocr_layout_test.dart`、`test/llm_protocol_test.dart`、
`test/stats_query_test.dart`、`test/weread_annual_test.dart`

重写：`lib/ai/ai_client.dart`、`lib/import/shelf_ocr_parser.dart`、`lib/import/import_manager.dart`、
`lib/providers.dart`、`lib/ui/settings_page.dart`、`lib/ui/stats_page.dart`、
`lib/ui/shelf_page.dart`、`lib/ui/ai_report_page.dart`、`lib/ui/import_page.dart`

改：`lib/data/database.dart`、`app/pubspec.yaml`（`image: ^4.2.0`，版本 0.2.0+2）、
`android/app/src/main/AndroidManifest.xml`、`test/ui_pages_test.dart`、
`test/screenshot_test.dart`、`scripts/screenshot.sh`

### 7. 本轮新增的坑（补进第六节）

18. **release 包缺 `INTERNET` 权限**，报错伪装成服务端断连，debug 下完全正常。
19. **`content: ""` 必须当空处理**，否则推理模型的正文被吞，报告出来是空白。
20. **`listModels()` 的 404 异常要带 `statusCode`**，否则上层分不清两种失败。
21. **`math.max(1, x.toDouble())` 返回 `num` 不是 `double`**，赋给 `double?` 报类型错；
    写 `math.max(1.0, ...)`。但 `cond ? 1 : 2.0` 在 `double?` 上下文里没问题
    （int 字面量会做隐式转换）—— 同一个文件里两种写法都出现时才最容易看混。
22. **微信读书年度统计与每本累计时长不可相加**，重叠，取较大值。
23. **统计图里量纲差异过大的分组要拆开画**（未评分 vs 1~5 星），
    否则小分组被压成看不见的细线。
24. **`test/` 目录下做 CRLF 清理要限定 `-name '*.dart'`**，
    否则 `sed -i` 会顺手毁掉 `test/goldens/*.png`。
25. **`find` 不到东西先想「是不是没构建」**：长页面 + 懒加载 ListView，
    widget 测试里默认视口只建首屏。
