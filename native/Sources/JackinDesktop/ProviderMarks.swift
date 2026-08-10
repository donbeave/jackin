// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import AppKit
import JackinUsageBridge
import SwiftUI

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
        for url in candidateURLs(named: name) {
            guard let image = NSImage(contentsOf: url) else { continue }
            // Copy so callers can set template without mutating a shared cache.
            let copy = image.copy() as? NSImage ?? image
            copy.isTemplate = template
            // Optical size for menu bar / plates (~16–18 pt).
            copy.size = NSSize(width: 18, height: 18)
            return copy
        }
        return nil
    }

    private static func candidateURLs(named name: String) -> [URL] {
        var urls: [URL] = []
        let bundles: [Bundle] = [Bundle.module, Bundle.main]
        for bundle in bundles {
            if let u = bundle.url(
                forResource: name,
                withExtension: "pdf",
                subdirectory: "ProviderMarks"
            ) {
                urls.append(u)
            }
            if let u = bundle.url(forResource: name, withExtension: "pdf") {
                urls.append(u)
            }
            // SPM resource bundle layout sometimes nests under resourceURL without subdirectory API.
            if let root = bundle.resourceURL {
                urls.append(root.appendingPathComponent("ProviderMarks/\(name).pdf"))
                urls.append(root.appendingPathComponent("\(name).pdf"))
            }
            urls.append(bundle.bundleURL.appendingPathComponent("ProviderMarks/\(name).pdf"))
        }
        // De-dupe while preserving order.
        var seen = Set<String>()
        return urls.filter { seen.insert($0.path).inserted && FileManager.default.fileExists(atPath: $0.path) }
    }
}
