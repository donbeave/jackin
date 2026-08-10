// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

/// Lazily creates and retains the AppKit Usage window hosting the existing
/// `UsageWindowRoot`. Plan 008 owns the window's content; this controller only
/// owns its lifecycle and focus.
///
/// Showing the window promotes the process to `.regular` so the **system menu
/// bar** ( + AppMainMenu) is available; closing the last titled window returns
/// to `.accessory` status-item mode.
///
/// **Native toolbar:** content is an `NSHostingController` so SwiftUI
/// `.toolbar` installs a real `NSToolbar` (unified titlebar). Plain
/// `NSHostingView` does **not** attach the window toolbar.
@MainActor
public final class UsageWindowController: NSObject, NSWindowDelegate {
    private let store: PresentationStore
    private var window: NSWindow?
    private var hostingController: NSHostingController<UsageWindowRoot>?

    public init(store: PresentationStore) {
        self.store = store
        super.init()
    }

    /// Show the Usage window, focused on a provider surface id (`nil` = Overview),
    /// creating it on first use and reusing it afterward.
    public func show(focusOn surfaceId: String?) {
        store.selectUsageSurface(surfaceId)
        let window = window ?? makeWindow()
        self.window = window
        window.makeKeyAndOrderFront(nil)
        AppActivation.presentWindows()
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "jackin❯ desktop"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.setFrameAutosaveName("jackin.desktop.usage-window")

        // Unified titlebar + toolbar (system NSToolbar — not a custom chrome strip).
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = false
        // Custom SwiftUI `.principal` item owns the centered branded title.
        // Keep NSWindow title for Window menu/accessibility without duplicating it at leading.
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .automatic

        // Hosting *controller* is required for SwiftUI toolbar → NSToolbar.
        let root = UsageWindowRoot(store: store)
        let host = NSHostingController(rootView: root)
        hostingController = host
        window.contentViewController = host

        window.center()
        return window
    }

    public func windowWillClose(_ notification: Notification) {
        // Window is still visible during willClose; resign on next run-loop turn.
        DispatchQueue.main.async {
            AppActivation.resignToAccessoryIfNeeded()
        }
    }

    public func invalidate() {
        window?.delegate = nil
        window?.orderOut(nil)
        window?.contentViewController = nil
        hostingController = nil
        window = nil
    }

    /// QI / snapshot: the live `NSWindow` after ``show(focusOn:)`` (nil if never shown).
    public var qiWindow: NSWindow? { window }
}
