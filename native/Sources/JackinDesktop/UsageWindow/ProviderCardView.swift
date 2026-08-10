// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

/// Provider detail — **content layer only** (LG-A2: no Liquid Glass on data).
///
/// Renders Rust ``UsageDetailPresentation`` rows mechanically.
/// Account switching lives in the **sidebar nest** under the selected provider
/// (FB1-48) — no duplicate chip strip here.
/// Official usage console: ``ProviderUsageLinks`` (browser escape hatch).
public struct ProviderCardView: View {
    public let content: UsageWindowModel.Content

    public init(content: UsageWindowModel.Content) {
        self.content = content
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // HTML `.detail-head` — provider mark + name + account · plan (VS-11 primary).
                detailHead

                if ProviderUsageLinks.usagePageURL(surfaceId: content.surfaceId) != nil {
                    openUsagePageControl
                }

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
                    if row.label == "Limit Reset Credits" {
                        limitResetCreditsCard(row)
                    } else {
                        bucketCard(row)
                    }
                }
            }
            .padding(20)
        }
        // LG-A7: soft edges under floating glass chrome (Tahoe).
        .modifier(GlassFallbacks.SoftScrollEdges())
        .accessibilityElement(children: .contain)
    }

    /// Identity head above Open usage (matches index.html `.page-head` / `.detail-head`).
    private var detailHead: some View {
        HStack(alignment: .center, spacing: 12) {
            providerLogoPlate(iconKey: content.iconKey, size: 36)
            VStack(alignment: .leading, spacing: 3) {
                Text(content.displayLabel)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                if let sub = headSubtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            [content.displayLabel, headSubtitle].compactMap { $0 }.joined(separator: ", ")
        )
    }

    /// Account · plan from selected account (Rust labels only).
    private var headSubtitle: String? {
        guard let account = content.headAccount else { return nil }
        var parts: [String] = []
        if !account.accountLabel.isEmpty { parts.append(account.accountLabel) }
        if let plan = account.planLabel, !plan.isEmpty { parts.append(plan) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Opens the provider’s official usage page (external browser) — HTML `.open-usage` pill.
    private var openUsagePageControl: some View {
        Button {
            if let url = ProviderUsageLinks.usagePageURL(surfaceId: content.surfaceId) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 6) {
                Text(ProviderUsageLinks.openUsagePageTitle)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.jackinPhosphor.opacity(0.92))
            }
        }
        .buttonStyle(.plain)
        .help("Open this provider’s official usage page in your browser")
        .accessibilityLabel(ProviderUsageLinks.openUsagePageTitle)
    }

    /// Bound bucket: show every Rust layout line as labeled detail (count, next expiry, …).
    private func limitResetCreditsCard(_ row: UsageDetailRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(row.label)
                .font(.subheadline.weight(.semibold))
            // Prefer structured lines from presentation; fall back to displayLabel split.
            let lines = row.layoutLines.isEmpty
                ? row.displayLabel.split(separator: " · ").map { String($0) }
                : row.layoutLines.compactMap { $0.leading ?? $0.trailing }
            if lines.isEmpty {
                Text(row.displayLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, text in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(limitResetFieldLabel(index: index, text: text))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 96, alignment: .leading)
                            Text(text)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassFallbacks.contentCardBackground()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label) \(row.displayLabel)")
    }

    /// Quiet field titles for Limit Reset Credits (geometry only; values stay Rust).
    private func limitResetFieldLabel(index: Int, text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("manual reset") { return "Available" }
        if lower.hasPrefix("next expires") || lower.contains("expires") { return "Next expires" }
        if index == 0 { return "Available" }
        if index == 1 { return "Next expires" }
        return "Detail"
    }

    /// Meta already carried by detail head + sidebar nest; omit to de-dupe.
    private static let sidebarDuplicatedMetaIds: Set<String> = [
        "focused", "header", "provider", "account", "username", "plan",
    ]

    /// Logo plate for provider identity (HTML `.plogo` role — SF Symbol, not brand color plate on status bar).
    @ViewBuilder
    private func providerLogoPlate(iconKey: String?, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.jackinPhosphor.opacity(0.18))
            if let iconKey, let symbol = desktopProviderSystemImage(iconKey: iconKey) {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(Color.jackinPhosphor)
            } else {
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(Color.jackinPhosphor)
            }
        }
        .frame(width: size, height: size)
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

    /// Limit card — label + hero remaining (primary), pace/reset secondary, meter last
    /// (matches `index.html` Usage `.limit` anatomy / VS-11).
    private func bucketCard(_ row: UsageDetailRow) -> some View {
        let hero = row.layoutLines.compactMap(\.leading).first
        let secondaryLeadings = Array(row.layoutLines.dropFirst().compactMap(\.leading))
        let resetTrailings = row.layoutLines.compactMap(\.trailing)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(row.label)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                if let hero {
                    Text(hero)
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(severityTint(row.severity))
                        .multilineTextAlignment(.trailing)
                }
            }

            ForEach(Array(secondaryLeadings.enumerated()), id: \.offset) { _, text in
                Text(text)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(resetTrailings.enumerated()), id: \.offset) { _, text in
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            if let meter = row.meterPercent {
                // Geometry from Rust only (1:1). 0% = empty track — no fake sliver.
                let frac = Double(meter) / 100.0
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.10))
                        if frac > 0 {
                            Capsule()
                                .fill(severityTint(row.severity))
                                .frame(width: geo.size.width * frac)
                        }
                    }
                }
                .frame(height: 5)
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
