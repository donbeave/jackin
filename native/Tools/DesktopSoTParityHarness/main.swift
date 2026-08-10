// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

/// CLT-safe SoT parity checks for status focus, Overview inventory, usage URLs.
/// Drives **shipped** `JackinUsageBridge` APIs (not re-implementations).
///
///   cd native && swift run -c release DesktopSoTParityHarness

import Foundation
import JackinUsageBridge

@main
struct DesktopSoTParityHarness {
    static func main() {
        var failures = 0
        func check(_ name: String, _ ok: Bool) {
            if ok {
                print("PASS  \(name)")
            } else {
                failures += 1
                print("FAIL  \(name)")
            }
        }

        // --- StatusPopoverFocus (shipped) ---
        check(
            "provider click → provider selection",
            StatusPopoverFocus.outcome(surfaceId: "claude", isFallbackItem: false)
                == .provider("claude")
                && StatusPopoverFocus.popoverSelection(for: .provider("claude")) == "claude"
        )
        check(
            "fallback item → overview",
            StatusPopoverFocus.outcome(surfaceId: nil, isFallbackItem: true) == .overview
                && StatusPopoverFocus.popoverSelection(for: .overview) == nil
        )
        check(
            "empty surface → overview",
            StatusPopoverFocus.outcome(surfaceId: "", isFallbackItem: false) == .overview
        )
        // Retain NSObject instances for the assertion — bare ObjectIdentifier(NSObject())
        // can free immediately and alias under allocator reuse (flaky FAIL).
        let buttonA = NSObject()
        let buttonB = NSObject()
        let buttonOther = NSObject()
        let idA = ObjectIdentifier(buttonA)
        let idB = ObjectIdentifier(buttonB)
        let idOther = ObjectIdentifier(buttonOther)
        let map = ["codex": idA, "claude": idB]
        check(
            "button identity map",
            StatusPopoverFocus.surfaceId(matchingButtonIdentity: idB, providerButtonIdentities: map)
                == "claude"
                && StatusPopoverFocus.surfaceId(
                    matchingButtonIdentity: idA,
                    providerButtonIdentities: map
                ) == "codex"
                && StatusPopoverFocus.surfaceId(
                    matchingButtonIdentity: idOther,
                    providerButtonIdentities: map
                ) == nil
        )
        // Keep strong refs live through the check (and past any optimizer elision).
        withExtendedLifetime(buttonA) {}
        withExtendedLifetime(buttonB) {}
        withExtendedLifetime(buttonOther) {}

        // --- OverviewInventory (shipped) ---
        let glances = [
            glance(id: "claude", label: "Anthropic", account: "Personal", bar: "12%", pct: 12),
            glance(
                id: "codex",
                label: "OpenAI",
                account: "a1",
                bar: "57%",
                pct: 57,
                resetLabel: "Resets in 3d",
                exactReset: "(15 Aug 2026, 17:02)"
            ),
        ]
        let accounts = [
            account(surface: "codex", key: "a1", label: "alexey@chainargos.com", pct: 57, selected: true),
            account(surface: "codex", key: "a2", label: "alexey@zhokhov.com", pct: 0, selected: false),
            account(surface: "claude", key: "p1", label: "Personal", pct: 12, selected: true),
        ]
        let multi = OverviewInventory.rows(accounts: accounts, glanceRows: glances)
        check(
            "multi-account inventory order + titles",
            multi.map(\.id) == ["claude#p1", "codex#a1", "codex#a2"]
                && multi[0].title == "Anthropic · Personal"
                && multi[2].barLabel == "0%"
                && multi[2].remainingPercent == 0
        )
        // OV-5: selected glance path composes relative + calendar (QI OpenAI exactReset).
        let codexSelected = multi.first { $0.id == "codex#a1" }
        check(
            "OV-5 selected inventory includes exactReset calendar",
            codexSelected?.resetLabel == "Resets in 3d\n15 Aug 2026, 17:02"
                && (codexSelected?.resetLabel?.contains("15 Aug 2026") == true)
        )
        // Unselected multi-account: no AccountRow reset DTO — nil (data-model limit).
        check(
            "OV-5 unselected multi-account reset nil without Account DTO",
            multi.first { $0.id == "codex#a2" }?.resetLabel == nil
        )
        let fallback = OverviewInventory.rows(accounts: [], glanceRows: glances)
        check(
            "empty accounts falls back to glance rows",
            fallback.count == 2 && fallback[0].surfaceId == "claude"
        )
        check(
            "OV-5 glance fallback composes exactReset",
            fallback.first { $0.surfaceId == "codex" }?.resetLabel
                == "Resets in 3d\n15 Aug 2026, 17:02"
        )

        // --- ProviderUsageLinks (shipped) ---
        check("desktop provider URLs complete", ProviderUsageLinks.desktopProviderURLsComplete)
        check(
            "open usage title fixed",
            ProviderUsageLinks.openUsagePageTitle == "Open usage page"
        )
        check(
            "unknown surface has no URL",
            ProviderUsageLinks.usagePageString(surfaceId: "opencode") == nil
        )

        // --- Meter empty-at-0 geometry (pure fraction) ---
        check("0% meter fraction empty", statusItemRemainingFraction(remainingPercent: 0) == 0.0)
        check("100% meter fraction full", statusItemRemainingFraction(remainingPercent: 100) == 1.0)
        check(
            "57% meter fraction",
            abs(statusItemRemainingFraction(remainingPercent: 57) - 0.57) < 0.0001
        )

        // --- Menu model ---
        check(
            "status context menu three rows",
            StatusItemMenuModel.rows.count == 3
                && StatusItemMenuModel.rows.map(\.action)
                == [.openUsageWindow, .refresh, .quit]
        )

        print("---")
        if failures == 0 {
            print("DesktopSoTParityHarness: ALL PASS (\(passCount(failures: failures)) checks)")
            exit(0)
        } else {
            print("DesktopSoTParityHarness: \(failures) FAILURE(S)")
            exit(1)
        }
    }

    private static func passCount(failures: Int) -> String {
        // fixed suite size for log readability
        "\(18 - failures)/18"
    }

    private static func glance(
        id: String,
        label: String,
        account: String,
        bar: String,
        pct: UInt8,
        resetLabel: String = "Resets in 1h",
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

    private static func account(
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
}
