// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Glance popover composition root — **Liquid Glass navigation chrome**.
///
/// Shell is translucent (`GlassFallbacks.panelSurfaceBackground`) so wallpaper
/// peeks through (LG-A1). Tab strip + footer sit on glass; scroll body is still
/// content (standard fills on rows only — LG-A2). Data remains Rust-owned.
///
/// **QI full-plate capture:** set `\.popoverQIFullPlate` so multi-limit heroes
/// (Session + Weekly + …) fit without a hollow clipped header-only plate.
private enum PopoverQIFullPlateKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// When true, popover max height expands so harness/QI snapshots can show
    /// every limit bucket (fill+track), not just the first hero in a scroll fold.
    public var popoverQIFullPlate: Bool {
        get { self[PopoverQIFullPlateKey.self] }
        set { self[PopoverQIFullPlateKey.self] = newValue }
    }
}

public struct PopoverRoot: View {
    @ObservedObject public var store: PresentationStore
    public var onOpenUsage: ((String?) -> Void)?
    @Environment(\.popoverQIFullPlate) private var qiFullPlate

    public init(store: PresentationStore, onOpenUsage: ((String?) -> Void)? = nil) {
        self.store = store
        self.onOpenUsage = onOpenUsage
    }

    public var body: some View {
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

            // Sticky glass footer dock — Open Usage Window (FB1-43 / LG-A8 one CTA).
            PopoverFooter {
                onOpenUsage?(store.popoverSelection)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        // Craft width aligns with popover.html (~424). Live menu-bar uses a
        // bounded max height + scroll; QI full-plate expands for multi-limit IA.
        .frame(width: 412)
        .frame(minHeight: 220, maxHeight: qiFullPlate ? 1600 : 640)
        // Liquid Glass panel — must sit on a clear NSPopover window.
        .background {
            GlassFallbacks.panelSurfaceBackground()
        }
        .clipShape(
            RoundedRectangle(cornerRadius: GlassFallbacks.panelCornerRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.28), radius: 32, y: 14)
        .padding(2)
        // ⌘R refresh without a second glass footer CTA (OV-9 / FB1-43: one Open Usage dock).
        .background {
            Button("Refresh") { store.refreshAll() }
                .keyboardShortcut("r", modifiers: [.command])
                .opacity(0)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
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
            // Overview inventory: per-account rows + official marks (OV-3…OV-10 / HTML mode-overview).
            PopoverOverviewTab(
                providers: store.providerGlanceRows,
                accounts: store.accounts,
                selection: $store.popoverSelection,
                onRefreshSurface: { surfaceId in
                    store.refresh(surfaceId: surfaceId)
                },
                onSelectAccount: { surfaceId, accountKey in
                    store.setSelectedAccount(surfaceId: surfaceId, accountKey: accountKey)
                }
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
