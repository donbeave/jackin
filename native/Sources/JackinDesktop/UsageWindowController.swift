// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

/// Lazily creates and retains the AppKit Usage window and its native split controller.
///
/// SwiftUI owns pane content. AppKit owns split geometry, the full-height sidebar,
/// its standard toolbar toggle, and the detail top accessory.
///
/// Showing the window promotes the process to `.regular` so the **system menu
/// bar** ( + AppMainMenu) is available; closing the last titled window returns
/// to `.accessory` status-item mode.
///
@MainActor
public final class UsageWindowController: NSObject, NSWindowDelegate {
    private let store: PresentationStore
    private let elevatesFixtureWindow: Bool
    private let onSplitControllerCreated: (NSSplitViewController) -> Void
    private var window: NSWindow?
    private var splitController: UsageWindowSplitController?
    private var toolbarController: UsageWindowToolbar?
    private var sidebarKeyMonitor: Any?

    public init(
        store: PresentationStore,
        elevatesFixtureWindow: Bool = false,
        onSplitControllerCreated: @escaping (NSSplitViewController) -> Void = { _ in }
    ) {
        self.store = store
        self.elevatesFixtureWindow = elevatesFixtureWindow
        self.onSplitControllerCreated = onSplitControllerCreated
        super.init()
    }

    /// Show the retained Usage window without changing its valid destination.
    public func show(size: CGSize? = nil) {
        present(size: size)
    }

    /// Show the Usage window at an explicit provider surface id (`nil` = Overview).
    public func show(focusOn surfaceId: String?, size: CGSize? = nil) {
        store.selectUsageSurface(surfaceId)
        present(size: size)
    }

    private func present(size: CGSize?) {
        let window = window ?? makeWindow()
        self.window = window
        if let size {
            window.setContentSize(size)
        }
        AppActivation.present(window)
        if elevatesFixtureWindow {
            window.orderFrontRegardless()
        }
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "jackin❯ desktop"
        window.isReleasedWhenClosed = false
        window.delegate = self
        if store.usesFixture {
            // Deterministic UI/visual QA must stay observable when WindowServer assigns rapid
            // fixture launches and the test runner to different or full-screen Spaces.
            window.collectionBehavior.formUnion([
                .canJoinAllSpaces,
                .canJoinAllApplications,
                .fullScreenAuxiliary,
            ])
            if elevatesFixtureWindow {
                window.level = .floating
            }
        } else {
            window.collectionBehavior.insert(.moveToActiveSpace)
        }
        window.contentMinSize = NSSize(width: 760, height: 500)
        window.identifier = NSUserInterfaceItemIdentifier("usage-window")
        window.setAccessibilityIdentifier("usage-window")
        if !store.usesFixture {
            window.setFrameAutosaveName("jackin.desktop.usage-window")
        }

        // Unified titlebar + standard AppKit split toolbar; no app-painted chrome.
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .automatic

        let split = UsageWindowSplitController(store: store)
        splitController = split
        window.contentViewController = split
        onSplitControllerCreated(split)
        sidebarKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            [weak window, weak split] event in
            guard window?.isKeyWindow == true, AppMainMenu.isSidebarKeyEquivalent(event) else {
                return event
            }
            split?.toggleSidebar(window)
            return nil
        }

        let toolbarController = UsageWindowToolbar(sidebarItem: split.splitViewItems[0])
        self.toolbarController = toolbarController
        let toolbar = toolbarController.makeToolbar()
        window.toolbar = toolbar
        toolbarController.installStandardItems(in: toolbar)

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
        if let sidebarKeyMonitor {
            NSEvent.removeMonitor(sidebarKeyMonitor)
            self.sidebarKeyMonitor = nil
        }
        window?.delegate = nil
        window?.orderOut(nil)
        window?.contentViewController = nil
        window?.toolbar = nil
        splitController = nil
        toolbarController = nil
        window = nil
    }

    /// Visual QA: the live `NSWindow` after `show` (nil if never shown).
    public var qiWindow: NSWindow? { window }
}
