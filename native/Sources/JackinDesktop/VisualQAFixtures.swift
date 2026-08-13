// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import Foundation
import JackinUsageBridge

/// Stable, explicit launch fixtures for native visual QA.
public enum VisualQAFixtureID: String, CaseIterable, Sendable {
    case noProviders = "F00-no-providers"
    case singleNormal = "F01-single-normal"
    case catalogNormal = "F02-catalog-normal"
    case multiAccount = "F03-multi-account"
    case nearlyExhausted = "F04-nearly-exhausted"
    case exhausted = "F05-exhausted"
    case staleLastGood = "F06-stale-last-good"
    case refreshingLastGood = "F07-refreshing-last-good"
    case partialTimeout = "F08-partial-timeout"
    case permissionDenied = "F09-permission-denied"
    case offlineCached = "F10-offline-cached"
    case longLabels = "F11-long-labels"
    case layoutEnvelope = "F12-layout-envelope"
    case initialLoading = "F13-initial-loading"
    case globalBridgeError = "F14-global-bridge-error"
}

/// Rust-shaped presentation records plus explicit transient state.
public struct VisualQAFixture: Sendable {
    public let id: VisualQAFixtureID
    public let glanceRows: [PresentationStore.GlanceProviderRow]
    public let statusGlanceRows: [PresentationStore.GlanceProviderRow]
    public let surfaces: [PresentationStore.SurfaceRow]
    public let accounts: [PresentationStore.AccountRow]
    public let popoverSelection: String?
    public let usageSelection: String?
    public let nextRefreshLabel: String
    public let isLoading: Bool
    public let isRefreshing: Bool
    public let globalError: String?

    public var allAccounts: [PresentationStore.AccountRow] { accounts }

    public var openaiAccounts: [PresentationStore.AccountRow] {
        accounts.filter { $0.surfaceId == "codex" }
    }

    public var openaiDetail: UsageDetailPresentation {
        surfaces.first { $0.id == "codex" }?.detailPresentation ?? .empty
    }
}

/// One catalog owns app launch, UI automation, and native capture data.
public enum VisualQAFixtures: Sendable {
    public static let frozenNow = "2026-08-12T12:00:00+07:00"
    public static let localeIdentifier = "en_US"
    public static let calendarIdentifier = "gregorian"
    public static let timeZoneIdentifier = "Asia/Ho_Chi_Minh"

