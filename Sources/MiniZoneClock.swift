// MiniZoneClock
// メニューバーに「ラベル（上）／時刻（下）」の2段表示で、複数地域の時計を小さく並べるアプリ。
// macOS 13 以降。

import AppKit
import ServiceManagement
import SwiftUI

// MARK: - データ

struct ClockEntry: Codable, Identifiable, Equatable {
    var id = UUID()
    var label: String
    var timeZoneID: String

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
}

enum TextSize: Int, CaseIterable, Identifiable {
    case small, medium, large
    var id: Int { rawValue }
    var title: String { ["小", "中", "大"][rawValue] }
    var labelPoint: CGFloat { [7, 8, 9][rawValue] }
    var timePoint: CGFloat { [10, 11, 12.5][rawValue] }
}

final class ClockStore: ObservableObject {
    private let clocksKey = "clocks"
    private let sizeKey = "textSize"
    private let gapKey = "gap"
    private let labelPointKey = "labelPoint"

    var onChange: (() -> Void)?

    @Published var clocks: [ClockEntry] {
        didSet { save(); onChange?() }
    }
    @Published var textSize: TextSize {
        didSet { UserDefaults.standard.set(textSize.rawValue, forKey: sizeKey); onChange?() }
    }
    /// ラベルの文字の大きさ（ポイント）
    @Published var labelPoint: Double {
        didSet { UserDefaults.standard.set(labelPoint, forKey: labelPointKey); onChange?() }
    }
    /// 時計どうしの間隔（ポイント）
    @Published var gap: Double {
        didSet { UserDefaults.standard.set(gap, forKey: gapKey); onChange?() }
    }

    init() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: clocksKey),
           let saved = try? JSONDecoder().decode([ClockEntry].self, from: data) {
            clocks = saved
        } else {
            clocks = [
                ClockEntry(label: "LA", timeZoneID: "America/Los_Angeles"),
                ClockEntry(label: "UTC", timeZoneID: "UTC"),
                ClockEntry(label: "JP", timeZoneID: "Asia/Tokyo"),
            ]
        }
        textSize = TextSize(rawValue: d.integer(forKey: sizeKey)) ?? .small
        gap = d.object(forKey: gapKey) as? Double ?? 6
        labelPoint = d.object(forKey: labelPointKey) as? Double ?? 8.5
    }

    private func save() {
        if let data = try? JSONEncoder().encode(clocks) {
            UserDefaults.standard.set(data, forKey: clocksKey)
        }
    }

    func move(_ id: UUID, by delta: Int) {
        guard let i = clocks.firstIndex(where: { $0.id == id }) else { return }
        let j = i + delta
        guard clocks.indices.contains(j) else { return }
        clocks.swapAt(i, j)
    }

    func remove(_ id: UUID) {
        clocks.removeAll { $0.id == id }
    }

    func add() {
        clocks.append(ClockEntry(label: "NEW", timeZoneID: TimeZone.current.identifier))
    }
}

// MARK: - 書式

enum Fmt {
    private static var timeCache: [String: DateFormatter] = [:]
    private static var detailCache: [String: DateFormatter] = [:]

    static func time(_ date: Date, in tz: TimeZone) -> String {
        let f = timeCache[tz.identifier] ?? {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "HH:mm"
            f.timeZone = tz
            timeCache[tz.identifier] = f
            return f
        }()
        return f.string(from: date)
    }

    static func detail(_ date: Date, in tz: TimeZone) -> String {
        let f = detailCache[tz.identifier] ?? {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ja_JP")
            f.dateFormat = "M/d(E) HH:mm"
            f.timeZone = tz
            detailCache[tz.identifier] = f
            return f
        }()
        return f.string(from: date)
    }

    static func offset(_ tz: TimeZone, at date: Date = Date()) -> String {
        let s = tz.secondsFromGMT(for: date)
        let sign = s < 0 ? "−" : "+"
        let h = abs(s) / 3600
        let m = abs(s) % 3600 / 60
        return m == 0 ? "UTC\(sign)\(h)" : String(format: "UTC%@%d:%02d", sign, h, m)
    }

    static func japaneseName(_ tz: TimeZone) -> String {
        tz.localizedName(for: .generic, locale: Locale(identifier: "ja_JP")) ?? ""
    }
}

// MARK: - メニューバー画像

