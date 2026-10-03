#!/usr/bin/env bash
#
# 构建 Android 安装包（release APK）。
#
# 前置：先执行 scripts/wsl-android-setup.sh 装好 JDK 17 与 Android SDK。
# 产物：app/build/app/outputs/flutter-apk/app-release.apk
#
# 用法：bash scripts/build-apk.sh
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../app" && pwd)"
FLUTTER="${FLUTTER_BIN:-$HOME/dev/flutter/bin/flutter}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PUB_HOSTED_URL="${PUB_HOSTED_URL:-https://pub.flutter-io.cn}"

if [ ! -d "$ANDROID_SDK_ROOT/platforms/android-34" ]; then
  echo "Android SDK 未就绪，先执行：bash scripts/wsl-android-setup.sh"
  exit 1
fi

cd "$APP_DIR"
"$FLUTTER" build apk --release

echo
echo "== 产物 =="
ls -lh build/app/outputs/flutter-apk/*.apk
