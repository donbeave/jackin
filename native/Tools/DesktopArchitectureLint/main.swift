// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

/// Pure architecture lint for JackinDesktop sources (no XCTest).
///
/// Mirrors ArchitectureTests.testDesktopSourcesDoNotComposePercentOrResetLiterals
/// so CLT environments without XCTest still gate the same CI hard-ban:
/// - no `String(format:` under JackinDesktop
/// - no usage-string tokens `% left` / `% used` / `resets ` outside SettingsView
///   (Settings chrome picker labels remain allowlisted)
///
/// Run after XCFramework exists:
///   cd native && swift run -c release DesktopArchitectureLint

import Foundation

@main
struct DesktopArchitectureLint {
    static func main() {
        let fm = FileManager.default
        // Package root = parent of Tools/
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
        let desktop =
            cwd.appendingPathComponent("Sources/JackinDesktop")
        guard fm.fileExists(atPath: desktop.path) else {
            // Allow running from repo root
            let alt = cwd.appendingPathComponent("native/Sources/JackinDesktop")
            if fm.fileExists(atPath: alt.path) {
                run(desktopRoot: alt)
                return
            }
            fputs("FAIL  JackinDesktop sources not found at \(desktop.path)\n", stderr)
            exit(2)
        }
        let bridgeRoot = desktop.deletingLastPathComponent()
            .appendingPathComponent("JackinUsageBridge")
        checkBridgeSerialization(bridgeRoot: bridgeRoot)
        checkGlassGate(desktopRoot: desktop)
        checkUsageWindowToolbarHost(desktopRoot: desktop)
        checkStatusPopoverFocusWiring(desktopRoot: desktop)
        checkPrimaryControlCraft(desktopRoot: desktop)
        checkUsageDetailGrouping(desktopRoot: desktop)
        checkUsageAccountRail(desktopRoot: desktop)
        run(desktopRoot: desktop)
    }

    /// LG-A / AR-4: no freestyle glass outside GlassFallbacks.
    static func checkGlassGate(desktopRoot: URL) {
        var failures = 0
        if let enumerator = FileManager.default.enumerator(
            at: desktopRoot,
            includingPropertiesForKeys: nil
        ) {
            while let url = enumerator.nextObject() as? URL {
                guard url.pathExtension == "swift" else { continue }
                let name = url.lastPathComponent
                if name == "GlassFallbacks.swift" { continue }
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
                if text.contains("glassEffect") || text.contains("#available(macOS 26") {
                    failures += 1
                    print("FAIL  \(name) contains glassEffect or #available(macOS 26 outside GlassFallbacks")
                }
            }
        }
        if failures == 0 {
            print("PASS  glassEffect / #available(macOS 26 only in GlassFallbacks")
        } else {
            print("DesktopArchitectureLint: glass-gate FAILURE")
            exit(1)
        }
    }

    /// FB1-65: Usage window must host via NSHostingController + unified toolbar.
    static func checkUsageWindowToolbarHost(desktopRoot: URL) {
        let path = desktopRoot.appendingPathComponent("UsageWindowController.swift")
        guard let text = try? String(contentsOf: path, encoding: .utf8) else {
            fputs("FAIL  UsageWindowController.swift missing\n", stderr)
            exit(2)
        }
        var ok = true
        if !text.contains("NSHostingController") {
            print("FAIL  UsageWindowController must use NSHostingController for NSToolbar")
            ok = false
        }
        if !text.contains("contentViewController") {
            print("FAIL  UsageWindowController must set contentViewController")
            ok = false
        }
        if !text.contains("toolbarStyle = .unified") {
            print("FAIL  UsageWindowController must set toolbarStyle = .unified")
            ok = false
        }
        if text.contains("contentView = NSHostingView") {
            print("FAIL  UsageWindowController must not assign contentView = NSHostingView (toolbar dies)")
            ok = false
        }
        if !text.contains("titleVisibility = .hidden") {
            print("FAIL  UsageWindowController must hide duplicate leading NSWindow title")
            ok = false
        }
        let rootPath = desktopRoot.appendingPathComponent("UsageWindow/UsageWindowRoot.swift")
        let rootText = try? String(contentsOf: rootPath, encoding: .utf8)
        if rootText?.contains("ToolbarItem(placement: .principal)") != true {
            print("FAIL  Usage toolbar must center brand in a principal item")
            ok = false
        }
        if ok {
            print("PASS  UsageWindowController NSToolbar hosting")
        } else {
            print("DesktopArchitectureLint: toolbar-host FAILURE")
            exit(1)
        }
    }

