import AppKit
import SwiftUI

/// Thin AppKit shell mirroring the incumbent hosts: retained Usage window
/// (full-size content, transparent unified titlebar, hidden title), native
/// split with full-height sidebar and detail top accessory, standard toolbar
/// (`.toggleSidebar` + `.sidebarTrackingSeparator`), per-provider status items
/// with dual-stack titles, transient popover, explicit right-click menu
/// (`.menu` is never assigned), Settings window. SwiftUI content views lift
/// verbatim; only this host layer is prototype-specific.
@MainActor
final class ProtoShell: NSObject, NSMenuDelegate {
    let store: ProtoStore
    let config: ProtoConfig
    private var usageWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var popover: NSPopover?
    private var statusItems: [String: NSStatusItem] = [:]
    private var splitController: NSSplitViewController?
    private var toolbarController: UsageWindowToolbar?
    private var sidebarKeyMonitor: Any?

    init(store: ProtoStore, config: ProtoConfig) {
        self.store = store
        self.config = config
    }

    func install(into app: NSApplication) {
        app.mainMenu = buildMainMenu()
        installStatusItems()
        let window = makeUsageWindow()
        usageWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    func wrap<V: View>(_ view: V) -> some View {
        // The accessibility environment keys are get-only in the macOS 26.5
        // SDK, so process-local Reduce Motion is honored by stripping view
        // animations here; Reduce Transparency has no SwiftUI-owned material
        // to adapt in this design (system materials follow the real setting,
        // proven post-signoff by visual-qa).
        //
        // Brand accent lives here so every hosted surface — window, popover,
        // settings — renders selection wells, toggles, pickers, and the one
        // prominent button in phosphor instead of system blue ("never system
        // accentColor for jackin chrome" — BrandColors).
        view
            .tint(.jackinPhosphor)
            .environment(\.locale, store.chrome.locale)
            .environment(\.layoutDirection, store.chrome.layoutDirection)
            .transaction { transaction in
                if self.config.reduceMotion { transaction.animation = nil }
            }
    }

    // MARK: Main menu

    /// Mirrors the incumbent AppMainMenu: full menu citizenship — App (About,
    /// Settings, Services, Hide, Quit), File, Edit, View (sidebar + Refresh),
    /// Window (system windowsMenu), Help. No manual Full Screen item.
    private func buildMainMenu() -> NSMenu {
        let main = NSMenu()
        main.addItem(wrap(appMenu(), title: "jackin❯ desktop"))
        main.addItem(wrap(fileMenu(), title: "File"))
        main.addItem(wrap(editMenu(), title: "Edit"))
        let view = viewMenu()
        main.addItem(wrap(view, title: "View"))
        main.addItem(wrap(scenarioMenu(), title: "Scenario"))
        let window = windowMenu()
        main.addItem(wrap(window, title: "Window"))
        main.addItem(wrap(helpMenu(), title: "Help"))
        NSApp.windowsMenu = window
        return main
    }

    /// Prototype-only preview driver: re-runs every fixture live without a
    /// relaunch. Not part of the product menu structure.
    private func scenarioMenu() -> NSMenu {
        let menu = NSMenu(title: "Scenario")
        for group in ProtoFixtures.scenarioMenu {
            for name in group.names {
                let description = ProtoFixtures.scenarioDescriptions[name] ?? name
                let item = NSMenuItem(
                    title: "\(name) — \(description)",
                    action: #selector(loadScenario(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = name
                item.toolTip = description
                if name == store.projection.scenario { item.state = .on }
                menu.addItem(item)
            }
            menu.addItem(.separator())
        }
        menu.delegate = self
        return menu
    }

    @objc private func loadScenario(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        store.loadScenario(name)
    }

    private func appMenu() -> NSMenu {
        let menu = NSMenu(title: "jackin❯ desktop")
        menu.addItem(
            withTitle: "About jackin❯ desktop", action: #selector(orderFrontAbout(_:)),
            keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Settings…", action: #selector(showSettings),
            keyEquivalent: ",")
        menu.addItem(.separator())
        let services = NSMenu(title: "Services")
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        servicesItem.submenu = services
        menu.addItem(servicesItem)
        NSApp.servicesMenu = services
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Hide jackin❯ desktop", action: #selector(NSApplication.hide(_:)),
            keyEquivalent: "h")
        let hideOthers = menu.addItem(
            withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)),
            keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(
            withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)),
            keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit jackin❯ desktop",
            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    private func fileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")
        menu.addItem(
            withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w")
        return menu
    }

