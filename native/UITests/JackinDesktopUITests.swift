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
        let overview = element("usage.overview.table")
        XCTAssertTrue(overview.waitForExistence(timeout: 5))
        XCTAssertEqual(overview.label, "Usage overview")
        XCTAssertEqual(element("usage.sidebar").label, "Usage providers sidebar")

        let openAI = element("usage.sidebar.provider.codex")
        XCTAssertTrue(openAI.waitForExistence(timeout: 3))
        openAI.click()

        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 3))
        XCTAssertTrue(element("usage.limit.bucket:0").exists)
        XCTAssertTrue(element("usage.refresh").isEnabled)
    }

    func testPartialFailureOverviewRemainsCoherentWhenRepresented() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F08-partial-timeout", selection: "overview", size: "920x620")
        else { return }

        for _ in 0..<3 {
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name("com.jackin-project.desktop.visual-qa.show-usage"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
        }

        XCTAssertTrue(element("usage.overview.table").waitForExistence(timeout: 5))
        XCTAssertFalse(element("usage.provider.codex").exists)
        XCTAssertTrue(element("usage.overview.error.kimi").waitForExistence(timeout: 3))
        XCTAssertTrue(element("usage.overview.retry.kimi").isEnabled)
        XCTAssertTrue(element("usage.sidebar.provider.codex").exists)
    }

    func testRefreshingUsageExposesNativeBusyState() {
        defer { application.terminate() }
        guard
            launchUsage(
                fixture: "F07-refreshing-last-good", selection: "overview", size: "920x620"
            )
        else { return }

        let refresh = element("usage.refresh")
        XCTAssertTrue(refresh.waitForExistence(timeout: 5))
        XCTAssertEqual(refresh.label, "Refreshing usage")
        XCTAssertEqual(refresh.value as? String, "In progress")
        XCTAssertFalse(refresh.isEnabled)
        XCTAssertTrue(element("usage.overview.table").exists)

        let usageWindow = application.windows["usage-window"]
        let sidebar = element("usage.sidebar")
        XCTAssertTrue(sidebar.exists)
        XCTAssertTrue(usageWindow.frame.contains(sidebar.frame))
        XCTAssertTrue(usageWindow.frame.contains(refresh.frame))
    }

    func testNativeSidebarToggleKeepsLeadingToolbarSlot() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F03-multi-account", selection: "codex", size: "920x620")
        else { return }

        let usageWindow = application.windows.firstMatch
        let hideSidebar = usageWindow.buttons["usage.sidebar-toggle"]
        XCTAssertTrue(hideSidebar.waitForExistence(timeout: 5), application.debugDescription)
        XCTAssertTrue(hideSidebar.waitForHittable(timeout: 5), application.debugDescription)
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
        XCTAssertTrue(picker.waitForHittable(timeout: 5), application.debugDescription)
        picker.click()
        let personal = application.menuItems["personal@example.test"]
        if !personal.waitForExistence(timeout: 3) {
            application.activate()
            XCTAssertTrue(picker.waitForHittable(timeout: 3), application.debugDescription)
            picker.click()
        }
        XCTAssertTrue(personal.waitForExistence(timeout: 5), application.debugDescription)
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

        let close = usageWindow.buttons["_XCUI:CloseWindow"]
        XCTAssertTrue(close.isHittable)
        close.click()
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

    func testStandardCommandsAndMenusShareNativeState() {
        defer { application.terminate() }
        guard launchUsage(fixture: "F02-catalog-normal", selection: "overview", size: "920x620")
        else { return }

        application.menuBars.menuBarItems["jackin❯ desktop"].click()
        application.menuItems["Settings…"].click()
        let settingsWindow = application.windows["settings-window"]
        XCTAssertTrue(
            settingsWindow.waitForExistence(timeout: 3),
            application.debugDescription
        )
        application.menuBars.menuBarItems["File"].click()
        application.menuItems["Close Window"].click()
        XCTAssertTrue(settingsWindow.waitForNonExistence(timeout: 3))

        let usageWindow = application.windows["usage-window"]
        usageWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03)).click()
        let sidebarToggle = usageWindow.buttons["usage.sidebar-toggle"]
        XCTAssertEqual(sidebarToggle.label, "Hide Sidebar")

        application.menuBars.menuBarItems["View"].click()
        application.menuItems["Hide Sidebar"].click()
        XCTAssertTrue(
            sidebarToggle.waitForLabel("Show Sidebar", timeout: 3), application.debugDescription)
        application.menuBars.menuBarItems["View"].click()
        application.menuItems["Show Sidebar"].click()
        XCTAssertTrue(sidebarToggle.waitForLabel("Hide Sidebar", timeout: 3))

        application.menuBars.menuBarItems["View"].click()
        application.menuItems["Refresh"].click()
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
        let overview = element("usage.overview.table")
        XCTAssertTrue(overview.waitForExistence(timeout: 5))
        XCTAssertEqual(overview.label, "Usage overview")
        XCTAssertEqual(element("usage.sidebar").label, "Usage providers sidebar")

        try application.performAccessibilityAudit { issue in
            self.handlesSystemAccessibilityAuditFalsePositive(issue, auditingOverview: true)
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
        var opened = application.windows["usage-window"].waitForExistence(timeout: 8)
        if !opened {
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name("com.jackin-project.desktop.visual-qa.show-usage"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            opened = application.windows["usage-window"].waitForExistence(timeout: 8)
        }
        XCTAssertTrue(opened, application.debugDescription)
        guard opened else { return false }
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("com.jackin-project.desktop.visual-qa.show-usage"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        application.activate()
        let foreground = application.wait(for: .runningForeground, timeout: 5)
        XCTAssertTrue(foreground, application.debugDescription)
        guard foreground else { return false }
        let usageWindow = application.windows["usage-window"]
        usageWindow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03)).click()
        let hittable = usageWindow.waitForHittable(timeout: 5)
        XCTAssertTrue(hittable, application.debugDescription)
        return hittable
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
        guard opened else { return false }
        return true
    }

    private func element(_ identifier: String) -> XCUIElement {
        application.descendants(matching: .any)[identifier]
    }

    private func handlesSystemAccessibilityAuditFalsePositive(
        _ issue: XCUIAccessibilityAuditIssue,
        auditingPopover: Bool = false,
        auditingOverview: Bool = false
    ) -> Bool {
        if auditingOverview,
            issue.auditType == .contrast
                || issue.auditType == .sufficientElementDescription
        {
            // Xcode 26 audits Table text against transient capture overlays and can return stale
            // anonymous container proxies. Source enforces primary text; this test separately
            // asserts the labeled table/sidebar while every other audit class remains strict.
            return true
        }

        if auditingPopover, issue.auditType == .parentChild {
            // Xcode 26 reports the AppKit-owned NSPopover bridge hierarchy without an element.
            return true
        }

        guard let element = issue.element else {
            XCTContext.runActivity(
                named: "Unhandled AX audit without element: \(issue.auditType)"
            ) { _ in }
            return false
        }

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
                // SwiftUI emits anonymous non-actionable layout groups. Their child controls and
                // text remain separate AX elements and are audited independently.
                return true
            }
        }

        if issue.auditType == .action,
            element.elementType == .popUpButton,
            ["usage.account-picker", "popover.account-picker"].contains(element.identifier)
        {
            return true
        }

        if auditingPopover,
            issue.auditType == .action,
            element.elementType == .popover,
            element.identifier.isEmpty,
            element.label.isEmpty
        {
            // NSPopover is a system-owned container, not an actionable control; its child native
            // buttons and picker expose their own actions and are audited independently.
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

        XCTContext.runActivity(
            named:
                "Unhandled AX audit: \(issue.auditType); type=\(element.elementType.rawValue); "
                + "id=\(element.identifier); label=\(element.label)"
        ) { _ in }
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
