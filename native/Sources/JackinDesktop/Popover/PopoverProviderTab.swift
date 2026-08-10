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
struct PopoverProviderTab: View {
    let provider: PresentationStore.GlanceProviderRow
    let surface: PresentationStore.SurfaceRow?
    let accounts: [PresentationStore.AccountRow]
    let refreshInProgress: Bool
    let onSelectAccount: (String, String) -> Void
    let onOpenUsageWindow: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                onOpenUsageWindow(provider.surfaceId)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(provider.displayLabel).font(.headline)
                        if !provider.accountLabel.isEmpty {
                            Text(provider.accountLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if refreshInProgress || provider.isRefreshing {
                        ProgressView().controlSize(.small)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(provider.dimmed ? 0.55 : 1)
            .accessibilityHint("Open Usage window")

            if let plan = provider.planLabel, !plan.isEmpty {
                Text(plan).font(.caption2).foregroundStyle(.secondary)
            }
            Text(provider.updatedLabel).font(.caption2).foregroundStyle(.tertiary)
            if let error = provider.lastError, !error.isEmpty {
                Text(error).font(.caption2).foregroundStyle(.red)
            }

            if ProviderUsageLinks.usagePageURL(surfaceId: provider.surfaceId) != nil {
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

            if accounts.count > 1 {
                accountStrip
            }

            bucketsSection
        }
        .padding(10)
    }

    /// Secondary account chips (left H-stack) — phosphor tint when selected.
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
                                    .foregroundStyle(account.selected ? Color.accentColor : .secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule(style: .continuous)
                                .fill(
                                    account.selected
                                        ? Color.accentColor.opacity(0.14)
                                        : Color.primary.opacity(0.06)
                                )
                                .overlay {
                                    Capsule(style: .continuous)
                                        .strokeBorder(
                                            account.selected
                                                ? Color.accentColor.opacity(0.40)
                                                : Color.primary.opacity(0.10),
                                            lineWidth: 0.5
                                        )
                                }
                        }
                        .foregroundStyle(account.selected ? Color.accentColor : Color.primary.opacity(0.85))
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

    private func detailBucketBlock(_ row: UsageDetailRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(row.label)
                .font(.caption.weight(.semibold))
            if let meter = row.meterPercent {
                bucketMeter(meter)
            }
            ForEach(Array(row.layoutLines.enumerated()), id: \.offset) { _, line in
                HStack {
                    if let leading = line.leading {
                        Text(leading)
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(severityTint(row.severity))
                    }
                    Spacer(minLength: 4)
                    if let trailing = line.trailing {
                        Text(trailing)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func limitResetBlock(_ row: UsageDetailRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
        .padding(.vertical, 4)
    }

    private func legacyBucketBlock(_ bucket: PresentationStore.BucketRow) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bucket.label).font(.caption.weight(.semibold))
            if let meter = bucket.meterPercent {
                bucketMeter(meter)
            }
            ForEach(Array(bucket.displaySegments.enumerated()), id: \.offset) { _, segment in
                Text(segment).font(.caption2)
            }
        }
        .padding(.vertical, 4)
    }

    /// Geometry from Rust only — 0% = empty track (no fake sliver).
    @ViewBuilder
    private func bucketMeter(_ meterPercent: UInt8) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.22))
                if meterPercent > 0 {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(meterPercent) / 100.0)
                }
            }
        }
        .frame(height: 4)
    }
}
