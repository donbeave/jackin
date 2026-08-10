// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Usage window — **one continuous content surface** with Liquid Glass nav
/// floating above it (Apple Adopting Liquid Glass / Telegram-style).
///
/// Not a hard three-pane split. `NavigationSplitView` on macOS 26 paints a
/// floating glass sidebar over detail content; detail uses standard materials
/// and may extend under the sidebar via `backgroundExtensionEffect`.
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
            List(selection: selectionBinding) {
                Section {
                    Label("Overview", systemImage: "square.grid.2x2")
                        .font(.body.weight(.semibold))
                        .tag(Self.overviewId)
                }

                Section("Providers") {
                    ForEach(model.sidebar) { row in
                        providerSidebarRow(row)
                            .tag(row.surfaceId)
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .accessibilityLabel("\(row.displayLabel) \(row.headline)")
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 236, max: 300)
            // LG-A5: system sidebar already Liquid Glass on Tahoe — clear, do not stack.
            .background { GlassFallbacks.sidebarBackground() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Text(store.nextRefreshLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background { GlassFallbacks.footerBarBackground() }
            }
        } detail: {
            // LG-A2 content layer under floating glass nav (LG-A6).
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
            .background { GlassFallbacks.windowContentBackground() }
            .modifier(GlassFallbacks.ContentBackgroundExtension())
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("Usage")
        .toolbar {
            // LG-A8: single primary action group on system glass toolbar.
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
        .onExitCommand { dismiss() }
        .onAppear {
            if !store.isOpen {
                store.openDefault()
            }
        }
        .frame(minWidth: 760, minHeight: 500)
    }

    /// Provider nav only — full-row selection (no one-sided “AI” accent bars).
    @ViewBuilder
    private func providerSidebarRow(_ row: PresentationStore.GlanceProviderRow) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayLabel)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                if !row.accountLabel.isEmpty {
                    Text(row.accountLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if !row.barLabel.isEmpty {
                Text(row.barLabel)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(severityTint(row.severity))
            }
        }
        .padding(.vertical, 3)
    }

    private var selectionBinding: Binding<String?> {
        Binding(
            get: { store.usageSelection ?? Self.overviewId },
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
