# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

MiniZoneClock is a macOS menu-bar app (Japanese-language UI and README) that shows several time zones side by side as small two-line items (label over 24h time). It is a single Swift source file with no Xcode project, no Swift package, and no tests.

## Build and run

```
bash build.sh
```

`build.sh` compiles `Sources/MiniZoneClock.swift` with `xcrun swiftc -O -parse-as-library` (target `<arch>-apple-macos13.0`), assembles `build/MiniZoneClock.app` with `Info.plist`, ad-hoc codesigns it, kills any running instance, replaces `/Applications/MiniZoneClock.app`, and launches it. It wipes `build/` each run. There is no lint step and no test suite.

## Architecture

All code lives in `Sources/MiniZoneClock.swift`:

- `ClockStore` (ObservableObject): the model. Holds the `ClockEntry` list (label + time zone id) and display settings (`TextSize`, label point size, gap), persisted to `UserDefaults` in `didSet`. Each change also calls `onChange?()` so the menu bar can redraw.
- `Fmt` / `Renderer`: time formatting and the drawing of the menu-bar image. The status item shows a rendered image rather than SwiftUI views.
- `SettingsView`, `TimeZonePicker`, `SettingsUI`: SwiftUI settings UI, hosted in an `NSWindow` via `NSHostingController`.
- `AppDelegate`: owns the `NSStatusItem`, a 1-second `Timer` that re-renders, the dropdown `NSMenu` (rebuilt via `NSMenuDelegate`), the settings window, and the launch-at-login toggle (`SMAppService.mainApp`).
- `@main enum Main`: manual entry point, which is why the build passes `-parse-as-library`.

`Info.plist` sets `LSUIElement` (no Dock icon) and bundle id `local.minizoneclock`. The minimum is macOS 13.

---

## 日本語訳

# CLAUDE.md（日本語訳）

このファイルは、このリポジトリで作業する Claude Code (claude.ai/code) への指針です。

### 概要

MiniZoneClock は、複数のタイムゾーンの時刻を、ラベル（上）と24時間表記の時刻（下）の2段表示で横に並べて表示する macOS のメニューバーアプリです（UI と README は日本語）。Swift のソースファイルは1つだけで、Xcode プロジェクトも Swift パッケージもテストもありません。

### ビルドと実行

```
bash build.sh
```

`build.sh` は `Sources/MiniZoneClock.swift` を `xcrun swiftc -O -parse-as-library`（ターゲットは `<arch>-apple-macos13.0`）でコンパイルし、`Info.plist` を使って `build/MiniZoneClock.app` を組み立て、アドホック署名をし、起動中のインスタンスを終了させ、`/Applications/MiniZoneClock.app` を置き換えて起動します。実行のたびに `build/` を削除します。lint の手順もテストスイートもありません。

### アーキテクチャ

コードはすべて `Sources/MiniZoneClock.swift` にあります。

- `ClockStore`（ObservableObject）: モデル。`ClockEntry` のリスト（ラベルとタイムゾーンID）と表示設定（`TextSize`、ラベルのポイントサイズ、間隔）を保持し、`didSet` で `UserDefaults` に保存します。変更のたびに `onChange?()` を呼び、メニューバーを再描画させます。
- `Fmt` / `Renderer`: 時刻のフォーマットと、メニューバー用画像の描画。ステータスアイテムには SwiftUI ビューではなく、描画した画像を表示します。
- `SettingsView`、`TimeZonePicker`、`SettingsUI`: SwiftUI の設定画面。`NSHostingController` 経由で `NSWindow` に載せています。
- `AppDelegate`: `NSStatusItem`、毎秒再描画する `Timer`、ドロップダウンの `NSMenu`（`NSMenuDelegate` で再構築）、設定ウィンドウ、ログイン時起動の切り替え（`SMAppService.mainApp`）を管理します。
- `@main enum Main`: 手動のエントリポイント。これがビルド時に `-parse-as-library` を付ける理由です。

`Info.plist` では `LSUIElement`（Dock にアイコンを出さない）とバンドルID `local.minizoneclock` を設定しています。最小対応は macOS 13 です。