    private func editMenu() -> NSMenu {
        // Target nil → first-responder chain (standard macOS Edit menu).
        let menu = NSMenu(title: "Edit")
        menu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = menu.addItem(
            withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(.separator())
        menu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(
            withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        return menu
    }

    private func viewMenu() -> NSMenu {
        let menu = NSMenu(title: "View")
        menu.delegate = self
        let toggle = NSMenuItem(
            title: "Hide Sidebar",
            action: #selector(NSSplitViewController.toggleSidebar(_:)),
            keyEquivalent: "s")
        toggle.keyEquivalentModifierMask = [.command, .control]
        toggle.target = nil
        menu.addItem(toggle)
        menu.addItem(.separator())
        menu.addItem(
            withTitle: store.chrome.refreshTitle, action: #selector(refreshNow),
            keyEquivalent: "r")
        return menu
    }

    private func windowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")
        menu.addItem(
            withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)),
            keyEquivalent: "m")
        menu.addItem(
            withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Usage", action: #selector(showUsage), keyEquivalent: "0")
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Bring All to Front",
            action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        return menu
    }

    private func helpMenu() -> NSMenu {
        let menu = NSMenu(title: "Help")
        menu.addItem(
            withTitle: "jackin❯ desktop Help", action: #selector(NSApplication.showHelp(_:)),
            keyEquivalent: "?")
        return menu
    }

