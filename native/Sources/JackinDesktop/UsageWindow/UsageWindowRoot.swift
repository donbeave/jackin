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
                        // Provider = identity only (no glance % — lives on account rows).
                        providerSidebarRow(row)
                            .tag(row.surfaceId)
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .accessibilityLabel(providerAccessibilityLabel(row))

                        // Nest accounts under the selected provider only.
                        if store.usageSelection == row.surfaceId {
                            let accts = store.accountsForSurface(row.surfaceId)
                            if !accts.isEmpty {
                                ForEach(accts) { account in
                                    accountSidebarRow(
                                        account,
                                        multi: accts.count > 1
                                    )
                                    .listRowInsets(EdgeInsets(top: 2, leading: 22, bottom: 2, trailing: 8))
                                }
                            } else if !row.accountLabel.isEmpty {
                                // Glance-only identity when list_accounts empty but glance has label.
                                accountFallbackRow(row)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 22, bottom: 2, trailing: 8))
                            }
                        }
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
                    ProviderCardView(content: content)
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
        .navigationTitle("jackin❯ desktop")
        // Real macOS window toolbar (NSToolbar via hosting controller).
        .windowToolbarStyle(.unified)
        .toolbarBackground(.visible, for: .windowToolbar)
        .toolbar {
            // LG-A8: system toolbar group — icon-only Refresh (standard macOS pattern).
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.refreshAll()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .labelStyle(.iconOnly)
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

    /// Provider nav — logo/name only. Multi-account count in caption; no glance progress.
    @ViewBuilder
    private func providerSidebarRow(_ row: PresentationStore.GlanceProviderRow) -> some View {
        let accts = store.accountsForSurface(row.surfaceId)
        VStack(alignment: .leading, spacing: 2) {
            Text(row.displayLabel)
                .font(.body.weight(.semibold))
                .lineLimit(1)
            if accts.count > 1 {
                Text("\(accts.count) accounts")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Account row under selected provider — glance % from `list_accounts` / remainingPercent.
    @ViewBuilder
    private func accountSidebarRow(
        _ account: PresentationStore.AccountRow,
        multi: Bool
    ) -> some View {
        Button {
            if multi {
                store.setSelectedAccount(surfaceId: account.surfaceId, accountKey: account.accountKey)
            }
        } label: {
            HStack(spacing: 8) {
                if multi {
                    Image(systemName: account.selected ? "circle.inset.filled" : "circle")
                        .font(.caption2)
                        .foregroundStyle(account.selected ? Color.accentColor : .secondary)
                        .frame(width: 12)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(account.accountLabel)
                        .font(.caption.monospaced().weight(account.selected || !multi ? .semibold : .medium))
                        .lineLimit(1)
                        .foregroundStyle(account.selected || !multi ? .primary : .secondary)
                    if let plan = account.planLabel, !plan.isEmpty {
                        Text(plan)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                if let pct = account.remainingPercent {
                    Text("\(pct)%")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!multi)
        .accessibilityLabel(accountSidebarAccessibility(account, multi: multi))
        .accessibilityAddTraits(account.selected || !multi ? .isSelected : [])
    }

    @ViewBuilder
    private func accountFallbackRow(_ row: PresentationStore.GlanceProviderRow) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(row.accountLabel)
                    .font(.caption.monospaced().weight(.semibold))
                    .lineLimit(1)
                if let plan = row.planLabel, !plan.isEmpty {
                    Text(plan)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            if !row.barLabel.isEmpty {
                Text(row.barLabel)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func providerAccessibilityLabel(_ row: PresentationStore.GlanceProviderRow) -> String {
        let accts = store.accountsForSurface(row.surfaceId)
        if accts.count > 1 {
            return "\(row.displayLabel), \(accts.count) accounts"
        }
        return row.displayLabel
    }

    private func accountSidebarAccessibility(
        _ account: PresentationStore.AccountRow,
        multi: Bool
    ) -> String {
        var parts = [account.accountLabel]
        if let plan = account.planLabel, !plan.isEmpty { parts.append(plan) }
        if let pct = account.remainingPercent { parts.append("\(pct) percent remaining") }
        if multi, account.selected { parts.append("selected") }
        return parts.joined(separator: ", ")
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
