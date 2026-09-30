#!/usr/bin/env bash
#
# 生成界面截图 —— 不需要 GTK、不需要显示器、不需要 sudo。
#
# 背景：本机 WSL 缺 GTK 开发库（clang / cmake / ninja / pkg-config / libgtk-3-dev），
# 装它们要 sudo 密码，所以 `flutter run -d linux` 跑不起来；Web 端也不通
# （sqflite 没有 web 实现）。flutter_test 自带 Skia 软件渲染，
# 能把真实界面（含真实种子书库数据）直接渲染成 PNG，用它做视觉验收。
#
# 用法：
#   bash scripts/screenshot.sh              # 重新生成全部截图
#   产物：app/test/goldens/*.png
#
# 改完 UI 后跑一次，肉眼看一眼这几张图，比对着代码空想快得多。
# 本脚本同时也是一道防线：纯逻辑测试断言不到文案，而插值写错
# （如 "$b.publishedAt" 被解析成 "${b}.publishedAt"）只有看图才发现得了。
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
FLUTTER="${FLUTTER_BIN:-$HOME/dev/flutter/bin/flutter}"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"

# 字体是硬前置：测试环境不自带任何字体，缺了中文和图标会全部渲染成空白方块。
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

cd "$APP_DIR"
# GOLDEN=1 是「开关」：screenshot_test.dart 默认跳过像素比对（否则每次改 UI
# 都会让 flutter test 变红），只有这里才真正写盘/比对。
GOLDEN=1 "$FLUTTER" test test/screenshot_test.dart --update-goldens

echo
echo "截图已生成："
ls -l test/goldens/*.png