enum Renderer {
    static func image(clocks: [ClockEntry], date: Date, size: TextSize, labelPoint: CGFloat, gap: CGFloat, height: CGFloat) -> NSImage {
        let labelFont = NSFont.systemFont(ofSize: labelPoint, weight: .semibold)
        let timeFont = NSFont.monospacedDigitSystemFont(ofSize: size.timePoint, weight: .regular)
        let labelAttr: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: NSColor.black]
        let timeAttr: [NSAttributedString.Key: Any] = [.font: timeFont, .foregroundColor: NSColor.black]

        struct Col { let label: NSString; let time: NSString; let ls: CGSize; let ts: CGSize; let w: CGFloat }
        let cols: [Col] = clocks.map { c in
            let l = c.label as NSString
            let t = Fmt.time(date, in: c.timeZone) as NSString
            let ls = l.size(withAttributes: labelAttr)
            let ts = t.size(withAttributes: timeAttr)
            return Col(label: l, time: t, ls: ls, ts: ts, w: ceil(max(ls.width, ts.width)))
        }

        let total = cols.reduce(0) { $0 + $1.w } + gap * CGFloat(max(cols.count - 1, 0))
        let width = max(ceil(total), 1)

        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            let overlap: CGFloat = 2.5  // 行の余白を詰めて2段を収める
            var x: CGFloat = 0
            for col in cols {
                let block = col.ls.height + col.ts.height - overlap
                let bottom = floor((height - block) / 2)
                col.time.draw(at: NSPoint(x: x + (col.w - col.ts.width) / 2, y: bottom), withAttributes: timeAttr)
                col.label.draw(at: NSPoint(x: x + (col.w - col.ls.width) / 2, y: bottom + col.ts.height - overlap),
                               withAttributes: labelAttr)
                x += col.w + gap
            }
            return true
        }
        image.isTemplate = true  // ライト／ダークのメニューバーに自動で合わせる
        return image
    }
}

// MARK: - 設定画面

struct PickTarget: Identifiable { let id: UUID }

// 設定画面の一時的な状態。
// コマンドラインツールだけの環境では @State（マクロ）が使えないため、ObservableObject で持つ。
final class SettingsUI: ObservableObject {
    @Published var picking: PickTarget?
    @Published var query = ""
}

struct SettingsView: View {
    @ObservedObject var store: ClockStore
    @ObservedObject var ui: SettingsUI

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("時計（左から順に表示）").font(.headline)

