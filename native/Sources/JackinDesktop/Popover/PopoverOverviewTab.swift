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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                overviewBrandPlate(iconKey: glance.iconKey)
                VStack(alignment: .leading, spacing: 1) {
                    Text(glance.displayLabel)
                        .font(.subheadline.weight(.semibold))
                    if let plan = glance.planLabel, !plan.isEmpty {
                        Text(plan)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer(minLength: 0)
            }

            ForEach(rows) { row in
                accountRow(row, iconKey: glance.iconKey)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassFallbacks.contentCardBackground()
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            if let reset = row.resetLabel, !reset.isEmpty {
                                Text(reset)
                                    .font(.caption2)
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
                            .font(.callout.weight(.semibold).monospacedDigit())
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

                Button {
                    onRefreshSurface?(row.surfaceId)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Refresh this provider")
                .accessibilityLabel("Refresh \(row.title)")
            }

            if let pct = row.remainingPercent {
                overviewMeter(percent: pct, severity: row.severity)
            }
        }
        .padding(.vertical, 2)
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
        let brand = brandChrome(for: iconKey)
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
        .frame(width: 26, height: 26)
    }

    /// Logo plate fills only (LG-6 / FB1-20) — not meter chrome.
    private func brandChrome(for iconKey: String) -> Color {
        switch iconKey {
        case "codex": return Color(red: 0.12, green: 0.72, blue: 0.52)
        case "claude": return Color(red: 0.86, green: 0.48, blue: 0.28)
        case "amp": return Color(red: 0.52, green: 0.38, blue: 0.92)
        case "grok": return Color(red: 0.35, green: 0.38, blue: 0.42)
        case "zai": return Color(red: 0.20, green: 0.55, blue: 0.95)
        case "kimi": return Color(red: 0.75, green: 0.35, blue: 0.55)
        case "minimax": return Color(red: 0.90, green: 0.55, blue: 0.20)
        default: return Color.jackinPhosphor
        }
    }
}
