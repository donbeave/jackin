// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Overview content — solid cards of Rust glance rows (LG-A2 content layer).
///
/// Glance % / reset match the status bar for each provider; selecting opens
/// full detail (Session, Spark, Auth, …).
struct OverviewListView: View {
    let model: UsageWindowModel
    var onSelect: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if model.isEmpty {
                    Text(UsageWindowModel.emptyHint)
                        .foregroundStyle(.secondary)
                        .padding()
                }
                ForEach(model.sidebar) { row in
                    Button {
                        onSelect(row.surfaceId)
                    } label: {
                        overviewCard(row)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(row.displayLabel) \(row.headline)")
                }
            }
            .padding(16)
        }
    }

    private func overviewCard(_ row: PresentationStore.GlanceProviderRow) -> some View {
        // Full continuous card — no one-sided accent bars (de-slop).
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.displayLabel)
                    .font(.headline)
                Spacer(minLength: 8)
                if !row.barLabel.isEmpty {
                    Text(row.barLabel)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(severityTint(row.severity))
                }
            }

            if !row.accountLabel.isEmpty {
                Text(row.accountLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let plan = row.planLabel, !plan.isEmpty {
                Text(plan)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }

            if let reset = row.resetLabel, !reset.isEmpty {
                Text(reset)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            if let exact = row.exactReset, !exact.isEmpty {
                Text(exact)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if let error = row.lastError, !error.isEmpty {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassFallbacks.contentCardBackground()
        }
    }
}