    public static func fixture(id: VisualQAFixtureID) -> VisualQAFixture {
        switch id {
        case .noProviders:
            return fixture(
                id: id,
                glanceRows: [],
                surfaces: [],
                accounts: [],
                popover: nil,
                usage: nil
            )
        case .singleNormal:
            return singleProviderFixture(id: id, provider: .codex, accounts: [codexPersonal()])
        case .catalogNormal:
            return catalogFixture(id: id)
        case .multiAccount:
            let accounts = [
                codexPersonal(selected: false),
                codexPlus(selected: true),
                account(
                    surfaceId: "codex",
                    key: "codex-organization",
                    label: "organization-production-sandbox@example.test",
                    plan: "Enterprise",
                    remaining: 88,
                    selected: false
                ),
            ]
            return singleProviderFixture(
                id: id,
                provider: .codex,
                accounts: accounts,
                glanceRemaining: 0,
                detail: exhaustedOpenAIDetail()
            )
        case .nearlyExhausted:
            return singleProviderFixture(
                id: id,
                provider: .claude,
                accounts: [claudePersonal()],
                detail: anthropicDetail()
            )
        case .exhausted:
            return singleProviderFixture(
                id: id,
                provider: .codex,
                accounts: [codexPlus()],
                glanceRemaining: 0,
                detail: exhaustedOpenAIDetail()
            )
        case .staleLastGood:
            let error = "Codex provider usage unavailable; cached quota is stale"
            return singleProviderFixture(
                id: id,
                provider: .codex,
                accounts: [codexPersonal(status: "stale")],
                status: "stale",
                updated: "47 min ago",
                error: error
            )
        case .refreshingLastGood:
            var fixture = catalogFixture(id: id, refreshingSurface: "codex")
            fixture = VisualQAFixture(
                id: fixture.id,
                glanceRows: fixture.glanceRows,
                statusGlanceRows: fixture.statusGlanceRows,
                surfaces: fixture.surfaces,
                accounts: fixture.accounts,
                popoverSelection: fixture.popoverSelection,
                usageSelection: fixture.usageSelection,
                nextRefreshLabel: fixture.nextRefreshLabel,
                isLoading: false,
                isRefreshing: true,
                globalError: nil
            )
            return fixture
        case .partialTimeout:
            return catalogFixture(
                id: id,
                failingSurface: "kimi",
                failureStatus: "unavailable",
                failureError: "usage provider probe timed out"
            )
        case .permissionDenied:
            let accounts = [
                account(
                    surfaceId: "claude",
                    key: "claude-unavailable",
                    label: "account unavailable",
                    plan: nil,
                    remaining: nil,
                    selected: true,
                    status: "unavailable"
                )
            ]
            return customSingleProviderFixture(
                id: id,
                surfaceId: "claude",
                iconKey: "claude",
                displayLabel: "Anthropic",
                accounts: accounts,
                remaining: nil,
                status: "unavailable",
                updated: "Just now",
                error: "Claude Keychain access denied",
                detail: .empty
            )
        case .offlineCached:
            return singleProviderFixture(
                id: id,
                provider: .kimi,
                accounts: [defaultAccount(provider: .kimi, status: "stale")],
                status: "stale",
                updated: "1h 12m ago",
                error: "Kimi billing endpoint unavailable; local presence only"
            )
        case .longLabels:
            let label = "OpenAI Organization Production Sandbox — Southeast Asia"
            let accountLabel = "organization-production-sandbox@example.test"
            let plan = "Enterprise workspace with centrally managed weekly limits"
            let error =
                "Provider response could not be refreshed; showing the last successful quota snapshot"
            let detail = UsageDetailPresentation(rows: [
                metadata(id: "status", label: "Status", value: "stale"),
                bucket(
                    id: "bucket:long",
                    label: "Organization-wide weekly accelerated-model allocation",
                    remaining: "57% left",
                    meter: 57,
                    severity: "warn",
                    supporting: [
                        "Resets Tuesday, 18 August 2026 at 23:59 Indochina Time"
                    ]
                ),
            ])
            return customSingleProviderFixture(
                id: id,
                surfaceId: "codex",
                iconKey: "codex",
                displayLabel: label,
                accounts: [
                    account(
                        surfaceId: "codex",
                        key: "codex-organization",
                        label: accountLabel,
                        plan: plan,
                        remaining: 57,
                        selected: true,
                        status: "stale"
                    )
                ],
                remaining: 57,
                status: "stale",
                updated: "47 min ago",
                error: error,
                detail: detail
            )
        case .layoutEnvelope:
            return layoutEnvelopeFixture()
        case .initialLoading:
            return VisualQAFixture(
                id: id,
                glanceRows: [],
                statusGlanceRows: [],
                surfaces: [],
                accounts: [],
                popoverSelection: nil,
                usageSelection: nil,
                nextRefreshLabel: "",
                isLoading: true,
                isRefreshing: false,
                globalError: nil
            )
        case .globalBridgeError:
            return VisualQAFixture(
                id: id,
                glanceRows: [],
                statusGlanceRows: [],
                surfaces: [],
                accounts: [],
                popoverSelection: nil,
                usageSelection: nil,
                nextRefreshLabel: "",
                isLoading: false,
                isRefreshing: false,
                globalError: "Usage presentation is unavailable"
            )
        }
    }

    private enum Provider: String, CaseIterable {
        case codex
        case claude
        case amp
        case grok
        case zai
        case kimi
        case minimax

        var label: String {
            switch self {
            case .codex: "OpenAI"
            case .claude: "Anthropic"
            case .amp: "Amp"
            case .grok: "xAI"
            case .zai: "Z.AI"
            case .kimi: "Kimi"
            case .minimax: "MiniMax"
            }
        }

        var remaining: UInt8 {
            switch self {
            case .codex: 57
            case .claude: 12
            case .amp: 100
            case .grok: 72
            case .zai: 81
            case .kimi: 45
            case .minimax: 33
            }
        }

