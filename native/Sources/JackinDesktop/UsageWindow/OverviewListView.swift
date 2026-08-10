// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Overview content — **per-account inventory** when accounts exist (HTML SoT),
/// else glance-provider fallback. Content layer only (LG-A2).
public struct OverviewListView: View {
    public let model: UsageWindowModel
    public let accounts: [PresentationStore.AccountRow]
    /// Select provider surface; optional account key for multi-account focus.
    public var onSelect: (String, String?) -> Void

    public init(
        model: UsageWindowModel,
        accounts: [PresentationStore.AccountRow],
        onSelect: @escaping (String, String?) -> Void
    ) {
        self.model = model
        self.accounts = accounts
        self.onSelect = onSelect
    }

    private var inventory: [OverviewInventoryRow] {
        OverviewInventory.rows(accounts: accounts, glanceRows: model.sidebar)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                overviewHead
                if model.isEmpty {
                    Text(UsageWindowModel.emptyHint)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    inventoryList
                }
            }
            .padding(16)
        }
        .modifier(GlassFallbacks.SoftScrollEdges())
    }

    private var overviewHead: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.jackinPhosphor)
                HStack(spacing: 0) {
                    Text("j")
                    Text("❯")
                        .fontWeight(.black)
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.black.opacity(0.78))
            }
            .frame(width: 36, height: 36)
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)

            VStack(alignment: .leading, spacing: 3) {
                Text("Overview")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.45)
                Text("Glance inventory · one row per account · Weekly (Daily for Amp)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var inventoryList: some View {
        VStack(spacing: 0) {
            ForEach(Array(inventory.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Divider()
                        .opacity(0.55)
                }
                Button {
                    onSelect(row.surfaceId, row.accountKey)
                } label: {
                    inventoryRow(row)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(row.title) \(row.barLabel)")
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            GlassFallbacks.contentCardBackground()
        }
    }

    private func inventoryRow(_ row: OverviewInventoryRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(row.title)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(-0.1)
                    .lineLimit(2)
                Spacer(minLength: 8)
                Text(row.barLabel)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .tracking(-0.5)
                    .foregroundStyle(
                        (row.remainingPercent == 0)
                            ? Color.secondary
                            : severityTint(row.severity)
                    )
            }

            if let reset = row.resetLabel, !reset.isEmpty {
                Text(reset.replacingOccurrences(of: "\n", with: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if let pct = row.remainingPercent {
                glanceMeter(percent: pct, severity: row.severity)
                    .padding(.top, 1)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 1:1 remaining fill; 0% empty track; severity color like HTML inventory meters.
    private func glanceMeter(percent: UInt8, severity: String) -> some View {
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
        .frame(height: 5)
    }
}
