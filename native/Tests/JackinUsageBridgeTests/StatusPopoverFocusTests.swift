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
        let a = ObjectIdentifier(NSObject())
        let b = ObjectIdentifier(NSObject())
        let map = ["codex": a, "claude": b]
        XCTAssertEqual(
            StatusPopoverFocus.surfaceId(matchingButtonIdentity: b, providerButtonIdentities: map),
            "claude"
        )
        XCTAssertNil(
            StatusPopoverFocus.surfaceId(
                matchingButtonIdentity: ObjectIdentifier(NSObject()),
                providerButtonIdentities: map
            )
        )
    }
}
