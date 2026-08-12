// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest

@testable import JackinUsageBridge

final class ProviderUsageLinksTests: XCTestCase {
    func testDesktopProviderOrderHasOfficialURLs() {
        XCTAssertTrue(
            ProviderUsageLinks.desktopProviderURLsComplete,
            "every DESKTOP_PROVIDER_ORDER surface must have OFFICIAL_USAGE_URLS entry"
        )
        for id in ProviderUsageLinks.desktopProviderOrder {
            guard let urlString = ProviderUsageLinks.usagePageString(surfaceId: id) else {
                return XCTFail("missing usage URL for \(id)")
            }
            XCTAssertNotNil(ProviderUsageLinks.usagePageURL(surfaceId: id), id)
            XCTAssertTrue(urlString.hasPrefix("https://"), id)
        }
    }

    func testUnknownSurfaceHasNoURL() {
        XCTAssertNil(ProviderUsageLinks.usagePageString(surfaceId: "opencode"))
        XCTAssertNil(ProviderUsageLinks.usagePageURL(surfaceId: "unknown"))
    }

    func testOpenUsagePageTitleIsFixed() {
        XCTAssertEqual(ProviderUsageLinks.openUsagePageTitle, "Open usage page")
    }
}
