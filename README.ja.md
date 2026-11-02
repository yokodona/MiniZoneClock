# MiniZoneClock

メニューバーに、複数の地域の時刻を小さく並べて表示するアプリです。
各時計は「ラベル（上）／時刻（下）」の2段表示で、初期設定は24時間表示です。

```
 UTC   JP    LA
13:45 22:45 05:45
```

## ダウンロードして使う場合

[最新の Release](https://github.com/yokodona/MiniZoneClock/releases/latest) から `MiniZoneClock-<バージョン>-arm64.zip` をダウンロードし、解凍して `MiniZoneClock.app` を「アプリケーション」フォルダに移します（Apple シリコン専用）。

Apple の公証を受けていないため、「開発元を検証できません」と出ることがあります。その場合は、アプリを右クリックして「開く」を選ぶか、ターミナルで次を実行してください。

```
xattr -cr /Applications/MiniZoneClock.app
```

## ビルドして使う場合（最初の1回）

1. ターミナルを開き、次のコマンドを実行します。

   ```
   git clone https://github.com/yokodona/MiniZoneClock.git
   cd MiniZoneClock
   bash build.sh
   ```

   ※「Swift コンパイラが見つかりません」と出たら、`xcode-select --install` を実行して
     コマンドラインツールを入れてから、もう一度 `bash build.sh` を実行してください。

2. ビルドが終わると `/Applications/MiniZoneClock.app` に入り、自動で起動します。

## 使い方

- メニューバーの時計をクリックすると、各地域の日付・時刻・時差が出ます。
- **設定…** で次の項目を変えられます。
  - 時計の追加・削除・並べ替え（‹ › ボタン）
  - ラベル（例: LA, UTC, JP）
  - 地域（検索で選べます。「Tokyo」「Los Angeles」「太平洋」などで検索できます）
  - 時刻の大きさ（小・中・大）、ラベルの大きさ、時計どうしの間隔
- **ログイン時に起動** にチェックを入れると、Macの起動時に自動で立ち上がります。
- **時刻の表記** で24時間表記と12時間表記（AM/PM）を切り替えられます。
- **言語** で表示言語を切り替えられます（自動／日本語／English）。初期設定は「自動」で、Mac の言語が日本語なら日本語、それ以外は英語で表示します。
- 最初は左から UTC / JP / LA の3つが入っています。

## メモ

- macOS 13 以降、Apple シリコン（M1など）でそのまま動きます（Rosetta 不要）。
