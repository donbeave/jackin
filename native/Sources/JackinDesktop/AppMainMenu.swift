// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

/// System **menu bar** for jackin❯ desktop when a document window is front
/// (Usage / Settings).
///
/// Accessory status-item mode has no app menu chrome;
/// switching to `.regular` reveals  + these menus.
///
/// Standard macOS menu citizenship for the Usage window.
@MainActor
public final class AppMainMenu: NSObject {
    private let store: PresentationStore
    private let openUsage: () -> Void
    private var settingsWindow: NSWindow?
    /// Strong: `NSWindow.delegate` is weak.
    private var settingsCloseProxy: SettingsWindowCloseProxy?

    init(store: PresentationStore, openUsage: @escaping () -> Void) {
        self.store = store
        self.openUsage = openUsage
        super.init()
    }

    /// Install once at launch; becomes visible when activation policy is `.regular`.
    func install() {
        let main = NSMenu()

        main.addItem(wrap(appMenu(), title: appMenuTitle))
        main.addItem(wrap(fileMenu(), title: "File"))
        main.addItem(wrap(editMenu(), title: "Edit"))
        main.addItem(wrap(viewMenu(), title: "View"))
        let window = windowMenu()
        main.addItem(wrap(window, title: "Window"))
        main.addItem(wrap(helpMenu(), title: "Help"))
        NSApp.windowsMenu = window

        NSApp.mainMenu = main
    }

    // MARK: - Menus

