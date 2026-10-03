#!/usr/bin/env bash
#
# 生成商店**图片素材**：
#   1. Feature Graphic（Google Play 必交项）1024×500，24 位 PNG 无 alpha，中英各一张
#   2. 全平台应用图标（从你自己设计的 1024×1024 母版派生）
#      iOS 19 档 / Android legacy 5 档 / Android 自适应图标 / Play 商店 512
#
# 与 store-screenshots.sh 的分工：
#   store-screenshots.sh → 界面截图（6 个页面 × 3 规格 × 2 语言 = 36 张）
#   store-assets.sh      → 图片素材（Feature Graphic + 应用图标）
#
# 用法：
#   bash scripts/store-assets.sh              # 全部生成
#   bash scripts/store-assets.sh --fg-only    # 只出 Feature Graphic（母版还没设计好时用）
#
# 前置（仅图标派生需要）：
#   store/assets/icon-master.png      1024×1024，不透明，四边满幅
#   可选 store/assets/icon-foreground.png  1024×1024，带透明背景（自适应图标前景层）
#   母版不存在时会明确跳过并打印规格，不会假装成功。
#
# 注意：图标派生会**直接改写仓库里的正式图标**（iOS xcassets 与 Android mipmap），
# 所以它在 flutter test 里默认关闭，只有本脚本设了 STORE_ASSETS=1 才真正落盘。
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
ROOT_DIR="$(cd "$APP_DIR/.." && pwd)"
ASSETS_DIR="$ROOT_DIR/store/assets"
FLUTTER="${FLUTTER_BIN:-$HOME/dev/flutter/bin/flutter}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"
export FLUTTER_STORAGE_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.flutter-io.cn}"

FG_ONLY=0
[ "${1:-}" = "--fg-only" ] && FG_ONLY=1

echo "=== 0. 工程位置 ==="
echo "app:    $APP_DIR"
echo "素材:   $ASSETS_DIR"

# ── 前置：字体 ────────────────────────────────────────────────────────────
# 测试环境不自带任何字体。Feature Graphic 上全是文字，缺中文字体会整张变成
# 豆腐块方块图；而且它是**最终要上传**的素材，出错必须挡在生成之前。
FIX="$APP_DIR/test/fixtures"
if [ ! -f "$FIX/simhei.ttf" ]; then
  echo "[缺] $FIX/simhei.ttf"
  echo "     复制：cp /mnt/c/Windows/Fonts/simhei.ttf $FIX/"
  exit 1
fi

echo
echo "=== 1. 图标母版检查 ==="
if [ -f "$ASSETS_DIR/icon-master.png" ]; then
  echo "icon-master.png      已找到"
  [ -f "$ASSETS_DIR/icon-foreground.png" ] \
    && echo "icon-foreground.png  已找到（自适应图标将使用独立前景层）" \
    || echo "icon-foreground.png  未提供（自适应图标将由母版满幅充当前景层）"
else
  echo "icon-master.png      未找到 → 图标派生将跳过"
  echo "                     正式图标由你自己设计，规格见 store/assets/icon-spec.md"
fi

cd "$APP_DIR"

# ── 前置：代码生成 ────────────────────────────────────────────────────────
# 与 store-screenshots.sh 同样的理由：`flutter test` 不会自动跑 gen-l10n，
# 陈旧生成物会以「The getter 'xxx' isn't defined for class 'S'」的形式报出来，
# 看起来像代码写错了。显式跑一遍，把这类误报去掉。
echo
echo "=== 2. 本地化代码生成（gen-l10n）==="
"$FLUTTER" gen-l10n 2>&1 \
  | grep -v "^Flutter assets will be downloaded\|^Because l10n.yaml exists\|^To use the command line arguments\|^$" || true

echo
if [ "$FG_ONLY" -eq 1 ]; then
  echo "=== 3. 生成 Feature Graphic（--fg-only，跳过图标派生）==="
  STORE_ASSETS=1 "$FLUTTER" test test/store_assets_test.dart \
    --plain-name 'Feature Graphic' 2>&1 | tail -20
else
  echo "=== 3. 生成图片素材 ==="
  STORE_ASSETS=1 "$FLUTTER" test test/store_assets_test.dart 2>&1 | tail -30
fi

