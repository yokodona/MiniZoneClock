#!/bin/bash
# MiniZoneClock をビルドして「アプリケーション」フォルダに入れ、起動します。
# 使い方: ターミナルでこのフォルダに移動して  bash build.sh
set -euo pipefail
cd "$(dirname "$0")"

if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Swift コンパイラが見つかりません。"
  echo "先に  xcode-select --install  を実行して、コマンドラインツールを入れてください。"
  exit 1
fi

APP="build/MiniZoneClock.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "ビルド中…"
xcrun swiftc -O -parse-as-library \
  -target "$(uname -m)-apple-macos13.0" \
  Sources/MiniZoneClock.swift \
  -o "$APP/Contents/MacOS/MiniZoneClock"

cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"

pkill -x MiniZoneClock 2>/dev/null || true
rm -rf /Applications/MiniZoneClock.app
ditto "$APP" /Applications/MiniZoneClock.app
open /Applications/MiniZoneClock.app

echo "完了しました。メニューバーに時計が出ていれば成功です。"
