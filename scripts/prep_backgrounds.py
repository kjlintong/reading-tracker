# -*- coding: utf-8 -*-
"""把 AI 生成的背景原图处理成可上架的 App 背景资源。

## 输出：每套皮肤**一张**素材，明暗共用

贴图不按明暗各做一版（曾经派生过 `_dark`，一度是 12 个文件）。
但「删掉深色版」不等于「只删文件」——**贴图亮度必须重新居中**，
否则深色下会彻底隐形。推导（合成公式）：

    结果 = 纸×scrim + (图×opacity + 纸×(1-opacity))×(1-scrim)

代入浅色纸（med 0.98、scrim 0.58、opacity 0.42）与深色纸
（med 0.14、scrim 0.30）：

| 贴图 med | 浅色纸合成 | 深色纸合成 | 深色下是否可见 |
|---|---|---|---|
| 0.14（旧浅色版） | 0.851，暗 0.13 | 0.138，暗 0.002 | ✗ 与纸色撞车 |
| 0.32（当前 TARGET_MED） | 0.846，暗 0.13 | 0.208，亮 0.07 | ✓ |

旧版撞车的原因：深色纸 med 0.14，旧贴图 med 0.135~0.28，几乎同亮。
此时遮罩和 opacity 怎么调都没用——调低遮罩会让纸也跟着变亮，
正好抵消贴图的贡献。所以 TARGET_MED 取在两态纸色的**中间**。

## 四个坑（每个都让输出彻底不能用，全部实测撞过）

### 坑 1：一条 LUT 套三个通道 = 把彩色图洗成灰
`Image.point(lut)` 传 1 个列表时是「三通道共用」，所有像素收敛到同一灰度。
苔藓的青绿、黄昏的酒红、狗的蜜黄全变成同一种棕灰，6 张像同一张。

### 坑 2：逐通道独立映射也照样洗灰
让 R/G/B 各自映射到**同一个**目标区间，通道间的相对差被抹平：
实测苔藓 R212/G195/B181（跨度 31）→ R48/G50/G49（跨度 1）。
让每通道映射各自的 p5~p95 也不行：那会把「这通道本来就暗」
（星空的 B 最暗）误判成「需要提亮」，扭曲色相。

**正解是分解再重组**：灰度压缩到目标（管明暗），
再把「像素 − 自己灰度」那部分（管色彩）等比加回去（管彩度）。

### 坑 3：按 p5/p95 对齐会让 6 张图亮度不一致
用 p5~p95 映射到目标区间后，水墨（分布偏亮端）被推到 med 0.424，
而星空停在 0.30——差 0.12，深色下切换皮肤光感明显跳变。
**必须按中位数对齐**，6 张才都落在 0.319~0.322。

### 坑 4：生成器在右下角打了「AI生成 WORKBUDDY」水印
6 张全有，不裁就是把别人的品牌烙进自己的 App。

## 另两个实现细节

- 统计域与映射域必须一致，统一在 gamma 域（曾因混用线性/gamma 导致方向反转）。
- Pillow 12 移除了 `Image.eval`，`point()` 也只收 1~2 个 LUT，
  所以纯 Python 逐像素计算 + `Image.frombytes`，不依赖便捷 API。

## 用法

    python3 scripts/prep_backgrounds.py <原始图目录> <输出目录>

原始图（1024x1536，文件名见 RAW_MAP）不入库，需自行重新生成。
输出目录放 app/assets/backgrounds/。
"""
from PIL import Image
import colorsys
import os
import sys

if len(sys.argv) < 3:
    sys.exit(
        '用法: python3 scripts/prep_backgrounds.py <原始图目录> <输出目录>\n'
        '  原始图目录需包含 6 张 AI 生成的 1024x1536 原图（文件名见 RAW_MAP）。\n'
        '  原图不入库，需自行重新生成；输出目录放 app/assets/backgrounds/。')

SRC, DST = sys.argv[1], sys.argv[2]

# ⚠️ 必须显式写出「原始文件名 → 输出名」的对应关系。
#
# 之前用 `zip(sorted(raws), SPECS)`，指望 SPECS 的顺序与 sorted() 一致。
# 实测不一致：sorted() 按字母序排的是
#   Abstract(星空) / Extreme(苔藓) / Soft_cream(猫) /
#   Soft_honey(狗) / Traditional(水墨) / Warm(黄昏)
# 而 SPECS 我按星空/水墨/苔藓/黄昏/猫/狗 写，
# 于是 mist 拿到苔藓、moss 拿到猫、cat 拿到水墨——整套贴图张冠李戴，
# 而且因为都是「低饱和低对比」的图，肉眼很难立刻发现是谁配错了。
# 名字靠猜时就该显式绑定。
RAW_MAP = {
    'Deep_space_night_sky_with_a_br_2026-10-09T07-19-08.png': 'starfield',
    'Traditional_Chinese_ink_wash_p_2026-10-09T03-55-40.png': 'mist',
    'Extreme_macro_photograph_of_we_2026-10-09T03-55-59.png': 'moss',
    'Warm_dusk_golden_hour_gradient_2026-10-09T03-55-59.png': 'dusk',
    'Soft_warm_cream_and_beige_back_2026-10-09T07-19-08.png': 'cat',
    'Soft_warm_honey_and_pale_amber_2026-10-09T07-19-07.png': 'dog',
}

WM_H = 0.075  # 底部水印带高度占比

# 目标亮度与动态范围。TARGET_MED 必须落在浅色纸（0.98）与
# 深色纸（0.14）之间，取 0.32 让两态都浮得出来（推导见文件头）。
TARGET_MED = 0.32
TARGET_DYN = 0.24

