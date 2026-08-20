import AppKit
import SwiftUI

// Brand tokens, identity assets, and provider marks — lifted verbatim from
// the incumbent implementation (Sources/JackinDesktop,
// Sources/JackinUsageBridge/BrandColors.swift) so the prototype renders the
// same identity. Assets are bundled under Resources/.

/// jackin❯ design tokens — phosphor accent system.
/// Dark `#5CF07A` · light `#0B774E` (AA-friendly). Never system
/// `Color.accentColor` for healthy metrics, brand mark, or selection wells.
enum JackinBrand {
    static let phosphorDarkSRGB = (r: 0x5C / 255.0, g: 0xF0 / 255.0, b: 0x7A / 255.0)
    static let phosphorLightSRGB = (r: 0x0B / 255.0, g: 0x77 / 255.0, b: 0x4E / 255.0)

    static var phosphor: Color { Color(nsColor: phosphorNSColor) }

    static let phosphorNSColor = NSColor(
        name: "jackinPhosphor",
        dynamicProvider: { appearance in
            let dark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            if dark {
                return NSColor(
                    srgbRed: phosphorDarkSRGB.r, green: phosphorDarkSRGB.g,
                    blue: phosphorDarkSRGB.b, alpha: 1)
            }
            return NSColor(
                srgbRed: phosphorLightSRGB.r, green: phosphorLightSRGB.g,
                blue: phosphorLightSRGB.b, alpha: 1)
        })
}

extension Color {
    /// Product phosphor accent — prefer over `Color.accentColor` for jackin chrome.
    static var jackinPhosphor: Color { JackinBrand.phosphor }
}

/// Meter tint from row state: danger red, warning orange, otherwise phosphor.
func meterTint(_ state: ProtoState) -> Color {
    switch state {
    case .danger, .depleted: .red
    case .warning: .orange
    default: .jackinPhosphor
    }
}

/// Brand well behind a provider mark: phosphor at whisper alpha on a
/// continuous squircle. The one place chrome-adjacent content wears the
/// brand color as a fill — quiet enough to stay content, loud enough to
/// read jackin❯ at a glance.
struct BrandMarkChip: View {
    let iconKey: String
    var fallbackGlyph: String = ""
    var markSize: CGFloat = 18
    var chipSize: CGFloat = 30

    var body: some View {
        Group {
            if let mark = ProviderMarks.swiftUIImage(forIconKey: iconKey) {
                mark
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.primary)
            } else if !fallbackGlyph.isEmpty {
                Text(fallbackGlyph)
                    .font(.system(size: markSize * 0.6, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: markSize, height: markSize)
        .frame(width: chipSize, height: chipSize)
        .background(
            RoundedRectangle(cornerRadius: chipSize * 0.28, style: .continuous)
                .fill(Color.jackinPhosphor.opacity(0.14))
        )
        .accessibilityHidden(true)
    }
}

/// Canonical generated jackin❯ identity assets for native surfaces.
@MainActor
enum JackinBrandIdentity {
    static func wordmark(for colorScheme: ColorScheme) -> NSImage? {
        loadSVG(named: colorScheme == .dark ? "JackinWordmarkDark" : "JackinWordmarkLight")
    }

    static func templateMonogram() -> NSImage? {
        guard let image = loadSVG(named: "JackinMonogramDark") else { return nil }
        image.isTemplate = true
        return image
    }

    private static func loadSVG(named name: String) -> NSImage? {
        let candidates = [
            Bundle.module.url(forResource: name, withExtension: "svg", subdirectory: "Brand"),
            Bundle.module.url(forResource: name, withExtension: "svg"),
        ]
        for case let url? in candidates {
            if let image = NSImage(contentsOf: url) {
                image.isTemplate = false
                return image
            }
        }
        return nil
    }
}

/// Quiet product signature inside the sidebar's system-owned structural plane.
struct JackinBrandSignature: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let wordmark = JackinBrandIdentity.wordmark(for: colorScheme) {
                Image(nsImage: wordmark)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 124, height: 34, alignment: .leading)
        .accessibilityHidden(true)
    }
}

/// Official provider logomarks (template) for status bar, popover, and Usage
/// chrome. Status bar stays template monochrome. Marks are provenance-audited
/// against vendor brand assets — see Resources/ProviderMarks/PROVENANCE.md.
/// Load order: vector **PDF preferred** (rsvg-rendered from official SVGs with
/// transparent paper — resolution-independent), 512² PNG fallback. Diverges
/// from the incumbent's PNG-first order, whose PDFs carried opaque paper.
@MainActor
enum ProviderMarks {
    static func templateImage(forIconKey iconKey: String) -> NSImage? {
        for ext in ["pdf", "png"] {
            // SPM flattens `.process` resources; check subdirectory then root.
            let candidates = [
                Bundle.module.url(
                    forResource: iconKey, withExtension: ext,
                    subdirectory: "ProviderMarks"),
                Bundle.module.url(forResource: iconKey, withExtension: ext),
            ]
            for case let url? in candidates {
                guard let image = NSImage(contentsOf: url) else { continue }
                let copy = image.copy() as? NSImage ?? image
                copy.isTemplate = true
                copy.size = NSSize(width: 18, height: 18)
                return copy
            }
        }
        return nil
    }

    static func swiftUIImage(forIconKey iconKey: String) -> Image? {
        guard let ns = templateImage(forIconKey: iconKey) else { return nil }
        return Image(nsImage: ns)
    }
}