            ForEach(store.clocks) { clock in
                HStack(spacing: 8) {
                    TextField("ラベル", text: labelBinding(clock.id))
                        .frame(width: 64)
                    Button {
                        ui.query = ""
                        ui.picking = PickTarget(id: clock.id)
                    } label: {
                        Text("\(clock.timeZoneID)  \(Fmt.offset(clock.timeZone))")
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button { store.move(clock.id, by: -1) } label: { Image(systemName: "chevron.left") }
                        .help("左へ")
                    Button { store.move(clock.id, by: 1) } label: { Image(systemName: "chevron.right") }
                        .help("右へ")
                    Button { store.remove(clock.id) } label: { Image(systemName: "minus.circle") }
                        .help("削除")
                }
            }

            Button {
                store.add()
            } label: {
                Label("時計を追加", systemImage: "plus")
            }

            Divider()

            Picker("時刻の大きさ", selection: $store.textSize) {
                ForEach(TextSize.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 260)

            HStack {
                Text("ラベルの大きさ")
                Slider(value: $store.labelPoint, in: 6...11, step: 0.5).frame(width: 160)
                Text(String(format: "%.1fpt", store.labelPoint)).monospacedDigit().foregroundColor(.secondary)
            }

            HStack {
                Text("時計の間隔")
                Slider(value: $store.gap, in: 2...16, step: 1).frame(width: 160)
                Text("\(Int(store.gap))pt").monospacedDigit().foregroundColor(.secondary)
            }

            Text("ラベルは「LA」「JP」のように短くすると幅が小さくなります。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 480)
        .sheet(item: $ui.picking) { target in
            TimeZonePicker(ui: ui, current: store.clocks.first(where: { $0.id == target.id })?.timeZoneID ?? "") { picked in
                if let i = store.clocks.firstIndex(where: { $0.id == target.id }) {
                    store.clocks[i].timeZoneID = picked
                }
            }
        }
    }

    private func labelBinding(_ id: UUID) -> Binding<String> {
        Binding(
            get: { store.clocks.first(where: { $0.id == id })?.label ?? "" },
            set: { newValue in
                if let i = store.clocks.firstIndex(where: { $0.id == id }) {
                    store.clocks[i].label = newValue
                }
            }
        )
    }
}

struct TimeZonePicker: View {
    @ObservedObject var ui: SettingsUI
    let current: String
    let onPick: (String) -> Void

    private func dismiss() { ui.picking = nil }

    private static let all: [String] = {
        var ids = TimeZone.knownTimeZoneIdentifiers.sorted()
        ids.removeAll { $0 == "UTC" }
        return ["UTC"] + ids
    }()

    private var filtered: [String] {
        let q = ui.query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return Self.all }
        return Self.all.filter { id in
            guard let tz = TimeZone(identifier: id) else { return false }
            let hay = "\(id) \(Fmt.japaneseName(tz)) \(tz.abbreviation() ?? "")"
                .lowercased()
                .replacingOccurrences(of: "_", with: " ")
            return hay.contains(q.replacingOccurrences(of: "_", with: " "))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("地域を選ぶ").font(.headline)
            TextField("検索（例: Tokyo, Los Angeles, 太平洋, UTC）", text: $ui.query)
                .textFieldStyle(.roundedBorder)
            List(filtered, id: \.self) { id in
                Button {
                    onPick(id)
                    dismiss()
                } label: {
                    HStack {
                        Text(id).fontWeight(id == current ? .bold : .regular)
                        if let tz = TimeZone(identifier: id) {
                            Text(Fmt.japaneseName(tz)).foregroundColor(.secondary)
                            Spacer()
                            Text(Fmt.offset(tz)).monospacedDigit().foregroundColor(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            HStack {
                Spacer()
                Button("キャンセル") { dismiss() }.keyboardShortcut(.cancelAction)
            }
        }
        .padding(16)
        .frame(width: 460, height: 460)
    }
}

// MARK: - アプリ本体

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let store = ClockStore()
    private let settingsUI = SettingsUI()
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var lastKey = ""
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        store.onChange = { [weak self] in
            DispatchQueue.main.async { self?.refresh(force: true) }
        }

        refresh(force: true)
        let t = Timer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        t.tolerance = 0.2
        RunLoop.main.add(t, forMode: .common)
        timer = t

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(tick), name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(tick), name: .NSSystemTimeZoneDidChange, object: nil)
    }

    @objc private func tick() { refresh(force: false) }

    private func refresh(force: Bool) {
        let now = Date()
        let key = store.clocks.map { "\($0.label)|\(Fmt.time(now, in: $0.timeZone))" }.joined(separator: ",")
            + "|\(store.textSize.rawValue)|\(store.labelPoint)|\(store.gap)"
        guard force || key != lastKey else { return }
        lastKey = key

        guard let button = statusItem.button else { return }
        if store.clocks.isEmpty {
            button.image = nil
            button.imagePosition = .noImage
            button.title = "🕐"
            return
        }
        button.title = ""
        button.imagePosition = .imageOnly
        button.image = Renderer.image(
            clocks: store.clocks, date: now, size: store.textSize, labelPoint: CGFloat(store.labelPoint),
            gap: CGFloat(store.gap), height: NSStatusBar.system.thickness)
    }

    // メニューは開くたびに作り直す（日付・時差を最新にするため）
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let now = Date()
        for c in store.clocks {
            let tz = c.timeZone
            let title = "\(c.label)    \(Fmt.detail(now, in: tz))    \(tz.abbreviation(for: now) ?? "") (\(Fmt.offset(tz, at: now)))"
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        if !store.clocks.isEmpty { menu.addItem(.separator()) }

        let settings = NSMenuItem(title: "設定…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let login = NSMenuItem(title: "ログイン時に起動", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store, ui: settingsUI)))
            w.title = "MiniZoneClock の設定"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            settingsWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func toggleLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
                if service.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "ログイン項目を変更できませんでした"
            alert.informativeText = "アプリを「アプリケーション」フォルダに入れてから、もう一度試してください。\n\n\(error.localizedDescription)"
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}

@main
enum Main {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)  // Dock に出さない
        withExtendedLifetime(delegate) { app.run() }
    }
}