    private var appMenuTitle: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? "jackin❯ desktop"
    }

    private func appMenu() -> NSMenu {
        let menu = NSMenu(title: appMenuTitle)

        menu.addItem(owned("About \(appMenuTitle)", #selector(orderFrontAbout(_:)), key: ""))
        menu.addItem(.separator())
        menu.addItem(owned("Settings…", #selector(openSettings(_:)), key: ","))
        menu.addItem(.separator())
        let services = NSMenu(title: "Services")
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        servicesItem.submenu = services
        menu.addItem(servicesItem)
        NSApp.servicesMenu = services
        menu.addItem(.separator())
        menu.addItem(
            routed(
                "Hide \(appMenuTitle)", #selector(NSApplication.hide(_:)), key: "h", target: NSApp))
        menu.addItem(
            routed(
                "Hide Others",
                #selector(NSApplication.hideOtherApplications(_:)),
                key: "h",
                modifiers: [.command, .option],
                target: NSApp
            )
        )
        menu.addItem(
            routed(
                "Show All",
                #selector(NSApplication.unhideAllApplications(_:)),
                key: "",
                target: NSApp
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            routed(
                "Quit \(appMenuTitle)",
                #selector(NSApplication.terminate(_:)),
                key: "q",
                target: NSApp
            )
        )
        return menu
    }

    private func fileMenu() -> NSMenu {
        let menu = NSMenu(title: "File")
        menu.addItem(firstResponder("Close Window", #selector(NSWindow.performClose(_:)), key: "w"))
        return menu
    }

    private func editMenu() -> NSMenu {
        // Target nil → first-responder chain (standard macOS Edit menu).
        let menu = NSMenu(title: "Edit")
        menu.addItem(firstResponder("Undo", Selector(("undo:")), key: "z"))
        menu.addItem(
            firstResponder(
                "Redo",
                Selector(("redo:")),
                key: "z",
                modifiers: [.command, .shift]
            )
        )
        menu.addItem(.separator())
        menu.addItem(firstResponder("Cut", #selector(NSText.cut(_:)), key: "x"))
        menu.addItem(firstResponder("Copy", #selector(NSText.copy(_:)), key: "c"))
        menu.addItem(firstResponder("Paste", #selector(NSText.paste(_:)), key: "v"))
        menu.addItem(firstResponder("Select All", #selector(NSText.selectAll(_:)), key: "a"))
        return menu
    }

    private func viewMenu() -> NSMenu {
        let menu = NSMenu(title: "View")
        menu.addItem(
            firstResponder(
                "Toggle Sidebar",
                #selector(NSSplitViewController.toggleSidebar(_:)),
                key: "s",
                modifiers: [.command, .control]
            )
        )
        menu.addItem(.separator())
        menu.addItem(owned("Refresh", #selector(refreshAll(_:)), key: "r"))
        return menu
    }

    private func windowMenu() -> NSMenu {
        let menu = NSMenu(title: "Window")
        menu.addItem(
            firstResponder("Minimize", #selector(NSWindow.performMiniaturize(_:)), key: "m"))
        menu.addItem(firstResponder("Zoom", #selector(NSWindow.performZoom(_:)), key: ""))
        menu.addItem(.separator())
        let usage = owned("Usage", #selector(showUsageWindow(_:)), key: "0")
        usage.identifier = NSUserInterfaceItemIdentifier("menu.show-usage")
        menu.addItem(usage)
        menu.addItem(.separator())
        menu.addItem(
            routed(
                "Bring All to Front",
                #selector(NSApplication.arrangeInFront(_:)),
                key: "",
                target: NSApp
            )
        )
        return menu
    }

    private func helpMenu() -> NSMenu {
        let menu = NSMenu(title: "Help")
        menu.addItem(
            routed(
                "jackin❯ desktop Help",
                #selector(NSApplication.showHelp(_:)),
                key: "?",
                target: NSApp
            )
        )
        return menu
    }

    // MARK: - Actions

    @objc private func orderFrontAbout(_: Any?) {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: appMenuTitle,
            .credits: NSAttributedString(
                string: "Limits-only usage for agent credentials.\nDisplay shell over jackin-usage."
            ),
        ])
    }

    @objc private func openSettings(_: Any?) {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            AppActivation.presentWindows()
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("settings-window")
        window.setAccessibilityIdentifier("settings-window")
        window.toolbarStyle = .unified
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        let proxy = SettingsWindowCloseProxy { [weak self] in
            self?.settingsWindow = nil
            self?.settingsCloseProxy = nil
            AppActivation.resignToAccessoryIfNeeded()
        }
        settingsCloseProxy = proxy
        window.delegate = proxy
        // Hosting controller so any future SwiftUI toolbar attaches as NSToolbar.
        window.contentViewController = NSHostingController(
            rootView: SettingsView(store: store)
                .frame(minWidth: 440, minHeight: 400)
        )
        window.center()
        window.setFrameAutosaveName("jackin.desktop.settings-window")
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        AppActivation.presentWindows()
    }

    @objc private func refreshAll(_: Any?) {
        store.refreshAll()
    }

    @objc private func showUsageWindow(_: Any?) {
        openUsage()
    }

    // MARK: - Helpers

    private func wrap(_ menu: NSMenu, title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    /// Action handled by this controller.
    private func owned(
        _ title: String,
        _ action: Selector,
        key: String,
        modifiers: NSEvent.ModifierFlags = [.command]
    ) -> NSMenuItem {
        makeItem(title, action: action, key: key, modifiers: modifiers, target: self)
    }

    /// Action on a fixed object (usually `NSApp`).
    private func routed(
        _ title: String,
        _ action: Selector,
        key: String,
        modifiers: NSEvent.ModifierFlags = [.command],
        target: AnyObject
    ) -> NSMenuItem {
        makeItem(title, action: action, key: key, modifiers: modifiers, target: target)
    }

    /// First-responder chain (Edit / window chrome).
    private func firstResponder(
        _ title: String,
        _ action: Selector,
        key: String,
        modifiers: NSEvent.ModifierFlags = [.command]
    ) -> NSMenuItem {
        makeItem(title, action: action, key: key, modifiers: modifiers, target: nil)
    }

    private func makeItem(
        _ title: String,
        action: Selector,
        key: String,
        modifiers: NSEvent.ModifierFlags,
        target: AnyObject?
    ) -> NSMenuItem {
        let row = NSMenuItem(title: title, action: action, keyEquivalent: key)
        if !key.isEmpty {
            row.keyEquivalentModifierMask = modifiers
        }
        row.target = target
        return row
    }
}

/// Clears Settings window ownership and resigns accessory when Settings closes.
@MainActor
private final class SettingsWindowCloseProxy: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }

    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async { [onClose] in
            onClose()
        }
    }
}

/// Activation policy bridge: accessory (status bar only) ↔ regular (menu bar + Dock).
@MainActor
public enum AppActivation {
    /// Show system menu bar ( + app menus) and allow Dock focus while windows are open.
    static func presentWindows() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Back to menu-bar agent when no app windows remain visible.
    static func resignToAccessoryIfNeeded() {
        let visible = NSApp.windows.contains { window in
            window.isVisible
                && !window.isSheet
                && window.styleMask.contains(.titled)
        }
        if !visible, NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