    /// Status left-click must focus provider (StatusPopoverFocus + popoverSelection).
    static func checkStatusPopoverFocusWiring(desktopRoot: URL) {
        let path = desktopRoot.appendingPathComponent("DesktopAppDelegate.swift")
        guard let text = try? String(contentsOf: path, encoding: .utf8) else {
            fputs("FAIL  DesktopAppDelegate.swift missing\n", stderr)
            exit(2)
        }
        var ok = true
        if !text.contains("StatusPopoverFocus") {
            print("FAIL  DesktopAppDelegate must use StatusPopoverFocus for left-click focus")
            ok = false
        }
        if !text.contains("popoverSelection") {
            print("FAIL  DesktopAppDelegate must set store.popoverSelection on left-click")
            ok = false
        }
        if ok {
            print("PASS  status left-click popover focus wiring")
        } else {
            print("DesktopArchitectureLint: status-focus FAILURE")
            exit(1)
        }
    }

    /// LG-A9: primary actions use selective tint, never solid phosphor slabs.
    static func checkPrimaryControlCraft(desktopRoot: URL) {
        let providerCard = desktopRoot
            .appendingPathComponent("UsageWindow/ProviderCardView.swift")
        let popoverFooter = desktopRoot
            .appendingPathComponent("Popover/PopoverFooter.swift")
        let popoverProvider = desktopRoot
            .appendingPathComponent("Popover/PopoverProviderTab.swift")
        guard
            let providerText = try? String(contentsOf: providerCard, encoding: .utf8),
            let footerText = try? String(contentsOf: popoverFooter, encoding: .utf8),
            let popoverProviderText = try? String(contentsOf: popoverProvider, encoding: .utf8)
        else {
            fputs("FAIL  primary control sources missing\n", stderr)
            exit(2)
        }

        var ok = true
        if providerText.contains(".fill(Color.jackinPhosphor.opacity(0.92))") {
            print("FAIL  Open usage page must not use a solid phosphor slab")
            ok = false
        }
        if !providerText.contains(".strokeBorder(Color.jackinPhosphor.opacity(0.32)") {
            print("FAIL  Open usage page must retain the HTML accent hairline")
            ok = false
        }
        if !footerText.contains(".frame(maxWidth: .infinity, alignment: .center)")
            || !footerText.contains(".foregroundStyle(Color.jackinPhosphor)")
        {
            print("FAIL  popover Open Usage Window must stay centered and accent-tinted")
            ok = false
        }
        if !popoverProviderText.contains("providerLogoPlate")
            || !popoverProviderText.contains("onRefreshProvider(provider.surfaceId)")
        {
            print("FAIL  popover provider header must retain logo plate + local refresh")
            ok = false
        }
        if popoverProviderText.contains("systemImage: \"safari\"")
            || !popoverProviderText.contains("Image(systemName: \"arrow.up.right\")")
        {
            print("FAIL  popover usage link must use the HTML external-link affordance")
            ok = false
        }
        if !popoverProviderText.contains("JackinBrand.accountSelectionFill")
            || !popoverProviderText.contains("JackinBrand.accountSelectionInk")
        {
            print("FAIL  popover account selection must use dual-theme HTML tokens")
            ok = false
        }
        if !popoverProviderText.contains("size: 32, weight: .semibold, design: .monospaced")
            || !popoverProviderText.contains("GlassFallbacks.popoverContentCardBackground()")
        {
            print("FAIL  popover metric type/card geometry must match HTML 32/14 tokens")
            ok = false
        }
        if ok {
            print("PASS  primary controls avoid solid phosphor slabs")
        } else {
            print("DesktopArchitectureLint: primary-control FAILURE")
            exit(1)
        }
    }

    /// G-U6: limit rows share one list container; row helpers cannot create cards.
    static func checkUsageDetailGrouping(desktopRoot: URL) {
        let path = desktopRoot.appendingPathComponent("UsageWindow/ProviderCardView.swift")
        guard let text = try? String(contentsOf: path, encoding: .utf8) else {
            fputs("FAIL  ProviderCardView.swift missing\n", stderr)
            exit(2)
        }
        let required = [
            "private var limitList: some View",
            "ForEach(Array(bucketRows.enumerated())",
            "if index > 0 {",
            "private func bucketRow",
            "private func limitResetCreditsRow",
        ]
        let forbidden = ["private func bucketCard", "private func limitResetCreditsCard"]
        let ok = required.allSatisfy(text.contains) && forbidden.allSatisfy { !text.contains($0) }
        if ok {
            print("PASS  Usage detail groups limit rows in one list")
        } else {
            print("FAIL  Usage detail must retain one limit-list container with divided rows")
            exit(1)
        }
    }

    /// G-U4: account rows share one inset rail; list rows cannot each own a well.
    static func checkUsageAccountRail(desktopRoot: URL) {
        let path = desktopRoot.appendingPathComponent("UsageWindow/UsageWindowRoot.swift")
        guard let text = try? String(contentsOf: path, encoding: .utf8) else {
            fputs("FAIL  UsageWindowRoot.swift missing\n", stderr)
            exit(2)
        }
        let required = [
            "UsageAccountRailView(accounts: accts)",
            ".listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: -12))",
        ]
        if required.allSatisfy(text.contains)
            && !text.contains("listRowBackground(accountNestWellBackground)")
            && !text.contains("private func accountSidebarRow")
        {
            print("PASS  Usage account rows share one inset rail")
        } else {
            print("FAIL  Usage account nest must retain one labeled inset rail")
            exit(1)
        }
    }

