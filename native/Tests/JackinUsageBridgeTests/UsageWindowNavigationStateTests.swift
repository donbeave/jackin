// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import XCTest

@testable import JackinDesktopUI

@MainActor
final class UsageWindowNavigationStateTests: XCTestCase {
    func testSidebarVisibilityHasOneToggleAuthority() {
        let state = UsageWindowNavigationState()

        XCTAssertTrue(state.isSidebarVisible)
        XCTAssertEqual(state.columnVisibility, .all)

        state.toggleSidebar()
        XCTAssertFalse(state.isSidebarVisible)
        XCTAssertEqual(state.columnVisibility, .detailOnly)

        state.toggleSidebar()
        XCTAssertTrue(state.isSidebarVisible)
        XCTAssertEqual(state.columnVisibility, .all)
    }

    func testNativeMenuValidationMirrorsSidebarAndKeyWindowState() {
        let store = PresentationStore()
        var sidebarVisible = true
        var canToggle = false
        let menu = AppMainMenu(
            store: store,
            openUsage: {},
            toggleUsageSidebar: {},
            isUsageSidebarVisible: { sidebarVisible },
            canToggleUsageSidebar: { canToggle }
        )
        let item = NSMenuItem(
            title: "",
            action: #selector(NSSplitViewController.toggleSidebar(_:)),
            keyEquivalent: "s"
        )

        XCTAssertFalse(menu.validateMenuItem(item))
        XCTAssertEqual(item.title, "Hide Sidebar")

        sidebarVisible = false
        canToggle = true
        XCTAssertTrue(menu.validateMenuItem(item))
        XCTAssertEqual(item.title, "Show Sidebar")
    }

    func testStandardMenuKeyEquivalents() {
        XCTAssertEqual(AppMainMenu.settingsKeyEquivalent, ",")
        XCTAssertEqual(AppMainMenu.settingsKeyModifiers, .command)
        XCTAssertEqual(AppMainMenu.closeKeyEquivalent, "w")
        XCTAssertEqual(AppMainMenu.closeKeyModifiers, .command)
        XCTAssertEqual(AppMainMenu.sidebarKeyEquivalent, "s")
        XCTAssertEqual(AppMainMenu.sidebarKeyModifiers, [.command, .control])
        XCTAssertEqual(AppMainMenu.refreshKeyEquivalent, "r")
        XCTAssertEqual(AppMainMenu.refreshKeyModifiers, .command)
    }
}
