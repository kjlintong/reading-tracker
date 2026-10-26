#!/usr/bin/env bash
#
# 生成「找书」推荐页 / 分享卡 / 设置页的效果图。
#
# 为什么要单独一个脚本：这三处界面都是**新交互**（四档分段、勾选入库、
# 皮肤化分享卡），纯 widget 测试断言得了行为，但看不出排版对不对——
# 四个 chip 在 390 宽的屏上排不排得下、理由文字会不会把行挤爆、
# 分享卡的标签胶囊在纸色上有没有糊成一片，这些只能看图。
#
# 用法：
#   bash scripts/feature-shots.sh
# 产物：store/shots/*.png
#
# ⚠️ SHOTS=1 不能省。默认不带这个变量时，测试里的用例直接 return——
# 结果是「测试全绿但一张图都不出」，很容易误判成代码正常。
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER="${FLUTTER_BIN:-$HOME/dev/flutter/bin/flutter}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"

cd "$APP_DIR"
SHOTS=1 "$FLUTTER" test \
  test/recommend_shots_test.dart \
  test/share_card_shots_test.dart \
  test/settings_search_shots_test.dart

# 总览图与图标对照图是 Python 拼的（WSL 侧有 PIL）。
if command -v python3 >/dev/null 2>&1 && python3 -c "import PIL" 2>/dev/null; then
  python3 "$ROOT_DIR/scripts/make_share_overview.py"
  python3 "$ROOT_DIR/scripts/make_icon_realworld.py"
else
  echo "[跳过] 拼图脚本需要 python3 + Pillow"
fi

echo
echo "效果图已生成："
ls -l "$ROOT_DIR/store/shots/"
