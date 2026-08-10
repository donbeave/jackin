// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Pure selection rules for status-item → glance popover focus (HTML SoT:
/// left-click opens Providers mode focused on that provider).
///
/// AppKit maps the clicked button to a `surfaceId` (or fallback); this type only
/// decides the store selection — no UI, no string invention.
public enum StatusPopoverFocus: Sendable {
    /// Result of resolving a left-click for the glance popover tab.
    public enum Outcome: Equatable, Sendable {
        /// Overview tab (`popoverSelection == nil`).
        case overview
        /// Provider tab for this host surface id.
        case provider(String)
    }

    /// Map a resolved click target to popover selection.
    /// - Parameters:
    ///   - surfaceId: Provider id when a provider status item was clicked.
    ///   - isFallbackItem: True when the empty-set fallback status item was clicked.
    public static func outcome(surfaceId: String?, isFallbackItem: Bool) -> Outcome {
        if isFallbackItem { return .overview }
        if let surfaceId, !surfaceId.isEmpty { return .provider(surfaceId) }
        return .overview
    }

    /// `PresentationStore.popoverSelection` value for an outcome.
    public static func popoverSelection(for outcome: Outcome) -> String? {
        switch outcome {
        case .overview: return nil
        case .provider(let id): return id
        }
    }

    /// Find which provider owns a button identity (pure map lookup).
    public static func surfaceId(
        matchingButtonIdentity identity: ObjectIdentifier,
        providerButtonIdentities: [String: ObjectIdentifier]
    ) -> String? {
        for (surfaceId, buttonIdentity) in providerButtonIdentities where buttonIdentity == identity {
            return surfaceId
        }
        return nil
    }
}
