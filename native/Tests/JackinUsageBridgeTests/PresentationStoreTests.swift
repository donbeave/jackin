// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest

@testable import JackinUsageBridge

final class PresentationStoreTests: XCTestCase {
    func testProductionLaunchDoesNotRequireSwiftOwnedHostPaths() {
        let launch = PresentationStore.LaunchConfiguration.resolve(
            environment: [:],
            homeDirectory: "/operator"
        )
        XCTAssertEqual(launch, .production)
    }

    func testDiscoveryDiagnosticKeepsRustOwnedSanitizedCopy() {
        let diagnostic = PresentationStore.DiscoveryDiagnostic(
            surfaceId: "claude",
            scopeLabel: "workspace sample",
            issue: "credential_denied",
            message: "Credential access was denied",
            displayLabel: "workspace sample: Credential access was denied"
        )

        XCTAssertEqual(diagnostic.id, "claude#workspace sample#credential_denied")
        XCTAssertEqual(
            diagnostic.displayLabel,
            "workspace sample: Credential access was denied"
        )
        XCTAssertFalse(diagnostic.displayLabel.contains("/Users/"))
        XCTAssertFalse(diagnostic.displayLabel.contains("op://"))
    }
}
