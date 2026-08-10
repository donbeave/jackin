// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

/// QI native captures via **shipped** views + `PresentationStore.applyQIFixture`.
///
///   cd native && swift run -c release DesktopVisualSnapshotHarness [outDir]
///
/// Does **not** re-implement dual-stack, toolbar, or popover chrome. Those come
/// from StatusItemRendering, UsageWindowController (real NSToolbar host), and
/// PopoverRoot (TabGrid + body + Footer).
///
/// Live `NSStatusItem` in the system menu bar remains uncapturable on CLT —
/// status PNGs are StatusItemRendering bitmap composites only (documented).

import AppKit
import JackinDesktopUI
import JackinUsageBridge
import SwiftUI

@main
struct DesktopVisualSnapshotHarness {
    static func main() {
        let out =
            CommandLine.arguments.count > 1
            ? CommandLine.arguments[1]
            : FileManager.default.currentDirectoryPath + "/qi-native-out"
        try? FileManager.default.createDirectory(
            atPath: out,
            withIntermediateDirectories: true
        )

        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)

        let fixture = QIFixture.make()

        // ── Dark: full PopoverRoot shell (tab grid + body + footer) ──
        NSApp.appearance = NSAppearance(named: .darkAqua)
        // Tall enough for G-P1 chrome (brand + mode + strip) + body + footer.
        capturePopover(
            fixture: fixture,
            selection: "codex",
            size: NSSize(width: 430, height: 640),
            path: "\(out)/popover-openai-dark.png",
            appearance: .darkAqua
        )
        capturePopover(
            fixture: fixture,
            selection: "claude",
            size: NSSize(width: 430, height: 600),
            path: "\(out)/popover-anthropic-dark.png",
            appearance: .darkAqua
        )

        // Usage detail / overview / nest — shipped detail surfaces
        render(
            ProviderCardView(
                content: UsageWindowModel.Content(
                    surfaceId: "codex",
                    displayLabel: "OpenAI",
                    iconKey: "codex",
                    detail: fixture.openaiDetail,
                    accounts: fixture.openaiAccounts
                )
            )
            .frame(width: 640, height: 720)
            .padding(8)
            .background(Color(nsColor: .windowBackgroundColor)),
            size: NSSize(width: 656, height: 736),
            path: "\(out)/usage-detail-openai-dark.png",
            appearance: .darkAqua
        )

