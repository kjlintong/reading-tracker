#!/usr/bin/env bash
# 在 WSL Ubuntu 中验证 Flutter 工程（日常用这个）
#
# 只做验证、不动代码：pub get → analyze → test → build bundle。
# 需要先把代码同步进 WSL 时，用 scripts/wsl-bootstrap.sh。
#
# 用法：
#   bash scripts/verify_wsl.sh              # 全量验证
#   bash scripts/verify_wsl.sh --pub-get-only
#   bash scripts/verify_wsl.sh --quick      # 跳过 build bundle

set -uo pipefail

FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/dev/flutter}"
export PATH="$FLUTTER_ROOT/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
# 不做 Android/iOS 构建，避免在无 SDK 环境报错
export ANDROID_HOME=""
export ANDROID_SDK_ROOT=""

# Flutter 工程在 app/ 子目录（根目录放的是 docs/scripts/tools）
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"

if [[ ! -f "$APP_DIR/pubspec.yaml" ]]; then
  echo "未找到 $APP_DIR/pubspec.yaml，请确认工程布局未被改动" >&2
  exit 1
fi

echo "=== 0. 工程位置 ==="
echo "$APP_DIR"

echo
echo "=== 1. 版本 ==="
flutter --version 2>&1 | head -3

echo
echo "=== 2. 依赖解析 ==="
cd "$APP_DIR"
flutter pub get 2>&1 | tail -5

if [[ "${1:-}" == "--pub-get-only" ]]; then
  echo "（仅执行 pub get，已跳过后续步骤）"
  exit 0
fi

echo
echo "=== 3. 静态分析 ==="
flutter analyze 2>&1 | tail -10

echo
echo "=== 4. 单元测试 ==="
flutter test --timeout 40s --reporter compact 2>&1 | tail -3

if [[ "${1:-}" != "--quick" ]]; then
  echo
  echo "=== 5. 资源打包（验证 Dart 编译） ==="
  flutter build bundle 2>&1 | tail -5
  echo "--- 已打包资源 ---"
  cat build/flutter_assets/AssetManifest.json 2>/dev/null || echo "(未找到 AssetManifest)"
fi

echo
echo "完成。"
