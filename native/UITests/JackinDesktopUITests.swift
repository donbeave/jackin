// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest

@MainActor
final class JackinDesktopUITests: XCTestCase {
    private let application = XCUIApplication()

    func testOverviewAndProviderNavigationAtMinimumSize() {
        defer { application.terminate() }
        launchUsage(fixture: "F02-catalog-normal", selection: "overview", size: "760x500")

        XCTAssertTrue(element("usage.sidebar").waitForExistence(timeout: 5))
        XCTAssertTrue(element("usage.overview.table").waitForExistence(timeout: 5))

        let openAI = element("usage.sidebar.provider.codex")
        XCTAssertTrue(openAI.waitForExistence(timeout: 3))
        openAI.click()

        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 3))
        XCTAssertTrue(element("usage.limit.bucket:0").exists)
        XCTAssertTrue(element("usage.refresh").isEnabled)
    }

    func testMultiAccountProviderUsesNativePicker() {
        defer { application.terminate() }
        launchUsage(fixture: "F03-multi-account", selection: "codex", size: "920x620")

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
        launchUsage(fixture: "F00-no-providers", selection: "overview", size: "760x500")
        XCTAssertTrue(element("usage.overview.empty").waitForExistence(timeout: 5))

        application.terminate()
        launchUsage(fixture: "F13-initial-loading", selection: "overview", size: "760x500")
        XCTAssertTrue(element("usage.loading").waitForExistence(timeout: 5))

        application.terminate()
        launchUsage(fixture: "F14-global-bridge-error", selection: "overview", size: "760x500")
        XCTAssertTrue(element("usage.global-error").waitForExistence(timeout: 5))
    }

    func testFocusedPopoverUsesRealHost() {
        defer { application.terminate() }
        application.launchArguments = [
            "--fixture", "F03-multi-account",
            "--open-popover",
            "--selection", "codex",
        ]
        application.launch()
        application.activate()

        XCTAssertTrue(
            element("popover.provider.codex").waitForExistence(timeout: 5),
            application.debugDescription
        )
        XCTAssertTrue(application.popovers.firstMatch.exists)
        XCTAssertTrue(element("popover.account-picker").exists)
        XCTAssertTrue(element("popover.refresh").exists)
        XCTAssertTrue(element("popover.open-usage").exists)
    }

    func testProviderDetailPassesAccessibilityAudit() throws {
        defer { application.terminate() }
        launchUsage(fixture: "F03-multi-account", selection: "codex", size: "920x620")
        XCTAssertTrue(element("usage.provider.codex").waitForExistence(timeout: 5))

        try application.performAccessibilityAudit { issue in
            self.handlesSystemAccessibilityAuditFalsePositive(issue)
        }
    }

    private func launchUsage(fixture: String, selection: String, size: String) {
        application.launchArguments = [
            "--fixture", fixture,
            "--open-usage",
            "--selection", selection,
            "--window-size", size,
        ]
        application.launch()
        XCTAssertTrue(application.windows["jackin❯ desktop"].waitForExistence(timeout: 5))
    }

    private func element(_ identifier: String) -> XCUIElement {
        application.descendants(matching: .any)[identifier]
    }

    private func handlesSystemAccessibilityAuditFalsePositive(
        _ issue: XCUIAccessibilityAuditIssue
    ) -> Bool {
        guard let element = issue.element else { return false }

        if issue.auditType == .sufficientElementDescription {
            if element.elementType == .touchBar {
                return true
            }
            if element.elementType == .group, element.identifier.isEmpty {
                return element.staticTexts.allElementsBoundByIndex.contains { text in
                    !text.label.isEmpty || !((text.value as? String) ?? "").isEmpty
                }
            }
        }

        if issue.auditType == .action,
            element.elementType == .popUpButton,
            element.identifier == "usage.account-picker"
        {
            return true
        }

        // Xcode 26 attributes native ProgressView track contrast to the combined quota row.
        // Every text in these rows uses primary system foreground; the meter remains system-owned.
        if issue.auditType == .contrast,
            element.elementType == .staticText,
            element.identifier.hasPrefix("usage.limit.")
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
