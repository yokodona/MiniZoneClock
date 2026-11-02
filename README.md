# MiniZoneClock

[日本語版はこちら](README.ja.md)

A macOS menu-bar app that shows several time zones side by side in small type.
Each clock is a two-line item (label on top, time below), in 24-hour format by default.

```
 UTC   JP    LA
13:45 22:45 05:45
```

## Features

- Multiple clocks in the menu bar, each with a custom label (e.g. LA, UTC, JP)
- Click the menu-bar clocks to see each zone's date, time and offset
- Settings window:
  - Add, remove and reorder clocks
  - Edit labels
  - Pick a time zone by searching (e.g. "Tokyo", "Los Angeles")
  - Adjust time size (small / medium / large), label size and spacing
- Optional launch at login
- UI in Japanese or English: follows the macOS language by default (Japanese if macOS is Japanese, English otherwise), and can be switched in Settings
- 24-hour or 12-hour (AM/PM) time format, switchable in Settings
- Starts with three clocks, left to right: UTC / JP / LA

## Requirements

- macOS 13 or later
- Runs natively on Apple silicon (no Rosetta needed)
- To build from source only: the Swift compiler from the Xcode Command Line Tools (`xcode-select --install`)

## Download

Grab `MiniZoneClock-1.0-arm64.zip` from the [Releases](https://github.com/yokodona/MiniZoneClock/releases) page, unzip it and move `MiniZoneClock.app` to `/Applications`. Apple silicon only.

The app is ad-hoc signed and not notarized, so macOS may say it cannot verify the developer. Either right-click the app and choose **Open**, or run:

```
xattr -cr /Applications/MiniZoneClock.app
```

## Build

```
git clone https://github.com/yokodona/MiniZoneClock.git
cd MiniZoneClock
bash build.sh
```

The script compiles the app, installs it to `/Applications/MiniZoneClock.app` and launches it.

## License

[MIT](LICENSE)

---

Built with Claude.
