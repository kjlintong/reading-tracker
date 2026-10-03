#!/usr/bin/env bash
# WSL 开发环境初始化（首次在新会话中开发时执行一次）
#
# 作用：把 Windows 侧的最新代码同步到 WSL 本地目录并装好依赖。
# 为什么要复制到 WSL 本地：/mnt/e/... 跨文件系统 I/O 极慢，
# flutter analyze 会慢到不可用。

set -euo pipefail

FLUTTER_ROOT="$HOME/dev/flutter"
SRC="${1:-/mnt/e/program/workbuddy/2026-09-29-10-49-47/reading-tracker}"
DEST="$HOME/project/reading-tracker"

export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
export FLUTTER_GIT_URL=https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git

echo "=== 1. 检查 Flutter SDK ==="
if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  echo "未找到 Flutter SDK，开始下载…"
  mkdir -p "$HOME/dev"
  curl -sSL -o "$HOME/dev/flutter_linux.tar.xz" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz"
  tar -xf "$HOME/dev/flutter_linux.tar.xz" -C "$HOME/dev"
  echo "Flutter SDK 已安装到 $FLUTTER_ROOT"
fi
export PATH="$FLUTTER_ROOT/bin:$PATH"
flutter --version | head -2

echo
echo "=== 2. 同步代码 ==="
# --delete 的取舍：
# · android/ios/windows 两侧都有（Windows 侧也保留），正常双向同步
# · linux/macos/web 只可能在 WSL 侧存在（Windows 侧未生成），必须排除，
#   否则会被 --delete 清掉
# · ephemeral 是构建期生成物，内含指向本机 pub-cache 的绝对路软链，
#   跨机器必然失效，绝不能参与同步
mkdir -p "$(dirname "$DEST")"
rsync -a --delete \
  --exclude '.dart_tool' --exclude 'build' --exclude '.idea' \
  --exclude 'app/linux' --exclude 'app/macos' --exclude 'app/web' \
  --exclude 'ephemeral' \
  "$SRC/" "$DEST/"
echo "已同步到 $DEST"

echo
echo "=== 3. 生成平台脚手架（若缺失） ==="
cd "$DEST/app"
if [[ ! -d android && ! -d windows ]]; then
  flutter create --project-name reading_tracker --org cn.reading \
    --platforms=android,ios,windows .
  echo "平台目录已生成"
else
  echo "平台目录已存在，跳过"
fi

echo
echo "=== 3b. SQLite 运行时（flutter test 必需） ==="
# sqflite_common_ffi 会 dlopen 'libsqlite3.so'，而 Ubuntu 默认只装了
# libsqlite3.so.0，缺这个软链会导致所有数据库测试报
# "Failed to load dynamic library 'libsqlite3.so'"
if [[ ! -e /usr/lib/x86_64-linux-gnu/libsqlite3.so ]]; then
  echo "创建 libsqlite3.so 软链（需要 sudo）"
  sudo ln -sf /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 \
    /usr/lib/x86_64-linux-gnu/libsqlite3.so
fi
echo "ok"

echo
echo "=== 4. 解析依赖 ==="
flutter pub get 2>&1 | tail -5

echo
echo "=== 5. 静态检查 ==="
flutter analyze --no-pub 2>&1 | tail -10

echo
echo "=== 6. 测试 ==="
flutter test 2>&1 | tail -5

echo
echo "完成。后续开发："
echo "  cd $DEST/app && flutter run -d linux     # 桌面端调试（最快）"
echo "  cd $DEST/app && flutter test             # 单元测试"
echo "  cd $DEST/tools && node report.mjs ...    # 数据工具"
