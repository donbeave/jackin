// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import JackinUsageBridge

final class OverviewInventoryTests: XCTestCase {
    private func glance(
        id: String,
        label: String,
        account: String = "",
        bar: String = "50%",
        pct: UInt8? = 50,
        resetLabel: String? = "Resets in 1h",
        exactReset: String? = nil
    ) -> PresentationStore.GlanceProviderRow {
        PresentationStore.GlanceProviderRow(
            surfaceId: id,
            iconKey: id,
            displayLabel: label,
            accountLabel: account,
            planLabel: nil,
            glanceRemainingPercent: pct,
            barLabel: bar,
            headline: bar,
            resetLabel: resetLabel,
            exactReset: exactReset,
            statusWord: "fresh",
            isRefreshing: false,
            statusLabel: "fresh",
            severity: "normal",
            updatedLabel: "now",
            lastError: nil,
            dimmed: false
        )
    }

    private func account(
        surface: String,
        key: String,
        label: String,
        pct: UInt8?,
        selected: Bool
    ) -> PresentationStore.AccountRow {
        PresentationStore.AccountRow(
            surfaceId: surface,
            accountKey: key,
            accountLabel: label,
            planLabel: "Plan",
            selected: selected,
            remainingPercent: pct,
            statusWord: "fresh"
        )
    }

    func testMultiAccountExpandsPerAccountInGlanceOrder() {
        let glances = [
            glance(id: "claude", label: "Anthropic", account: "Personal", bar: "12%", pct: 12),
            glance(id: "codex", label: "OpenAI", account: "a1", bar: "57%", pct: 57),
        ]
        let accounts = [
            account(surface: "codex", key: "a1", label: "alexey@chainargos.com", pct: 57, selected: true),
            account(surface: "codex", key: "a2", label: "alexey@zhokhov.com", pct: 0, selected: false),
            account(surface: "claude", key: "p1", label: "Personal", pct: 12, selected: true),
        ]
        let rows = OverviewInventory.rows(accounts: accounts, glanceRows: glances)
        XCTAssertEqual(rows.map(\.id), [
            "claude#p1",
            "codex#a1",
            "codex#a2",
        ])
        XCTAssertEqual(rows[0].title, "Anthropic · Personal")
        XCTAssertEqual(rows[1].title, "OpenAI · alexey@chainargos.com")
        XCTAssertEqual(rows[2].barLabel, "0%")
        XCTAssertEqual(rows[2].remainingPercent, 0)
    }

    func testEmptyAccountsFallsBackToGlanceRows() {
        let glances = [glance(id: "amp", label: "Amp", account: "Free", bar: "100%", pct: 100)]
        let rows = OverviewInventory.rows(accounts: [], glanceRows: glances)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].surfaceId, "amp")
        XCTAssertEqual(rows[0].title, "Amp · Free")
        XCTAssertEqual(rows[0].barLabel, "100%")
    }

    /// OV-5: selected multi-account row composes relative + calendar from glance (QI OpenAI shape).
    func testSelectedAccountComposesExactResetCalendarWithRelative() {
        let glances = [
            glance(
                id: "codex",
                label: "OpenAI",
                account: "alexey@chainargos.com",
                bar: "57%",
                pct: 57,
                resetLabel: "Resets in 3d",
                exactReset: "(15 Aug 2026, 17:02)"
            ),
        ]
        let accounts = [
            account(
                surface: "codex",
                key: "a1",
                label: "alexey@chainargos.com",
                pct: 57,
                selected: true
            ),
            account(
                surface: "codex",
                key: "a2",
                label: "alexey@zhokhov.com",
                pct: 0,
                selected: false
            ),
        ]
        let rows = OverviewInventory.rows(accounts: accounts, glanceRows: glances)
        XCTAssertEqual(rows.count, 2)
        let selected = rows.first { $0.accountKey == "a1" }
        XCTAssertEqual(
            selected?.resetLabel,
            "Resets in 3d\n15 Aug 2026, 17:02",
            "OV-5: relative + calendar from glance exactReset via overviewResetDisplay"
        )
        XCTAssertTrue(
            selected?.resetLabel?.contains("15 Aug 2026") == true,
            "calendar date from fixture exactReset must appear in inventory"
        )
        // Non-selected: AccountRow has no reset DTO — honest nil (data-model limit).
        let unselected = rows.first { $0.accountKey == "a2" }
        XCTAssertNil(unselected?.resetLabel)
        XCTAssertEqual(unselected?.remainingPercent, 0)
    }

    /// OV-5 glance fallback path (no accounts list) still composes exactReset.
    func testGlanceFallbackComposesExactReset() {
        let glances = [
            glance(
                id: "codex",
                label: "OpenAI",
                account: "a@example.com",
                bar: "57%",
                pct: 57,
                resetLabel: "Resets in 3d",
                exactReset: "(15 Aug 2026, 17:02)"
            ),
        ]
        let rows = OverviewInventory.rows(accounts: [], glanceRows: glances)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].resetLabel, "Resets in 3d\n15 Aug 2026, 17:02")
    }

    func testOverviewResetDisplayStripsParenthesesAndJoins() {
        XCTAssertEqual(
            overviewResetDisplay(
                resetLabel: "Resets in 3d",
                exactReset: "(15 Aug 2026, 17:02)"
            ),
            "Resets in 3d\n15 Aug 2026, 17:02"
        )
        XCTAssertEqual(
            overviewResetDisplay(resetLabel: "Resets in 1h", exactReset: nil),
            "Resets in 1h"
        )
        XCTAssertEqual(
            overviewResetDisplay(resetLabel: nil, exactReset: "(Today, 18:40)"),
            "Today, 18:40"
        )
        XCTAssertNil(overviewResetDisplay(resetLabel: nil, exactReset: nil))
        XCTAssertNil(overviewResetDisplay(resetLabel: "  ", exactReset: "()"))
    }
}
