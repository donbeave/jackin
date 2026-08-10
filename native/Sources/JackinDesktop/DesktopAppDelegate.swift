// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import Combine
import JackinUsageBridge
import SwiftUI

/// Owns the per-provider `NSStatusItem`s, keyed by Rust `surfaceId`, and the one
/// shared transient popover. Rust owns detection, ranking (SB-17), and every
/// string; this controller reconciles items against `store.statusBarGlanceRows`
/// and rebuilds when ranked order changes (SB-13).
@MainActor
public final class StatusBarController: NSObject {
    private let store: PresentationStore
    private var providerItems: [String: NSStatusItem] = [:]
    private var fallbackItem: NSStatusItem?
    /// Last applied burn-first rank order (left → right = rank 1…n).
    private var canonicalOrder: [String] = []
    private let popover = NSPopover()
    private weak var anchoredButton: NSStatusBarButton?
    private var cancellables: Set<AnyCancellable> = []
    /// Opens the Usage window focused on a provider (`nil` = Overview).
    private let onOpenUsage: (String?) -> Void
    /// Owns the context menu and is the `NSMenuItem` target. Must stay retained
    /// for the bar lifetime (see `StatusItemMenu` docs — drop target ⇒ all rows disabled).
    private let statusItemMenu: StatusItemMenu

    init(
        store: PresentationStore,
        menuRouter: StatusItemMenuRouter,
        onOpenUsage: @escaping (String?) -> Void
    ) {
        self.store = store
        self.onOpenUsage = onOpenUsage
        self.statusItemMenu = StatusItemMenu(router: menuRouter)
        super.init()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = PopoverRoot.liveContentSize
        // Liquid Glass popover: clear NSPopover chrome so panel glass refracts
        // the desktop (LG-A1). Host must stay GlassPopoverHostingController.
        let root = PopoverRoot(store: store) { [weak self] surfaceId in
            self?.popover.performClose(nil)
            self?.anchoredButton = nil
            self?.onOpenUsage(surfaceId)
        }
        popover.contentViewController = GlassPopoverHostingController(rootView: root)

        // Burn-first chips only (SB-3/14/17/19) — not full providerGlanceRows inventory.
        store.$statusBarGlanceRows
            .receive(on: RunLoop.main)
            .sink { [weak self] rows in self?.apply(rows: rows) }
            .store(in: &cancellables)
        store.$statusBarShowsValues
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshTitles() }
            .store(in: &cancellables)

