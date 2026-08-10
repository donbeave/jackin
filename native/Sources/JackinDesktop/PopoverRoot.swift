// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Glance popover composition root — **Liquid Glass navigation chrome**.
///
/// Shell is translucent (`GlassFallbacks.panelSurfaceBackground`) so wallpaper
/// peeks through (LG-A1). Tab strip + footer sit on glass; scroll body is still
/// content (standard fills on rows only — LG-A2). Data remains Rust-owned.
struct PopoverRoot: View {
    @ObservedObject var store: PresentationStore
    var onOpenUsage: ((String?) -> Void)?

    init(store: PresentationStore, onOpenUsage: ((String?) -> Void)? = nil) {
        self.store = store
        self.onOpenUsage = onOpenUsage
    }

    var body: some View {
        VStack(spacing: 0) {
            // Nav chrome: provider strip (glass selection, not content cards).
            PopoverTabGrid(
                providers: store.providerGlanceRows,
                selection: $store.popoverSelection
            )
            .padding(.top, 8)

            GlassFallbacks.glassSeparator()
                .padding(.top, 2)

            // Content scrolls under glass chrome (LG-A7 soft edges).
            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .modifier(GlassFallbacks.SoftScrollEdges())

            GlassFallbacks.glassSeparator()

            // Glass control dock (LG-A8 single refresh group).
            PopoverFooter(refreshInProgress: store.refreshInProgress) {
                store.refreshAll()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: 340)
        .frame(minHeight: 200, maxHeight: 480)
        // Liquid Glass panel — must sit on a clear NSPopover window.
        .background {
            GlassFallbacks.panelSurfaceBackground()
        }
        .clipShape(
            RoundedRectangle(cornerRadius: GlassFallbacks.panelCornerRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.28), radius: 32, y: 14)
        .padding(2)
    }

    @ViewBuilder
    private var content: some View {
        if let selection = store.popoverSelection,
           let provider = store.providerGlanceRows.first(where: { $0.surfaceId == selection })
        {
            PopoverProviderTab(
                provider: provider,
                surface: store.surfaces.first(where: { $0.id == selection }),
                accounts: store.accountsForSurface(selection),
                refreshInProgress: store.refreshInProgress,
                onSelectAccount: { surfaceId, accountKey in
                    store.setSelectedAccount(surfaceId: surfaceId, accountKey: accountKey)
                },
                onOpenUsageWindow: { id in onOpenUsage?(id) }
            )
        } else if store.providerGlanceRows.isEmpty {
            emptyState
        } else {
            PopoverOverviewTab(
                providers: store.providerGlanceRows,
                selection: $store.popoverSelection
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.right")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("No agent usage detected")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Sign in to a supported agent to see usage.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