        let storeOverview = makeStore(fixture: fixture, popover: nil, usage: nil)
        let overviewModel = UsageWindowModel(
            glanceRows: storeOverview.providerGlanceRows,
            surfaces: storeOverview.surfaces,
            accounts: storeOverview.accounts,
            selection: nil
        )
        render(
            OverviewListView(model: overviewModel, accounts: storeOverview.accounts) { _, _ in }
                .frame(width: 640, height: 560)
                .padding(8)
                .background(Color(nsColor: .windowBackgroundColor)),
            size: NSSize(width: 656, height: 576),
            path: "\(out)/usage-overview-dark.png",
            appearance: .darkAqua
        )
        render(
            UsageAccountNestView(
                providerLabel: "OpenAI",
                accounts: fixture.openaiAccounts
            )
            .frame(width: 280, height: 220)
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor)),
            size: NSSize(width: 304, height: 244),
            path: "\(out)/usage-provider-nest-dark.png",
            appearance: .darkAqua
        )

        // Status dual-stack via **StatusItemRendering** (not a hand-rolled layout).
        captureStatusItemRendering(
            fixture: fixture,
            path: "\(out)/status-desktop-dark.png",
            appearance: .darkAqua
        )

        // Real NSWindow (toolbar + sidebar nest + detail) via UsageWindowController.
        // Prefer CGWindow full-window over NSHostingView NavigationSplitView (sidebar blank offscreen).
        let windowOkDark = captureUsageWindow(
            fixture: fixture,
            focusSurfaceId: "codex",
            appearance: .darkAqua,
            fullPath: "\(out)/usage-window-openai-dark.png",
            toolbarPath: "\(out)/usage-toolbar-dark.png"
        )
        let overviewOkDark = captureUsageWindow(
            fixture: fixture,
            focusSurfaceId: nil,
            appearance: .darkAqua,
            fullPath: "\(out)/usage-window-overview-dark.png",
            toolbarPath: nil
        )
        let toolbarOkDark = windowOkDark

        // ── Light ──
        NSApp.appearance = NSAppearance(named: .aqua)
        capturePopover(
            fixture: fixture,
            selection: "codex",
            size: NSSize(width: 430, height: 640),
            path: "\(out)/popover-openai-light.png",
            appearance: .aqua
        )
        capturePopover(
            fixture: fixture,
            selection: "claude",
            size: NSSize(width: 430, height: 600),
            path: "\(out)/popover-anthropic-light.png",
            appearance: .aqua
        )
        render(
            ProviderCardView(
                content: UsageWindowModel.Content(
                    surfaceId: "codex",
                    displayLabel: "OpenAI",
                    iconKey: "codex",
                    detail: fixture.openaiDetail,
                    accounts: fixture.openaiAccounts
                )
            )
            .frame(width: 640, height: 720)
            .padding(8)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, .light),
            size: NSSize(width: 656, height: 736),
            path: "\(out)/usage-detail-openai-light.png",
            appearance: .aqua
        )
        render(
            OverviewListView(model: overviewModel, accounts: storeOverview.accounts) { _, _ in }
                .frame(width: 640, height: 560)
                .padding(8)
                .background(Color(nsColor: .windowBackgroundColor))
                .environment(\.colorScheme, .light),
            size: NSSize(width: 656, height: 576),
            path: "\(out)/usage-overview-light.png",
            appearance: .aqua
        )
        render(
            UsageAccountNestView(
                providerLabel: "OpenAI",
                accounts: fixture.openaiAccounts
            )
            .frame(width: 280, height: 220)
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, .light),
            size: NSSize(width: 304, height: 244),
            path: "\(out)/usage-provider-nest-light.png",
            appearance: .aqua
        )
        captureStatusItemRendering(
            fixture: fixture,
            path: "\(out)/status-desktop-light.png",
            appearance: .aqua
        )
        let windowOkLight = captureUsageWindow(
            fixture: fixture,
            focusSurfaceId: "codex",
            appearance: .aqua,
            fullPath: "\(out)/usage-window-openai-light.png",
            toolbarPath: "\(out)/usage-toolbar-light.png"
        )
        let overviewOkLight = captureUsageWindow(
            fixture: fixture,
            focusSurfaceId: nil,
            appearance: .aqua,
            fullPath: "\(out)/usage-window-overview-light.png",
            toolbarPath: nil
        )
        let toolbarOkLight = windowOkLight

        // Manifest for VISUAL_QA_LOG honesty
        let manifest = """
        # DesktopVisualSnapshotHarness manifest
        out: \(out)
        popover: PopoverRoot (TabGrid + ProviderTab + Footer) via PresentationStore.applyQIFixture
        status: StatusItemRendering.icon + StatusItemRendering.title (AppKit bitmap)
        status_live_nsstatusitem: prefer live screencapture when JackinDesktop is running (see VISUAL_QA_LOG)
        usage_window: UsageWindowController CGWindow full (sidebar nest + detail) — not blank NSHostingView split
        usage_detail: ProviderCardView (+ window detail column)
        usage_overview: OverviewListView (+ window overview)
        usage_nest: UsageAccountNestView (+ window sidebar when CGWindow OK)
        usage_window_openai_dark: \(windowOkDark ? "OK" : "BLOCKED")
        usage_window_overview_dark: \(overviewOkDark ? "OK" : "BLOCKED")
        usage_window_openai_light: \(windowOkLight ? "OK" : "BLOCKED")
        usage_window_overview_light: \(overviewOkLight ? "OK" : "BLOCKED")
        usage_toolbar_dark: \(toolbarOkDark ? "UsageWindowController titlebar crop" : "BLOCKED")
        usage_toolbar_light: \(toolbarOkLight ? "UsageWindowController titlebar crop" : "BLOCKED")
        """
        try? manifest.write(
            to: URL(fileURLWithPath: "\(out)/MANIFEST.md"),
            atomically: true,
            encoding: .utf8
        )
        print(manifest)
        print("DesktopVisualSnapshotHarness: wrote snapshots to \(out)")
    }

    // MARK: - Shipped capture paths

    @MainActor
    private static func makeStore(
        fixture: QIFixture,
        popover: String?,
        usage: String?
    ) -> PresentationStore {
        let store = PresentationStore()
        store.applyQIFixture(
            glanceRows: fixture.glanceRows,
            surfaces: fixture.surfaces,
            accounts: fixture.allAccounts,
            popoverSelection: popover,
            usageSelection: usage
        )
        return store
    }

    @MainActor
    private static func capturePopover(
        fixture: QIFixture,
        selection: String,
        size: NSSize,
        path: String,
        appearance: NSAppearance.Name
    ) {
        let store = makeStore(fixture: fixture, popover: selection, usage: selection)
        // Stage color matches appearance so Light chrome never sits on black void.
        let stage =
            appearance == .darkAqua
            ? Color(nsColor: .underPageBackgroundColor)
            : Color(nsColor: .windowBackgroundColor)
        render(
            ZStack {
                stage
                PopoverRoot(store: store)
            }
            .frame(width: size.width, height: size.height),
            size: size,
            path: path,
            appearance: appearance
        )
    }

    /// Bitmap dual-stack extras using **only** StatusItemRendering APIs.
    @MainActor
    private static func captureStatusItemRendering(
        fixture: QIFixture,
        path: String,
        appearance: NSAppearance.Name
    ) {
        let rows = fixture.glanceRows
        let iconSize: CGFloat = 16
        let cellW: CGFloat = 52
        let height: CGFloat = 36
        let width = CGFloat(rows.count) * cellW + 16
        let size = NSSize(width: width, height: height)

        let image = NSImage(size: size)
        image.lockFocus()
        if let nsApp = NSAppearance(named: appearance) {
            nsApp.performAsCurrentDrawingAppearance {
                drawStatusStrip(rows: rows, iconSize: iconSize, cellW: cellW, height: height)
            }
        } else {
            drawStatusStrip(rows: rows, iconSize: iconSize, cellW: cellW, height: height)
        }
        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:])
        else {
            fputs("FAIL status StatusItemRendering png \(path)\n", stderr)
            writeBlockedPlaceholder(path: path, reason: "StatusItemRendering encode failed")
            return
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            print("WROTE \(path) [StatusItemRendering]")
        } catch {
            fputs("FAIL write \(path): \(error)\n", stderr)
        }
    }

    @MainActor
    private static func drawStatusStrip(
        rows: [PresentationStore.GlanceProviderRow],
        iconSize: CGFloat,
        cellW: CGFloat,
        height: CGFloat
    ) {
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: CGFloat(rows.count) * cellW + 16, height: height).fill()

        var x: CGFloat = 8
        for row in rows {
            let icon = StatusItemRendering.icon(forIconKey: row.iconKey)
            let iconRect = NSRect(x: x, y: (height - iconSize) / 2, width: iconSize, height: iconSize)
            icon.draw(
                in: iconRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high]
            )

            let title = StatusItemRendering.title(
                barLabel: row.barLabel,
                resetLabel: row.resetLabel
            )
            let textRect = NSRect(
                x: x + iconSize + 2,
                y: 2,
                width: cellW - iconSize - 4,
                height: height - 4
            )
            title.draw(in: textRect)
            x += cellW
        }
    }

    /// Real `UsageWindowController` NSWindow via CGWindow (sidebar + detail + toolbar).
    /// Returns false when capture fails — never invents a stand-in window chrome.
    @MainActor
    @discardableResult
    private static func captureUsageWindow(
        fixture: QIFixture,
        focusSurfaceId: String?,
        appearance: NSAppearance.Name,
        fullPath: String,
        toolbarPath: String?
    ) -> Bool {
        NSApp.appearance = NSAppearance(named: appearance)
        let store = makeStore(
            fixture: fixture,
            popover: focusSurfaceId,
            usage: focusSurfaceId
        )
        let controller = UsageWindowController(store: store)
        controller.show(focusOn: focusSurfaceId)
        guard let window = controller.qiWindow else {
            fputs("FAIL usage window: no window for \(fullPath)\n", stderr)
            writeBlockedPlaceholder(path: fullPath, reason: "UsageWindowController.qiWindow nil")
            if let toolbarPath {
                writeBlockedPlaceholder(path: toolbarPath, reason: "UsageWindowController.qiWindow nil")
            }
            controller.invalidate()
            return false
        }

        window.setFrame(NSRect(x: 80, y: 80, width: 920, height: 620), display: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        window.layoutIfNeeded()
        window.contentViewController?.view.layoutSubtreeIfNeeded()
        // Allow NavigationSplitView + toolbar to materialize before CGWindow grab.
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.45))

        guard let full = captureFullWindowImage(window: window) else {
            writeBlockedPlaceholder(
                path: fullPath,
                reason: "CGWindow full-window capture unavailable"
            )
            if let toolbarPath {
                writeBlockedPlaceholder(
                    path: toolbarPath,
                    reason: "CGWindow full-window capture unavailable"
                )
            }
            print("BLOCKED \(fullPath) [CGWindow]")
            controller.invalidate()
            return false
        }

        // Full window PNG
        if !writeCGImagePNG(full, path: fullPath) {
            controller.invalidate()
            return false
        }
        print("WROTE \(fullPath) [UsageWindowController full CGWindow]")

        // Titlebar/toolbar band crop
        if let toolbarPath {
            let scale = CGFloat(full.width) / max(window.frame.width, 1)
            let bandPx = max(1, Int((56 * scale).rounded()))
            let cropH = min(bandPx, full.height)
            if let band = full.cropping(to: CGRect(x: 0, y: 0, width: full.width, height: cropH)),
                writeCGImagePNG(band, path: toolbarPath)
            {
                print("WROTE \(toolbarPath) [UsageWindowController titlebar crop]")
            } else {
                writeBlockedPlaceholder(path: toolbarPath, reason: "titlebar crop failed")
            }
        }

        controller.invalidate()
        return true
    }

    @MainActor
    private static func captureFullWindowImage(window: NSWindow) -> CGImage? {
        let windowId = CGWindowID(window.windowNumber)
        guard windowId != 0 else { return nil }
        return CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowId,
            [.boundsIgnoreFraming, .bestResolution]
        )
    }

    private static func writeCGImagePNG(_ image: CGImage, path: String) -> Bool {
        let rep = NSBitmapImageRep(cgImage: image)
        guard let png = rep.representation(using: .png, properties: [:]) else {
            fputs("FAIL png encode \(path)\n", stderr)
            return false
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            fputs("FAIL write \(path): \(error)\n", stderr)
            return false
        }
    }

    private static func writeBlockedPlaceholder(path: String, reason: String) {
        // 1×1 transparent PNG + sidecar reason so absence of craft is honest.
        let size = NSSize(width: 4, height: 4)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        if let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:])
        {
            try? png.write(to: URL(fileURLWithPath: path))
        }
        let side = path.replacingOccurrences(of: ".png", with: ".BLOCKED.txt")
        try? reason.write(to: URL(fileURLWithPath: side), atomically: true, encoding: .utf8)
    }

    @MainActor
    private static func render<V: View>(
        _ view: V,
        size: NSSize,
        path: String,
        appearance: NSAppearance.Name
    ) {
        let scheme: ColorScheme = appearance == .darkAqua ? .dark : .light
        let root = view
            .frame(width: size.width, height: size.height)
            .environment(\.colorScheme, scheme)
            .preferredColorScheme(scheme)
        let host = NSHostingView(rootView: root)
        host.appearance = NSAppearance(named: appearance)
        host.wantsLayer = true
        host.layer?.backgroundColor =
            (appearance == .darkAqua
                ? NSColor.underPageBackgroundColor
                : NSColor.windowBackgroundColor).cgColor
        host.frame = NSRect(origin: .zero, size: size)
        // Two layout passes: glass/material chrome often needs a second tick.
        host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        host.layoutSubtreeIfNeeded()

        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
            fputs("FAIL bitmap for \(path)\n", stderr)
            return
        }
        host.cacheDisplay(in: host.bounds, to: rep)
        let image = NSImage(size: size)
        image.addRepresentation(rep)
        guard let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let png = bitmap.representation(using: .png, properties: [:])
        else {
            fputs("FAIL png encode \(path)\n", stderr)
            return
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            print("WROTE \(path)")
        } catch {
            fputs("FAIL write \(path): \(error)\n", stderr)
        }
    }
}

