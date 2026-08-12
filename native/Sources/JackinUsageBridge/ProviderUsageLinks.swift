// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Official provider usage / quota pages for “Open usage page” (browser escape hatch).
///
/// Product boundary: `plans/native-liquid-glass/InformationArchitecture.md`.
///
/// Keys are host `surface_id` values (`codex`, `claude`, …) from
/// `DESKTOP_PROVIDER_ORDER`. No string synthesis beyond this map.
public enum ProviderUsageLinks {
    /// Canonical HTTPS URL for the provider’s own usage console, if known.
    public static func usagePageURL(surfaceId: String) -> URL? {
        guard let raw = usagePageString(surfaceId: surfaceId) else { return nil }
        return URL(string: raw)
    }

    /// Same as ``usagePageURL`` but raw string (tests / HTML parity).
    public static func usagePageString(surfaceId: String) -> String? {
        switch surfaceId {
        case "codex":
            return "https://chatgpt.com/codex/settings/usage"
        case "claude":
            return "https://claude.ai/settings/usage"
        case "amp":
            return "https://ampcode.com/settings"
        case "grok":
            return "https://console.x.ai/team/default/usage"
        case "zai":
            return "https://z.ai/manage-apikey/coding-plan/personal/usage"
        case "kimi":
            return "https://www.kimi.com/membership/subscription?tab=quota"
        case "minimax":
            return "https://platform.minimax.io/console/usage"
        default:
            return nil
        }
    }

    /// Toolbar / button title (fixed product copy).
    public static let openUsagePageTitle = "Open usage page"

    /// Host surface ids in `DESKTOP_PROVIDER_ORDER` (must each have a URL).
    public static let desktopProviderOrder: [String] = [
        "codex", "claude", "amp", "grok", "zai", "kimi", "minimax",
    ]

    /// True when every desktop provider has a non-empty official usage URL.
    public static var desktopProviderURLsComplete: Bool {
        desktopProviderOrder.allSatisfy { id in
            guard let urlString = usagePageString(surfaceId: id),
                !urlString.isEmpty,
                URL(string: urlString) != nil
            else {
                return false
            }
            return true
        }
    }
}
