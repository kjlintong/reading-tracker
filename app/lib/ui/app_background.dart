import 'dart:ui';

import 'package:flutter/material.dart';

import '../perf.dart';
import 'theme.dart';

/// 皮肤背景层：把贴图铺在页面底下，并保证上面的文字始终读得清。
///
/// ## 为什么必须有这一层，而不是直接给Scaffold 一个带图的 background
///
/// 三个理由，缺一不可：
///
/// 1. **文字可读性**。阅读类 App 的主体是书名、笔记、统计数字。
///    任何纹理都可能正好压在字下面。行业做法（晋江 / Reeden / QQ 阅读）
///    都是「图片 + 遮罩 + 文字」，不是「图片当底色」——Reeden 甚至把
///    「背景图不透明度」「背景图模糊度」做成了两个独立滑块供用户调。
///
/// 2. **两层都要有**。[_scrim] 是关键的一层：它铺在图与内容之间，
///    用**纸色**而非黑色。早期我用纯黑遮罩，结果深色模式没问题、
///    浅色模式整屏发灰——黑色遮罩在浅色纸上等于把纸弄脏了。
///    用纸色遮罩，图片就像「染进纸里」而不是「蒙了层灰」。
///
/// 3. **性能**。[ImageFilter.blur] 在低端机上很贵，尤其全屏大面积模糊。
///    所以 blur 只在 [AppTheme.backgroundBlur] 明确要求时才启用
///    （见 theme.dart里各贴图皮肤的取舍说明），且用 sigma 而非 BackdropFilter
///    的默认行为——直接对图片做高斯模糊比对整个子树做模糊便宜得多。
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.theme,
    required this.brightness,
    required this.child,
    this.imageProvider,
  });

  final AppTheme theme;
  final Brightness brightness;
  final Widget child;

  /// 覆盖背景图的加载方式。生产环境留空（内部用 [AssetImage]）。
  ///
  /// ## 这个口子存在的理由不是「方便写测试」，而是**测试必须能看到真实效果**
  ///
  /// widget 测试里 `Image.asset` 走 rootBundle，而测试环境的
  /// AssetManifest 只有条目名、没有图片字节，于是解码失败、
  /// `errorBuilder` 静默返回空——出图脚本跑出来是一张纯色纸，
  /// 看起来「背景没生效」，实际是图根本没加载。
  ///
  /// 有了这个参数，测试可以注入 [MemoryImage]（直接从文件读字节），
  /// 于是样张图里看到的就是用户会看到的合成结果：贴图 + 遮罩 + 模糊。
  /// 靠 mock rootBundle 来绕过也行，但那样测的是「我 mock 的样子」，
  /// 不是代码真实行为——而背景贴图最需要验证的恰恰是**合成后的观感**。
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    // 性能打点：MaterialApp.builder 每次路由变化都会跑这里，
    // 这个计数能直接看出「切一个页面重建了几次背景」。
    perfMark('AppBackground.build');
    // 明暗共用同一张素材：不再为深色单独派生 `_dark` 版本。
    //
    // 之所以能这样，是因为贴图亮度被**重新居中到med 0.32**
    // （见 AppTheme.backgroundAsset 的注释与 scripts/prep_backgrounds.py）——
    // 落在浅色纸 0.98 与深色纸 0.14 的中间，所以同一张图
    // 浅色下被压成纸纹、深色下被提亮成微光，两边都看得见。
    final asset = theme.backgroundAsset;

    // 纯色皮肤：不做任何额外工作，交给 Scaffold 自己的纸色。
    if (asset == null || theme.backgroundOpacity <= 0) {
      return child;
    }

    final isLight = brightness == Brightness.light;

    final scheme = Theme.of(context).colorScheme;
    // 遮罩用当前纸色（surface），不是纯黑——
    // 黑色遮罩在浅色纸上等于把纸弄脏，纸色遮罩才像「染进纸里」。
    final scrimColor = scheme.surface;

    // 只算 provider，滤波质量交给 Image 自己的 filterQuality。
    //
    // 两个踩过的坑：
    // 1. `Image` 的参数名是 `image`，**没有** `imageProvider` 这个参数
    //    （ImageProvider 是 Image.file/image.asset 的内部实现）。
    // 2. `filterQuality` 不在 ImageProvider 基类上，
    //    所以 `AssetImage(x)..filterQuality = y` 会报undefined setter。
    //    540x810 铺到高倍屏的插值痕迹，用 Image 层的 filterQuality
    //    就已经能压住，不必动 provider。
    final provider = imageProvider ?? AssetImage(asset);

    Widget image = Image(
      image: provider,
      fit: BoxFit.cover,
      // 用低通（medium）而不是默认的 cubic 重采样放大结果——
      // 背景是虚化纹理，低通的插值痕迹明显更轻。
      filterQuality: FilterQuality.medium,
      // 换肤瞬间旧图要立刻消失、显示新图；
      // 不开这个会在同一帧里残留上一套皮肤的图。
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );

    if (theme.backgroundBlur > 0) {
      image = ImageFiltered(
        imageFilter: _blurFilter(theme.backgroundBlur),
        child: image,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ⚠️ 背景三层包在 RepaintBoundary 里，是为了**路由切换时不再重画**。
        //
        // 这三层里有两样东西很贵：
        //   - [ImageFiltered] 的全屏高斯模糊（猫屿 sigma 0.2，1260×2800）
        //   - [Opacity] 的 saveLayer
        // AppBackground 挂在 MaterialApp.builder 上、盖住整个 Navigator，
        // 所以**每次 push 新路由它都会重建**。不缓存的话，
        // 用户点一下按钮、转场动画还没开始，GPU 就得先把整屏重新模糊一遍——
        // 真机上实测是「点进新页面卡一秒」。
        //
        // RepaintBoundary 让这三层有自己的 compositing layer：
        // 内容与尺寸没变时，路由切换直接**贴回旧 layer**，一次像素都不用重画。
        // 换肤（换 seed / 换贴图）时内容变了，边界会正常重画。
        RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ⚠️ 最底这层**不透明纸色**是整个组件的地基，删了会出两种事故：
              //
              // 1. 截图导出成半透明 PNG。真机上Scaffold 透明后透到窗口底色，
              //    勉强能看；但截图是像素级拷贝，底下那层「什么都没有」
              //    被如实记录成 alpha=0—— 上传到官网/商店就是一片透明，
              //    直接露出网页自己的底色（2026-10-09 用户实机发现）。
              // 2. 贴图没铺满的地方会漏出黑底（滚动超界、圆角裁切处）。
              //
              // 它也正是文档里那条合成公式里的「纸」：
              //   结果 = 纸×scrim + (图×opacity + 纸×(1-opacity))×(1-scrim)
              // 公式里的纸以前只是注释，谁都没真的画过。
              ColoredBox(color: scrimColor),

              // 遮罩先铺，还是图先铺？
              // 图在下、遮罩在上：遮罩要盖住图，才能把图"压"进纸里。
              Opacity(opacity: theme.backgroundOpacity, child: image),
              // ⚠️ 用withOpacity 而不是 withValues(alpha:)：
              // 后者是 Flutter 3.27+ 的 API，本项目锁在 3.24.5，调用直接编译失败。
              ColoredBox(color: scrimColor.withOpacity(_scrim(isLight))),
            ],
          ),
        ),
        child,
      ],
    );
  }

  /// 遮罩不透明度 —— 明暗适配的唯一手段。
  ///
  /// ## 既然只有一张图了，为什么浅深还要给不同的遮罩
  ///
  /// 因为**纸色本身差一个数量级**（浅 med 0.98 vs 深 med 0.14）。
  /// 同一张 med 0.32 的图要同时在两边可见，遮罩就得反向补偿：
  /// 浅色下遮罩重一点，把图「压暗成纸纹」；深色下遮罩轻一点，
  /// 让图「提亮成微光」。这正是同一张图该有的两种表现，
  /// 也是不派生 `_dark` 版本之后仍能两用的原因。
  ///
  /// ## 这两个数是被样张图逼出来的，不是拍脑袋定的
  ///
  /// 最初取 0.76 / 0.64，出图后发现暮色那套几乎看不出是张黄昏——
  /// 因为**两个衰减是乘在一起的**：贴图 opacity 0.28 × (1 - 0.76)
  /// ≈ 实际只有 6.7% 可见度。也就是说遮罩压 76% 之后，
  /// 贴图皮肤里 backgroundOpacity 那一档参数基本失效了，
  /// 全被遮罩吃掉，设 0.20 和设 0.30 看起来一样。
  ///
  /// 浅色降到 0.58 后实际可见度回到 12%~14%：
  /// 能看出是「暮色」而不是「米白纸」，同时深色文字对比度仍在
  /// 10:1 以上（WCAG AA 正文要求 4.5:1，余量充足）。
  ///
  /// 之所以敢降到这里，是因为贴图本身已经过两道处理：
  /// 降彩度（上限 0.085）+ 亮度重映射（中位对齐 0.32），
  /// 比原始壁纸温和得多，不需要再靠重遮罩兜底。
  ///
  /// 深色那档从 0.46 降到 0.30 是被样张图逼出来的：
  /// 原本以为「深色纸压得住、遮罩可以重一点」，
  /// 出图后发现星河那套深色下几乎全黑——因为贴图和深色纸
  /// **亮度撞了**，再叠一层 0.46 的深色遮罩，可见度只剩 8%，
  /// 等于白做。降到 0.30 后可见度 11%，深色文字仍有 12:1 对比度。
  ///
  /// 现在贴图亮度重新居中到 0.32 之后，这一档的余量比之前宽：
  /// 深色合成结果约 0.208（亮 0.07），浅色约 0.846（暗 0.13），
  /// 两边都稳稳浮得出来，不再是「压在临界点上」。
  double _scrim(bool isLight) => isLight ? 0.58 : 0.30;

  /// 按 sigma 缓存高斯模糊滤镜。
  ///
  /// ## 为什么必须缓存（这是「点开新页面卡一秒」的真凶）
  ///
  /// `ImageFilter.blur(...)` 每次调用都返回**一个新对象**，而
  /// `RenderImageFilter` 判断要不要重画，用的是 `imageFilter != oldWidget.imageFilter`
  /// —— 对象相等是**按引用**的，新对象永远「不等于」旧对象。
  ///
  /// 于是每次 AppBackground 重建（MaterialApp.builder 每次路由变化都会跑），
  /// 都会 `markNeedsPaint` → **整屏 1260×2800 的高斯模糊重算一遍**。
  ///
  /// 上一轮给背景三层加了 `RepaintBoundary`，本来能挡住这次重画，
  /// 但 RepaintBoundary 只在「没人要求重画」时才能贴回旧 layer；
  /// 上面这条 `markNeedsPaint` 恰好就是「要求重画」——
  /// **边界被这一行直接抵消掉了**。所以 RepaintBoundary 与本缓存必须同时在。
  ///
  /// 缓存后，同一个 sigma 拿到的是**同一个对象**，`!=` 为假，
  /// 不重画、不重算模糊，路由切换就是真的零成本。
  static final Map<double, ImageFilter> _blurCache = {};

  static ImageFilter _blurFilter(double sigma) => _blurCache.putIfAbsent(
        sigma,
        () => ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.decal,
        ),
      );
}
