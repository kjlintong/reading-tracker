#!/usr/bin/env bash
#
# 一次性搭建 Android 构建环境（WSL 侧）。装完即可 `flutter build apk`。
#
# 组件与来源：
#   JDK 17        <- apt（Android Gradle Plugin 8.x 要求 Java 17）
#   cmdline-tools <- dl.google.com
#   platform-tools / platforms;android-34 / build-tools;34.0.0 <- sdkmanager
#
# 用法：bash scripts/wsl-android-setup.sh
set -euo pipefail

SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}"
TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
TOOLS_ZIP="$HOME/Android/cmdline-tools.zip"
SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"

# sdkmanager 依赖 JAVA_HOME，缺失时按 javac 的真实位置反推
if [ -z "${JAVA_HOME:-}" ]; then
  JAVAC="$(command -v javac || true)"
  if [ -n "$JAVAC" ]; then
    JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$JAVAC")")")"
  else
    JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
  fi
  export JAVA_HOME
fi
echo "JAVA_HOME=$JAVA_HOME"

echo "== 1/4 准备目录 =="
mkdir -p "$SDK_ROOT/cmdline-tools" "$HOME/Android"

if [ ! -x "$SDKMANAGER" ]; then
  echo "== 2/4 下载 command line tools =="
  [ -f "$TOOLS_ZIP" ] || curl -L --fail --progress-bar -o "$TOOLS_ZIP" "$TOOLS_URL"
  rm -rf "$SDK_ROOT/cmdline-tools/tmp-extract"
  mkdir -p "$SDK_ROOT/cmdline-tools/tmp-extract"
  unzip -q -o "$TOOLS_ZIP" -d "$SDK_ROOT/cmdline-tools/tmp-extract"
  rm -rf "$SDK_ROOT/cmdline-tools/latest"
  mv "$SDK_ROOT/cmdline-tools/tmp-extract/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
  rm -rf "$SDK_ROOT/cmdline-tools/tmp-extract"
else
  echo "== 2/4 cmdline-tools 已存在，跳过 =="
fi

export ANDROID_SDK_ROOT="$SDK_ROOT"
export ANDROID_HOME="$SDK_ROOT"

echo "== 3/4 接受 license =="
# sdkmanager 会逐个 SDK 询问 y/N，用 yes 批量答应
yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true

echo "== 4/4 安装 SDK 组件 =="
"$SDKMANAGER" --install "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo
echo "== 完成，已安装组件 =="
"$SDKMANAGER" --list_installed
