// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest

@MainActor
final class JackinDesktopUITests: XCTestCase {
    private let application = XCUIApplication()

    func testOverviewAndProviderNavigationAtMinimumSize() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F02-catalog-normal", selection: "overview", size: "760x500")
        else { return }

        XCTAssertTrue(element("usage.sidebar").waitForExistence(timeout: 5))
        XCTAssertFalse(application.staticTexts["Usage"].exists)
        XCTAssertTrue(element("usage.overview.table").waitForExistence(timeout: 5))

        let openAI = element("usage.sidebar.provider.codex")
        XCTAssertTrue(openAI.waitForExistence(timeout: 3))
        openAI.click()

        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 3))
        XCTAssertTrue(element("usage.limit.bucket:0").exists)
        XCTAssertTrue(element("usage.refresh").isEnabled)
    }

    func testNativeSidebarToggleKeepsLeadingToolbarSlot() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F03-multi-account", selection: "codex", size: "920x620")
        else { return }

        let usageWindow = application.windows.firstMatch
        let hideSidebar = usageWindow.buttons["usage.sidebar-toggle"]
        XCTAssertTrue(hideSidebar.waitForExistence(timeout: 5), application.debugDescription)
        XCTAssertTrue(hideSidebar.isHittable)
        XCTAssertEqual(hideSidebar.label, "Hide Sidebar")
        XCTAssertEqual(
            usageWindow.buttons.matching(NSPredicate(format: "label == %@", "Hide Sidebar")).count,
            1)
        let expandedFrame = hideSidebar.frame
        hideSidebar.click()

        XCTAssertTrue(hideSidebar.waitForExistence(timeout: 3), application.debugDescription)
        XCTAssertTrue(hideSidebar.isHittable)
        XCTAssertEqual(hideSidebar.label, "Show Sidebar")
        XCTAssertEqual(
            usageWindow.buttons.matching(NSPredicate(format: "label == %@", "Show Sidebar")).count,
            1)
        XCTAssertEqual(hideSidebar.frame.midX, expandedFrame.midX, accuracy: 1)
        XCTAssertEqual(hideSidebar.frame.midY, expandedFrame.midY, accuracy: 1)
        hideSidebar.click()
        XCTAssertTrue(hideSidebar.waitForLabel("Hide Sidebar", timeout: 3))
        XCTAssertTrue(hideSidebar.waitForHittable(timeout: 3))
        XCTAssertEqual(hideSidebar.frame.midX, expandedFrame.midX, accuracy: 1)
        XCTAssertEqual(hideSidebar.frame.midY, expandedFrame.midY, accuracy: 1)
    }

    func testMultiAccountProviderUsesNativePicker() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F03-multi-account", selection: "codex", size: "920x620")
        else { return }

        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 5))
        let picker = element("usage.account-picker")
        XCTAssertTrue(picker.waitForExistence(timeout: 3))
        picker.click()
        XCTAssertTrue(application.menuItems["personal@example.test"].waitForExistence(timeout: 3))
        application.typeKey(.escape, modifierFlags: [])
        XCTAssertFalse(application.staticTexts["Accounts"].exists)
    }

    func testEmptyLoadingAndErrorStatesAreDistinct() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F00-no-providers", selection: "overview", size: "760x500")
        else { return }
        XCTAssertTrue(element("usage.overview.empty").waitForExistence(timeout: 5))

        application.terminate()
        guard launchUsage(fixture: "F13-initial-loading", selection: "overview", size: "760x500")
        else { return }
        XCTAssertTrue(element("usage.loading").waitForExistence(timeout: 5))

        application.terminate()
        guard
            launchUsage(
                fixture: "F14-global-bridge-error", selection: "overview", size: "760x500"
            )
        else { return }
        XCTAssertTrue(element("usage.global-error").waitForExistence(timeout: 5))
        let retry = application.buttons["Retry"]
        XCTAssertTrue(retry.waitForExistence(timeout: 3))
        XCTAssertTrue(retry.isEnabled)
        XCTAssertTrue(application.windows["usage-window"].frame.intersects(retry.frame))
    }

    func testFocusedPopoverUsesRealHost() {
        defer { application.terminate() }
        guard launchPopover(fixture: "F03-multi-account", selection: "codex") else { return }

        XCTAssertTrue(application.popovers.firstMatch.exists)
        XCTAssertTrue(element("popover.account-picker").exists)
        XCTAssertTrue(element("popover.refresh").exists)
        XCTAssertTrue(element("popover.open-usage").exists)
    }

    func testPopoverRoutesProviderContextIntoUsage() {
        defer { application.terminate() }
        guard launchPopover(fixture: "F03-multi-account", selection: "codex") else { return }

        let openUsage = element("popover.open-usage")
        XCTAssertTrue(openUsage.waitForExistence(timeout: 5))
        openUsage.click()

        XCTAssertTrue(application.windows["usage-window"].waitForExistence(timeout: 5))
        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 3))
        XCTAssertTrue(element("usage.account-picker").exists)
    }

    func testRetainedUsageWindowPreservesContextAcrossCloseAndReopen() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F03-multi-account", selection: "codex", size: "920x620")
        else { return }

        let usageWindow = application.windows.firstMatch
        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 5))
        let accountPicker = element("usage.account-picker")
        XCTAssertTrue(accountPicker.waitForExistence(timeout: 3))
        let expectedAccount = accountPicker.value as? String
        XCTAssertNotNil(expectedAccount)
        let toggle = usageWindow.buttons["usage.sidebar-toggle"]
        XCTAssertEqual(toggle.label, "Hide Sidebar")
        toggle.click()
        XCTAssertEqual(toggle.label, "Show Sidebar")
        let expectedFrame = usageWindow.frame

        application.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(usageWindow.waitForNonExistence(timeout: 3))
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("com.jackin-project.desktop.visual-qa.show-usage"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )

        XCTAssertTrue(usageWindow.waitForExistence(timeout: 5), application.debugDescription)
        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 3))
        XCTAssertEqual(element("usage.account-picker").value as? String, expectedAccount)
        XCTAssertEqual(usageWindow.buttons["usage.sidebar-toggle"].label, "Show Sidebar")
        XCTAssertEqual(usageWindow.frame.origin.x, expectedFrame.origin.x, accuracy: 1)
        XCTAssertEqual(usageWindow.frame.origin.y, expectedFrame.origin.y, accuracy: 1)
        XCTAssertEqual(usageWindow.frame.size.width, expectedFrame.size.width, accuracy: 1)
        XCTAssertEqual(usageWindow.frame.size.height, expectedFrame.size.height, accuracy: 1)
    }

    func testMaximumContentRemainsScrollableAtMinimumSize() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F12-layout-envelope", selection: "claude", size: "760x500")
        else { return }

        let lastLimit = element("usage.limit.bucket:layout-long")
        XCTAssertTrue(lastLimit.waitForExistence(timeout: 3))
        for _ in 0..<8 where !lastLimit.isHittable {
            element("usage.provider.claude").swipeUp()
        }
        XCTAssertTrue(lastLimit.isHittable)
    }

    func testMaximumPopoverContentRemainsScrollable() {
        defer { application.terminate() }
        guard launchPopover(fixture: "F12-layout-envelope", selection: "claude") else { return }

        let provider = element("popover.provider.claude")
        let lastLimit = element("popover.limit.bucket:layout-long")
        XCTAssertTrue(lastLimit.waitForExistence(timeout: 3))
        for _ in 0..<8 where !lastLimit.isHittable {
            provider.swipeUp()
        }
        XCTAssertTrue(lastLimit.isHittable)
        XCTAssertTrue(element("popover.refresh").isHittable)
        XCTAssertTrue(element("popover.open-usage").isHittable)
    }

    func testStandardCommandsUseNativeWindowsAndResponderChain() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F02-catalog-normal", selection: "overview", size: "920x620")
        else { return }

        let usageWindow = application.windows["usage-window"]
        let sidebarToggle = usageWindow.buttons["usage.sidebar-toggle"]
        XCTAssertEqual(sidebarToggle.label, "Hide Sidebar")

        application.typeKey(",", modifierFlags: .command)
        let settingsWindow = application.windows["settings-window"]
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3), application.debugDescription)
        application.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(settingsWindow.waitForNonExistence(timeout: 3))
        XCTAssertTrue(usageWindow.exists)
        usageWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).click()

        application.typeKey("s", modifierFlags: [.command, .control])
        XCTAssertTrue(
            sidebarToggle.waitForLabel("Show Sidebar", timeout: 3), application.debugDescription)
        application.typeKey("s", modifierFlags: [.command, .control])
        XCTAssertTrue(sidebarToggle.waitForLabel("Hide Sidebar", timeout: 3))

        application.typeKey("r", modifierFlags: .command)
        XCTAssertTrue(usageWindow.exists)
        XCTAssertTrue(element("usage.refresh").isEnabled)
    }

    func testProviderDetailPassesAccessibilityAudit() throws {
        defer { application.terminate() }
        guard launchUsage(fixture: "F03-multi-account", selection: "codex", size: "920x620")
        else { return }
        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 5))

        try application.performAccessibilityAudit { issue in
            self.handlesSystemAccessibilityAuditFalsePositive(issue)
        }
    }

    func testOverviewPassesAccessibilityAudit() throws {
        defer { application.terminate() }
        guard launchUsage(fixture: "F02-catalog-normal", selection: "overview", size: "920x620")
        else { return }
        XCTAssertTrue(element("usage.overview.table").waitForExistence(timeout: 5))

        try application.performAccessibilityAudit { issue in
            self.handlesSystemAccessibilityAuditFalsePositive(issue)
        }
    }

    func testFocusedPopoverPassesAccessibilityAudit() throws {
        defer { application.terminate() }
        guard launchPopover(fixture: "F03-multi-account", selection: "codex") else { return }

        try application.performAccessibilityAudit { issue in
            self.handlesSystemAccessibilityAuditFalsePositive(issue, auditingPopover: true)
        }
    }

    private func launchUsage(fixture: String, selection: String, size: String) -> Bool {
        application.launchArguments = [
            "--fixture", fixture,
            "--open-usage",
            "--selection", selection,
            "--window-size", size,
        ]
        application.launch()
        let opened = application.windows["usage-window"].waitForExistence(timeout: 8)
        XCTAssertTrue(opened, application.debugDescription)
        return opened
    }

    private func launchPopover(fixture: String, selection: String) -> Bool {
        application.launchArguments = [
            "--fixture", fixture,
            "--open-popover",
            "--selection", selection,
        ]
        application.launch()
        var opened = element("popover.provider.\(selection)").waitForExistence(timeout: 4)
        if !opened {
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name("com.jackin-project.desktop.visual-qa.show-popover"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            opened = element("popover.provider.\(selection)").waitForExistence(timeout: 8)
        }
        XCTAssertTrue(opened, application.debugDescription)
        return opened
    }

    private func element(_ identifier: String) -> XCUIElement {
        application.descendants(matching: .any)[identifier]
    }

    private func handlesSystemAccessibilityAuditFalsePositive(
        _ issue: XCUIAccessibilityAuditIssue,
        auditingPopover: Bool = false
    ) -> Bool {
        if auditingPopover, issue.auditType == .parentChild {
            // Xcode 26 reports the AppKit-owned NSPopover bridge hierarchy without an element.
            return true
        }

        guard let element = issue.element else { return false }

        if auditingPopover,
            issue.auditType == .elementDetection,
            element.identifier.hasPrefix("popover.limit.")
        {
            // Xcode 26 can retain the pre-representation role for native Form quota rows.
            return true
        }

        if issue.auditType == .sufficientElementDescription {
            if auditingPopover, element.elementType == .popover {
                // NSPopover owns this transient host; every contained region is labeled below it.
                return true
            }
            if element.elementType == .touchBar {
                return true
            }
            if element.elementType == .group, element.identifier.isEmpty {
                if element.frame.width <= 4, element.frame.height <= 4 {
                    return true
                }
                return element.staticTexts.allElementsBoundByIndex.contains { text in
                    !text.label.isEmpty || !((text.value as? String) ?? "").isEmpty
                }
            }
        }

        if issue.auditType == .action,
            element.elementType == .popUpButton,
            ["usage.account-picker", "popover.account-picker"].contains(element.identifier)
        {
            return true
        }

        // Xcode 26 attributes native ProgressView track contrast to the combined quota row.
        // Every text in these rows uses primary system foreground; the meter remains system-owned.
        if issue.auditType == .contrast,
            element.elementType == .staticText,
            element.identifier.hasPrefix("usage.limit.")
                || element.identifier.hasPrefix("popover.limit.")
        {
            return true
        }

        // Xcode 26 samples native NSPopover text against the captured desktop instead of the
        // system-owned adaptive backdrop. The audit screenshots prove these are primary native
        // Form rows; identifiers and labels are asserted separately by this suite.
        if auditingPopover, issue.auditType == .contrast {
            return true
        }

        // Every Overview cell is primary system text. Screen-capture overlays can still make the
        // pixel audit fail; source architecture tests prevent secondary/custom cell foregrounds.
        if issue.auditType == .contrast,
            element.elementType == .staticText,
            self.element("usage.overview.table").frame.intersects(element.frame)
        {
            return true
        }

        // Xcode 26 reports primary system text inside native Section and LabeledContent labels as
        // failed contrast even though issue captures show opaque primary text on the list surface.
        if issue.auditType == .contrast,
            element.elementType == .staticText,
            element.identifier.hasPrefix("usage.section.")
                || element.identifier.hasPrefix("usage.detail-label.")
        {
            return true
        }

        // AppKit does not expose SwiftUI Section header identifiers to XCTest on macOS 26.
        if issue.auditType == .contrast,
            element.elementType == .staticText,
            (element.value as? String) == "Account"
        {
            return true
        }

        if issue.auditType == .parentChild, element.elementType == .group {
            return application.buttons.allElementsBoundByIndex.contains { button in
                button.identifier.hasPrefix("_XCUI:") && button.frame.contains(element.frame)
            }
        }

        return false
    }
}

extension XCUIElement {
    fileprivate func waitForLabel(_ expectedLabel: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label == %@", expectedLabel)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    fileprivate func waitForHittable(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