# ── 自检 ──────────────────────────────────────────────────────────────────
# Play 对 Feature Graphic 的要求是**硬性**的（1024×500 / 无 alpha / JPEG 或 PNG），
# 出图不看就等于没出。本机没有 Pillow / ImageMagick，直接读 PNG 头：
#   IHDR 宽高 = 第 16..23 字节；color type = 第 25 字节（2 = truecolor 无 alpha）。
# 顺带核 iOS App Store 图标 1024×1024，以及 Play 列表图标 512×512。
echo
echo "=== 4. 尺寸与格式自检 ==="
python3 - "$ROOT_DIR" "$FG_ONLY" <<'PY'
import os, struct, sys

ROOT, FG_ONLY = sys.argv[1], sys.argv[2] == '1'

# Feature Graphic 是 Play 的必交项，任何时候都要查。
checks = [
    ('store/assets/feature-graphic.zh.png', 1024, 500, True,  'Play Feature Graphic 中文'),
    ('store/assets/feature-graphic.en.png', 1024, 500, True,  'Play Feature Graphic 英文'),
]

# 图标派生是可选的（取决于母版是否已设计好）。--fg-only 或母版不存在时，
# 不检查图标——否则会因为「本来就跳过了」而报一堆假失败。
master = os.path.join(ROOT, 'store/assets/icon-master.png')
check_icons = not FG_ONLY and os.path.exists(master)
if not check_icons:
    print('  （跳过图标检查：'
          + ('--fg-only' if FG_ONLY else '未提供 store/assets/icon-master.png')
          + '）')

if check_icons:
    checks += [
        ('app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
         1024, 1024, True, 'App Store 图标 1024'),
        ('store/assets/icon-play-512.png', 512, 512, False, 'Play 列表图标 512'),
    ]

bad = []
for rel, w, h, need_opaque, label in checks:
    p = os.path.join(ROOT, rel)
    if not os.path.exists(p):
        bad.append(f'{label}: 文件不存在（{rel}）')
        continue
    with open(p, 'rb') as fh:
        head = fh.read(26)
    if head[:8] != b'\x89PNG\r\n\x1a\n':
        bad.append(f'{label}: 不是 PNG')
        continue
    gw, gh = struct.unpack('>II', head[16:24])
    ctype = head[25]
    size_kb = os.path.getsize(p) / 1024

    notes = []
    if (gw, gh) != (w, h):
        bad.append(f'{label}: {gw}×{gh}，应为 {w}×{h}')
    if need_opaque and ctype != 2:
        # color type: 0=灰度 2=RGB 3=索引 4=灰度+alpha 6=RGBA
        bad.append(f'{label}: color type={ctype}，要求 2（24 位无 alpha）')
    if ctype == 2:
        notes.append('24 位无 alpha')
    else:
        notes.append(f'color type={ctype}')

    print(f'  OK  {label:34s} {gw}×{gh}  {size_kb:6.1f} KB  {" / ".join(notes)}')

if check_icons:
    # Play 规定列表图标 ≤ 1 MB
    big = os.path.join(ROOT, 'store/assets/icon-play-512.png')
    if os.path.exists(big) and os.path.getsize(big) > 1024 * 1024:
        bad.append('Play 列表图标超过 1 MB 上限')

    # Android legacy + adaptive 图标是否齐全
    res = os.path.join(ROOT, 'app/android/app/src/main/res')
    for density in ('mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'):
        for name in ('ic_launcher.png', 'ic_launcher_foreground.png'):
            p = os.path.join(res, f'mipmap-{density}', name)
            if not os.path.exists(p):
                bad.append(f'Android 图标缺失: mipmap-{density}/{name}')

    if os.path.exists(os.path.join(res, 'mipmap-anydpi-v26/ic_launcher.xml')):
        print('  OK  Android adaptive                mipmap-anydpi-v26/ic_launcher.xml')
    else:
        bad.append('Android 自适应图标缺失: mipmap-anydpi-v26/ic_launcher.xml')

if bad:
    print('\n  [不合格]')
    for b in bad:
        print('   -', b)
    sys.exit(1)
print('\n  全部合规')
PY

echo
echo "=== 5. 完成 ==="
echo "素材目录：$ASSETS_DIR"
ls -l "$ASSETS_DIR"/*.png 2>/dev/null || true
