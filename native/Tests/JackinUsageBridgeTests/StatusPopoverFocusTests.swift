// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import JackinUsageBridge

/// Shipped ``StatusPopoverFocus`` rules — left-click status → popover tab.
final class StatusPopoverFocusTests: XCTestCase {
    func testProviderClickSelectsSurface() {
        let outcome = StatusPopoverFocus.outcome(surfaceId: "claude", isFallbackItem: false)
        XCTAssertEqual(outcome, .provider("claude"))
        XCTAssertEqual(StatusPopoverFocus.popoverSelection(for: outcome), "claude")
    }

    func testFallbackItemOpensOverview() {
        let outcome = StatusPopoverFocus.outcome(surfaceId: nil, isFallbackItem: true)
        XCTAssertEqual(outcome, .overview)
        XCTAssertNil(StatusPopoverFocus.popoverSelection(for: outcome))
    }

    func testEmptySurfaceIdOpensOverview() {
        let outcome = StatusPopoverFocus.outcome(surfaceId: "", isFallbackItem: false)
        XCTAssertEqual(outcome, .overview)
    }

    func testSurfaceIdMapLookup() {
        // Retain NSObject for ObjectIdentifier lifetime (avoids free/reuse alias flake).
        let buttonA = NSObject()
        let buttonB = NSObject()
        let a = ObjectIdentifier(buttonA)
        let b = ObjectIdentifier(buttonB)
        let map = ["codex": a, "claude": b]
        XCTAssertEqual(
            StatusPopoverFocus.surfaceId(matchingButtonIdentity: b, providerButtonIdentities: map),
            "claude"
        )
        XCTAssertEqual(
            StatusPopoverFocus.surfaceId(matchingButtonIdentity: a, providerButtonIdentities: map),
            "codex"
        )
        let other = NSObject()
        XCTAssertNil(
            StatusPopoverFocus.surfaceId(
                matchingButtonIdentity: ObjectIdentifier(other),
                providerButtonIdentities: map
            )
        )
        withExtendedLifetime(buttonA) {}
        withExtendedLifetime(buttonB) {}
        withExtendedLifetime(other) {}
    }
}
