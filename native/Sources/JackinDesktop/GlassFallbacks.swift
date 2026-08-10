// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0
//
// Centralized Liquid Glass surface — **latest stable macOS (Tahoe 26) craft target**.
//
// Apple (binding):
// - https://developer.apple.com/documentation/technologyoverviews/liquid-glass
// - https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass
// - https://developer.apple.com/documentation/technologyoverviews/swiftui
// - HIG Materials: LG = navigation layer only; never content layer.
//
// Decisions: LG-A1–LG-A12, AR-4/AR-5/AR-6, VS-1, FB1-55–61.
// No other source file may contain `#available(macOS 26` or `glassEffect`.
//
// Pre-26 / Reduce Transparency: system materials only (not a second design lane).

import AppKit
import SwiftUI

public enum GlassFallbacks {
    // MARK: - Corner radii (continuous / concentric)

    /// Glance popover outer radius.
    public static let panelCornerRadius: CGFloat = 20
    /// Floating control islands / chrome tiles.
    public static let chromeTileCornerRadius: CGFloat = 12
    /// Content-layer cards (standard materials — not glass).
    public static let contentCardCornerRadius: CGFloat = 12
    /// Popover HTML `.group` / `.block` radius.
    public static let popoverContentCardCornerRadius: CGFloat = 14
    public static let chipCornerRadius: CGFloat = 8

    // MARK: - LG-A1 Navigation glass (Tahoe)

    /// Inset chrome control (footer island, toolbar-adjacent tiles).
    @ViewBuilder
    public static func chromeBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if #available(macOS 26, *) {
            content()
                .glassEffect(.regular, in: .rect(cornerRadius: chromeTileCornerRadius))
        } else {
            content()
                .background(
                    .ultraThinMaterial,
                    in: RoundedRectangle(cornerRadius: chromeTileCornerRadius, style: .continuous)
                )
        }
    }

    /// Sidebar accessory footer strip (nav chrome).
    @ViewBuilder
    public static func footerBarBackground() -> some View {
        if #available(macOS 26, *) {
            Rectangle().fill(.clear).glassEffect(.regular, in: .rect)
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
    }

    /// Usage sidebar: on Tahoe, system `List`/`.sidebar` already supplies Liquid Glass.
    /// Returning clear avoids **glass-on-glass** (LG-A5). Older OS gets ultraThin only.
    @ViewBuilder
    public static func sidebarBackground() -> some View {
        if #available(macOS 26, *) {
            Color.clear
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
    }

    /// Glance popover shell — regular glass (LG-A1 / A10). Requires clear NSPopover host.
    ///
    /// Always paints an opaque adaptive base under glass so NSHostingView /
    /// offscreen bitmaps (esp. Light) never collapse to a black void when
    /// `glassEffect` fails to composite.
    @ViewBuilder
    public static func panelSurfaceBackground() -> some View {
        let shape = RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
        ZStack {
            // Adaptive solid base (Light/Dark) — required for snapshot QI + legible chrome.
            shape.fill(Color(nsColor: .windowBackgroundColor))
            if #available(macOS 26, *) {
                shape
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: panelCornerRadius))
            } else {
                shape.fill(.ultraThinMaterial)
            }
            shape.strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
        }
    }

    /// Floating control island (popover Refresh dock, chrome groups).
    @ViewBuilder
    public static func floatingChromeIsland() -> some View {
        let shape = RoundedRectangle(cornerRadius: chromeTileCornerRadius, style: .continuous)
        ZStack {
            shape.fill(Color(nsColor: .controlBackgroundColor).opacity(0.92))
            if #available(macOS 26, *) {
                shape
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect(cornerRadius: chromeTileCornerRadius))
            } else {
                shape.fill(.thinMaterial)
            }
        }
    }

    /// Soft hairline between glass chrome regions (not a solid pane wall).
    @ViewBuilder
    public static func glassSeparator() -> some View {
        Rectangle()
            .fill(Color.primary.opacity(0.10))
            .frame(height: 0.5)
            .padding(.horizontal, 10)
    }

    // MARK: - LG-A2 Content (never glass)

    /// Detail / window content fill — standard materials only.
    @ViewBuilder
    public static func windowContentBackground() -> some View {
        Rectangle().fill(Color(nsColor: .windowBackgroundColor).opacity(0.94))
    }

    /// Content card — full continuous stroke (FB1-60 de-slop).
    @ViewBuilder
    public static func contentCardBackground() -> some View {
        RoundedRectangle(cornerRadius: contentCardCornerRadius, style: .continuous)
            .fill(.background.secondary)
            .overlay {
                RoundedRectangle(cornerRadius: contentCardCornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
    }

    /// Popover content card — same material role, HTML-specific 14 pt geometry.
    @ViewBuilder
    public static func popoverContentCardBackground() -> some View {
        RoundedRectangle(cornerRadius: popoverContentCardCornerRadius, style: .continuous)
            .fill(.background.secondary)
            .overlay {
                RoundedRectangle(cornerRadius: popoverContentCardCornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
    }

    // MARK: - LG-A6 / A7 Edge extension + scroll edges (Tahoe)

    /// Extend detail content under floating glass sidebar.
    public struct ContentBackgroundExtension: ViewModifier {
        public func body(content: Content) -> some View {
            if #available(macOS 26, *) {
                content.backgroundExtensionEffect()
            } else {
                content
            }
        }
    }

    /// Soft scroll-edge dissolve under floating glass chrome (LG-A7).
    public struct SoftScrollEdges: ViewModifier {
        public func body(content: Content) -> some View {
            if #available(macOS 26, *) {
                content
                    .scrollEdgeEffectStyle(.soft, for: .top)
                    .scrollEdgeEffectStyle(.soft, for: .bottom)
            } else {
                content
            }
        }
    }

    // MARK: - Selection / idle fills (not glass)

    @ViewBuilder
    public static func selectedControlFill() -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.jackinPhosphor.opacity(0.90))
    }

    @ViewBuilder
    public static func idleControlFill(enabled: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.primary.opacity(enabled ? 0.07 : 0.03))
    }

    /// Plan/status pill — content-adjacent, not glass.
    @ViewBuilder
    public static func statusChipBackground(tint: Color) -> some View {
        Capsule().fill(tint.opacity(0.16))
    }

    /// Not for menu bar (FB1-6). Subtle non-glass capsule if needed elsewhere.
    @ViewBuilder
    public static func statusItemChipBackground(severity: Color) -> some View {
        Capsule(style: .continuous)
            .fill(Color.primary.opacity(0.06))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(severity.opacity(0.18), lineWidth: 0.5)
            }
    }
}
