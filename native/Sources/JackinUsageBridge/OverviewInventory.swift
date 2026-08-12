// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// One Overview inventory row — **per account** when `list_accounts` has rows
/// (HTML Usage SoT), else one row per glance provider (single-account fallback).
public struct OverviewInventoryRow: Identifiable, Equatable, Sendable {
    public var id: String
    public let surfaceId: String
    public let accountKey: String?
    /// Display title, e.g. `OpenAI · alexey@…` (labels from Rust only).
    public let title: String
    public let planLabel: String?
    /// Glance remaining from account row or glance row (Rust only).
    public let remainingPercent: UInt8?
    public let barLabel: String
    /// OV-5: relative reset and calendar date when known.
    ///
    /// The two values are newline-separated.
    /// Rust strings only — composed by ``overviewResetDisplay``.
    public let resetLabel: String?
    public let severity: String
    public let statusLabel: String?
    public let lastError: String?

    public init(
        id: String,
        surfaceId: String,
        accountKey: String?,
        title: String,
        planLabel: String?,
        remainingPercent: UInt8?,
        barLabel: String,
        resetLabel: String?,
        severity: String,
        statusLabel: String? = nil,
        lastError: String? = nil
    ) {
        self.id = id
        self.surfaceId = surfaceId
        self.accountKey = accountKey
        self.title = title
        self.planLabel = planLabel
        self.remainingPercent = remainingPercent
        self.barLabel = barLabel
        self.resetLabel = resetLabel
        self.severity = severity
        self.statusLabel = statusLabel
        self.lastError = lastError
    }
}

/// OV-5 / HTML mode-overview: combine Rust relative reset + exact calendar when known.
///
/// - `resetLabel`: e.g. `Resets in 3d`
/// - `exactReset`: Rust parenthetical or bare calendar, e.g. `(15 Aug 2026, 17:02)`
///
/// Returns newline-joined dual line for multi-line Overview UI; single line when only one
/// side is present. Never invents dates — empty inputs → nil.
public func overviewResetDisplay(resetLabel: String?, exactReset: String?) -> String? {
    let relative = resetLabel?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    var calendar = exactReset?
        .trimmingCharacters(in: .whitespacesAndNewlines)
    if let calendarValue = calendar,
        calendarValue.hasPrefix("("),
        calendarValue.hasSuffix(")")
    {
        calendar =
            calendarValue.count > 2
            ? String(calendarValue.dropFirst().dropLast())
                .trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
    }
    let relativeValue = (relative?.isEmpty == false) ? relative : nil
    let calendarValue = (calendar?.isEmpty == false) ? calendar : nil
    switch (relativeValue, calendarValue) {
    case (let rel?, let cal?) where !rel.isEmpty && !cal.isEmpty:
        // Avoid duplicate if one already embeds the other.
        if rel.localizedCaseInsensitiveContains(cal) { return rel }
        if cal.localizedCaseInsensitiveContains(rel) { return cal }
        return "\(rel)\n\(cal)"
    case (let rel?, _):
        return rel
    case (_, let cal?):
        return cal
    default:
        return nil
    }
}

public enum OverviewInventory: Sendable {
    /// Build Overview rows: multi-account expansion first; else glance providers.
    ///
    /// **OV-5 reset:** selected account + single-account glance paths compose
    /// `resetLabel` + `exactReset` via ``overviewResetDisplay``.
    ///
    /// **Data-model limit:** `AccountRow` has no per-account reset fields from
    /// Rust — non-selected multi-account rows cannot show calendar/relative until
    /// the DTO exposes them (deferred; not invented).
    public static func rows(
        accounts: [PresentationStore.AccountRow],
        glanceRows: [PresentationStore.GlanceProviderRow]
    ) -> [OverviewInventoryRow] {
        if !accounts.isEmpty {
            let glanceBySurface = Dictionary(
                uniqueKeysWithValues: glanceRows.map { ($0.surfaceId, $0) })
            // Preserve glance provider order, then accounts within each surface as listed.
            var out: [OverviewInventoryRow] = []
            let surfaceOrder = glanceRows.map(\.surfaceId)
            let extraSurfaces = Set(accounts.map(\.surfaceId)).subtracting(surfaceOrder)
            let orderedSurfaces = surfaceOrder + extraSurfaces.sorted()
            for surfaceId in orderedSurfaces {
                let surfaceAccounts = accounts.filter { $0.surfaceId == surfaceId }
                guard !surfaceAccounts.isEmpty else { continue }
                let glance = glanceBySurface[surfaceId]
                let providerName = glance?.displayLabel ?? surfaceId
                for account in surfaceAccounts {
                    let pct = account.remainingPercent
                    let bar: String
                    if let pct {
                        bar = "\(pct)%"
                    } else if account.selected,
                        let glanceBar = glance?.barLabel,
                        !glanceBar.isEmpty
                    {
                        bar = glanceBar
                    } else {
                        bar = "–"
                    }
                    // Selected account inherits glance reset+exact (Rust glance is for focused account).
                    // Unselected accounts: no AccountRow reset DTO → nil (honest OV-5 partial).
                    let reset: String?
                    if account.selected {
                        reset = overviewResetDisplay(
                            resetLabel: glance?.resetLabel,
                            exactReset: glance?.exactReset
                        )
                    } else {
                        reset = nil
                    }
                    out.append(
                        OverviewInventoryRow(
                            id: "\(surfaceId)#\(account.accountKey)",
                            surfaceId: surfaceId,
                            accountKey: account.accountKey,
                            title: "\(providerName) · \(account.accountLabel)",
                            planLabel: account.planLabel,
                            remainingPercent: pct
                                ?? (account.selected ? glance?.glanceRemainingPercent : nil),
                            barLabel: bar,
                            resetLabel: reset,
                            // Per-account nest severity (HTML a-meter mid/low/high), not provider glance only.
                            severity: account.meterSeverity,
                            statusLabel: glance?.statusLabel,
                            lastError: glance?.lastError
                        )
                    )
                }
            }
            return out
        }
        return glanceRows.map { row in
            OverviewInventoryRow(
                id: row.surfaceId,
                surfaceId: row.surfaceId,
                accountKey: nil,
                title: row.accountLabel.isEmpty
                    ? row.displayLabel
                    : "\(row.displayLabel) · \(row.accountLabel)",
                planLabel: row.planLabel,
                remainingPercent: row.glanceRemainingPercent,
                barLabel: row.barLabel.isEmpty ? "–" : row.barLabel,
                resetLabel: overviewResetDisplay(
                    resetLabel: row.resetLabel,
                    exactReset: row.exactReset
                ),
                severity: row.severity,
                statusLabel: row.statusLabel,
                lastError: row.lastError
            )
        }
    }
}