    /// Plan 002 Step 5: every `UsageMenuBarBridge` access must be serialized off
    /// the main actor through `RefreshScheduler`, so `PresentationStore` holds no
    /// bridge reference and makes no direct `bridge.` calls — the only bridge
    /// access is inside `scheduler.run { … }` closures (whose parameter is named
    /// `handle`). A stray `bridge.` in code would re-introduce a main-actor
    /// freeze during a Keychain consent sheet.
    static func checkBridgeSerialization(bridgeRoot: URL) {
        let store = bridgeRoot.appendingPathComponent("PresentationStore.swift")
        guard let text = try? String(contentsOf: store, encoding: .utf8) else {
            fputs("FAIL  PresentationStore.swift not found for bridge-serialization scan\n", stderr)
            exit(2)
        }
        var offenders: [Int] = []
        for (index, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
        {
            // Strip line/inline comments before scanning for code access.
            let code = String(rawLine).components(separatedBy: "//").first ?? ""
            if code.contains("bridge.") || code.contains("UsageMenuBarBridge") {
                offenders.append(index + 1)
            }
        }
        if offenders.isEmpty && text.contains("scheduler") {
            print("PASS  PresentationStore.swift serializes all bridge access via RefreshScheduler")
        } else {
            for line in offenders {
                print("FAIL  PresentationStore.swift:\(line) direct bridge access outside RefreshScheduler")
            }
            if !text.contains("scheduler") {
                print("FAIL  PresentationStore.swift does not reference RefreshScheduler")
            }
            print("DesktopArchitectureLint: bridge-serialization FAILURE")
            exit(1)
        }
    }

    static func run(desktopRoot: URL) {
        let usageStringTokens = ["% left", "% used", "resets "]
        let alwaysBanned = ["String(format:"]
        // Preference chrome may label pickers; StatusItemLabel parses Rust reset prefixes.
        let preferenceChromeFiles: Set<String> = ["SettingsView.swift"]
        let resetParserFiles: Set<String> = ["StatusItemLabel.swift"]

        var files: [URL] = []
        if let enumerator = FileManager.default.enumerator(
            at: desktopRoot,
            includingPropertiesForKeys: nil
        ) {
            while let url = enumerator.nextObject() as? URL {
                if url.pathExtension == "swift" {
                    files.append(url)
                }
            }
        }
        guard !files.isEmpty else {
            fputs("FAIL  no Swift files under \(desktopRoot.path)\n", stderr)
            exit(2)
        }

        var failures = 0
        for file in files {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else {
                failures += 1
                print("FAIL  unreadable \(file.lastPathComponent)")
                continue
            }
            let name = file.lastPathComponent
            for token in alwaysBanned {
                if text.contains(token) {
                    failures += 1
                    print("FAIL  \(name) contains banned \(token)")
                }
            }
            if preferenceChromeFiles.contains(name) {
                print("PASS  \(name) (preference chrome allowlist)")
                continue
            }
            for token in usageStringTokens {
                if resetParserFiles.contains(name), token == "resets " {
                    continue
                }
                // Strip // comments so doc examples don't trip product-string bans.
                let codeOnly = text.split(separator: "\n").map { line -> String in
                    let s = String(line)
                    if let r = s.range(of: "//") { return String(s[..<r.lowerBound]) }
                    return s
                }.joined(separator: "\n")
                if codeOnly.contains(token) {
                    failures += 1
                    print("FAIL  \(name) contains banned usage-string token \(token)")
                }
            }
            if failures == 0 || !usageStringTokens.contains(where: { text.contains($0) }) {
                // per-file ok only when no failure on this file — simplify: print pass if clean
            }
        }

        // Re-scan clean summary
        var clean = 0
        for file in files {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { continue }
            let name = file.lastPathComponent
            var bad = false
            for token in alwaysBanned where text.contains(token) {
                bad = true
            }
            if !preferenceChromeFiles.contains(name) {
                let codeOnly = text.split(separator: "\n").map { line -> String in
                    let s = String(line)
                    if let r = s.range(of: "//") { return String(s[..<r.lowerBound]) }
                    return s
                }.joined(separator: "\n")
                for token in usageStringTokens {
                    if resetParserFiles.contains(name), token == "resets " { continue }
                    if codeOnly.contains(token) { bad = true }
                }
            }
            if !bad {
                clean += 1
                print("PASS  \(name)")
            }
        }

        print("---")
        print("DesktopArchitectureLint: scanned \(files.count) files, \(clean) clean")
        if failures == 0 {
            print("DesktopArchitectureLint: ALL PASS")
            exit(0)
        } else {
            print("DesktopArchitectureLint: \(failures) FAILURE(S)")
            exit(1)
        }
    }
}
