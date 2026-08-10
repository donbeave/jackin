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
public struct UsageWindowRoot: View {
    @ObservedObject public var store: PresentationStore
    @Environment(\.dismiss) private var dismiss

    public init(store: PresentationStore) {
        self.store = store
    }

    private static let overviewId = "__overview__"

    private var model: UsageWindowModel {
        UsageWindowModel(
            glanceRows: store.providerGlanceRows,
            surfaces: store.surfaces,
            accounts: store.accounts,
            selection: store.usageSelection
        )
    }

    public var body: some View {
        let model = self.model
        NavigationSplitView {
            List(selection: selectionBinding) {
                // HTML `.side` · Browse / Overview (All accounts)
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Overview")
                                .font(.body.weight(.semibold))
                            Text("All accounts")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } icon: {
                        sidebarLogoPlate(systemImage: "square.grid.2x2", tint: Color.jackinPhosphor)
                    }
                    .tag(Self.overviewId)
                    .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                } header: {
                    Text("Browse")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }

                Section {
                    ForEach(model.sidebar) { row in
                        // Provider = identity only (no glance % — lives on account rows).
                        providerSidebarRow(row)
                            .tag(row.surfaceId)
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                            .listRowBackground(providerRowBackground(selected: store.usageSelection == row.surfaceId))
                            .accessibilityLabel(providerAccessibilityLabel(row))

                        // Nest accounts under the selected provider only — inset well (HTML ACCOUNTS).
                        if store.usageSelection == row.surfaceId {
                            let accts = store.accountsForSurface(row.surfaceId)
                            if !accts.isEmpty {
                                ForEach(accts) { account in
                                    accountSidebarRow(
                                        account,
                                        multi: accts.count > 1
                                    )
                                    .listRowInsets(EdgeInsets(top: 2, leading: 18, bottom: 2, trailing: 8))
                                    .listRowBackground(accountNestWellBackground)
                                }
                            } else if !row.accountLabel.isEmpty {
                                accountFallbackRow(row)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 18, bottom: 2, trailing: 8))
                                    .listRowBackground(accountNestWellBackground)
                            }
                        }
                    }
                } header: {
                    Text("Providers")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 236, max: 300)
            // LG-A5: system sidebar already Liquid Glass on Tahoe — clear, do not stack.
            .background { GlassFallbacks.sidebarBackground() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack(spacing: 6) {
                    Text("Limits only")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                    Text(store.nextRefreshLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
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
                    OverviewListView(
                        model: model,
                        accounts: store.accounts
                    ) { surfaceId, accountKey in
                        store.selectUsageSurface(surfaceId)
                        if let accountKey {
                            store.setSelectedAccount(surfaceId: surfaceId, accountKey: accountKey)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { GlassFallbacks.windowContentBackground() }
            .modifier(GlassFallbacks.ContentBackgroundExtension())
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("jackin❯ desktop")
        // NSToolbar items (window.toolbarStyle = .unified is set on NSWindow host).
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

    /// Provider nav — logo plate + name; multi-account caption; **no** glance progress (G-U3).
    @ViewBuilder
    private func providerSidebarRow(_ row: PresentationStore.GlanceProviderRow) -> some View {
        let accts = store.accountsForSurface(row.surfaceId)
        HStack(spacing: 10) {
            sidebarProviderLogo(iconKey: row.iconKey)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayLabel)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                if accts.count > 1 {
                    Text("\(accts.count) accounts")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else if !row.accountLabel.isEmpty {
                    Text(row.accountLabel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// HTML `.nav-provider.on` selection well (accent tint, not glass-on-glass).
    @ViewBuilder
    private func providerRowBackground(selected: Bool) -> some View {
        if selected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.jackinPhosphor.opacity(0.14))
        } else {
            Color.clear
        }
    }

    /// Inset nest under selected provider (HTML ACCOUNTS group).
    private var accountNestWellBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.primary.opacity(0.05))
    }

    private func sidebarProviderLogo(iconKey: String) -> some View {
        sidebarLogoPlate(iconKey: iconKey, tint: Color.jackinPhosphor)
    }

    private func sidebarLogoPlate(
        iconKey: String? = nil,
        systemImage: String? = nil,
        tint: Color
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(tint.opacity(0.18))
            if let iconKey, let mark = ProviderMarks.swiftUIImage(forIconKey: iconKey) {
                mark
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .colorMultiply(tint)
            } else {
                let symbol = systemImage
                    ?? iconKey.flatMap { desktopProviderSystemImage(iconKey: $0) }
                    ?? "circle.grid.cross"
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: 26, height: 26)
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
                        .foregroundStyle(account.selected ? Color.jackinPhosphor : .secondary)
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
                // Glance progress on account (HTML SoT): % + mini meter; 0% empty.
                // Color = HTML a-pct / a-meter mid|low|high (severityTint).
                if let pct = account.remainingPercent {
                    let sev = account.meterSeverity
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(verbatim: String(pct) + "%")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(
                                pct == 0 ? Color.secondary : severityTint(sev)
                            )
                        UsageAccountMiniMeter(percent: pct, severity: sev)
                    }
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
            if let pct = row.glanceRemainingPercent {
                let sev = accountMeterSeverity(
                    severity: row.severity,
                    remainingPercent: pct
                )
                VStack(alignment: .trailing, spacing: 3) {
                    Text(row.barLabel.isEmpty ? String(pct) + "%" : row.barLabel)
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(
                            pct == 0 ? Color.secondary : severityTint(sev)
                        )
                    UsageAccountMiniMeter(percent: pct, severity: sev)
                }
            } else if !row.barLabel.isEmpty {
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
