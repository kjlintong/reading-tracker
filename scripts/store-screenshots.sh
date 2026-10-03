#!/usr/bin/env bash
#
# 生成**上架用**的双语商店截图（Google Play + App Store）。
#
# 与 scripts/screenshot.sh 的分工：
#   screenshot.sh        → app/test/goldens/*.png，1170×2532，用途是**视觉回归**
#   store-screenshots.sh → store/screenshots/**，平台硬性尺寸，用途是**上架素材**
#
# 两者不可互相替代。goldens 那批是 1170×2532，长边 / 短边 = 2.16，
# 而 Google Play 明确规定「长边不得超过短边的 2 倍」——会被 Play Console 直接拒收；
# App Store 那边又是像素级精确匹配，且本项目 TARGETED_DEVICE_FAMILY = "1,2"，
# 6.9 寸 iPhone 与 13 寸 iPad 两档都是必交项。
#
# ⚠️ 一个容易踩的坑：App Store 的 6.9 寸档必须是 1320×2868，比例 2.17:1，
#    **超过 Play 的 2.0 上限**。也就是说 iPhone 那套图永远不能给 Play 用，
#    Play 那套（1080×1920）也不是 Apple 承认的尺寸——两边规则互斥，
#    所以这里才必须出三套而不是一套。自检脚本对此分档判定，不会误报。
#
# 用法：
#   bash scripts/store-screenshots.sh            # 出全部 36 张
#   bash scripts/store-screenshots.sh --no-check # 出图后不做尺寸自检
#   产物：store/screenshots/<规格>/<语言>/NN-名称.png
#
# 规格：play(1080×1920) / iphone69(1320×2868) / ipad13(2064×2752)
# 语言：zh / en          页面：01-shelf 02-stats 03-profile 04-detail 05-report 06-import
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
ROOT_DIR="$(cd "$APP_DIR/.." && pwd)"
OUT_DIR="$ROOT_DIR/store/screenshots"
FLUTTER="${FLUTTER_BIN:-$HOME/dev/flutter/bin/flutter}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"

CHECK=1
[ "${1:-}" = "--no-check" ] && CHECK=0

echo "=== 0. 工程位置 ==="
echo "app:  $APP_DIR"
echo "输出: $OUT_DIR"

# ── 前置：字体 ────────────────────────────────────────────────────────────
# 测试环境不自带任何字体。缺中文字体会让所有汉字变成空白方块（豆腐块），
# 缺 MaterialIcons 会让底部导航和全部图标变成方块。这两样缺一个，图就废了，
# 所以直接挡在这里，而不是等出完 36 张图再发现。
FIX="$APP_DIR/test/fixtures"
missing=0
if [ ! -f "$FIX/simhei.ttf" ]; then
  echo "[缺] $FIX/simhei.ttf"
  echo "     复制：cp /mnt/c/Windows/Fonts/simhei.ttf $FIX/"
  missing=1
fi
if [ ! -f "$FIX/MaterialIcons-Regular.otf" ]; then
  echo "[缺] $FIX/MaterialIcons-Regular.otf"
  echo "     复制：cp <flutter>/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf $FIX/"
  missing=1
fi
[ "$missing" -eq 0 ] || { echo "补齐字体后再跑（否则截图不可读）"; exit 1; }

# Roboto 只是「英文截图更专业」的加分项，测试里取不到会自动降级，不阻塞。
FLUTTER_ROOT_DIR="$(dirname "$(dirname "$FLUTTER")")"
if [ -f "$FLUTTER_ROOT_DIR/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf" ]; then
  echo "=== 1. 字体 ==="
  echo "Roboto: 已找到（英文截图使用真正的 Roboto 字形）"
else
  echo "=== 1. 字体 ==="
  echo "Roboto: 未找到，英文截图将回退到中文字体的拉丁字形（不阻塞）"
fi

cd "$APP_DIR"

# ── 前置：代码生成 ────────────────────────────────────────────────────────
# 必须显式跑。`flutter test` **不会**自动触发 gen-l10n（实测：ARB 改了、
# 生成文件没跟上时，test 直接报 “The getter 'xxx' isn't defined for class 'S'”
# 这种指向生成文件的迷惑错误，而不是告诉你「该跑 gen-l10n 了」）。
# 更隐蔽的是：生成物 lib/l10n/app_localizations*.dart 在 Windows 侧被带进来的
# 陈旧副本覆盖后，本地 `flutter test` 一样会红，但原因看起来像代码写错了。
echo
echo "=== 2. 本地化代码生成（gen-l10n）==="
"$FLUTTER" gen-l10n 2>&1 | grep -v "^Flutter assets will be downloaded\|^Because l10n.yaml exists\|^To use the command line arguments\|^$" || true

