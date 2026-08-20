// The launch-contract harness. Copy into Sources/<Feature>Proto/ and keep
// the contract intact: --tr-scenario, --tr-appearance, --tr-window,
// --tr-reduce, --tr-backdrop. Feature code supplies the scenarios and the
// root view; nothing here is feature-specific.

import AppKit
import SwiftUI

struct ProtoConfig {
    var scenario = "default"
    var appearance: NSAppearance.Name?
    var window: CGSize?
    var reduceTransparency = false
    var reduceMotion = false
    var backdrop: NSColor?

    static func parse(_ args: [String]) -> ProtoConfig {
        var config = ProtoConfig()
        func value(after flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1)
            else { return nil }
            return args[index + 1]
        }
        if let name = value(after: "--tr-scenario") { config.scenario = name }
        switch value(after: "--tr-appearance") {
        case "light": config.appearance = .aqua
        case "dark": config.appearance = .darkAqua
        case .some(let other): fatalError("unknown --tr-appearance \(other)")
        case nil: break
        }
        if let size = value(after: "--tr-window") {
            let parts = size.split(separator: "x").compactMap { Double($0) }
            guard parts.count == 2 else { fatalError("--tr-window expects WxH, got \(size)") }
            config.window = CGSize(width: parts[0], height: parts[1])
        }
        if let list = value(after: "--tr-reduce") {
            for item in list.split(separator: ",") {
                switch item {
                case "transparency": config.reduceTransparency = true
                case "motion": config.reduceMotion = true
                default: fatalError("unknown --tr-reduce item \(item)")
                }
            }
        }
        switch value(after: "--tr-backdrop") {
        case "standard":
            config.backdrop = NSColor(srgbRed: 0.42, green: 0.45, blue: 0.50, alpha: 1)
        case .some(let hex):
            config.backdrop = NSColor(hex: hex) ?? { fatalError("bad --tr-backdrop \(hex)") }()
        case nil: break
        }
        return config
    }
}

@MainActor
final class ProtoDelegate: NSObject, NSApplicationDelegate {
    let config: ProtoConfig
    /// Feature hook: installs scenario UI before the readiness tick loop.
    var onLaunch: ((NSApplication) -> Void)?
    private var backdrop: NSWindow?
    private var lastFrame: CGRect = .zero
    private var stableTicks = 0
    private var announced = false

    init(config: ProtoConfig) { self.config = config }

    func applicationDidFinishLaunching(_ notification: Notification) {
        onLaunch?(NSApp)
        // Defaults leak across runs (table column autosave, restoration);
        // a deterministic prototype starts clean every launch.
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        if let name = config.appearance { NSApp.appearance = NSAppearance(named: name) }
        Task { @MainActor in
            while !self.announced {
                try? await Task.sleep(for: .milliseconds(400))
                self.tick()
            }
        }
    }

    private func tick() {
        // Match only normal-level windows: an unfiltered lookup grabs the
        // backdrop, clamps it, and announces the wrong window number.
        guard
            let window = NSApp.windows.first(where: { $0.isVisible && $0.level == .normal })
        else { return }
        // The backdrop is created only after the main window exists — a
        // delegate-created window before SwiftUI scene setup suppresses
        // WindowGroup window creation entirely. Ordering holds: it exists
        // before TR-READY is announced.
        if backdrop == nil, let color = config.backdrop {
            let screen = NSScreen.main!.frame
            let back = NSWindow(
                contentRect: screen, styleMask: .borderless, backing: .buffered, defer: false)
            back.backgroundColor = color
            back.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
            back.collectionBehavior = [.canJoinAllSpaces, .stationary]
            back.orderFrontRegardless()
            backdrop = back
        }
        if let size = config.window, window.contentLayoutRect.size != size {
            window.setContentSize(size)
            window.isRestorable = false
        }
        NSApp.activate(ignoringOtherApps: true)
        // Announce readiness only after geometry holds still twice — the
        // capture harness waits for this line.
        if window.frame == lastFrame {
            stableTicks += 1
            if stableTicks == 2 {
                print("TR-READY \(window.windowNumber)")
                fflush(stdout)
                announced = true
            }
        } else {
            stableTicks = 0
            lastFrame = window.frame
        }
    }
}

extension NSColor {
    convenience init?(hex: String) {
        var value: UInt64 = 0
        guard Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
            .scanHexInt64(&value)
        else { return nil }
        self.init(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1)
    }
}
