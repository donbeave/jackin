// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Provider detail — **content layer only** (LG-A2: no Liquid Glass on data).
///
/// Renders Rust ``UsageDetailPresentation`` rows mechanically. Account switcher
/// is a secondary control system (left H-scroll pills — FB1-29 / FB1-48), not a
/// second glass sidebar.
struct ProviderCardView: View {
    let content: UsageWindowModel.Content
    var onSelectAccount: ((String) -> Void)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Accounts first when multi-account (distinct from provider nav).
                if content.accounts.count > 1 {
                    accountSwitcher
                }

                // Group metadata then buckets for scan hierarchy (VS-11).
                let meta = content.detail.rows.filter { $0.kind != .bucket }
                let buckets = content.detail.rows.filter { $0.kind == .bucket }

                if !meta.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(meta.enumerated()), id: \.element.id) { index, row in
                            if index > 0 {
                                Divider().opacity(0.45)
                            }
                            metadataRow(row)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background {
                        GlassFallbacks.contentCardBackground()
                    }
                }

                ForEach(buckets) { row in
                    bucketCard(row)
                }
            }
            .padding(20)
        }
        // LG-A7: soft edges under floating glass chrome (Tahoe).
        .modifier(GlassFallbacks.SoftScrollEdges())
        .accessibilityElement(children: .contain)
    }

    private func metadataRow(_ row: UsageDetailRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(row.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(Array(row.layoutLines.enumerated()), id: \.offset) { _, line in
                    lineView(line, trailingStyle: .primary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label) \(row.displayLabel)")
    }

    private func bucketCard(_ row: UsageDetailRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(row.label)
                .font(.subheadline.weight(.semibold))
            if let meter = row.meterPercent {
                // Geometry from Rust only; color from severity (3 status levels).
                let frac = Double(meter) / 100.0
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.10))
                        Capsule()
                            .fill(severityTint(row.severity))
                            .frame(width: max(3, geo.size.width * frac))
                    }
                }
                .frame(height: 5)
            }
            // Leading segments first; reset on its own trailing line (FB1-31).
            ForEach(Array(row.layoutLines.enumerated()), id: \.offset) { _, line in
                lineView(line, trailingStyle: .secondary, leadingTint: severityTint(row.severity))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // Content layer — standard material only (LG-A2 / HIG).
            GlassFallbacks.contentCardBackground()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label) \(row.displayLabel)")
    }

    @ViewBuilder
    private func lineView(
        _ line: UsagePresentationLine,
        trailingStyle: HierarchicalShapeStyle,
        leadingTint: Color? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let leading = line.leading {
                Text(leading)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(leadingTint ?? .primary)
            }
            if line.leading != nil, line.trailing != nil {
                Spacer(minLength: 8)
            } else if line.trailing != nil {
                Spacer(minLength: 0)
            }
            if let trailing = line.trailing {
                Text(trailing)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(trailingStyle)
            }
        }
        .frame(maxWidth: .infinity, alignment: line.leading == nil ? .trailing : .leading)
    }

    /// Left-aligned account pills — full continuous capsule stroke (de-slop).
    private var accountSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(content.accounts) { account in
                    Button {
                        onSelectAccount?(account.accountKey)
                    } label: {
                        Text(account.accountLabel)
                            .font(.caption.weight(account.selected ? .semibold : .regular))
                            .lineLimit(1)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(
                                        account.selected
                                            ? Color.accentColor.opacity(0.90)
                                            : Color.primary.opacity(0.06)
                                    )
                                    .overlay {
                                        Capsule(style: .continuous)
                                            .strokeBorder(
                                                account.selected
                                                    ? Color.accentColor.opacity(0.5)
                                                    : Color.primary.opacity(0.10),
                                                lineWidth: 0.5
                                            )
                                    }
                            }
                            .foregroundStyle(account.selected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        "\(account.accountLabel)\(account.selected ? ", selected" : "")"
                    )
                    .accessibilityAddTraits(account.selected ? .isSelected : [])
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