// MARK: - Fixtures (DATA_CONTRACT numbers — labels only, no invented %)

private struct QIFixture {
    let openaiGlance: PresentationStore.GlanceProviderRow
    let anthropicGlance: PresentationStore.GlanceProviderRow
    let ampGlance: PresentationStore.GlanceProviderRow
    let openaiSurface: PresentationStore.SurfaceRow
    let anthropicSurface: PresentationStore.SurfaceRow
    let openaiAccounts: [PresentationStore.AccountRow]
    let anthropicAccount: PresentationStore.AccountRow
    let allAccounts: [PresentationStore.AccountRow]
    let glanceRows: [PresentationStore.GlanceProviderRow]
    let surfaces: [PresentationStore.SurfaceRow]
    let openaiDetail: UsageDetailPresentation

    static func make() -> QIFixture {
        let openaiAccounts = [
            PresentationStore.AccountRow(
                surfaceId: "codex",
                accountKey: "a1",
                accountLabel: "alexey@chainargos.com",
                planLabel: "Pro 20×",
                selected: true,
                remainingPercent: 57,
                statusWord: "fresh",
                severity: "warn" // HTML a-meter mid / --status-mid
            ),
            PresentationStore.AccountRow(
                surfaceId: "codex",
                accountKey: "a2",
                accountLabel: "alexey@zhokhov.com",
                planLabel: "Plus",
                selected: false,
                remainingPercent: 0,
                statusWord: "fresh",
                severity: "normal" // depleted empty track
            ),
        ]
        let anthropicAccount = PresentationStore.AccountRow(
            surfaceId: "claude",
            accountKey: "p1",
            accountLabel: "Personal",
            planLabel: "Max 20×",
            selected: true,
            remainingPercent: 12,
            statusWord: "fresh",
            severity: "danger" // HTML a-meter low
        )
        let ampAccount = PresentationStore.AccountRow(
            surfaceId: "amp",
            accountKey: "free",
            accountLabel: "Free",
            planLabel: nil,
            selected: true,
            remainingPercent: 100,
            statusWord: "fresh",
            severity: "normal" // HTML a-meter high / phosphor
        )
        let openaiGlance = PresentationStore.GlanceProviderRow(
            surfaceId: "codex",
            iconKey: "codex",
            displayLabel: "OpenAI",
            accountLabel: "alexey@chainargos.com",
            planLabel: "Pro 20×",
            glanceRemainingPercent: 57,
            barLabel: "57%",
            headline: "57% left",
            resetLabel: "Resets in 3d",
            exactReset: "(15 Aug 2026, 17:02)",
            statusWord: "fresh",
            isRefreshing: false,
            statusLabel: "fresh",
            severity: "warn",
            updatedLabel: "Just now",
            lastError: nil,
            dimmed: false
        )
        let anthropicGlance = PresentationStore.GlanceProviderRow(
            surfaceId: "claude",
            iconKey: "claude",
            displayLabel: "Anthropic",
            accountLabel: "Personal",
            planLabel: "Max 20×",
            glanceRemainingPercent: 12,
            barLabel: "12%",
            headline: "12% left",
            resetLabel: "Resets in 1h",
            exactReset: nil,
            statusWord: "fresh",
            isRefreshing: false,
            statusLabel: "fresh",
            severity: "danger",
            updatedLabel: "2 min ago",
            lastError: nil,
            dimmed: false
        )
        let ampGlance = PresentationStore.GlanceProviderRow(
            surfaceId: "amp",
            iconKey: "amp",
            displayLabel: "Amp",
            accountLabel: "Free",
            planLabel: nil,
            glanceRemainingPercent: 100,
            barLabel: "100%",
            headline: "100% left",
            resetLabel: "Resets in 18h",
            exactReset: nil,
            statusWord: "fresh",
            isRefreshing: false,
            statusLabel: "fresh",
            severity: "normal",
            updatedLabel: "1 min ago",
            lastError: nil,
            dimmed: false
        )

        func bucket(
            id: String,
            label: String,
            remaining: String,
            meter: UInt8,
            severity: String,
            pace: String?,
            reset: String?
        ) -> UsageDetailRow {
            var lines: [UsagePresentationLine] = [
                UsagePresentationLine(leading: remaining, trailing: nil)
            ]
            if let pace {
                lines.append(UsagePresentationLine(leading: pace, trailing: nil))
            }
            if let reset {
                lines.append(UsagePresentationLine(leading: nil, trailing: reset))
            }
            return UsageDetailRow(
                rowId: id,
                kind: .bucket,
                label: label,
                layoutLines: lines,
                displayLabel: [remaining, pace, reset].compactMap { $0 }.joined(separator: " · "),
                meterPercent: meter,
                severity: severity
            )
        }

        let openaiDetail = UsageDetailPresentation(rows: [
            UsageDetailRow(
                rowId: "status",
                kind: .metadata,
                label: "Status",
                layoutLines: [UsagePresentationLine(leading: "fresh", trailing: nil)],
                displayLabel: "fresh",
                meterPercent: nil,
                severity: "normal"
            ),
            UsageDetailRow(
                rowId: "updated",
                kind: .metadata,
                label: "Updated",
                layoutLines: [UsagePresentationLine(leading: "Just now", trailing: nil)],
                displayLabel: "Just now",
                meterPercent: nil,
                severity: "normal"
            ),
            UsageDetailRow(
                rowId: "auth",
                kind: .metadata,
                label: "Auth",
                layoutLines: [
                    UsagePresentationLine(leading: "OAuth · ~/.codex/auth.json", trailing: nil)
                ],
                displayLabel: "OAuth · ~/.codex/auth.json",
                meterPercent: nil,
                severity: "normal"
            ),
            bucket(
                id: "bucket:0",
                label: "Session",
                remaining: "63% left",
                meter: 63,
                severity: "normal",
                pace: "On pace",
                reset: "Resets in 2h 14m"
            ),
            bucket(
                id: "bucket:1",
                label: "Weekly",
                remaining: "57% left",
                meter: 57,
                severity: "warn",
                pace: "13% in deficit",
                reset: "Resets in 3d"
            ),
            bucket(
                id: "bucket:2",
                label: "Codex Spark 5-hour",
                remaining: "88% left",
                meter: 88,
                severity: "normal",
                pace: "On pace",
                reset: "Resets in 4h 02m"
            ),
            bucket(
                id: "bucket:3",
                label: "Codex Spark Weekly",
                remaining: "100% left",
                meter: 100,
                severity: "normal",
                pace: nil,
                reset: "Resets in 7d"
            ),
            UsageDetailRow(
                rowId: "bucket:4",
                kind: .bucket,
                label: "Limit Reset Credits",
                layoutLines: [
                    UsagePresentationLine(leading: "3 manual resets available", trailing: nil),
                    UsagePresentationLine(leading: "Next expires in 3d 4h", trailing: nil),
                ],
                displayLabel: "3 manual resets available · Next expires in 3d 4h",
                meterPercent: nil,
                severity: "normal"
            ),
        ])

        let anthropicDetail = UsageDetailPresentation(rows: [
            bucket(
                id: "bucket:0",
                label: "Session",
                remaining: "74% left",
                meter: 74,
                severity: "normal",
                pace: "12% in deficit",
                reset: "Resets in 4h 19m"
            ),
            bucket(
                id: "bucket:1",
                label: "Weekly",
                remaining: "12% left",
                meter: 12,
                severity: "danger",
                pace: "On pace",
                reset: "Resets in 1h"
            ),
        ])

        let openaiSurface = PresentationStore.SurfaceRow(
            id: "codex",
            label: "OpenAI",
            enabled: true,
            statusBarLabel: "57%",
            status: "fresh",
            accountLabel: "alexey@chainargos.com",
            username: nil,
            planLabel: "Pro 20×",
            credentialOrigin: "OAuth · ~/.codex/auth.json",
            estimateCaption: nil,
            buckets: [],
            updatedLabel: "Just now",
            lastError: nil,
            detailPresentation: openaiDetail
        )
        let anthropicSurface = PresentationStore.SurfaceRow(
            id: "claude",
            label: "Anthropic",
            enabled: true,
            statusBarLabel: "12%",
            status: "fresh",
            accountLabel: "Personal",
            username: nil,
            planLabel: "Max 20×",
            credentialOrigin: nil,
            estimateCaption: nil,
            buckets: [],
            updatedLabel: "2 min ago",
            lastError: nil,
            detailPresentation: anthropicDetail
        )
        let ampSurface = PresentationStore.SurfaceRow(
            id: "amp",
            label: "Amp",
            enabled: true,
            statusBarLabel: "100%",
            status: "fresh",
            accountLabel: "Free",
            username: nil,
            planLabel: nil,
            credentialOrigin: nil,
            estimateCaption: nil,
            buckets: [],
            updatedLabel: "1 min ago",
            lastError: nil,
            detailPresentation: UsageDetailPresentation(rows: [])
        )

        return QIFixture(
            openaiGlance: openaiGlance,
            anthropicGlance: anthropicGlance,
            ampGlance: ampGlance,
            openaiSurface: openaiSurface,
            anthropicSurface: anthropicSurface,
            openaiAccounts: openaiAccounts,
            anthropicAccount: anthropicAccount,
            allAccounts: openaiAccounts + [anthropicAccount, ampAccount],
            glanceRows: [anthropicGlance, openaiGlance, ampGlance],
            surfaces: [openaiSurface, anthropicSurface, ampSurface],
            openaiDetail: openaiDetail
        )
    }
}
