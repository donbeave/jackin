// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Overview tab — HTML `mode-overview` inventory (OV-1…OV-13, FB1-12).
///
/// **IA:** one group per provider (logo + company name), then **per-account**
/// rows with weekly/fallback %, meter (3-status only), reset, and per-surface
/// refresh (OV-8). No mystery severity dots (OV-10). 0% accounts still show
/// (OV-7). Data from ``OverviewInventory`` + Rust glance/account rows only.
public struct PopoverOverviewTab: View {
    let providers: [PresentationStore.GlanceProviderRow]
    let accounts: [PresentationStore.AccountRow]
    @Binding var selection: String?
    /// Force-refresh one surface (OV-8). Global Refresh footer is rejected (OV-9).
    var onRefreshSurface: ((String) -> Void)?
    /// Multi-account: select account then focus Providers on that surface.
    var onSelectAccount: ((String, String) -> Void)?

    public init(
        providers: [PresentationStore.GlanceProviderRow],
        accounts: [PresentationStore.AccountRow] = [],
        selection: Binding<String?>,
        onRefreshSurface: ((String) -> Void)? = nil,
        onSelectAccount: ((String, String) -> Void)? = nil
    ) {
        self.providers = providers
        self.accounts = accounts
        self._selection = selection
        self.onRefreshSurface = onRefreshSurface
        self.onSelectAccount = onSelectAccount
    }

    private var inventory: [OverviewInventoryRow] {
        OverviewInventory.rows(accounts: accounts, glanceRows: providers)
    }

    /// Provider groups in glance order; accounts nested (HTML `.group` / `.account`).
    private var groups: [(glance: PresentationStore.GlanceProviderRow, rows: [OverviewInventoryRow])] {
        let bySurface = Dictionary(grouping: inventory, by: \.surfaceId)
        return providers.compactMap { glance in
            let rows = bySurface[glance.surfaceId] ?? []
            guard !rows.isEmpty else { return nil }
            return (glance, rows)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(groups, id: \.glance.surfaceId) { group in
                providerGroup(glance: group.glance, rows: group.rows)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Provider group (HTML `.group`)

    private func providerGroup(
        glance: PresentationStore.GlanceProviderRow,
        rows: [OverviewInventoryRow]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                overviewBrandPlate(iconKey: glance.iconKey)
                Text(glance.displayLabel)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                if let role = desktopProviderOverviewRole(iconKey: glance.iconKey) {
                    Text(role)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().opacity(0.55)

            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Divider().opacity(0.55)
                }
                accountRow(row, iconKey: glance.iconKey)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassFallbacks.popoverContentCardBackground()
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: GlassFallbacks.popoverContentCardCornerRadius,
                style: .continuous
            )
        )
    }

    // MARK: - Account row (HTML `.account`)

    private func accountRow(_ row: OverviewInventoryRow, iconKey: String) -> some View {
        let accountLabel = accountLabelOnly(from: row)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Button {
                    if let key = row.accountKey {
                        onSelectAccount?(row.surfaceId, key)
                    }
                    selection = row.surfaceId
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(accountLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            if let reset = row.resetLabel, !reset.isEmpty {
                                Text(reset)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                    .fixedSize(horizontal: false, vertical: true)
                            } else if row.remainingPercent == 0 {
                                Text("Fully used")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer(minLength: 4)
                        Text(row.barLabel)
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundStyle(
                                (row.remainingPercent == 0)
                                    ? Color.secondary
                                    : severityTint(row.severity)
                            )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(row.title) \(row.barLabel)")

                PopoverRefreshButton(label: "Refresh \(row.title)") {
                    onRefreshSurface?(row.surfaceId)
                }
            }

            if let pct = row.remainingPercent {
                overviewMeter(percent: pct, severity: row.severity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    /// Strip `Provider · account` inventory title → account-only label (HTML `.account-label`).
    private func accountLabelOnly(from row: OverviewInventoryRow) -> String {
        if let key = row.accountKey, !key.isEmpty {
            // title is "OpenAI · alexey@…" when multi-account
            if let r = row.title.range(of: " · ") {
                return String(row.title[r.upperBound...])
            }
        }
        // Single-account fallback: prefer trailing account segment if present
        if let r = row.title.range(of: " · ") {
            return String(row.title[r.upperBound...])
        }
        return row.title
    }

    /// 1:1 remaining fill; 0% empty track; **status high/mid/low only** (FB1-20).
    private func overviewMeter(percent: UInt8, severity: String) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.10))
                if percent > 0 {
                    Capsule()
                        .fill(severityTint(severity))
                        .frame(width: geo.size.width * CGFloat(percent) / 100.0)
                }
            }
        }
        .frame(height: 4)
    }

    private func overviewBrandPlate(iconKey: String) -> some View {
        let brand = desktopProviderBrandChrome(iconKey: iconKey)
        return ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(brand.opacity(0.88))
            if let mark = ProviderMarks.swiftUIImage(forIconKey: iconKey) {
                mark
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .colorInvert()
                    .opacity(0.98)
            } else if let symbol = desktopProviderSystemImage(iconKey: iconKey) {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
            }
        }
        .frame(width: 28, height: 28)
    }

}
