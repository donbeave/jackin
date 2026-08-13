// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

/// Provider identity chrome only.
///
/// Never use these colors for quota state.
public func desktopProviderBrandChrome(iconKey: String?) -> Color {
    switch iconKey {
    case "codex": Color(red: 0.12, green: 0.72, blue: 0.52)
    case "claude": Color(red: 0.86, green: 0.48, blue: 0.28)
    case "amp": Color(red: 0.52, green: 0.38, blue: 0.92)
    case "grok": Color(red: 0.35, green: 0.38, blue: 0.42)
    case "zai": Color(red: 0.20, green: 0.55, blue: 0.95)
    case "kimi": Color(red: 0.75, green: 0.35, blue: 0.55)
    case "minimax": Color(red: 0.90, green: 0.55, blue: 0.20)
    default: Color.jackinPhosphor
    }
}

/// Official provider logomarks (template PDF) for status bar, popover plates, and Usage chrome.
///
/// **LG-P1–P4 / FB1-6:** status bar uses `NSImage.isTemplate = true` monochrome silhouettes.
/// Popover/Usage may place the same mark on a brand-tinted plate (white template glyph).
/// Masters + provenance: `Resources/ProviderMarks/PROVENANCE.md`.
@MainActor
public enum ProviderMarks {
    /// Bundled PDF resource base name for a Desktop provider icon key.
    public static func resourceName(forIconKey iconKey: String) -> String? {
        switch iconKey {
        case "codex": return "codex"
        case "claude": return "claude"
        case "amp": return "amp"
        case "grok": return "grok"
        case "kimi": return "kimi"
        case "zai": return "zai"
        case "minimax": return "minimax"
        default: return nil
        }
    }

    /// Load official mark as template `NSImage` for menu-bar / monochrome use.
    public static func templateImage(forIconKey iconKey: String) -> NSImage? {
        guard let name = resourceName(forIconKey: iconKey) else { return nil }
        return loadPDF(named: name, template: true)
    }

    /// SwiftUI image of the official mark (template rendering for mono; pair with plate for color).
    public static func swiftUIImage(forIconKey iconKey: String) -> Image? {
        guard let ns = templateImage(forIconKey: iconKey) else { return nil }
        return Image(nsImage: ns)
    }

    /// Whether a bundled official mark exists for this key.
    public static func hasMark(forIconKey iconKey: String) -> Bool {
        templateImage(forIconKey: iconKey) != nil
    }

    private static func loadPDF(named name: String, template: Bool) -> NSImage? {
        // Prefer **PNG with alpha** (black glyph, transparent bg) so plates don't
        // fill solid white from opaque PDF paper. PDF is fallback only.
        for url in candidateURLs(named: name, extensions: ["png", "pdf"]) {
            guard let image = NSImage(contentsOf: url) else { continue }
            let copy = image.copy() as? NSImage ?? image
            copy.isTemplate = template
            copy.size = NSSize(width: 18, height: 18)
            return copy
        }
        return nil
    }

    private static func candidateURLs(named name: String, extensions: [String]) -> [URL] {
        var urls: [URL] = []
        #if SWIFT_PACKAGE
        let bundles: [Bundle] = [Bundle.module, Bundle.main]
        #else
        let bundles: [Bundle] = [Bundle.main]
        #endif
        for bundle in bundles {
            for ext in extensions {
                if let url = bundle.url(
                    forResource: name,
                    withExtension: ext,
                    subdirectory: "ProviderMarks"
                ) {
                    urls.append(url)
                }
                if let url = bundle.url(forResource: name, withExtension: ext) {
                    urls.append(url)
                }
                if let root = bundle.resourceURL {
                    urls.append(root.appendingPathComponent("ProviderMarks/\(name).\(ext)"))
                    urls.append(root.appendingPathComponent("\(name).\(ext)"))
                }
                urls.append(bundle.bundleURL.appendingPathComponent("ProviderMarks/\(name).\(ext)"))
            }
        }
        var seen = Set<String>()
        return urls.filter {
            seen.insert($0.path).inserted && FileManager.default.fileExists(atPath: $0.path)
        }
    }
}