# ── 前置：开关 ────────────────────────────────────────────────────────────
# store_screenshots_test.dart 默认整体跳过——36 张图逐张 settle 会明显拖慢
# 每一次日常 `flutter test`。只有这里设了 STORE_SHOTS=1 才真正渲染。
echo
echo "=== 3. 渲染（STORE_SHOTS=1）==="
rm -rf "$OUT_DIR"
STORE_SHOTS=1 "$FLUTTER" test test/store_screenshots_test.dart 2>&1 | tail -20

# ── 自检 ──────────────────────────────────────────────────────────────────
# 两个平台都是硬性像素要求，出图不看尺寸等于没出。这里不依赖任何第三方库
# （本机 WSL 与 Windows 侧都没有 Pillow / ImageMagick），直接读 PNG 的
# IHDR 块——宽高就是文件第 16..23 字节，大端 uint32。
if [ "$CHECK" -eq 1 ]; then
  echo
  echo "=== 4. 尺寸自检 ==="
  python3 - "$OUT_DIR" <<'PY'
import struct, sys, os

OUT = sys.argv[1]

# 三档规格各自适用**不同**的规则——这一点很容易搞错：
#
#   play      Play 要求「长边 ≤ 短边的 2 倍」。1080×1920 = 1.78，合规。
#   iphone69  Apple 6.9 寸是**像素级精确匹配**，且必须是 1320×2868（= 2.17:1）。
#             这个比例**超过了 Play 的 2.0 上限**——也就是说 iPhone 这套图
#             永远不能拿去给 Play 用，反之 Play 那套也不是 Apple 合法的尺寸。
#             两套图必须分开出，这不是浪费，是两边规则互斥。
#   ipad13    13 寸 iPad，1320/2868 之外的另一个必交档。
#
# 所以「长边超短边 2 倍」这条只在 dev == 'play' 时才判不合格。
EXPECT = {
    'play': {
        'size': (1080, 1920),
        'label': 'Google Play 手机 16:9',
        'aspect_2to1': True,
        'accepted': [(1080, 1920)],
    },
    'iphone69': {
        'size': (1320, 2868),
        'label': 'App Store iPhone 6.9 寸',
        'aspect_2to1': False,
        'accepted': [(1320, 2868), (1290, 2796), (1260, 2736)],
    },
    'ipad13': {
        'size': (2064, 2752),
        'label': 'App Store iPad 13 寸',
        'aspect_2to1': False,
        'accepted': [(2064, 2752), (2048, 2732)],
    },
}
PAGES = 7
bad = []

total = 0
for dev, spec in EXPECT.items():
    w, h = spec['size']
    rows = []
    for loc in ('zh', 'en'):
        d = os.path.join(OUT, dev, loc)
        pngs = sorted(f for f in os.listdir(d) if f.endswith('.png')) if os.path.isdir(d) else []
        total += len(pngs)
        if len(pngs) != PAGES:
            bad.append(f'{dev}/{loc}: 期望 {PAGES} 张，实到 {len(pngs)} 张')
        for fn in pngs:
            p = os.path.join(d, fn)
            with open(p, 'rb') as fh:
                head = fh.read(24)
            if head[:8] != b'\x89PNG\r\n\x1a\n':
                bad.append(f'{dev}/{loc}/{fn}: 不是 PNG')
                continue
            gw, gh = struct.unpack('>II', head[16:24])

            # 必须是该平台承认的精确像素之一（Apple 是像素级硬匹配）
            if (gw, gh) not in spec['accepted']:
                acc = ' / '.join(f'{a}×{b}' for a, b in spec['accepted'])
                bad.append(f'{dev}/{loc}/{fn}: {gw}×{gh} 不是合法尺寸，应为 {acc}')

            # Play 专属的几何约束
            if spec['aspect_2to1'] and max(gw, gh) > 2 * min(gw, gh):
                bad.append(f'{dev}/{loc}/{fn}: {gw}×{gh} 长边超短边 2 倍，Play 会拒收')

            # 两平台共同的上限：单张 ≤ 8 MB
            if os.path.getsize(p) > 8 * 1024 * 1024:
                bad.append(f'{dev}/{loc}/{fn}: 超过 8 MB')
        rows.append(f'    {loc}: {len(pngs)} 张')
    print(f'  {dev:9s} {w}×{h}  ({spec["label"]})')
    for r in rows:
        print(r)

print(f'\n  合计 {total} 张')
print('  注：iphone69 的 2.17:1 是 Apple 的强制比例，超过 Play 的 2 倍上限，')
print('      因此该套图只用于 App Store；Play 用 play 那套。')
if bad:
    print('\n  [不合格]')
    for b in bad:
        print('   -', b)
    sys.exit(1)
print('  全部尺寸合规')
PY
  echo
  echo "=== 5. 完成 ==="
else
  echo
  echo "=== 4. 完成（已跳过尺寸自检）==="
fi

echo "产物目录：$OUT_DIR"
find "$OUT_DIR" -name '*.png' | sort | sed 's|^|  |'
