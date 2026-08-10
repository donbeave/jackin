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

/// Assert every Desktop provider icon key loads a bundled official mark via the
/// **shipped** `ProviderMarks` + `StatusItemRendering.icon` path (SB-6 / LG-1).
@MainActor
func assertOfficialProviderMarksBundled() {
    let keys = desktopProviderIconKeys
    precondition(keys.count == 7, "expected 7 Desktop providers, got \(keys.count)")
    for key in keys {
        precondition(
            ProviderMarks.hasMark(forIconKey: key),
            "missing official ProviderMark for \(key) — see Resources/ProviderMarks"
        )
        let statusIcon = StatusItemRendering.icon(forIconKey: key)
        precondition(statusIcon.size.width > 0 && statusIcon.size.height > 0)
        fputs("PASS  ProviderMark+status icon \(key)\n", stderr)
    }
    fputs("PASS  ProviderMarks bundled for \(keys.count) Desktop providers\n", stderr)
}

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

        // Fail closed: seven Desktop providers must load official bundled marks
        // (not SF Symbol primary when assets are present). SB-6 / LG-1.
        assertOfficialProviderMarksBundled()

        let fixture = QIFixture.make()

        // ── Dark: full PopoverRoot shell (tab grid + body + footer) ──
        NSApp.appearance = NSAppearance(named: .darkAqua)
        // Tall enough for G-P1 chrome (brand + mode + strip) + body + footer.
        // Full multi-limit plate: Session + Weekly (+ Spark/Limit Reset for OpenAI).
        capturePopover(
            fixture: fixture,
            selection: "codex",
            size: NSSize(width: 430, height: 1100),
            path: "\(out)/popover-openai-dark.png",
            appearance: .darkAqua
        )
        // Tall plate: Session + Weekly + All models + Sonnet + Fable + Daily + Extra (HTML SoT).
        capturePopover(
            fixture: fixture,
            selection: "claude",
            size: NSSize(width: 430, height: 1400),
            path: "\(out)/popover-anthropic-dark.png",
            appearance: .darkAqua
        )
        capturePopover(
            fixture: fixture,
            selection: "amp",
            size: NSSize(width: 430, height: 900),
            path: "\(out)/popover-amp-dark.png",
            appearance: .darkAqua
        )
        // Overview inventory (selection nil) — OV-3…OV-10 / HTML mode-overview
        capturePopover(
            fixture: fixture,
            selection: nil,
            size: NSSize(width: 430, height: 900),
            path: "\(out)/popover-overview-dark.png",
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
        // Toolbar may be BLOCKED even when full window PNG exists (white-blob icon crop).
        let toolbarOkDark =
            windowOkDark
            && !FileManager.default.fileExists(atPath: "\(out)/usage-toolbar-dark.BLOCKED.txt")

        // ── Light ──
        NSApp.appearance = NSAppearance(named: .aqua)
        capturePopover(
            fixture: fixture,
            selection: "codex",
            size: NSSize(width: 430, height: 1100),
            path: "\(out)/popover-openai-light.png",
            appearance: .aqua
        )
        capturePopover(
            fixture: fixture,
            selection: "claude",
            size: NSSize(width: 430, height: 1400),
            path: "\(out)/popover-anthropic-light.png",
            appearance: .aqua
        )
        capturePopover(
            fixture: fixture,
            selection: "amp",
            size: NSSize(width: 430, height: 900),
            path: "\(out)/popover-amp-light.png",
            appearance: .aqua
        )
        capturePopover(
            fixture: fixture,
            selection: nil,
            size: NSSize(width: 430, height: 900),
            path: "\(out)/popover-overview-light.png",
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
        let toolbarOkLight =
            windowOkLight
            && !FileManager.default.fileExists(atPath: "\(out)/usage-toolbar-light.BLOCKED.txt")

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
        selection: String?,
        size: NSSize,
        path: String,
        appearance: NSAppearance.Name
    ) {
        // nil selection = Overview inventory (HTML mode-overview).
        let store = makeStore(fixture: fixture, popover: selection, usage: selection)
        // Stage color matches appearance so Light chrome never sits on black void.
        let stage =
            appearance == .darkAqua
            ? Color(nsColor: .underPageBackgroundColor)
            : Color(nsColor: .windowBackgroundColor)
        // QI full-plate: expand maxHeight so Weekly/danger meters are not clipped
        // to a hollow header-only plate under the scroll fold.
        render(
            ZStack {
                stage
                PopoverRoot(store: store)
                    .environment(\.popoverQIFullPlate, true)
            }
            .frame(width: size.width, height: size.height),
            size: size,
            path: path,
            appearance: appearance
        )
    }

    /// Bitmap dual-stack extras using **only** StatusItemRendering APIs.
    ///
    /// QI stage paints a **menu-bar-like solid** under the strip so Light
    /// `labelColor` (near-black) is readable (clear fill → blank PNG). Template
    /// icons are tinted with label color (same as NSStatusItem template path).
    /// Cell width is measured from dual-stack title so `100%` stays one line.
    @MainActor
    private static func captureStatusItemRendering(
        fixture: QIFixture,
        path: String,
        appearance: NSAppearance.Name
    ) {
        let rows = fixture.glanceRows
        let iconSize: CGFloat = 14
        let height: CGFloat = 28
        let padX: CGFloat = 8
        let gapIconText: CGFloat = 3
        let cellPad: CGFloat = 6

        // Measure cells under the target appearance (fonts + title metrics).
        var cellWidths: [CGFloat] = []
        if let nsApp = NSAppearance(named: appearance) {
            nsApp.performAsCurrentDrawingAppearance {
                cellWidths = rows.map { row in
                    let title = StatusItemRendering.title(
                        barLabel: row.barLabel,
                        resetLabel: row.resetLabel
                    )
                    // Cap height so dual-stack doesn't claim infinite width; measure natural size.
                    let textSize = title.boundingRect(
                        with: NSSize(width: 120, height: height),
                        options: [.usesLineFragmentOrigin, .usesFontLeading]
                    ).size
                    // One-line tokens like `100%` need full monospaced width (not 32pt clip).
                    return max(iconSize + gapIconText + ceil(textSize.width) + cellPad, 56)
                }
            }
        } else {
            cellWidths = Array(repeating: 64, count: rows.count)
        }

        let stripW = cellWidths.reduce(0, +) + padX * 2
        let size = NSSize(width: stripW, height: height)

        let image = NSImage(size: size)
        image.lockFocus()
        if let nsApp = NSAppearance(named: appearance) {
            nsApp.performAsCurrentDrawingAppearance {
                drawStatusStrip(
                    rows: rows,
                    cellWidths: cellWidths,
                    iconSize: iconSize,
                    height: height,
                    padX: padX,
                    gapIconText: gapIconText,
                    appearance: appearance
                )
            }
        } else {
            drawStatusStrip(
                rows: rows,
                cellWidths: cellWidths,
                iconSize: iconSize,
                height: height,
                padX: padX,
                gapIconText: gapIconText,
                appearance: appearance
            )
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
        cellWidths: [CGFloat],
        iconSize: CGFloat,
        height: CGFloat,
        padX: CGFloat,
        gapIconText: CGFloat,
        appearance: NSAppearance.Name
    ) {
        let stripW = cellWidths.reduce(0, +) + padX * 2
        let bounds = NSRect(x: 0, y: 0, width: stripW, height: height)
        // Menu-bar stage — not clear. Light labelColor is near-black; clear → blank PNG.
        let stage =
            appearance == .darkAqua
            ? NSColor(calibratedWhite: 0.14, alpha: 1)
            : NSColor(calibratedWhite: 0.90, alpha: 1)
        stage.setFill()
        bounds.fill()

        let label = NSColor.labelColor
        var x: CGFloat = padX
        for (index, row) in rows.enumerated() {
            let cellW = index < cellWidths.count ? cellWidths[index] : 64
            let icon = StatusItemRendering.icon(forIconKey: row.iconKey)
            let iconRect = NSRect(
                x: x,
                y: (height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            drawTemplateIcon(icon, in: iconRect, tint: label)

            let title = StatusItemRendering.title(
                barLabel: row.barLabel,
                resetLabel: row.resetLabel
            )
            let textRect = NSRect(
                x: x + iconSize + gapIconText,
                y: 1,
                width: max(cellW - iconSize - gapIconText - 2, 24),
                height: height - 2
            )
            title.draw(in: textRect)
            x += cellW
        }
    }

    /// Draw SF Symbol / template `NSImage` as a solid silhouette (menu-bar style).
    @MainActor
    private static func drawTemplateIcon(_ image: NSImage, in rect: NSRect, tint: NSColor) {
        guard rect.width > 0, rect.height > 0 else { return }
        let tinted = NSImage(size: rect.size, flipped: false) { drawRect in
            image.draw(
                in: drawRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0,
                respectFlipped: true,
                hints: [.interpolation: NSImageInterpolation.high]
            )
            tint.set()
            drawRect.fill(using: .sourceAtop)
            return true
        }
        tinted.draw(in: rect)
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

        // Accessory→regular so titlebar/toolbar composites (matches live app path).
        NSApp.setActivationPolicy(.regular)
        // On-screen frame so screencapture -R can sample real composite pixels.
        if let screen = NSScreen.main {
            let vis = screen.visibleFrame
            let w: CGFloat = 920
            let h: CGFloat = 620
            let x = vis.midX - w / 2
            let y = vis.midY - h / 2
            window.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
        } else {
            window.setFrame(NSRect(x: 80, y: 80, width: 920, height: 620), display: true)
        }
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.layoutIfNeeded()
        window.contentViewController?.view.layoutSubtreeIfNeeded()
        // Allow NavigationSplitView + toolbar SF Symbols to composite.
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.9))
        window.contentViewController?.view.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))

        guard let full = captureWindowImageNonBlank(window: window) else {
            writeBlockedPlaceholder(
                path: fullPath,
                reason: "window capture blank or unavailable (CGWindow/view bitmap)"
            )
            if let toolbarPath {
                writeBlockedPlaceholder(
                    path: toolbarPath,
                    reason: "window capture blank or unavailable (CGWindow/view bitmap)"
                )
            }
            print("BLOCKED \(fullPath) [blank-or-missing window capture]")
            controller.invalidate()
            NSApp.setActivationPolicy(.prohibited)
            return false
        }

        // Full window PNG — reject all-black before write.
        if !writeCGImagePNG(full, path: fullPath, requireNonBlank: true) {
            writeBlockedPlaceholder(path: fullPath, reason: "full window PNG encode/blank")
            if let toolbarPath {
                writeBlockedPlaceholder(path: toolbarPath, reason: "full window PNG encode/blank")
            }
            controller.invalidate()
            NSApp.setActivationPolicy(.prohibited)
            return false
        }
        print("WROTE \(fullPath) [UsageWindowController window capture]")

        // Titlebar/toolbar band crop (CGImage y=0 is top in this bitmap path).
        if let toolbarPath {
            let scale = CGFloat(full.width) / max(window.frame.width, 1)
            let bandPx = max(1, Int((56 * scale).rounded()))
            let cropH = min(bandPx, full.height)
            if let band = full.cropping(to: CGRect(x: 0, y: 0, width: full.width, height: cropH)) {
                // Dark `cacheDisplay` often paints SF Symbol toolbar icons as solid white
                // disks — not acceptable G-U1 evidence (HTML has readable Refresh glyph).
                if appearance == .darkAqua, toolbarCropHasBlownOutIcons(band) {
                    writeBlockedPlaceholder(
                        path: toolbarPath,
                        reason: """
                        Dark titlebar crop: SF Symbol toolbar icons unreadable (solid white blobs). \
                        Prefer CGWindow/screencapture -R/-l. Product: icon-only Refresh via UsageWindowRoot.toolbar. \
                        Light harness crop + ArchitectureLint prove NSToolbar host when Dark composite fails.
                        """
                    )
                    print("BLOCKED \(toolbarPath) [dark toolbar icons unreadable — white blobs]")
                } else if writeCGImagePNG(band, path: toolbarPath, requireNonBlank: true) {
                    // Clear any prior BLOCKED sidecar after successful readable crop.
                    let side = toolbarPath.replacingOccurrences(of: ".png", with: ".BLOCKED.txt")
                    try? FileManager.default.removeItem(atPath: side)
                    print("WROTE \(toolbarPath) [UsageWindowController titlebar crop]")
                } else {
                    writeBlockedPlaceholder(
                        path: toolbarPath,
                        reason: "titlebar crop blank or failed"
                    )
                }
            } else {
                writeBlockedPlaceholder(
                    path: toolbarPath,
                    reason: "titlebar crop blank or failed"
                )
            }
        }

        controller.invalidate()
        NSApp.setActivationPolicy(.prohibited)
        return true
    }

    /// Prefer live composite: screencapture -R region, then -l, then CGWindow.
    /// Last: theme-frame `cacheDisplay` (may blank Liquid Glass sidebar / blow out Dark toolbar icons).
    @MainActor
    private static func captureWindowImageNonBlank(window: NSWindow) -> CGImage? {
        // Prefer on-screen region capture (Screen Recording often works when CGWindow is black).
        fputs("INFO trying screencapture -R window frame\n", stderr)
        if let region = captureWindowViaScreencaptureRegion(window: window), !cgImageIsBlank(region) {
            return region
        }
        fputs("WARN screencapture -R failed — trying screencapture -l\n", stderr)
        if let sc = captureWindowViaScreencapture(window: window), !cgImageIsBlank(sc) {
            return sc
        }
        fputs("WARN screencapture -l failed — trying CGWindow\n", stderr)
        if let cg = captureFullWindowCGImage(window: window), !cgImageIsBlank(cg) {
            return cg
        }
        fputs("WARN CGWindow blank/unavailable — trying view bitmap\n", stderr)
        if let viewImg = captureWindowViaViewBitmap(window: window), !cgImageIsBlank(viewImg) {
            // View bitmap can white-out glass sidebar + Dark SF Symbols; still better than pure black.
            return viewImg
        }
        return nil
    }

    /// `screencapture -R x,y,w,h` using Cocoa frame → top-left screen coords.
    @MainActor
    private static func captureWindowViaScreencaptureRegion(window: NSWindow) -> CGImage? {
        let frame = window.frame
        guard frame.width > 8, frame.height > 8 else { return nil }
        // Global Cocoa coords: origin bottom-left. screencapture -R: origin top-left of main display.
        guard let screen = window.screen ?? NSScreen.main else { return nil }
        let screenFrame = screen.frame
        // Convert window bottom-left to global top-left pixel coords for -R.
        // Use primary display height for Y flip when multi-display (screencapture uses global desktop).
        let globalMaxY = NSScreen.screens.map(\.frame.maxY).max() ?? screenFrame.maxY
        let x = Int(frame.minX.rounded())
        let y = Int((globalMaxY - frame.maxY).rounded())
        let w = Int(frame.width.rounded())
        let h = Int(frame.height.rounded())
        guard w > 0, h > 0 else { return nil }

        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("jackin-qi-region-\(window.windowNumber).png")
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        proc.arguments = ["-x", "-R", "\(x),\(y),\(w),\(h)", tmp.path]
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            return nil
        }
        guard proc.terminationStatus == 0,
              let img = NSImage(contentsOf: tmp),
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            try? FileManager.default.removeItem(at: tmp)
            return nil
        }
        try? FileManager.default.removeItem(at: tmp)
        return cg
    }

    /// macOS `screencapture -l <windowID>` — captures real window pixels.
    @MainActor
    private static func captureWindowViaScreencapture(window: NSWindow) -> CGImage? {
        let windowId = window.windowNumber
        guard windowId > 0 else { return nil }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("jackin-qi-win-\(windowId).png")
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        proc.arguments = ["-x", "-l", String(windowId), tmp.path]
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            return nil
        }
        guard proc.terminationStatus == 0,
              let img = NSImage(contentsOf: tmp),
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            try? FileManager.default.removeItem(at: tmp)
            return nil
        }
        try? FileManager.default.removeItem(at: tmp)
        return cg
    }

    /// Dark titlebar: solid white disks where SF Symbols should be (view-bitmap / bad composite).
    /// Readable Dark icons are soft gray/phosphor, not near-pure white fills.
    private static func toolbarCropHasBlownOutIcons(_ image: CGImage, sampleStep: Int = 2) -> Bool {
        let w = image.width
        let h = image.height
        guard w > 8, h > 4 else { return true }
        let bytesPerPixel = 4
        let bytesPerRow = w * bytesPerPixel
        var data = [UInt8](repeating: 0, count: h * bytesPerRow)
        guard let ctx = CGContext(
            data: &data,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return true
        }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var pureWhite = 0
        var total = 0
        let step = max(1, sampleStep)
        // Focus mid band where unified toolbar icons sit (skip traffic lights left strip).
        let x0 = w / 4
        let x1 = (w * 3) / 4
        var y = 0
        while y < h {
            var x = x0
            while x < x1 {
                let i = y * bytesPerRow + x * bytesPerPixel
                let r = data[i]
                let g = data[i + 1]
                let b = data[i + 2]
                total += 1
                if r >= 245, g >= 245, b >= 245 {
                    pureWhite += 1
                }
                x += step
            }
            y += step
        }
        guard total > 0 else { return true }
        // >1.2% near-pure white in icon zone ⇒ blown-out disks (not thin glyph edges).
        return Double(pureWhite) / Double(total) > 0.012
    }

    @MainActor
    private static func captureFullWindowCGImage(window: NSWindow) -> CGImage? {
        let windowId = CGWindowID(window.windowNumber)
        guard windowId != 0 else { return nil }
        return CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowId,
            [.boundsIgnoreFraming, .bestResolution]
        )
    }

    /// Bitmap the window's theme frame (titlebar + content) without Screen Recording.
    @MainActor
    private static func captureWindowViaViewBitmap(window: NSWindow) -> CGImage? {
        // Walk to NSThemeFrame when present so the unified toolbar is included.
        var view: NSView? = window.contentView
        while let superview = view?.superview {
            view = superview
        }
        guard let root = view ?? window.contentView else { return nil }
        root.layoutSubtreeIfNeeded()
        let bounds = root.bounds
        guard bounds.width > 1, bounds.height > 1 else { return nil }
        guard let rep = root.bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        root.cacheDisplay(in: bounds, to: rep)
        return rep.cgImage
    }

    /// True when nearly all samples are near-black (failed CGWindow permission).
    private static func cgImageIsBlank(_ image: CGImage, sampleStep: Int = 8) -> Bool {
        let w = image.width
        let h = image.height
        guard w > 0, h > 0 else { return true }
        let bytesPerPixel = 4
        let bytesPerRow = w * bytesPerPixel
        var data = [UInt8](repeating: 0, count: h * bytesPerRow)
        guard let ctx = CGContext(
            data: &data,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return true
        }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var bright = 0
        var total = 0
        let step = max(1, sampleStep)
        var y = 0
        while y < h {
            var x = 0
            while x < w {
                let i = y * bytesPerRow + x * bytesPerPixel
                let r = data[i]
                let g = data[i + 1]
                let b = data[i + 2]
                total += 1
                if max(r, g, b) > 12 { bright += 1 }
                x += step
            }
            y += step
        }
        guard total > 0 else { return true }
        // Blank if fewer than 0.5% of samples exceed near-black.
        return Double(bright) / Double(total) < 0.005
    }

    private static func writeCGImagePNG(
        _ image: CGImage,
        path: String,
        requireNonBlank: Bool = false
    ) -> Bool {
        if requireNonBlank, cgImageIsBlank(image) {
            fputs("FAIL blank CGImage rejected for \(path)\n", stderr)
            return false
        }
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
        // HTML SoT: Personal (selected) + Work (secondary chip).
        let anthropicAccounts = [
            PresentationStore.AccountRow(
                surfaceId: "claude",
                accountKey: "p1",
                accountLabel: "Personal",
                planLabel: "Max 20×",
                selected: true,
                remainingPercent: 12,
                statusWord: "fresh",
                severity: "danger" // HTML a-meter low
            ),
            PresentationStore.AccountRow(
                surfaceId: "claude",
                accountKey: "w1",
                accountLabel: "Work",
                planLabel: "Team",
                selected: false,
                remainingPercent: nil,
                statusWord: "fresh",
                severity: "normal"
            ),
        ]
        let anthropicAccount = anthropicAccounts[0]
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

        // HTML popover.html Anthropic stack (order fixed by SoT):
        // Session, Weekly, All models, Sonnet, Fable only, Daily Routines, Extra usage.
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
                pace: "52% in reserve",
                reset: "Resets in 1h"
            ),
            bucket(
                id: "bucket:2",
                label: "All models",
                remaining: "28% left",
                meter: 28,
                severity: "warn",
                pace: "Weekly all-models window",
                reset: "Resets with weekly"
            ),
            bucket(
                id: "bucket:3",
                label: "Sonnet",
                remaining: "35% left",
                meter: 35,
                severity: "warn",
                pace: "Model-scoped · paced",
                reset: "Resets in 6d 12h"
            ),
            bucket(
                id: "bucket:4",
                label: "Fable only",
                remaining: "28% left",
                meter: 28,
                severity: "warn",
                pace: nil,
                reset: "Resets in 12h 19m"
            ),
            bucket(
                id: "bucket:5",
                label: "Daily Routines",
                remaining: "100% left",
                meter: 100,
                severity: "normal",
                pace: "No reset timestamp from provider",
                reset: nil
            ),
            // Extra usage: limits-only spend bound (no invent % meter).
            UsageDetailRow(
                rowId: "bucket:6",
                kind: .bucket,
                label: "Extra usage",
                layoutLines: [
                    UsagePresentationLine(leading: "Spend bound", trailing: nil),
                    UsagePresentationLine(
                        leading: "Quota-bound money / spend slot (limits only)",
                        trailing: nil
                    ),
                ],
                displayLabel: "Spend bound · Quota-bound money / spend slot (limits only)",
                meterPercent: nil,
                severity: "normal"
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
            allAccounts: openaiAccounts + anthropicAccounts + [ampAccount],
            glanceRows: [anthropicGlance, openaiGlance, ampGlance],
            surfaces: [openaiSurface, anthropicSurface, ampSurface],
            openaiDetail: openaiDetail
        )
    }
}
