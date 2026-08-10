// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

/// Provider tab body — glance depth matching `popover.html` craft.
///
/// Prefers Rust ``UsageDetailPresentation`` buckets (same as Usage window);
/// falls back to `surface.buckets` segments when detail is empty.
/// Account switcher is secondary (tint chips, not solid green slabs).
public struct PopoverProviderTab: View {
    public let provider: PresentationStore.GlanceProviderRow
    public let surface: PresentationStore.SurfaceRow?
    public let accounts: [PresentationStore.AccountRow]
    public let refreshInProgress: Bool
    public let onSelectAccount: (String, String) -> Void
    public let onOpenUsageWindow: (String) -> Void

    public init(
        provider: PresentationStore.GlanceProviderRow,
        surface: PresentationStore.SurfaceRow?,
        accounts: [PresentationStore.AccountRow],
        refreshInProgress: Bool,
        onSelectAccount: @escaping (String, String) -> Void,
        onOpenUsageWindow: @escaping (String) -> Void
    ) {
        self.provider = provider
        self.surface = surface
        self.accounts = accounts
        self.refreshInProgress = refreshInProgress
        self.onSelectAccount = onSelectAccount
        self.onOpenUsageWindow = onOpenUsageWindow
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Identity header — open full Usage window (popover.html head + chevron).
            Button {
                onOpenUsageWindow(provider.surfaceId)
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(provider.displayLabel)
                            .font(.title3.weight(.semibold))
                        Text(headerMetaLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 8)
                    if refreshInProgress || provider.isRefreshing {
                        ProgressView().controlSize(.small)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(provider.dimmed ? 0.55 : 1)
            .accessibilityHint("Open Usage window")

            if let error = provider.lastError, !error.isEmpty {
                Text(error).font(.caption2).foregroundStyle(.red)
            }

            if ProviderUsageLinks.usagePageURL(surfaceId: provider.surfaceId) != nil {
                openUsagePageLink
            }

            if accounts.count > 1 {
                accountStrip
            }

            bucketsSection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    /// Codex · OpenAI · Updated just now (Rust labels only).
    private var headerMetaLine: String {
        var parts: [String] = []
        if !provider.accountLabel.isEmpty { parts.append(provider.accountLabel) }
        if let plan = provider.planLabel, !plan.isEmpty { parts.append(plan) }
        if !provider.updatedLabel.isEmpty {
            let u = provider.updatedLabel
            parts.append(u.lowercased().hasPrefix("updated") ? u : "Updated \(u)")
        }
        return parts.joined(separator: " · ")
    }

    private var openUsagePageLink: some View {
        Button {
            if let url = ProviderUsageLinks.usagePageURL(surfaceId: provider.surfaceId) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            Label(ProviderUsageLinks.openUsagePageTitle, systemImage: "safari")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ProviderUsageLinks.openUsagePageTitle)
    }

    /// Secondary account chips — selected = phosphor fill (popover.html account rail).
    private var accountStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(accounts) { account in
                    Button {
                        onSelectAccount(provider.surfaceId, account.accountKey)
                    } label: {
                        HStack(spacing: 4) {
                            Text(account.accountLabel)
                                .font(.caption2.monospaced().weight(account.selected ? .semibold : .medium))
                                .lineLimit(1)
                            if let pct = account.remainingPercent {
                                Text("\(pct)%")
                                    .font(.caption2.monospacedDigit().weight(.semibold))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            Capsule(style: .continuous)
                                .fill(
                                    account.selected
                                        ? Color.accentColor.opacity(0.88)
                                        : Color.primary.opacity(0.08)
                                )
                                .overlay {
                                    if !account.selected {
                                        Capsule(style: .continuous)
                                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                                    }
                                }
                        }
                        .foregroundStyle(account.selected ? Color.white : Color.primary.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(account.selected ? .isSelected : [])
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var bucketsSection: some View {
        if let detail = surface?.detailPresentation, !detail.rows.isEmpty {
            let buckets = detail.rows.filter { $0.kind == .bucket }
            ForEach(buckets) { row in
                if row.label == "Limit Reset Credits" {
                    limitResetBlock(row)
                } else {
                    detailBucketBlock(row)
                }
            }
        } else if let surface {
            ForEach(Array(surface.buckets.enumerated()), id: \.offset) { _, bucket in
                legacyBucketBlock(bucket)
            }
        }
    }

    /// Hero remaining (VS-11 primary) + meter + pace/reset — popover.html `.hero` / `.meter`.
    private func detailBucketBlock(_ row: UsageDetailRow) -> some View {
        let hero = row.layoutLines.compactMap(\.leading).first
        let paceLines = row.layoutLines.dropFirst().compactMap(\.leading)
        let resetLines = row.layoutLines.compactMap(\.trailing)

        return VStack(alignment: .leading, spacing: 6) {
            Text(row.label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.4)

            if let hero {
                Text(hero)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(severityTint(row.severity))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            if let meter = row.meterPercent {
                bucketMeter(meter, severity: row.severity, height: 7)
            }

            ForEach(Array(paceLines.enumerated()), id: \.offset) { _, pace in
                Text(pace)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(resetLines.enumerated()), id: \.offset) { _, reset in
                Text(reset)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassFallbacks.contentCardBackground()
        }
    }

    private func limitResetBlock(_ row: UsageDetailRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(row.label)
                .font(.caption.weight(.semibold))
            let lines = row.layoutLines.isEmpty
                ? row.displayLabel.split(separator: " · ").map(String.init)
                : row.layoutLines.compactMap { $0.leading ?? $0.trailing }
            ForEach(Array(lines.enumerated()), id: \.offset) { _, text in
                Text(text)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassFallbacks.contentCardBackground()
        }
    }

    private func legacyBucketBlock(_ bucket: PresentationStore.BucketRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(bucket.label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if let meter = bucket.meterPercent {
                bucketMeter(meter, severity: "normal", height: 7)
            }
            ForEach(Array(bucket.displaySegments.enumerated()), id: \.offset) { _, segment in
                Text(segment).font(.caption)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassFallbacks.contentCardBackground()
        }
    }

    /// Geometry from Rust only — 0% = empty track (no fake sliver); severity colors fill.
    @ViewBuilder
    private func bucketMeter(_ meterPercent: UInt8, severity: String, height: CGFloat) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.10))
                if meterPercent > 0 {
                    Capsule()
                        .fill(severityTint(severity))
                        .frame(width: geometry.size.width * CGFloat(meterPercent) / 100.0)
                }
            }
        }
        .frame(height: height)
    }
}
