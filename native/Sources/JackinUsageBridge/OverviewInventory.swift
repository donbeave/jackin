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
    public let resetLabel: String?
    public let severity: String

    public init(
        id: String,
        surfaceId: String,
        accountKey: String?,
        title: String,
        planLabel: String?,
        remainingPercent: UInt8?,
        barLabel: String,
        resetLabel: String?,
        severity: String
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
    }
}

public enum OverviewInventory: Sendable {
    /// Build Overview rows: multi-account expansion first; else glance providers.
    public static func rows(
        accounts: [PresentationStore.AccountRow],
        glanceRows: [PresentationStore.GlanceProviderRow]
    ) -> [OverviewInventoryRow] {
        if !accounts.isEmpty {
            let glanceBySurface = Dictionary(uniqueKeysWithValues: glanceRows.map { ($0.surfaceId, $0) })
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
                    } else if account.selected, let g = glance?.barLabel, !g.isEmpty {
                        bar = g
                    } else {
                        bar = "–"
                    }
                    out.append(
                        OverviewInventoryRow(
                            id: "\(surfaceId)#\(account.accountKey)",
                            surfaceId: surfaceId,
                            accountKey: account.accountKey,
                            title: "\(providerName) · \(account.accountLabel)",
                            planLabel: account.planLabel,
                            remainingPercent: pct ?? (account.selected ? glance?.glanceRemainingPercent : nil),
                            barLabel: bar,
                            resetLabel: account.selected ? glance?.resetLabel : nil,
                            severity: glance?.severity ?? "normal"
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
                resetLabel: row.resetLabel,
                severity: row.severity
            )
        }
    }
}
