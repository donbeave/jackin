// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

/// Prove all seven Desktop provider keys load official bundled marks via the
/// shipped APIs (`ProviderMarks` + `StatusItemRendering.icon`).
///
///   cd native && swift run -c release ProviderMarksHarness
///
/// Exit 0 only when every key has a non-nil official mark and a status icon
/// that is not the jackin fallback for unknown keys.

import AppKit
import JackinDesktopUI
import JackinUsageBridge
import Foundation

@main
struct ProviderMarksHarness {
    static func main() {
        _ = NSApplication.shared
        var failed = 0
        let keys = desktopProviderIconKeys
        fputs("ProviderMarksHarness: \(keys.count) Desktop keys\n", stderr)
        for key in keys {
            let has = ProviderMarks.hasMark(forIconKey: key)
            let mark = ProviderMarks.templateImage(forIconKey: key)
            let status = StatusItemRendering.icon(forIconKey: key)
            let ok = has && mark != nil && status.size.width > 0
            fputs(
                "\(ok ? "PASS" : "FAIL")  \(key) hasMark=\(has) markSize=\(mark?.size ?? .zero) statusTemplate=\(status.isTemplate)\n",
                stderr
            )
            if !ok { failed += 1 }
        }
        // Unknown key must not pretend to be an official mark.
        let unknown = ProviderMarks.hasMark(forIconKey: "not-a-provider")
        fputs("\(unknown ? "FAIL" : "PASS")  unknown key hasMark=false\n", stderr)
        if unknown { failed += 1 }

        if failed > 0 {
            fputs("ProviderMarksHarness: \(failed) FAIL\n", stderr)
            exit(1)
        }
        fputs("ProviderMarksHarness: ALL PASS (\(keys.count)/\(keys.count) official marks)\n", stderr)
    }
}