        apply(rows: store.statusBarGlanceRows)
    }

    private func apply(rows: [PresentationStore.GlanceProviderRow]) {
        guard !rows.isEmpty else {
            removeAllProviderItems()
            ensureFallbackItem()
            return
        }
        removeFallbackItem()
        let newOrder = rows.map(\.surfaceId)
        // SB-13: NSStatusItem left→right order is creation order. When Rust
        // rank changes, remove and recreate so visual order tracks rank 1 first.
        if statusBarOrderRequiresRebuild(previous: canonicalOrder, next: newOrder) {
            removeAllProviderItems()
        } else {
            for id in Array(providerItems.keys) where !newOrder.contains(id) {
                removeProviderItem(id: id)
            }
        }
        canonicalOrder = newOrder
        for row in rows {
            let item = providerItems[row.surfaceId] ?? makeProviderItem(surfaceId: row.surfaceId)
            providerItems[row.surfaceId] = item
            configure(item: item, row: row)
        }
    }

    private func makeProviderItem(surfaceId: String) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "jackin.desktop.status.\(surfaceId)"
        if let button = item.button {
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        return item
    }

    private func configure(item: NSStatusItem, row: PresentationStore.GlanceProviderRow) {
        guard let button = item.button else { return }
        // LG-A1 / FB1-6: template icon + dual-stack values — no glass chip chrome.
        button.image = StatusItemRendering.icon(forIconKey: row.iconKey)
        button.imagePosition = .imageLeading
        button.attributedTitle =
            store.statusBarShowsValues
            ? StatusItemRendering.title(barLabel: row.barLabel, resetLabel: row.resetLabel)
            : NSAttributedString(string: "")
        button.appearsDisabled = row.dimmed
        // Tooltip carries full Rust headline + optional exact reset (detail beyond bar).
        var tip = row.headline
        if let exact = row.exactReset, !exact.isEmpty {
            tip = "\(tip) \(exact)"
        }
        button.toolTip = tip
        button.setAccessibilityLabel("\(row.displayLabel) \(row.headline)")
    }

    private func ensureFallbackItem() {
        guard fallbackItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "jackin.desktop.status.fallback"
        if let button = item.button {
            button.image = StatusItemRendering.fallbackIcon()
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel("jackin❯ desktop usage")
        }
        fallbackItem = item
    }

    private func refreshTitles() {
        for row in store.statusBarGlanceRows {
            if let item = providerItems[row.surfaceId] {
                configure(item: item, row: row)
            }
        }
    }

    private func removeProviderItem(id: String) {
        guard let item = providerItems.removeValue(forKey: id) else { return }
        if anchoredButton === item.button {
            popover.performClose(nil)
            anchoredButton = nil
        }
        NSStatusBar.system.removeStatusItem(item)
    }

    private func removeAllProviderItems() {
        for id in Array(providerItems.keys) {
            removeProviderItem(id: id)
        }
    }

    private func removeFallbackItem() {
        guard let item = fallbackItem else { return }
        if anchoredButton === item.button {
            popover.performClose(nil)
            anchoredButton = nil
        }
        NSStatusBar.system.removeStatusItem(item)
        fallbackItem = nil
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        // Right-click shows the static context menu; left-click toggles the popover.
        if NSApp.currentEvent?.type == .rightMouseUp {
            statusItemMenu.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: sender.bounds.height + 4),
                in: sender
            )
            return
        }
        togglePopover(sender)
    }

    /// Resolve which provider (or fallback) owns this status button.
    private func clickTarget(for button: NSStatusBarButton) -> (surfaceId: String?, isFallback: Bool) {
        let identity = ObjectIdentifier(button)
        var map: [String: ObjectIdentifier] = [:]
        for (id, item) in providerItems {
            if let b = item.button {
                map[id] = ObjectIdentifier(b)
            }
        }
        if let sid = StatusPopoverFocus.surfaceId(
            matchingButtonIdentity: identity,
            providerButtonIdentities: map
        ) {
            return (sid, false)
        }
        if let fb = fallbackItem?.button, ObjectIdentifier(fb) == identity {
            return (nil, true)
        }
        return (nil, false)
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        // Anchored to the same button → toggle closed (keep last selection).
        if popover.isShown, anchoredButton === sender {
            popover.performClose(sender)
            anchoredButton = nil
            return
        }
        if popover.isShown {
            popover.performClose(sender)
        }
        // HTML SoT: left-click focuses that provider (or Overview for fallback).
        let target = clickTarget(for: sender)
        let outcome = StatusPopoverFocus.outcome(
            surfaceId: target.surfaceId,
            isFallbackItem: target.isFallback
        )
        store.popoverSelection = StatusPopoverFocus.popoverSelection(for: outcome)

        anchoredButton = sender
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        // Re-assert clear chrome after the popover window materializes (LG translucency).
        if let window = popover.contentViewController?.view.window {
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
        }
        popover.contentViewController?.view.layer?.backgroundColor = NSColor.clear.cgColor
    }

    /// Cancel subscriptions, close the popover, and remove every status item.
    /// Safe to call more than once.
    func invalidate() {
        cancellables.removeAll()
        if popover.isShown {
            popover.performClose(nil)
        }
        popover.contentViewController = nil
        anchoredButton = nil
        removeAllProviderItems()
        removeFallbackItem()
    }
}

/// Application delegate for jackin❯ desktop (menu-bar agent). Owns the store,
/// status-bar controller, main menu, and document windows (Usage / Settings).
@MainActor
public final class DesktopAppDelegate: NSObject, NSApplicationDelegate {
    let store: PresentationStore
    private let launchConfiguration: PresentationStore.LaunchConfiguration
    private var statusBar: StatusBarController?
    private var usageWindow: UsageWindowController?
    /// Retained: menu item targets point here / AppMainMenu for the process life.
    private var mainMenu: AppMainMenu?

    public override init() {
        self.launchConfiguration = PresentationStore.LaunchConfiguration.resolve(
            environment: ProcessInfo.processInfo.environment,
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser.path
        )
        self.store = PresentationStore()
        super.init()
    }

    public func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        store.openForLaunch(launchConfiguration)
        let usageWindow = UsageWindowController(store: store)
        self.usageWindow = usageWindow

        let menu = AppMainMenu(store: store) { [weak usageWindow] in
            usageWindow?.show(focusOn: nil)
        }
        menu.install()
        self.mainMenu = menu

        let router = StatusItemMenuRouter(
            openUsageWindow: { [weak usageWindow] surfaceId in usageWindow?.show(focusOn: surfaceId) },
            refresh: { [weak store] in store?.refreshAll() },
            quit: { NSApp.terminate(nil) }
        )
        statusBar = StatusBarController(store: store, menuRouter: router) { [weak usageWindow] surfaceId in
            usageWindow?.show(focusOn: surfaceId)
        }
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Menu-bar agent stays alive after Usage/Settings close.
        false
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        // Dock click while regular (or after hide) → bring Usage forward.
        if !hasVisibleWindows {
            usageWindow?.show(focusOn: nil)
        }
        return true
    }

    public func applicationWillTerminate(_ notification: Notification) {
        statusBar?.invalidate()
        statusBar = nil
        usageWindow?.invalidate()
        usageWindow = nil
        mainMenu = nil
        store.shutdown()
    }
}
