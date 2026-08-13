// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

/// SwiftUI content for the native AppKit sidebar split item.
public struct UsageWindowSidebar: View {
    private enum Destination: Hashable {
        case overview
        case provider(String)
    }

    @ObservedObject public var store: PresentationStore

    public init(store: PresentationStore) {
        self.store = store
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
        VStack(spacing: 0) {
            List(selection: destination) {
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
            .accessibilityLabel("Usage providers sidebar")
            .accessibilityIdentifier("usage.sidebar")

            JackinBrandSignature()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 190, idealWidth: 220, maxWidth: 280)
    }

    private var destination: Binding<Destination?> {
        Binding(
            get: { store.usageSelection.map(Destination.provider) ?? .overview },
            set: { value in
                let surfaceId: String?
                switch value {
                case .overview, .none:
                    surfaceId = nil
                case .provider(let selectedSurfaceId):
                    surfaceId = selectedSurfaceId
                }
                guard surfaceId != store.usageSelection else { return }
                DispatchQueue.main.async { [store] in
                    store.selectUsageSurface(surfaceId)
                }
            }
        )
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

/// SwiftUI content for the native AppKit detail split item.
public struct UsageWindowDetail: View {
    @ObservedObject public var store: PresentationStore

    public init(store: PresentationStore) {
        self.store = store
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
        detail
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                if !store.isOpen {
                    store.openDefault()
                }
            }
    }

    @ViewBuilder
    private var detail: some View {
        if store.isOpening, store.providerGlanceRows.isEmpty {
            ProgressView("Loading usage")
                .controlSize(.large)
                .accessibilityIdentifier("usage.loading")
        } else if let error = store.lastError, store.providerGlanceRows.isEmpty {
            ContentUnavailableView {
                Label("Usage unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Retry") { store.retryLastOperation() }
                    .disabled(store.isOpening || store.refreshInProgress)
                    .accessibilityIdentifier("usage.retry")
            }
            .accessibilityIdentifier("usage.global-error")
        } else if let content = model.content {
            ProviderDetailView(
                content: content,
                providerError: store.surfaces.first { $0.id == content.surfaceId }?.lastError,
                onSelectAccount: store.setSelectedAccount,
                onRetry: { store.refresh(surfaceId: content.surfaceId) }
            )
        } else {
            OverviewListView(
                model: model,
                accounts: store.accounts,
                onSelect: { surfaceId, accountKey in
                    store.selectUsageSurface(surfaceId)
                    if let accountKey {
                        store.setSelectedAccount(surfaceId: surfaceId, accountKey: accountKey)
                    }
                },
                onRetry: { surfaceId in
                    store.refresh(surfaceId: surfaceId)
                }
            )
        }
    }
}

/// Native split-item top accessory for detail-local identity and Refresh.
struct UsageWindowDetailAccessory: View {
    @ObservedObject var store: PresentationStore

    var body: some View {
        ZStack {
            Text("jackin❯ desktop")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("usage.brand-title")

            HStack {
                Spacer()
                refreshButton
            }
        }
        .frame(minHeight: 40)
    }

    private var refreshButton: some View {
        Button {
            store.refreshAll()
        } label: {
            Label {
                Text(store.refreshInProgress ? "Refreshing usage" : "Refresh")
            } icon: {
                ZStack {
                    Image(systemName: "arrow.clockwise")
                        .opacity(store.refreshInProgress ? 0 : 1)
                    ProgressView()
                        .controlSize(.small)
                        .opacity(store.refreshInProgress ? 1 : 0)
                }
                .frame(width: 16, height: 16)
            }
        }
        .keyboardShortcut("r", modifiers: [.command])
        .disabled(store.refreshInProgress)
        .accessibilityValue(store.refreshInProgress ? "In progress" : "")
        .accessibilityIdentifier("usage.refresh")
    }
}
