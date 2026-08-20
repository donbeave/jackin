import AppKit
import SwiftUI

// Brand tokens, identity assets, and provider marks — lifted verbatim from
// the incumbent implementation (Sources/JackinDesktop,
// Sources/JackinUsageBridge/BrandColors.swift) so the prototype renders the
// same identity. Assets are bundled under Resources/.

/// jackin❯ design tokens — phosphor accent system.
///
/// Dark `#5CF07A` · light `#0B774E` (AA-friendly). Never system
/// `Color.accentColor` for healthy metrics, brand mark, or selection wells.
enum JackinBrand {
    static let phosphorDarkSRGB = (r: 0x5C / 255.0, g: 0xF0 / 255.0, b: 0x7A / 255.0)
    static let phosphorLightSRGB = (r: 0x0B / 255.0, g: 0x77 / 255.0, b: 0x4E / 255.0)

    static var phosphor: Color { Color(nsColor: phosphorNSColor) }
    static var phosphorWash: Color { Color(nsColor: phosphorWashNSColor) }
    static var warning: Color { Color(nsColor: warningNSColor) }
    static var danger: Color { Color(nsColor: dangerNSColor) }
    static var stage: Color { Color(nsColor: stageNSColor) }
    static var card: Color { Color(nsColor: cardNSColor) }
    static var separator: Color { Color(nsColor: separatorNSColor) }
    static var meterTrack: Color { Color(nsColor: meterTrackNSColor) }
    static var muted: Color { Color(nsColor: mutedNSColor) }
    static var quiet: Color { Color(nsColor: quietNSColor) }

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

    /// Adaptive color table.
    ///
    /// Explicit semantic endpoints keep small status
    /// text above WCAG AA against the native content grounds in both appearances.
    /// Light grounds: stage #F3F4F1, card #FCFCFA. Dark grounds: stage
    /// #101618, card #162022. Semantic and supporting colors adapt here,
    /// never in a view.
    static let phosphorWashNSColor = dynamicColor(
        name: "jackinPhosphorWash",
        light: rgb(0xE3F3E7),
        dark: rgb(0x16372A))
    static let stageNSColor = dynamicColor(
        name: "jackinStage",
        light: rgb(0xF3F4F1),
        dark: rgb(0x101618))
    static let cardNSColor = dynamicColor(
        name: "jackinCard",
        light: rgb(0xFCFCFA),
        dark: rgb(0x162022))
    static let separatorNSColor = dynamicColor(
        name: "jackinSeparator",
        light: rgb(0xD4D7D2),
        dark: rgb(0x343D3F))
    static let meterTrackNSColor = dynamicColor(
        name: "jackinMeterTrack",
        light: rgb(0xE2E5E0),
        dark: rgb(0x293335))
    static let mutedNSColor = dynamicColor(
        name: "jackinMuted",
        light: rgb(0x59615D),
        dark: rgb(0xADB5B2))
    static let quietNSColor = dynamicColor(
        name: "jackinQuiet",
        light: rgb(0x6A726E),
        dark: rgb(0x858E8B))
    static let warningNSColor = dynamicColor(
        name: "jackinWarning",
        light: rgb(0x7A4B00),
        dark: rgb(0xFFC15A))
    static let dangerNSColor = dynamicColor(
        name: "jackinDanger",
        light: rgb(0xB42318),
        dark: rgb(0xFF7B72))

    private static func rgb(
        _ hex: UInt32, alpha: CGFloat = 1
    ) -> (
        CGFloat, CGFloat, CGFloat, CGFloat
    ) {
        (
            CGFloat((hex >> 16) & 0xFF) / 255,
            CGFloat((hex >> 8) & 0xFF) / 255,
            CGFloat(hex & 0xFF) / 255,
            alpha
        )
    }

    private static func dynamicColor(
        name: String,
        light: (CGFloat, CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat, CGFloat)
    ) -> NSColor {
        NSColor(
            name: NSColor.Name(name),
            dynamicProvider: { appearance in
                let value =
                    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? dark : light
                return NSColor(
                    srgbRed: value.0, green: value.1, blue: value.2, alpha: value.3)
            })
    }
}

/// Four-point spatial scale.
///
/// Native controls retain system-owned internal metrics.
enum JackinSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
}

/// Compact type ramp for authored content; system controls keep native fonts.
enum JackinType {
    static let heroMetric = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let metadata = Font.caption
    static let tertiary = Font.caption2
}

extension Color {
    /// Product phosphor accent — prefer over `Color.accentColor` for jackin chrome.
    static var jackinPhosphor: Color { JackinBrand.phosphor }
    static var jackinMuted: Color { JackinBrand.muted }
    static var jackinQuiet: Color { JackinBrand.quiet }
}

/// Meter tint from row state: danger red, warning orange, otherwise phosphor.
func meterTint(_ state: ProtoState) -> Color {
    switch state {
    case .danger, .depleted: JackinBrand.danger
    case .warning: JackinBrand.warning
    default: .jackinPhosphor
    }
}

/// Brand well behind a provider mark: phosphor at whisper alpha on a
/// continuous squircle.
///
/// The one place chrome-adjacent content wears the
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
                .fill(JackinBrand.phosphorWash)
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
/// chrome.
///
/// Status bar stays template monochrome. Marks are provenance-audited
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