# 彩度上限：超过才压，不足不补。
#
# 这一版修正了一个方向性错误：之前写成「把彩度**收敛到** SAT_TARGET」，
# 结果 5 张图全变成同一种棕橘色——因为一旦强制拉到同一彩度，
# 图与图之间的**色相差异**也被一起抹平了：
# 水墨该是灰青、狗该是蜜黄、黄昏该是酒红，全成了橘色。
#
# 彩度不是「多少」，而是「什么颜色」。该做的是：
#   - 彩度**高于**上限的（黄昏 0.075）压下来，防止刺眼；
#   - 彩度**低于**上限的（星空 0.032、苔藓 0.020）**原样保留**，
#     它们淡是内容本身决定的（水墨就是灰的、星空就是暗的），
#     强行提亮只会把低饱和纹理染上一层假色。
# 于是每张图各留各的色相，只有「过艳的」被收敛。
SAT_MAX = 0.085


def luma(r, g, b):
    """0~255 → 0~1 gamma 域灰度（Rec.601）。"""
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0


def sat_of(im):
    """全图平均彩度：像素三通道极差，均值归一化到 0~1。"""
    probe = im.resize((96, 144), Image.LANCZOS)
    px = list(probe.getdata())
    return sum(max(p) - min(p) for p in px) / (3 * len(px)) / 255.0


def gray_stats(im):
    """返回 (中位灰度, p5, p95)。

    对齐**必须用中位数**，不能用 p5/p95：
    按 p5/p95 映射时，分布偏亮端的图会被推到目标区间上沿、
    偏暗端的停在中间，6 张亮度就差了 0.12（见文件头坑 3）。
    """
    probe = im.resize((96, 144), Image.LANCZOS)
    vals = sorted(luma(*p) for p in probe.getdata())
    n = len(vals)
    lo, hi = vals[n * 5 // 100], vals[n * 95 // 100]
    if hi - lo < 0.02:
        mid = (lo + hi) / 2
        lo, hi = mid - 0.01, mid + 0.01
    return vals[n // 2], lo, hi


def recolor(im, med, g_lo, g_hi, out_med, out_dyn, sat):
    """分解再重组：灰度按中位对齐映射，色度等比加回。"""
    dyn = max(g_hi - g_lo, 1e-3)
    scale = out_dyn / dyn
    w, h = im.size
    src = im.tobytes()
    out = bytearray(len(src))
    for i in range(0, len(src), 3):
        r, g, b = src[i], src[i + 1], src[i + 2]
        l = 0.299 * r + 0.587 * g + 0.114 * b  # 0~255 灰度
        v = (l / 255.0 - med) * scale + out_med
        v = min(1.0, max(0.0, v))
        base = v * 255.0
        out[i] = min(255, max(0, int(round(base + (r - l) * sat))))
        out[i + 1] = min(255, max(0, int(round(base + (g - l) * sat))))
        out[i + 2] = min(255, max(0, int(round(base + (b - l) * sat))))
    return Image.frombytes('RGB', (w, h), bytes(out))


os.makedirs(DST, exist_ok=True)
present = {f for f in os.listdir(SRC) if f.endswith('.png')}
missing = set(RAW_MAP) - present
assert not missing, '原图缺失：%s' % missing

for raw in sorted(RAW_MAP):
    name = RAW_MAP[raw]
    im = Image.open(os.path.join(SRC, raw)).convert('RGB')
    W, H = im.size
    im = im.crop((0, 0, W, int(H * (1 - WM_H))))  # ①裁水印

    # ② 分解重组。彩度按「只压过艳」自适应——
    #    原图彩度从 0.020 到 0.084 差四倍多，固定系数会让
    #    偏灰的仍然偏灰、刺眼的仍然刺眼。
    #    sat_scale<=1 恒成立（除非原图无彩）。
    src_sat = sat_of(im)
    sat_scale = min(1.0, SAT_MAX / src_sat) if src_sat > 1e-4 else 1.0
    med, lo, hi = gray_stats(im)
    im = recolor(im, med, lo, hi, TARGET_MED, TARGET_DYN, sat_scale)

    im = im.resize((540, 810), Image.LANCZOS)  # ③ 降采样
    out_path = os.path.join(DST, 'bg_%s.webp' % name)
    im.save(out_path, 'WEBP', quality=82, method=6)

    px = list(Image.open(out_path).convert('RGB')
              .resize((64, 96), Image.LANCZOS).getdata())
    m = len(px)
    ls = sorted(luma(*p) for p in px)
    med_out, span = ls[m // 2], ls[m * 95 // 100] - ls[m * 5 // 100]
    sat_v = sum(max(p) - min(p) for p in px) / (3 * m) / 255.0
    kb = os.path.getsize(out_path) / 1024.0
    # 记录平均色相（HSV 的 H），用来肉眼核对「图与图确实不同色」
    hs = []
    for pr in px:
        h, _sv, _v = colorsys.rgb_to_hsv(pr[0] / 255.0, pr[1] / 255.0,
                                          pr[2] / 255.0)
        hs.append(h * 360)
    hue = sum(hs) / len(hs)
    ok = (abs(med_out - TARGET_MED) < 0.03 and span > 0.15
          and sat_v <= SAT_MAX + 0.015)
    print('%-10s %3.0fKB med=%.3f 彩%.3f hue=%3.0f %s' % (
        name, kb, med_out, sat_v, hue, 'OK' if ok else '✗'))

#亮度和动态范围共同决定「明暗两态都浮得出来」，
# 所以两项都要卡：med 必须居中，span 必须够（否则是一张平色）。
# 彩度只卡上限，因为低彩度是内容本身决定的（星空就该是淡的）。