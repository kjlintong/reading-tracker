# Readnest 效果图（推荐书单 / 分享卡 / 图标）

本目录是**给人看的效果图**，不是回归基准。复现命令写在下面每一节。

> ⚠️ 三条命令都需要带环境变量。不带的话测试会**直接 return**——
> 表现是「测试全绿但一张图都不出」，很容易误判成代码正常。

---

## 一、推荐书单「找书」页

```bash
SHOTS=1 flutter test test/recommend_shots_test.dart
```

产物 `recommend-*.png`（390×844 @3x）：

| 文件 | 看什么 |
|---|---|
| `recommend-01-source-and-list.png` | 四档分段条 + 书架档列表（已在架的书带静态对勾） |
| `recommend-02-llm.png` | 大模型档：每条都带推荐理由 |
| `recommend-03-search.png` | 联网搜索档：理由是模型从搜索候选里挑的 |
| `recommend-04-selected.png` | 勾选后：底部出现「把 N 本加入书架」 |
| `recommend-05-greyed.png` | 缺凭据：其余三档**置灰但不隐藏** |
| `recommend-06-added.png` | 入库后：条目移出列表 + 页面内小字反馈（不是 SnackBar） |

### 为什么用假服务

Dio 的拦截器 mock 在 `testWidgets` 的 FakeAsync 里**永远不 resolve**
（FakeAsync 不交还真实事件循环，拦截器里的异步链就卡住）。
真跑网络层的话截到的永远是「加载中」骨架屏。
页面只认 `available()` 与 `recommend()` 两个方法，覆写它们就够了
（见 `test/support/fake_recommend_service.dart`）。

---

## 二、分享卡（12 套皮肤 × 明暗 = 24 张）

```bash
SHOTS=1 flutter test test/share_card_shots_test.dart
```

产物 `share-<skin>-<light|dark>.png`，另有 `share-overview.png` 是拼在一张的总览。

分享卡以前把颜色写死（绿底绿标签白卡片），换皮肤时分享图还是那张绿底，
跟用户眼前的界面完全不像同一款产品。现在配色由 `ProfileShareStyle.of(theme, brightness)`
从皮肤算出来——**算得对不对只有看图才知道**：纸色跟界面是否一致、
标签胶囊在纸色上有没有糊成一片、进度条槽色跟底色分不分得开。

### 离屏渲染的两个坑

1. **品牌角标必须先解码成 `ui.Image` 再用 `RawImage` 同步绘制**。
   `Image.asset` 的异步解码只触发重绘（`markNeedsPaint`）不触发 build，
   而截图流程只等「调度了 build」才重截 → 第一帧截图里根本没有那张图。
2. **卡片自己不取 Theme**（颜色全从 `style` 传进来），
   但**字体的 fontFamily 来自 Theme**——不给 Theme 的话中文全是豆腐块。

---

## 三、设置页「第三方渠道 → 搜索服务」

```bash
SHOTS=1 flutter test test/settings_search_shots_test.dart
```

产物 `settings-search-service.png`：推荐书单第 4 档「联网搜索」要的可配置
搜索服务（endpoint + Key + 附加请求头 + 验证按钮）。

这段排在第三方渠道那一节的**第三块**，前面还有微信读书与大模型两段——
排在第几、跟上面的分隔线留多少空、按钮在不在视野里，只能看图。

---

## 四、图标实机效果

`icon-realworld.png`（由 `scripts/make_icon_realworld.py` 生成）：抽屉图标加圆角遮罩后的
各尺寸（192/120/72/48）、桌面图标、Play 商店 512，以及分享卡右上角那个品牌角标。