        var reset: String? {
            switch self {
            case .codex: "Resets in 3d"
            case .claude: "Resets in 1h"
            case .amp: "Resets in 18h"
            default: nil
            }
        }
    }

    private static func fixture(
        id: VisualQAFixtureID,
        glanceRows: [PresentationStore.GlanceProviderRow],
        surfaces: [PresentationStore.SurfaceRow],
        accounts: [PresentationStore.AccountRow],
        popover: String?,
        usage: String?
    ) -> VisualQAFixture {
        VisualQAFixture(
            id: id,
            glanceRows: glanceRows,
            statusGlanceRows: Array(glanceRows.prefix(3)),
            surfaces: surfaces,
            accounts: accounts,
            popoverSelection: popover,
            usageSelection: usage,
            nextRefreshLabel: "next update 4m",
            isLoading: false,
            isRefreshing: false,
            globalError: nil
        )
    }

    private static func singleProviderFixture(
        id: VisualQAFixtureID,
        provider: Provider,
        accounts: [PresentationStore.AccountRow],
        glanceRemaining: UInt8? = nil,
        status: String = "fresh",
        updated: String = "Just now",
        error: String? = nil,
        detail: UsageDetailPresentation? = nil
    ) -> VisualQAFixture {
        customSingleProviderFixture(
            id: id,
            surfaceId: provider.rawValue,
            iconKey: provider.rawValue,
            displayLabel: provider.label,
            accounts: accounts,
            remaining: glanceRemaining ?? provider.remaining,
            status: status,
            updated: updated,
            error: error,
            detail: detail ?? detailPresentation(for: provider)
        )
    }

    private static func customSingleProviderFixture(
        id: VisualQAFixtureID,
        surfaceId: String,
        iconKey: String,
        displayLabel: String,
        accounts: [PresentationStore.AccountRow],
        remaining: UInt8?,
        status: String,
        updated: String,
        error: String?,
        detail: UsageDetailPresentation
    ) -> VisualQAFixture {
        let selected = accounts.first(where: \.selected) ?? accounts.first
        let provider = Provider(rawValue: surfaceId)
        let glance = glance(
            surfaceId: surfaceId,
            iconKey: iconKey,
            label: displayLabel,
            accountLabel: selected?.accountLabel ?? "",
            planLabel: selected?.planLabel,
            remaining: remaining,
            reset: provider?.reset,
            status: status,
            updated: updated,
            error: error,
            refreshing: false
        )
        let surface = surface(
            glance: glance,
            detail: detail,
            credentialOrigin: surfaceId == "codex" ? "OAuth · ~/.codex/auth.json" : nil
        )
        return fixture(
            id: id,
            glanceRows: [glance],
            surfaces: [surface],
            accounts: accounts,
            popover: surfaceId,
            usage: surfaceId
        )
    }

    private static func catalogFixture(
        id: VisualQAFixtureID,
        refreshingSurface: String? = nil,
        failingSurface: String? = nil,
        failureStatus: String = "fresh",
        failureError: String? = nil
    ) -> VisualQAFixture {
        let accounts = catalogAccounts()
        let glances = Provider.allCases.map { provider in
            let selected = accounts.first { $0.surfaceId == provider.rawValue && $0.selected }
            let isFailure = provider.rawValue == failingSurface
            return glance(
                surfaceId: provider.rawValue,
                iconKey: provider.rawValue,
                label: provider.label,
                accountLabel: selected?.accountLabel ?? "",
                planLabel: selected?.planLabel,
                remaining: provider.remaining,
                reset: provider.reset,
                status: isFailure ? failureStatus : "fresh",
                updated: "Just now",
                error: isFailure ? failureError : nil,
                refreshing: provider.rawValue == refreshingSurface
            )
        }
        let surfaces = glances.map { row in
            surface(
                glance: row,
                detail: detailPresentation(for: Provider(rawValue: row.surfaceId) ?? .amp),
                credentialOrigin: row.surfaceId == "codex" ? "OAuth · ~/.codex/auth.json" : nil
            )
        }
        let statusOrder = ["claude", "codex", "minimax"].compactMap { id in
            glances.first { $0.surfaceId == id }
        }
        return VisualQAFixture(
            id: id,
            glanceRows: glances,
            statusGlanceRows: statusOrder,
            surfaces: surfaces,
            accounts: accounts,
            popoverSelection: "codex",
            usageSelection: nil,
            nextRefreshLabel: "next update 4m",
            isLoading: false,
            isRefreshing: false,
            globalError: nil
        )
    }

