// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Usage window — Apple Liquid Glass **navigation** + solid **content**.
///
/// Principles (Adopting Liquid Glass / LG-A1–A12):
/// - `NavigationSplitView` sidebar + toolbar = glass nav layer (`GlassFallbacks`)
/// - Detail = standard materials only (no glass data cards)
/// - Provider rows primary; account switching lives in content (left H-scroll pills)
/// - Toolbar groups related actions (Refresh)
/// - SwiftUI only; all % / labels from Rust via ``UsageWindowModel``
struct UsageWindowRoot: View {
    @ObservedObject var store: PresentationStore
    @Environment(\.dismiss) private var dismiss

    private static let overviewId = "__overview__"

    private var model: UsageWindowModel {
        UsageWindowModel(
            glanceRows: store.providerGlanceRows,
            surfaces: store.surfaces,
            accounts: store.accounts,
            selection: store.usageSelection
        )
    }

    var body: some View {
        let model = self.model
        NavigationSplitView {
            // MARK: Navigation layer (Liquid Glass)
            List(selection: selectionBinding) {
                Section {
                    Label {
                        Text("Overview")
                            .font(.body.weight(.semibold))
                    } icon: {
                        Image(systemName: "square.grid.2x2")
                    }
                    .tag(Self.overviewId)
                    .accessibilityLabel("Overview")
                }

                Section("Providers") {
                    // Canonical Capsule / DESKTOP_PROVIDER_ORDER from Rust glance rows.
                    ForEach(model.sidebar) { row in
                        providerSidebarRow(row)
                            .tag(row.surfaceId)
                            .accessibilityLabel("\(row.displayLabel) \(row.headline)")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 248, max: 320)
            .background {
                GlassFallbacks.sidebarBackground()
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Glass footer dock (nav chrome) — limits-only refresh hint.
                HStack {
                    Text(store.nextRefreshLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    GlassFallbacks.footerBarBackground()
                }
            }
        } detail: {
            // MARK: Content layer (standard materials only)
            Group {
                if let content = model.content {
                    ProviderCardView(
                        content: content,
                        onSelectAccount: { key in
                            store.setSelectedAccount(
                                surfaceId: content.surfaceId,
                                accountKey: key
                            )
                        }
                    )
                } else {
                    OverviewListView(model: model) { surfaceId in
                        store.selectUsageSurface(surfaceId)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                GlassFallbacks.windowContentBackground()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("Usage")
        .toolbar {
            // LG-A8: single primary action group on the glass toolbar.
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    store.refreshAll()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: [.command])
                .help("Refresh all enabled providers")
            }
        }
        .onExitCommand {
            dismiss()
        }
        .onAppear {
            if !store.isOpen {
                store.openDefault()
            }
        }
        .frame(minWidth: 760, minHeight: 500)
    }

    /// Primary provider nav row: name + glance headline + trailing bar %.
    /// Distinct from account pills (those live in content — LG-A3 / FB1-48).
    @ViewBuilder
    private func providerSidebarRow(_ row: PresentationStore.GlanceProviderRow) -> some View {
        HStack(spacing: 10) {
            // Brand plate stand-in via severity for status color (not glass).
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(severityTint(row.severity).opacity(0.85))
                .frame(width: 8, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayLabel)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                if !row.accountLabel.isEmpty {
                    Text(row.accountLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if !row.headline.isEmpty {
                    Text(row.headline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            // Same glance % as the status bar (`barLabel`).
            if !row.barLabel.isEmpty {
                Text(row.barLabel)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(severityTint(row.severity))
            }
        }
        .padding(.vertical, 2)
    }

    private var selectionBinding: Binding<String?> {
        Binding(
            get: {
                store.usageSelection ?? Self.overviewId
            },
            set: { newValue in
                if newValue == Self.overviewId || newValue == nil {
                    store.selectUsageSurface(nil)
                } else {
                    store.selectUsageSurface(newValue)
                }
            }
        )
    }
}