    private func wrap(_ menu: NSMenu, title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    @objc private func orderFrontAbout(_: Any?) {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "jackin❯ desktop",
            .credits: NSAttributedString(
                string: "Limits-only usage for agent credentials.\nDisplay shell over jackin-usage."),
        ])
    }

    // MARK: Usage window

    private func makeUsageWindow() -> NSWindow {
        let split = NSSplitViewController()
        split.splitView.isVertical = true

        let sidebarHost = NSHostingController(rootView: wrap(SidebarView(store: store)))
        // NSHostingController defaults to propagating SwiftUI's preferred
        // content size; in a split view that resizes the window on every
        // selection swap. Opt out — the split/window owns geometry.
        sidebarHost.sizingOptions = []
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarHost)
        sidebarItem.allowsFullHeightLayout = true
        sidebarItem.minimumThickness = 190
        sidebarItem.maximumThickness = 280
        sidebarItem.collapseBehavior = .preferResizingSiblingsWithFixedSplitView

        let detailHost = NSHostingController(
            rootView: wrap(
                DetailRootView(store: store) { [weak self] in
                    self?.showSettings()
                }))
        detailHost.sizingOptions = []
        let detailItem = NSSplitViewItem(viewController: detailHost)
        detailItem.automaticallyAdjustsSafeAreaInsets = true

        split.addSplitViewItem(sidebarItem)
        split.addSplitViewItem(detailItem)
        splitController = split

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.title = "Usage"
        window.isReleasedWhenClosed = false
        window.setContentSize(config.window ?? NSSize(width: 920, height: 620))
        window.contentViewController = split

        // Unified titlebar + standard AppKit split toolbar; no app-painted chrome.
        // Title follows the selection (System Settings wayfinding): section
        // name as title, account as subtitle.
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.titlebarSeparatorStyle = .automatic

        sidebarKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            [weak window, weak split] event in
            guard window?.isKeyWindow == true,
                Self.isSidebarKeyEquivalent(event)
            else { return event }
            split?.toggleSidebar(window)
            return nil
        }

        let refreshHost = NSHostingView(
            rootView: AnyView(wrap(RefreshToolbarButton(store: store))))
        let toolbarController = UsageWindowToolbar(
            sidebarItem: sidebarItem, refreshView: refreshHost,
            refreshTitle: store.chrome.refreshTitle)
        self.toolbarController = toolbarController
        let toolbar = toolbarController.makeToolbar()
        window.toolbar = toolbar
        toolbarController.installStandardItems(in: toolbar)

        // Set after contentViewController/toolbar — assigning those resets
        // the window's size limits. Sidebar min 190 + a usable detail list
        // is the floor; below that the design does not hold. minSize in
        // frame units: contentMinSize alone is not honored once a split
        // view controller owns the content. (Limits constrain interactive
        // resize; programmatic setContentSize bypasses them by design.)
        window.contentMinSize = NSSize(width: 760, height: 500)
        window.minSize = NSWindow.frameRect(
            forContentRect: NSRect(x: 0, y: 0, width: 760, height: 500),
            styleMask: window.styleMask
        ).size
        observeWindowTitles(window)
        return window
    }

    /// Selection-driven window title/subtitle, re-registered after every
    /// change (withObservationTracking fires once).
    private func observeWindowTitles(_ window: NSWindow) {
        withObservationTracking {
            applyWindowTitles(window)
        } onChange: { [weak self, weak window] in
            Task { @MainActor in
                guard let self, let window else { return }
                self.observeWindowTitles(window)
            }
        }
    }

    private func applyWindowTitles(_ window: NSWindow) {
        switch store.resolvedSidebar {
        case .overview:
            window.title = "Usage"
            window.subtitle = ""
        case .provider(let key):
            window.title = store.provider(key)?.name ?? "Usage"
            window.subtitle = ""
        case .account(let providerKey, _):
            let provider = store.provider(providerKey)
            window.title = provider?.name ?? "Usage"
            window.subtitle =
                provider.flatMap { store.account(for: $0) }?.label ?? ""
        }
    }

    static func isSidebarKeyEquivalent(_ event: NSEvent) -> Bool {
        let commandModifiers: NSEvent.ModifierFlags = [.command, .control, .option, .shift]
        return event.type == .keyDown
            && (event.keyCode == 1
                || event.charactersIgnoringModifiers?.lowercased() == "s")
            && event.modifierFlags.intersection(commandModifiers) == [.command, .control]
    }

    /// Sidebar command title follows collapse state, like the incumbent;
    /// Scenario items check the live projection.
    func menuWillOpen(_ menu: NSMenu) {
        if menu.title == "Scenario" {
            for item in menu.items {
                if let name = item.representedObject as? String {
                    item.state = name == store.projection.scenario ? .on : .off
                }
            }
            return
        }
        guard menu.title == "View",
            let toggle = menu.items.first(where: {
                $0.action == #selector(NSSplitViewController.toggleSidebar(_:))
            })
        else { return }
        let collapsed = splitController?.splitViewItems.first?.isCollapsed == true
        toggle.title = collapsed ? "Show Sidebar" : "Hide Sidebar"
    }

    // MARK: Status items and popover
    private func installStatusItems() {
        reconcileStatusItems()
    }

    private func makeStatusItem(for key: String) {
        guard let provider = store.provider(key) else { return }
        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image =
                ProviderMarks.templateImage(forIconKey: provider.iconKey)
                ?? JackinBrandIdentity.templateMonogram()
            button.imagePosition = .imageLeading
            // System-minimum icon–title gap; default spacing leaves a
            // loose pad the dual-stack title makes obvious.
            button.imageHugsTitle = true
            button.toolTip = provider.name
            button.setAccessibilityLabel(provider.name)
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItems[key] = item
    }

    /// Status items follow the live projection: scenario swaps and accepted
    /// mutations (F15) add, remove, and relabel items without a relaunch.
    private func reconcileStatusItems() {
        withObservationTracking {
            let wanted = store.projection.statusRows
            for (key, item) in statusItems where !wanted.contains(key) {
                NSStatusBar.system.removeStatusItem(item)
                statusItems.removeValue(forKey: key)
            }
            for key in wanted where statusItems[key] == nil {
                makeStatusItem(for: key)
            }
            for (key, item) in statusItems {
                if let provider = store.provider(key) {
                    item.button?.attributedTitle = StatusItemRendering.title(
                        barLabel: store.statusPercent(provider) ?? "",
                        compactResetLabel: provider.compactResetLabel,
                        percentTint: store.statusTint(provider))
                }
            }
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.reconcileStatusItems()
            }
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard
            let event = NSApp.currentEvent,
            let key = statusItems.first(where: { $0.value.button == sender })?.key,
            let provider = store.provider(key)
        else { return }
        if event.type == .rightMouseUp {
            showStatusMenu(for: sender)
        } else {
            togglePopover(for: provider, from: sender)
        }
    }

    /// Right click opens an explicit transient menu; `.menu` stays nil so the
    /// primary click keeps sole ownership of the popover.
    private func showStatusMenu(for button: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(
            withTitle: "Open Usage Window", action: #selector(showUsage),
            keyEquivalent: "")
        menu.addItem(
            withTitle: store.chrome.refreshTitle, action: #selector(refreshNow),
            keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit jackin❯ desktop",
            action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        for item in menu.items { item.target = self }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4),
                   in: button)
    }

    private func togglePopover(for provider: ProtoProvider, from button: NSView) {
        if let popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
            return
        }
        // Multi-screen + activation: a status-item click does not make the
        // app active, and on secondary displays an inactive app's transient
        // popover can fail to present. Activate first, then make the popover
        // window key so it is the focused surface after the click.
        NSApp.activate(ignoringOtherApps: true)
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = PopoverView.contentSize
        popover.contentViewController = NSHostingController(
            rootView: wrap(
                PopoverView(
                    store: store, provider: provider,
                    onOpenUsage: { [weak self] in
                        guard let self else { return }
                        // Exact popover-to-Usage handoff: same provider/account.
                        if let account = store.account(for: provider),
                            provider.accounts.count > 1
                        {
                            store.navigate(
                                to: .account(provider: provider.key, account: account.key))
                        } else {
                            store.navigate(to: .provider(provider.key))
                        }
                        popover.performClose(nil)
                        self.popover = nil
                        showUsage()
                    })))
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        self.popover = popover
    }

    // MARK: Actions

    @objc func showUsage() {
        guard let window = usageWindow else { return }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func refreshNow() {
        store.refresh()
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            // Incumbent chrome: unified toolbar, visible title, miniaturizable,
            // autosaved frame; SwiftUI content carries only a min size.
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false)
            window.title = "Settings"
            window.isReleasedWhenClosed = false
            window.toolbarStyle = .unified
            window.titlebarAppearsTransparent = false
            window.titleVisibility = .visible
            window.contentViewController = NSHostingController(
                rootView: wrap(SettingsView(store: store))
                    .frame(minWidth: 440, minHeight: 400))
            window.center()
            window.setFrameAutosaveName("jackin.desktop.settings-window")
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

/// AppKit rendering for one per-provider `NSStatusItem`. Dual stack: compact
/// reset countdown (top, secondary) + glance % (bottom, state-tinted like the
/// window meters: phosphor healthy, orange warning, red danger/depleted).
/// All colors are dynamic — the menu bar's light/dark adaptation is preserved.
/// Vertical fit is measured: two 9pt line fragments, baseline offsets
/// −0.5 / −3.5 — raster-verified so the text ink center matches the icon ink
/// center in the 22pt bar.
enum StatusItemRendering {
    static func title(
        barLabel: String, compactResetLabel: String?,
        percentTint: NSColor
    ) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.maximumLineHeight = 9
        paragraph.minimumLineHeight = 9
        paragraph.lineSpacing = 0

        let bottomFont = NSFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .semibold)
        let topFont = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .semibold)

        guard let compactResetLabel, !compactResetLabel.isEmpty else {
            return NSAttributedString(
                string: barLabel,
                attributes: [
                    .font: bottomFont,
                    .foregroundColor: percentTint,
                    .paragraphStyle: paragraph,
                ])
        }

        // Measured against the rendered button: the multi-line title block
        // draws top-aligned, ~2.5pt above the icon's center. A −2.5pt global
        // shift with a 3pt spread (top −0.5, bottom −3.5) lands the text ink
        // mid exactly on the icon ink mid (raster-verified, both lines).
        let result = NSMutableAttributedString()
        result.append(
            NSAttributedString(
                string: compactResetLabel + "\n",
                attributes: [
                    .font: topFont,
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .paragraphStyle: paragraph,
                    .baselineOffset: -0.5,
                ]))
        result.append(
            NSAttributedString(
                string: barLabel,
                attributes: [
                    .font: bottomFont,
                    .foregroundColor: percentTint,
                    .paragraphStyle: paragraph,
                    .baselineOffset: -3.5,
                ]))
        return result
    }
}

