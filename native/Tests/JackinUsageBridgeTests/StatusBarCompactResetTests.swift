// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import XCTest

/// Pure string compacting for status-bar dual-stack.
///
/// Mirrors `StatusItemRendering.compactResetCountdown` logic so the bridge
/// test target can verify without AppKit / JackinDesktop linkage.
final class StatusBarCompactResetTests: XCTestCase {
    private func compact(_ resetLabel: String?) -> String? {
        guard var text = resetLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else {
            return nil
        }
        let prefixes = ["Resets in ", "Resets ", "resets in ", "resets "]
        for prefix in prefixes where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
            break
        }
        if let head = text.split(separator: "·", maxSplits: 1, omittingEmptySubsequences: true)
            .first
        {
            text = head.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let head = text.split(separator: "(", maxSplits: 1, omittingEmptySubsequences: true)
            .first
        {
            text = head.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text.isEmpty ? nil : text
    }

    func testStripsResetsInPrefix() {
        XCTAssertEqual(compact("Resets in 3d"), "3d")
        XCTAssertEqual(compact("Resets in 2h 14m"), "2h 14m")
        XCTAssertEqual(compact("Resets daily"), "daily")
    }

    func testTakesSegmentBeforeDotSeparator() {
        XCTAssertEqual(compact("Resets in 3d · (15 Aug 2026)"), "3d")
    }

    func testNilAndEmpty() {
        XCTAssertNil(compact(nil))
        XCTAssertNil(compact(""))
        XCTAssertNil(compact("   "))
    }
}
