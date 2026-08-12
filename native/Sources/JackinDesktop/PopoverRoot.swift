// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

private enum PopoverQIFullPlateKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    public var popoverQIFullPlate: Bool {
        get { self[PopoverQIFullPlateKey.self] }
        set { self[PopoverQIFullPlateKey.self] = newValue }
    }
}

/// A1 focused-provider glance hosted by the real system `NSPopover`.
public struct PopoverRoot: View {
    public static let liveContentSize = CGSize(width: 380, height: 520)

    @ObservedObject public var store: PresentationStore
    public var onOpenUsage: ((String?) -> Void)?
    @Environment(\.popoverQIFullPlate) private var qiFullPlate

    public init(store: PresentationStore, onOpenUsage: ((String?) -> Void)? = nil) {
        self.store = store
        self.onOpenUsage = onOpenUsage
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            controls
                .padding(12)
        }
        .frame(width: 380)
        .frame(
            minHeight: 260,
            idealHeight: qiFullPlate ? 1_100 : 520,
            maxHeight: qiFullPlate ? 1_100 : 520
        )
        .background {
            Button("Refresh") { store.refreshAll() }
                .keyboardShortcut("r", modifiers: [.command])
                .hidden()
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isOpening, store.providerGlanceRows.isEmpty {
            ProgressView("Loading usage")
                .controlSize(.large)
                .accessibilityIdentifier("popover.loading")
        } else if let error = store.lastError, store.providerGlanceRows.isEmpty {
            ContentUnavailableView(
                "Usage unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
            .accessibilityIdentifier("popover.global-error")
        } else if let provider = selectedProvider {
            providerForm(provider)
        } else {
            ContentUnavailableView(
                "No providers detected",
                systemImage: "chevron.right",
                description: Text(UsageWindowModel.emptyHint)
            )
            .accessibilityIdentifier("popover.empty")
        }
    }

    private var selectedProvider: PresentationStore.GlanceProviderRow? {
        if let selection = store.popoverSelection,
            let match = store.providerGlanceRows.first(where: { $0.surfaceId == selection })
        {
            return match
        }
        return store.providerGlanceRows.first
    }

    private func providerForm(_ provider: PresentationStore.GlanceProviderRow) -> some View {
        let surface = store.surfaces.first { $0.id == provider.surfaceId }
        let accounts = store.accountsForSurface(provider.surfaceId)
        let metadataRows = surface?.detailPresentation.rows.filter { $0.kind != .bucket } ?? []
        let limitRows = surface?.detailPresentation.rows.filter { $0.kind == .bucket } ?? []

        return Form {
            Section {
                providerIdentity(provider)
            }

            if accounts.count > 1 {
                Section {
                    Picker("Account", selection: accountSelection(accounts, provider: provider)) {
                        ForEach(accounts) { account in
                            Text(account.accountLabel)
                                .tag(account.accountKey)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Account")
                    .accessibilityIdentifier("popover.account-picker")
                } header: {
                    sectionHeader("Account")
                }
            }

            if !metadataRows.isEmpty {
                Section {
                    ForEach(metadataRows) { row in
                        LabeledContent(row.label, value: row.displayLabel)
                            .accessibilityLabel("\(row.label), \(row.displayLabel)")
                    }
                } header: {
                    sectionHeader("Details")
                }
            }

            if !limitRows.isEmpty {
                Section {
                    ForEach(limitRows) { row in
                        limitRow(row)
                    }
                } header: {
                    sectionHeader("Limits")
                }
            } else if surface?.lastError == nil {
                Section {
                    Text("No limit details available")
                        .foregroundStyle(.secondary)
                } header: {
                    sectionHeader("Limits")
                }
            }

            if let error = surface?.lastError ?? provider.lastError {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .accessibilityIdentifier("popover.provider-error")
                } header: {
                    sectionHeader("Provider status")
                }
            }
        }
        .formStyle(.grouped)
        .accessibilityLabel("\(provider.displayLabel) usage details")
        .accessibilityIdentifier("popover.provider.\(provider.surfaceId)")
    }

    private func providerIdentity(_ provider: PresentationStore.GlanceProviderRow) -> some View {
        HStack(spacing: 10) {
            if let mark = ProviderMarks.swiftUIImage(forIconKey: provider.iconKey) {
                mark
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayLabel)
                    .font(.headline)
                Text(provider.statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if provider.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(provider.statusLabel)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("popover.provider-identity")
    }

    private func accountSelection(
        _ accounts: [PresentationStore.AccountRow],
        provider: PresentationStore.GlanceProviderRow
    ) -> Binding<String> {
        Binding(
            get: { accounts.first(where: \.selected)?.accountKey ?? accounts[0].accountKey },
            set: { store.setSelectedAccount(surfaceId: provider.surfaceId, accountKey: $0) }
        )
    }

    private func limitRow(_ row: UsageDetailRow) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent(row.label) {
                Text(row.layoutLines.first?.leading ?? row.displayLabel)
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
            if let percent = row.meterPercent {
                ProgressView(value: Double(percent), total: 100)
                    .tint(severityTint(row.severity))
                    .accessibilityHidden(true)
            }
            ForEach(Array(row.layoutLines.dropFirst().enumerated()), id: \.offset) { _, line in
                if let value = line.leading ?? line.trailing {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label), \(row.displayLabel)")
        .accessibilityIdentifier("popover.limit.\(row.rowId)")
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .accessibilityLabel(title)
    }

    private var controls: some View {
        HStack {
            Button {
                if let id = selectedProvider?.surfaceId {
                    store.refresh(surfaceId: id)
                } else {
                    store.refreshAll()
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(store.refreshInProgress)
            .accessibilityIdentifier("popover.refresh")

            Spacer()

            Button("Open Usage") {
                onOpenUsage?(selectedProvider?.surfaceId)
            }
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier("popover.open-usage")
        }
    }
}