    private static func layoutEnvelopeFixture() -> VisualQAFixture {
        var base = catalogFixture(id: .layoutEnvelope)
        let accounts = [
            codexPersonal(selected: false),
            codexPlus(selected: false),
            account(
                surfaceId: "codex",
                key: "codex-organization",
                label: "organization-production-sandbox@example.test",
                plan: "Enterprise",
                remaining: 88,
                selected: true
            ),
            claudePersonal(selected: false),
            account(
                surfaceId: "claude",
                key: "claude-work",
                label: "Work",
                plan: "Team",
                remaining: nil,
                selected: false
            ),
            account(
                surfaceId: "claude",
                key: "claude-third",
                label: "Research workspace",
                plan: "Team",
                remaining: 28,
                selected: true
            ),
            defaultAccount(provider: .amp),
            account(
                surfaceId: "amp",
                key: "amp-layout-secondary",
                label: "Secondary layout account",
                plan: nil,
                remaining: 100,
                selected: false
            ),
            defaultAccount(provider: .grok),
            defaultAccount(provider: .zai),
            defaultAccount(provider: .kimi),
            defaultAccount(provider: .minimax),
        ]
        let longRow = bucket(
            id: "bucket:layout-long",
            label: "Organization-wide weekly accelerated-model allocation",
            remaining: "28% left",
            meter: 28,
            severity: "warn",
            supporting: ["Resets Tuesday, 18 August 2026 at 23:59 Indochina Time"]
        )
        let detail = UsageDetailPresentation(
            rows: [
                metadata(id: "status", label: "Status", value: "fresh"),
                metadata(id: "updated", label: "Updated", value: "Just now"),
                metadata(id: "account", label: "Account", value: "Research workspace"),
                metadata(id: "plan", label: "Plan", value: "Team"),
            ] + anthropicDetail().rows + [longRow]
        )
        let surfaces = base.surfaces.map { row in
            guard row.id == "claude" else { return row }
            return PresentationStore.SurfaceRow(
                id: row.id,
                label: row.label,
                enabled: row.enabled,
                statusBarLabel: row.statusBarLabel,
                status: row.status,
                accountLabel: "Research workspace",
                username: row.username,
                planLabel: "Team",
                credentialOrigin: row.credentialOrigin,
                estimateCaption: row.estimateCaption,
                buckets: row.buckets,
                updatedLabel: row.updatedLabel,
                lastError: row.lastError,
                detailPresentation: detail
            )
        }
        base = VisualQAFixture(
            id: .layoutEnvelope,
            glanceRows: base.glanceRows,
            statusGlanceRows: base.statusGlanceRows,
            surfaces: surfaces,
            accounts: accounts,
            popoverSelection: "claude",
            usageSelection: "claude",
            nextRefreshLabel: base.nextRefreshLabel,
            isLoading: false,
            isRefreshing: false,
            globalError: nil
        )
        return base
    }

    private static func catalogAccounts() -> [PresentationStore.AccountRow] {
        [
            codexPersonal(),
            codexPlus(selected: false),
            claudePersonal(),
            account(
                surfaceId: "claude",
                key: "claude-work",
                label: "Work",
                plan: "Team",
                remaining: nil,
                selected: false
            ),
            defaultAccount(provider: .amp),
            defaultAccount(provider: .grok),
            defaultAccount(provider: .zai),
            defaultAccount(provider: .kimi),
            defaultAccount(provider: .minimax),
        ]
    }

    private static func codexPersonal(
        selected: Bool = true,
        status: String = "fresh"
    ) -> PresentationStore.AccountRow {
        account(
            surfaceId: "codex",
            key: "codex-personal",
            label: "personal@example.test",
            plan: "Pro 20×",
            remaining: 57,
            selected: selected,
            status: status
        )
    }

