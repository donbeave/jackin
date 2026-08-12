// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// A1 two-column Usage window with system-owned sidebar and toolbar chrome.
public struct UsageWindowRoot: View {
    private enum Destination: Hashable {
        case overview
        case provider(String)
    }

    @ObservedObject public var store: PresentationStore
    @Environment(\.dismiss) private var dismiss
    @State private var destination: Destination?

    public init(store: PresentationStore) {
        self.store = store
        _destination = State(
            initialValue: store.usageSelection.map(Destination.provider) ?? .overview
        )
    }

    private var model: UsageWindowModel {
        UsageWindowModel(
            glanceRows: store.providerGlanceRows,
            surfaces: store.surfaces,
            accounts: store.accounts,
            selection: store.usageSelection
        )
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $destination) {
                Label("Overview", systemImage: "rectangle.grid.2x2")
                    .tag(Destination.overview)
                    .accessibilityIdentifier("usage.sidebar.overview")

                Section {
                    ForEach(model.sidebar) { provider in
                        Label {
                            Text(provider.displayLabel)
                        } icon: {
                            providerMark(provider)
                        }
                        .tag(Destination.provider(provider.surfaceId))
                        .accessibilityIdentifier("usage.sidebar.provider.\(provider.surfaceId)")
                    }
                } header: {
                    Text("Providers")
                        .accessibilityLabel("Providers")
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 190, ideal: 220, max: 280)
            .accessibilityLabel("Usage providers sidebar")
            .accessibilityIdentifier("usage.sidebar")
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.refreshAll()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(store.refreshInProgress)
                .accessibilityIdentifier("usage.refresh")
            }
        }
        .onExitCommand { dismiss() }
        .onAppear {
            if !store.isOpen {
                store.openDefault()
            }
        }
        .onChange(of: destination) { _, value in
            switch value {
            case .overview, .none:
                store.selectUsageSurface(nil)
            case .provider(let surfaceId):
                store.selectUsageSurface(surfaceId)
            }
        }
        .onChange(of: store.usageSelection) { _, surfaceId in
            let updated = surfaceId.map(Destination.provider) ?? .overview
            if destination != updated {
                destination = updated
            }
        }
        .frame(minWidth: 760, minHeight: 500)
    }

    @ViewBuilder
    private var detail: some View {
        if store.isOpening, store.providerGlanceRows.isEmpty {
            ProgressView("Loading usage")
                .controlSize(.large)
                .accessibilityIdentifier("usage.loading")
        } else if let error = store.lastError, store.providerGlanceRows.isEmpty {
            ContentUnavailableView(
                "Usage unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
            .accessibilityIdentifier("usage.global-error")
        } else if let content = model.content {
            ProviderCardView(
                content: content,
                providerError: store.surfaces.first { $0.id == content.surfaceId }?.lastError,
                onSelectAccount: store.setSelectedAccount
            )
        } else {
            OverviewListView(model: model, accounts: store.accounts) { surfaceId, accountKey in
                store.selectUsageSurface(surfaceId)
                if let accountKey {
                    store.setSelectedAccount(surfaceId: surfaceId, accountKey: accountKey)
                }
            }
        }
    }

    @ViewBuilder
    private func providerMark(_ provider: PresentationStore.GlanceProviderRow) -> some View {
        if let mark = ProviderMarks.swiftUIImage(forIconKey: provider.iconKey) {
            mark
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "circle.grid.cross")
        }
    }
}
