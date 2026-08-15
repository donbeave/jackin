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

    private var appDelegateSource: String {
        get throws {
            let url = URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Sources/JackinDesktop/DesktopAppDelegate.swift")
            return try String(contentsOf: url, encoding: .utf8)
        }
    }

    func testPopoverContentOrderAndFooterPlacement() throws {
        let source = try popoverSource
        let identity = try XCTUnwrap(source.range(of: "providerIdentity(provider)"))
        let limits = try XCTUnwrap(source.range(of: "if !limitRows.isEmpty"))
        let details = try XCTUnwrap(source.range(of: "if !metadataRows.isEmpty"))
        let formEnd = try XCTUnwrap(source.range(of: "private func providerIdentity"))
        let controls = try XCTUnwrap(source.range(of: "private var controls"))
        let formSource = source[identity.lowerBound..<formEnd.lowerBound]
        let controlsSource = source[controls.lowerBound...]

        XCTAssertLessThan(identity.lowerBound, limits.lowerBound)
        XCTAssertLessThan(limits.lowerBound, details.lowerBound)
        XCTAssertFalse(formSource.contains("Picker("))
        XCTAssertTrue(controlsSource.contains("HStack(spacing: 4)"))
        XCTAssertTrue(
            controlsSource.contains(
                "Label(\"Refresh\", systemImage: \"arrow.clockwise\")\n"
                    + "                        .labelStyle(.iconOnly)"
            )
        )
        XCTAssertTrue(
            controlsSource.contains(
                "Label(\"Open Usage\", systemImage: \"macwindow\")\n"
                    + "                        .labelStyle(.iconOnly)"
            )
        )
        XCTAssertFalse(controlsSource.contains("\n            .labelStyle(.iconOnly)"))
        XCTAssertTrue(controlsSource.contains("Spacer(minLength: 12)"))
        XCTAssertTrue(controlsSource.contains("Picker("))
        XCTAssertTrue(controlsSource.contains(".labelsHidden()"))
        XCTAssertFalse(source.contains("ScrollViewReader { proxy in"))
        XCTAssertTrue(
            source.contains(
                "@State private var providerScrollPosition = ScrollPosition(edge: .top)"
            )
        )
        XCTAssertTrue(source.contains(".scrollPosition($providerScrollPosition)"))
        XCTAssertTrue(source.contains(".defaultScrollAnchor(.top, for: .initialOffset)"))
        XCTAssertTrue(source.contains(".task(id: presentationState.sequence)"))
        XCTAssertTrue(source.contains(".task(id: provider.accountLabel)"))
        XCTAssertTrue(source.contains("providerScrollPosition.scrollTo(edge: .top)"))
        XCTAssertFalse(source.contains(".scrollPosition(id:"))
        XCTAssertTrue(controlsSource.contains(".help(\"Refresh\")"))
        XCTAssertTrue(controlsSource.contains(".help(\"Open Usage\")"))
        XCTAssertTrue(controlsSource.contains(".help(\"Choose account\")"))
    }

    func testPopoverResetsScrollOnlyAfterExplicitNativePresentation() throws {
        let source = try appDelegateSource
        let toggle = try XCTUnwrap(source.range(of: "private func togglePopover"))
        let reset = try XCTUnwrap(
            source.range(of: "private func resetPopoverScrollAfterPresentation")
        )
        let toggleBody = source[toggle.lowerBound..<reset.lowerBound]
        let resetBody = source[reset.lowerBound...]

        XCTAssertFalse(source.contains("NSPopoverDelegate"))
        XCTAssertFalse(source.contains("popoverDidShow"))
        XCTAssertEqual(
            toggleBody.components(separatedBy: "resetPopoverScrollAfterPresentation()").count,
            3
        )
        XCTAssertTrue(resetBody.contains("DispatchQueue.main.async"))
        XCTAssertTrue(resetBody.contains("popoverPresentationState.beginPresentation()"))
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
