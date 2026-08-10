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
@MainActor
final class UsageWindowController: NSObject, NSWindowDelegate {
    private let store: PresentationStore
    private var window: NSWindow?

    init(store: PresentationStore) {
        self.store = store
        super.init()
    }

    /// Show the Usage window, focused on a provider surface id (`nil` = Overview),
    /// creating it on first use and reusing it afterward.
    func show(focusOn surfaceId: String?) {
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
        // Centered title-bar brand (macOS centers NSWindow.title).
        window.title = "jackin❯ desktop"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: UsageWindowRoot(store: store))
        window.center()
        window.setFrameAutosaveName("jackin.desktop.usage-window")
        return window
    }

    func windowWillClose(_ notification: Notification) {
        // Window is still visible during willClose; resign on next run-loop turn.
        DispatchQueue.main.async {
            AppActivation.resignToAccessoryIfNeeded()
        }
    }

    func invalidate() {
        window?.delegate = nil
        window?.orderOut(nil)
        window?.contentView = nil
        window = nil
    }
}