    private static func codexPlus(selected: Bool = true) -> PresentationStore.AccountRow {
        account(
            surfaceId: "codex",
            key: "codex-plus",
            label: "secondary@example.test",
            plan: "Plus",
            remaining: 0,
            selected: selected
        )
    }

    private static func claudePersonal(selected: Bool = true) -> PresentationStore.AccountRow {
        account(
            surfaceId: "claude",
            key: "claude-personal",
            label: "Personal",
            plan: "Max 20×",
            remaining: 12,
            selected: selected
        )
    }

    private static func defaultAccount(
        provider: Provider,
        status: String = "fresh"
    ) -> PresentationStore.AccountRow {
        let label = provider == .amp ? "Free" : provider == .grok ? "Team" : "Default"
        return account(
            surfaceId: provider.rawValue,
            key: "\(provider.rawValue)-default",
            label: label,
            plan: nil,
            remaining: provider.remaining,
            selected: true,
            status: status
        )
    }

    private static func account(
        surfaceId: String,
        key: String,
        label: String,
        plan: String?,
        remaining: UInt8?,
        selected: Bool,
        status: String = "fresh"
    ) -> PresentationStore.AccountRow {
        PresentationStore.AccountRow(
            surfaceId: surfaceId,
            accountKey: key,
            accountLabel: label,
            planLabel: plan,
            selected: selected,
            remainingPercent: remaining,
            statusWord: status,
            severity: severity(for: remaining)
        )
    }

    private static func glance(
        surfaceId: String,
        iconKey: String,
        label: String,
        accountLabel: String,
        planLabel: String?,
        remaining: UInt8?,
        reset: String?,
        status: String,
        updated: String,
        error: String?,
        refreshing: Bool
    ) -> PresentationStore.GlanceProviderRow {
        let barLabel = remaining.map { "\($0)%" } ?? ""
        let headline = remaining.map { "\($0)% left" } ?? status
        return PresentationStore.GlanceProviderRow(
            surfaceId: surfaceId,
            iconKey: iconKey,
            displayLabel: label,
            accountLabel: accountLabel,
            planLabel: planLabel,
            glanceRemainingPercent: remaining,
            barLabel: barLabel,
            headline: headline,
            resetLabel: reset,
            exactReset: surfaceId == "codex" ? "(15 Aug 2026, 17:02)" : nil,
            statusWord: status,
            isRefreshing: refreshing,
            statusLabel: refreshing ? "Refreshing \(label) usage" : status,
            severity: severity(for: remaining),
            updatedLabel: updated,
            lastError: error,
            dimmed: status != "fresh"
        )
    }

    private static func surface(
        glance: PresentationStore.GlanceProviderRow,
        detail: UsageDetailPresentation,
        credentialOrigin: String?
    ) -> PresentationStore.SurfaceRow {
        PresentationStore.SurfaceRow(
            id: glance.surfaceId,
            label: glance.displayLabel,
            enabled: true,
            statusBarLabel: glance.barLabel,
            status: glance.statusWord,
            accountLabel: glance.accountLabel,
            username: nil,
            planLabel: glance.planLabel,
            credentialOrigin: credentialOrigin,
            estimateCaption: nil,
            buckets: [],
            updatedLabel: glance.updatedLabel,
            lastError: glance.lastError,
            detailPresentation: detail
        )
    }

    private static func detailPresentation(for provider: Provider) -> UsageDetailPresentation {
        switch provider {
        case .codex: openAIDetail()
        case .claude: anthropicDetail()
        default: .empty
        }
    }

