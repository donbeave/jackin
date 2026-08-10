// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Provider detail — **content layer only** (LG-A2: no Liquid Glass on data).
///
/// Renders Rust ``UsageDetailPresentation`` rows mechanically.
/// Account switching lives in the **sidebar nest** under the selected provider
/// (FB1-48) — no duplicate chip strip here.
struct ProviderCardView: View {
    let content: UsageWindowModel.Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Group metadata then buckets for scan hierarchy (VS-11).
                // Skip rows already shown in page chrome / sidebar (header, account, plan).
                let meta = content.detail.rows.filter { row in
                    row.kind != .bucket && !Self.sidebarDuplicatedMetaIds.contains(row.rowId)
                }

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

                ForEach(content.detail.rows.filter { $0.kind == .bucket }) { row in
                    bucketCard(row)
                }
            }
            .padding(20)
        }
        // LG-A7: soft edges under floating glass chrome (Tahoe).
        .modifier(GlassFallbacks.SoftScrollEdges())
        .accessibilityElement(children: .contain)
    }

    /// Meta already carried by sidebar account nest + detail identity; omit to de-dupe.
    private static let sidebarDuplicatedMetaIds: Set<String> = [
        "focused", "header", "provider", "account", "username", "plan",
    ]

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
}
