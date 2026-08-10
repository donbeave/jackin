// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

/// Renders shipped SwiftUI craft views with DATA_CONTRACT fixtures to PNG
/// for QI native captures (no live network).
///
///   cd native && swift run -c release DesktopVisualSnapshotHarness [outDir]

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

        // Headless-friendly app instance for AppKit image rendering.
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.prohibited)

        let fixture = QIFixture.make()
        let model = UsageWindowModel(
            glanceRows: fixture.glanceRows,
            surfaces: fixture.surfaces,
            accounts: fixture.allAccounts,
            selection: nil
        )

        // Dark scenes
        NSApp.appearance = NSAppearance(named: .darkAqua)
        render(
            popoverBody(
                provider: fixture.openaiGlance,
                surface: fixture.openaiSurface,
                accounts: fixture.openaiAccounts
            ),
            size: NSSize(width: 424, height: 560),
            path: "\(out)/popover-openai-dark.png",
            appearance: .darkAqua
        )
        render(
            popoverBody(
                provider: fixture.anthropicGlance,
                surface: fixture.anthropicSurface,
                accounts: [fixture.anthropicAccount]
            ),
            size: NSSize(width: 424, height: 520),
            path: "\(out)/popover-anthropic-dark.png",
            appearance: .darkAqua
        )
        render(
            ProviderCardView(
                content: UsageWindowModel.Content(
                    surfaceId: "codex",
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
        render(
            OverviewListView(model: model, accounts: fixture.allAccounts) { _, _ in }
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
        render(
            statusDualStackPreview(fixture: fixture)
                .frame(width: 420, height: 80)
                .padding(12)
                .background(Color(nsColor: .underPageBackgroundColor)),
            size: NSSize(width: 444, height: 104),
            path: "\(out)/status-desktop-dark.png",
            appearance: .darkAqua
        )
        render(
            toolbarStandIn()
                .environment(\.colorScheme, .dark),
            size: NSSize(width: 920, height: 52),
            path: "\(out)/usage-toolbar-dark.png",
            appearance: .darkAqua
        )

        // Light scenes
        NSApp.appearance = NSAppearance(named: .aqua)
        render(
            popoverBody(
                provider: fixture.openaiGlance,
                surface: fixture.openaiSurface,
                accounts: fixture.openaiAccounts
            ),
            size: NSSize(width: 424, height: 560),
            path: "\(out)/popover-openai-light.png",
            appearance: .aqua
        )
        render(
            popoverBody(
                provider: fixture.anthropicGlance,
                surface: fixture.anthropicSurface,
                accounts: [fixture.anthropicAccount]
            ),
            size: NSSize(width: 424, height: 520),
            path: "\(out)/popover-anthropic-light.png",
            appearance: .aqua
        )
        render(
            ProviderCardView(
                content: UsageWindowModel.Content(
                    surfaceId: "codex",
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
            OverviewListView(model: model, accounts: fixture.allAccounts) { _, _ in }
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
        render(
            statusDualStackPreview(fixture: fixture)
                .frame(width: 420, height: 80)
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .environment(\.colorScheme, .light),
            size: NSSize(width: 444, height: 104),
            path: "\(out)/status-desktop-light.png",
            appearance: .aqua
        )
        render(
            toolbarStandIn()
                .environment(\.colorScheme, .light),
            size: NSSize(width: 920, height: 52),
            path: "\(out)/usage-toolbar-light.png",
            appearance: .aqua
        )

        print("DesktopVisualSnapshotHarness: wrote snapshots to \(out)")
    }

    /// Hosted popover body craft (provider tab on panel surface) — shell chrome needs live NSPopover.
    @ViewBuilder
    private static func popoverBody(
        provider: PresentationStore.GlanceProviderRow,
        surface: PresentationStore.SurfaceRow,
        accounts: [PresentationStore.AccountRow]
    ) -> some View {
        PopoverProviderTab(
            provider: provider,
            surface: surface,
            accounts: accounts,
            refreshInProgress: false,
            onSelectAccount: { _, _ in },
            onOpenUsageWindow: { _ in }
        )
        .frame(width: 412)
        .background {
            GlassFallbacks.panelSurfaceBackground()
        }
        .clipShape(
            RoundedRectangle(cornerRadius: GlassFallbacks.panelCornerRadius, style: .continuous)
        )
        .padding(6)
    }

    private static func toolbarStandIn() -> some View {
        HStack {
            Spacer()
            Text("jackin❯ desktop").font(.headline)
            Spacer()
            Image(systemName: "arrow.clockwise")
        }
        .padding(.horizontal, 16)
        .frame(width: 920, height: 52)
        .background(.bar)
    }

    @MainActor
    private static func render<V: View>(
        _ view: V,
        size: NSSize,
        path: String,
        appearance: NSAppearance.Name
    ) {
        let root = view
            .frame(width: size.width, height: size.height)
            .environment(
                \.colorScheme,
                appearance == .darkAqua ? .dark : .light
            )
        let host = NSHostingView(rootView: root)
        host.appearance = NSAppearance(named: appearance)
        host.frame = NSRect(origin: .zero, size: size)
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

    private static func statusDualStackPreview(fixture: QIFixture) -> some View {
        HStack(spacing: 16) {
            ForEach(fixture.glanceRows) { row in
                HStack(spacing: 4) {
                    Image(systemName: desktopProviderSystemImage(iconKey: row.iconKey) ?? "circle")
                        .font(.system(size: 12))
                    VStack(alignment: .leading, spacing: 0) {
                        if let r = row.resetLabel {
                            Text(compactReset(r))
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Text(row.barLabel)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    }
                }
            }
            Spacer()
        }
    }
}

/// Local compact of reset labels (fixture display only; mirrors StatusItemRendering trim rules).
private func compactReset(_ resetLabel: String) -> String {
    var text = resetLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    for prefix in ["Resets in ", "Resets ", "resets in ", "resets "] {
        if text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
            break
        }
    }
    if let cut = text.split(separator: "·").first {
        text = cut.trimmingCharacters(in: .whitespaces)
    }
    return text
}

// MARK: - Fixtures (DATA_CONTRACT numbers)

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
                statusWord: "fresh"
            ),
            PresentationStore.AccountRow(
                surfaceId: "codex",
                accountKey: "a2",
                accountLabel: "alexey@zhokhov.com",
                planLabel: "Plus",
                selected: false,
                remainingPercent: 0,
                statusWord: "fresh"
            ),
        ]
        let anthropicAccount = PresentationStore.AccountRow(
            surfaceId: "claude",
            accountKey: "p1",
            accountLabel: "Personal",
            planLabel: "Max 20×",
            selected: true,
            remainingPercent: 12,
            statusWord: "fresh"
        )
        let ampAccount = PresentationStore.AccountRow(
            surfaceId: "amp",
            accountKey: "free",
            accountLabel: "Free",
            planLabel: nil,
            selected: true,
            remainingPercent: 100,
            statusWord: "fresh"
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
            surfaces: [openaiSurface, anthropicSurface],
            openaiDetail: openaiDetail
        )
    }
}
