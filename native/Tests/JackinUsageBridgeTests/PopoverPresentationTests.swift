// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest

@testable import JackinDesktopUI
@testable import JackinUsageBridge

final class PopoverPresentationTests: XCTestCase {
    private var popoverSource: String {
        get throws {
            let url = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Sources/JackinDesktop/PopoverRoot.swift")
            return try String(contentsOf: url, encoding: .utf8)
        }
    }

    func testPopoverOrderIsIdentityPickerLimitsDetails() throws {
        let source = try popoverSource
        let identity = try XCTUnwrap(source.range(of: "providerIdentity(provider)"))
        let picker = try XCTUnwrap(source.range(of: "if accounts.count > 1"))
        let limits = try XCTUnwrap(source.range(of: "if !limitRows.isEmpty"))
        let details = try XCTUnwrap(source.range(of: "if !metadataRows.isEmpty"))

        XCTAssertLessThan(identity.lowerBound, picker.lowerBound)
        XCTAssertLessThan(picker.lowerBound, limits.lowerBound)
        XCTAssertLessThan(limits.lowerBound, details.lowerBound)
    }

    @MainActor
    func testSingleAccountIdentityNeedsNoPicker() {
        let fixture = VisualQAFixtures.fixture(id: .singleNormal)
        XCTAssertEqual(fixture.accounts.count, 1)
        XCTAssertEqual(
            fixture.surfaces.first?.identity?.accountLabel,
            fixture.accounts.first?.accountLabel
        )
    }

    @MainActor
    func testExactAccountSelectionUpdatesIdentityAndUsageHandoff() {
        let fixture = VisualQAFixtures.fixture(id: .multiAccount)
        let store = PresentationStore()
        store.applyQIFixture(
            glanceRows: fixture.glanceRows,
            statusBarGlanceRows: fixture.statusGlanceRows,
            surfaces: fixture.surfaces,
            accounts: fixture.accounts,
            providerGroups: fixture.providerGroups,
            refreshingProjection: fixture.refreshingProjection,
            accountProjections: fixture.accountProjections,
            popoverSelection: fixture.popoverSelection,
            usageSelection: fixture.usageSelection
        )

        store.setSelectedAccount(surfaceId: "codex", accountKey: "codex-organization")
        let context = UsageNavigationContext(
            surfaceId: "codex",
            accountKey: "codex-organization"
        )
        store.selectUsageContext(
            surfaceId: context.surfaceId,
            accountKey: context.accountKey
        )

        XCTAssertEqual(
            store.surfaces.first?.identity?.accountLabel,
            "organization-production-sandbox@example.test")
        XCTAssertEqual(store.providerGlanceRows.first?.glanceRemainingPercent, 88)
        XCTAssertEqual(store.usageSelection, "codex")
        XCTAssertEqual(store.usageAccountSelection, "codex-organization")
    }
}
