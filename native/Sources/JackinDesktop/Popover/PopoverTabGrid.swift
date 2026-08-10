// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

/// Sticky popover chrome matching `popover.html`: brand line · **Overview | Providers**
/// segmented mode · provider strip (icons + glance meters) only in Providers mode.
///
/// Selection: `nil` = Overview mode; non-nil surface id = Providers mode focused on that row.
public struct PopoverTabGrid: View {
    public let providers: [PresentationStore.GlanceProviderRow]
    @Binding public var selection: String?

    public init(
        providers: [PresentationStore.GlanceProviderRow],
        selection: Binding<String?>
    ) {
        self.providers = providers
        self._selection = selection
    }

    private var isOverviewMode: Bool { selection == nil }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            brandLine
            modeSegment
            if !isOverviewMode {
                providerStrip
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    // MARK: - Brand (popover.html `.brand-line`)

    private var brandLine: some View {
        HStack(spacing: 8) {
            // j❯ mark — brand moment only (VS-13).
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.accentColor.opacity(0.92))
                    .frame(width: 22, height: 22)
                Text("j❯")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            HStack(spacing: 0) {
                Text("jackin")
                    .font(.subheadline.weight(.semibold))
                Text("❯")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                Text(" desktop")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("jackin❯ desktop")
    }

    // MARK: - Mode segment (Overview | Providers)

    private var modeSegment: some View {
        HStack(spacing: 0) {
            modeButton(title: "Overview", overview: true)
            modeButton(title: "Providers", overview: false)
        }
        .padding(3)
        .background {
            // Use secondary system fill — readable in Light + Dark (not pure primary ink).
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.35))
        }
    }

    private func modeButton(title: String, overview: Bool) -> some View {
        let on = overview ? isOverviewMode : !isOverviewMode
        return Button {
            if overview {
                selection = nil
            } else if selection == nil {
                // Enter Providers mode on first available surface (canonical order).
                selection = providers.first?.surfaceId
            }
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background {
                    if on {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .shadow(color: .black.opacity(0.08), radius: 1, y: 0.5)
                    }
                }
                .foregroundStyle(on ? Color.primary : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: - Provider strip (only in Providers mode)

    private var providerStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(providers) { provider in
                    providerTab(provider)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func providerTab(_ provider: PresentationStore.GlanceProviderRow) -> some View {
        let on = selection == provider.surfaceId
        return Button {
            selection = provider.surfaceId
        } label: {
            VStack(spacing: 5) {
                // HTML `.plogo` role — rounded brand plate (SF Symbol; system accent tint).
                brandPlate(iconKey: provider.iconKey, selected: on)
                Text(provider.displayLabel)
                    .font(.caption2.weight(on ? .semibold : .medium))
                    .lineLimit(1)
                meter(provider.glanceRemainingPercent)
            }
            .frame(minWidth: 56)
            .opacity(provider.dimmed ? 0.55 : 1)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background {
                if on {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.accentColor.opacity(0.30), lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(provider.displayLabel)
        .accessibilityValue(provider.barLabel)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    /// Provider identity plate (popover.html `.plogo` density — not bare SF glyph).
    private func brandPlate(iconKey: String?, selected: Bool) -> some View {
        let symbol = iconKey.flatMap { desktopProviderSystemImage(iconKey: $0) } ?? "circle.grid.cross"
        return ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.28) : Color.primary.opacity(0.10))
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(selected ? Color.accentColor : Color.primary.opacity(0.85))
        }
        .frame(width: 28, height: 28)
    }

    /// Meter geometry only — nil remaining = empty track (FB1-5).
    @ViewBuilder
    private func meter(_ remaining: UInt8?) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.25))
                if let remaining, remaining > 0 {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(remaining) / 100.0)
                }
            }
        }
        .frame(width: 40, height: 3)
    }
}
