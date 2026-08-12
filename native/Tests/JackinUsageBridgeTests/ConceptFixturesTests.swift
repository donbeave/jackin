// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest

@testable import JackinDesktopUI
@testable import JackinUsageBridge

final class ConceptFixturesTests: XCTestCase {
    func testCatalogContainsEveryStableFixtureExactlyOnce() {
        XCTAssertEqual(ConceptFixtureID.allCases.count, 15)
        XCTAssertEqual(Set(ConceptFixtureID.allCases.map(\.rawValue)).count, 15)
        for id in ConceptFixtureID.allCases {
            XCTAssertEqual(ConceptFixtures.fixture(id: id).id, id)
        }
    }

    func testCatalogProviderOrderAndLayoutEnvelope() {
        let catalog = ConceptFixtures.fixture(id: .catalogNormal)
        XCTAssertEqual(
            catalog.glanceRows.map(\.surfaceId),
            ["codex", "claude", "amp", "grok", "zai", "kimi", "minimax"]
        )
        XCTAssertEqual(
            catalog.statusGlanceRows.map(\.surfaceId),
            ["claude", "codex", "minimax"]
        )
        XCTAssertEqual(ConceptFixtures.fixture(id: .layoutEnvelope).accounts.count, 12)
    }

    func testFixtureIdentitiesAreSynthetic() {
        for id in ConceptFixtureID.allCases {
            let fixture = ConceptFixtures.fixture(id: id)
            for account in fixture.accounts {
                XCTAssertFalse(account.accountLabel.contains("chainargos"))
                XCTAssertFalse(account.accountLabel.contains("zhokhov"))
                if account.accountLabel.contains("@") {
                    XCTAssertTrue(account.accountLabel.hasSuffix(".test"))
                }
            }
        }
    }

    func testFixtureModeRequiresExplicitSelector() {
        let production = ConceptLaunchOptions.resolve(
            arguments: ["JackinDesktop"], environment: [:])
        XCTAssertFalse(production.usesFixture)

        let fixture = ConceptLaunchOptions.resolve(
            arguments: ["JackinDesktop", "--fixture", "F03-multi-account"],
            environment: [:]
        )
        XCTAssertEqual(fixture.fixtureID, .multiAccount)
        XCTAssertNil(fixture.invalidFixtureID)

        let invalid = ConceptLaunchOptions.resolve(
            arguments: ["JackinDesktop", "--fixture", "F99-unknown"],
            environment: [:]
        )
        XCTAssertNil(invalid.fixtureID)
        XCTAssertEqual(invalid.invalidFixtureID, "F99-unknown")
    }

    @MainActor
    func testFixtureAccountSelectionNeverCallsBridge() {
        let fixture = ConceptFixtures.fixture(id: .multiAccount)
        let store = PresentationStore()
        store.applyQIFixture(
            glanceRows: fixture.glanceRows,
            statusBarGlanceRows: fixture.statusGlanceRows,
            surfaces: fixture.surfaces,
            accounts: fixture.accounts,
            popoverSelection: fixture.popoverSelection,
            usageSelection: fixture.usageSelection
        )

        store.setSelectedAccount(surfaceId: "codex", accountKey: "codex-organization")

        XCTAssertTrue(
            store.accounts.first { $0.accountKey == "codex-organization" }?.selected == true
        )
        XCTAssertEqual(store.accounts.filter(\.selected).count, 1)
    }

    func testA1SourcesExposeNoDestructiveAction() throws {
        let sources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/JackinDesktop")
        for relativePath in [
            "PopoverRoot.swift",
            "UsageWindow/UsageWindowRoot.swift",
            "UsageWindow/ProviderCardView.swift",
        ] {
            let text = try String(
                contentsOf: sources.appendingPathComponent(relativePath),
                encoding: .utf8
            ).lowercased()
            for token in ["delete", "revoke", "consume reset", "sign out"] {
                XCTAssertFalse(text.contains(token), "\(relativePath) exposes \(token)")
            }
        }
    }
}
