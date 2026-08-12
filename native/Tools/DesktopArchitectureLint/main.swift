// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import Darwin
import Foundation

@main
struct DesktopArchitectureLint {
    static func main() throws {
        let manager = FileManager.default
        let current = URL(fileURLWithPath: manager.currentDirectoryPath)
        let root =
            manager.fileExists(atPath: current.appendingPathComponent("Sources").path)
            ? current
            : current.appendingPathComponent("native")
        let desktop = root.appendingPathComponent("Sources/JackinDesktop")
        var failures: [String] = []

        func read(_ relativePath: String) -> String {
            let url = desktop.appendingPathComponent(relativePath)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else {
                failures.append("missing \(relativePath)")
                return ""
            }
            return text
        }

        func require(_ condition: Bool, _ message: String) {
            if condition {
                print("PASS  \(message)")
            } else {
                failures.append(message)
                print("FAIL  \(message)")
            }
        }

        let popover = read("PopoverRoot.swift")
        let delegate = read("DesktopAppDelegate.swift")
        let usage = read("UsageWindow/UsageWindowRoot.swift")
        let overview = read("UsageWindow/OverviewListView.swift")
        let provider = read("UsageWindow/ProviderDetailView.swift")

        require(delegate.contains("NSPopover()"), "real NSPopover host")
        require(
            delegate.contains("NSHostingController(rootView: root)"), "ordinary native popover host"
        )
        require(
            !delegate.contains("popover.appearance =")
                && !delegate.contains("popover.contentViewController?.view.wantsLayer"),
            "system popover appearance preserved"
        )
        require(
            !delegate.contains("popover.backgroundColor")
                && !delegate.contains("popover.hasShadow"),
            "system popover material and shadow preserved"
        )

        require(popover.contains("Form {"), "popover uses native Form")
        require(popover.contains("Picker(\"Account\""), "popover uses native account Picker")
        require(popover.contains("ProgressView(value:"), "popover uses native limit progress")
        require(!popover.contains("PopoverTabGrid"), "popover has no provider tab strip")

        require(usage.contains("NavigationSplitView"), "Usage uses NavigationSplitView")
        require(usage.contains(".listStyle(.sidebar)"), "Usage uses native sidebar List")
        require(
            usage.contains("List(selection: destination)")
                && usage.contains("private var destination: Binding")
                && !usage.contains("@State private var destination"),
            "Usage sidebar has one store-owned selection authority"
        )
        require(
            usage.contains("ToolbarItem(placement: .primaryAction)"), "Usage uses native toolbar")
        let usageController = read("UsageWindowController.swift")
        require(
            usageController.contains(".moveToActiveSpace")
                && read("AppMainMenu.swift").contains("window.orderFrontRegardless()"),
            "retained Usage window follows explicit reopen to the active Space"
        )
        require(overview.contains("Table("), "Overview uses native Table")
        require(provider.contains("List {"), "provider detail uses native List")
        require(
            provider.contains("Picker(\"Account\""), "provider detail uses native account Picker")
        require(
            provider.contains("ProgressView(value:"), "provider detail uses native limit progress")

        let retired = [
            "GlassFallbacks.swift",
            "GlassPopoverHostingController.swift",
            "Popover/PopoverTabGrid.swift",
            "Popover/PopoverFooter.swift",
            "UsageWindow/UsageAccountNestView.swift",
        ]
        for path in retired {
            require(
                !manager.fileExists(atPath: desktop.appendingPathComponent(path).path),
                "retired custom surface removed: \(path)"
            )
        }

        let enumerator = manager.enumerator(at: desktop, includingPropertiesForKeys: nil)
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            require(!text.contains("glassEffect"), "no custom glass in \(url.lastPathComponent)")
            require(
                !text.contains("NSVisualEffectView"),
                "no hand-painted material in \(url.lastPathComponent)"
            )
        }

        if !failures.isEmpty {
            fputs("DesktopArchitectureLint: \(failures.count) failure(s)\n", stderr)
            Darwin.exit(1)
        }
        print("DesktopArchitectureLint: A1 native structure OK")
    }
}