    private static func openAIDetail() -> UsageDetailPresentation {
        UsageDetailPresentation(rows: [
            metadata(id: "status", label: "Status", value: "fresh"),
            metadata(id: "updated", label: "Updated", value: "Just now"),
            metadata(id: "auth", label: "Auth", value: "OAuth · ~/.codex/auth.json"),
            bucket(
                id: "bucket:0",
                label: "Session",
                remaining: "63% left",
                meter: 63,
                severity: "normal",
                supporting: ["On pace", "Resets in 2h 14m"]
            ),
            bucket(
                id: "bucket:1",
                label: "Weekly",
                remaining: "57% left",
                meter: 57,
                severity: "warn",
                supporting: ["13% in deficit · Runs out in 2d 17h", "Resets in 3d"]
            ),
            bucket(
                id: "bucket:2",
                label: "Codex Spark 5-hour",
                remaining: "88% left",
                meter: 88,
                severity: "normal",
                supporting: ["On pace", "Resets in 4h 02m"]
            ),
            bucket(
                id: "bucket:3",
                label: "Codex Spark Weekly",
                remaining: "100% left",
                meter: 100,
                severity: "normal",
                supporting: ["Resets in 7d"]
            ),
            detail(
                id: "bucket:4",
                label: "Limit Reset Credits",
                lines: ["3 manual resets available", "Next expires in 3d 4h"]
            ),
        ])
    }

    private static func exhaustedOpenAIDetail() -> UsageDetailPresentation {
        var rows = openAIDetail().rows
        rows[3] = bucket(
            id: "bucket:0",
            label: "Session",
            remaining: "0% left",
            meter: 0,
            severity: "danger",
            supporting: ["Resets in 42m"]
        )
        return UsageDetailPresentation(rows: rows)
    }

    private static func anthropicDetail() -> UsageDetailPresentation {
        UsageDetailPresentation(rows: [
            bucket(
                id: "bucket:0",
                label: "Session",
                remaining: "74% left",
                meter: 74,
                severity: "normal",
                supporting: ["12% in deficit", "Resets in 4h 19m"]
            ),
            bucket(
                id: "bucket:1",
                label: "Weekly",
                remaining: "12% left",
                meter: 12,
                severity: "danger",
                supporting: ["52% in reserve", "Resets in 1h"]
            ),
            bucket(
                id: "bucket:2",
                label: "All models",
                remaining: "28% left",
                meter: 28,
                severity: "warn",
                supporting: ["Weekly all-models window", "Resets with weekly"]
            ),
            bucket(
                id: "bucket:3",
                label: "Sonnet",
                remaining: "35% left",
                meter: 35,
                severity: "warn",
                supporting: ["Model-scoped · paced", "Resets in 6d 12h"]
            ),
            bucket(
                id: "bucket:4",
                label: "Fable only",
                remaining: "28% left",
                meter: 28,
                severity: "warn",
                supporting: ["Resets in 12h 19m"]
            ),
            bucket(
                id: "bucket:5",
                label: "Daily Routines",
                remaining: "100% left",
                meter: 100,
                severity: "normal",
                supporting: ["No reset timestamp from provider"]
            ),
            detail(
                id: "bucket:6",
                label: "Extra usage",
                lines: ["Spend bound", "Quota-bound money / spend slot (limits only)"]
            ),
        ])
    }

    private static func metadata(id: String, label: String, value: String) -> UsageDetailRow {
        UsageDetailRow(
            rowId: id,
            kind: .metadata,
            label: label,
            layoutLines: [UsagePresentationLine(leading: value, trailing: nil)],
            displayLabel: value,
            meterPercent: nil,
            severity: "normal"
        )
    }

    private static func detail(id: String, label: String, lines: [String]) -> UsageDetailRow {
        UsageDetailRow(
            rowId: id,
            kind: .detail,
            label: label,
            layoutLines: lines.map { UsagePresentationLine(leading: $0, trailing: nil) },
            displayLabel: lines.joined(separator: " · "),
            meterPercent: nil,
            severity: "normal"
        )
    }

    private static func bucket(
        id: String,
        label: String,
        remaining: String,
        meter: UInt8,
        severity: String,
        supporting: [String]
    ) -> UsageDetailRow {
        UsageDetailRow(
            rowId: id,
            kind: .bucket,
            label: label,
            layoutLines: ([remaining] + supporting).map {
                UsagePresentationLine(leading: $0, trailing: nil)
            },
            displayLabel: ([remaining] + supporting).joined(separator: " · "),
            meterPercent: meter,
            severity: severity
        )
    }

    private static func severity(for remaining: UInt8?) -> String {
        guard let remaining else { return "normal" }
        if remaining <= 15 { return "danger" }
        if remaining <= 60 { return "warn" }
        return "normal"
    }
}
