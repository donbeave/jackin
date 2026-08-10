// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Overview content — **per-account inventory** when accounts exist (HTML SoT),
/// else glance-provider fallback. Content layer only (LG-A2).
struct OverviewListView: View {
    let model: UsageWindowModel
    let accounts: [PresentationStore.AccountRow]
    /// Select provider surface; optional account key for multi-account focus.
    var onSelect: (String, String?) -> Void

    private var inventory: [OverviewInventoryRow] {
        OverviewInventory.rows(accounts: accounts, glanceRows: model.sidebar)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if model.isEmpty {
                    Text(UsageWindowModel.emptyHint)
                        .foregroundStyle(.secondary)
                        .padding()
                }
                ForEach(inventory) { row in
                    Button {
                        onSelect(row.surfaceId, row.accountKey)
                    } label: {
                        inventoryCard(row)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(row.title) \(row.barLabel)")
                }
            }
            .padding(16)
        }
        .modifier(GlassFallbacks.SoftScrollEdges())
    }

    private func inventoryCard(_ row: OverviewInventoryRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.title)
                    .font(.headline)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(row.barLabel)
                    .font(.title3.weight(.semibold).monospacedDigit())
                    .foregroundStyle(severityTint(row.severity))
            }

            if let plan = row.planLabel, !plan.isEmpty {
                Text(plan)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }

            if let pct = row.remainingPercent {
                glanceMeter(percent: pct)
            }

            if let reset = row.resetLabel, !reset.isEmpty {
                Text(reset)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassFallbacks.contentCardBackground()
        }
    }

    /// 1:1 remaining fill; 0% empty track.
    private func glanceMeter(percent: UInt8) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.10))
                if percent > 0 {
                    Capsule()
                        .fill(Color.primary.opacity(0.35))
                        .frame(width: geo.size.width * CGFloat(percent) / 100.0)
                }
            }
        }
        .frame(height: 4)
    }
}