/// Standard AppKit toolbar identifiers keep the system toggle in one stable
/// leading slot; the label follows collapse state while the width stays put.
@MainActor
final class UsageWindowToolbar: NSObject, NSToolbarDelegate {
    static let identifier = NSToolbar.Identifier("usage.window-toolbar")
    static let refreshIdentifier = NSToolbarItem.Identifier("usage.refresh")
    private weak var sidebarItem: NSSplitViewItem?
    private weak var toolbar: NSToolbar?
    private let refreshView: NSView
    private let refreshTitle: String
    private var sidebarObservation: NSKeyValueObservation?
    private var sidebarToggleWidthConstraint: NSLayoutConstraint?

    init(sidebarItem: NSSplitViewItem, refreshView: NSView, refreshTitle: String) {
        self.sidebarItem = sidebarItem
        self.refreshView = refreshView
        self.refreshTitle = refreshTitle
        super.init()
        sidebarObservation = sidebarItem.observe(\.isCollapsed, options: [.initial, .new]) {
            [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateSidebarItemLabel()
            }
        }
    }

    func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: Self.identifier)
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        return toolbar
    }

    func installStandardItems(in toolbar: NSToolbar) {
        self.toolbar = toolbar
        toolbar.itemIdentifiers = [
            .toggleSidebar, .sidebarTrackingSeparator, .flexibleSpace, Self.refreshIdentifier,
        ]
        updateSidebarItemLabel()
        lockSidebarToggleWidth()
        DispatchQueue.main.async { [weak self] in
            self?.updateSidebarItemLabel()
            self?.lockSidebarToggleWidth()
        }
    }

    func toolbar(
        _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard itemIdentifier == Self.refreshIdentifier else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.view = refreshView
        item.label = refreshTitle
        item.paletteLabel = refreshTitle
        item.toolTip = refreshTitle
        item.visibilityPriority = .high
        return item
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, Self.refreshIdentifier]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, .flexibleSpace, Self.refreshIdentifier]
    }

    private func updateSidebarItemLabel() {
        guard let toolbar, let sidebarItem else { return }
        let label = sidebarItem.isCollapsed ? "Show Sidebar" : "Hide Sidebar"
        guard let item = toolbar.items.first(where: { $0.itemIdentifier == .toggleSidebar })
        else { return }
        item.label = label
        item.paletteLabel = label
        item.toolTip = label
        item.view?.setAccessibilityLabel(label)
        item.view?.setAccessibilityHelp(label)
    }

    private func lockSidebarToggleWidth() {
        guard sidebarToggleWidthConstraint == nil,
            let item = toolbar?.items.first(where: { $0.itemIdentifier == .toggleSidebar }),
            let view = item.view
        else { return }
        view.layoutSubtreeIfNeeded()
        let nativeWidth = view.frame.width > 0 ? view.frame.width : 44
        let constraint = view.widthAnchor.constraint(equalToConstant: nativeWidth)
        constraint.isActive = true
        sidebarToggleWidthConstraint = constraint
    }
}
