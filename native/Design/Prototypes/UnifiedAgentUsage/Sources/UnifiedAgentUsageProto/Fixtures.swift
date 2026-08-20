import SwiftUI

// Canonical fixture records from native/Design/UnifiedAgentUsage/Fixtures.md
// (revision recorded in SIGNOFF.md). Strings here stand in for immutable
// Rust-owned display input; the prototype changes layout only.

enum ProtoState: String, Sendable {
    case current, warning, danger, depleted, stale, refreshing, unavailable

    var label: String? {
        switch self {
        case .current: nil
        case .warning: "Low"
        case .danger: "Very low"
        case .depleted: "Depleted"
        case .stale: "Stale"
        case .refreshing: "Updating…"
        case .unavailable: "Unavailable"
        }
    }

    var symbol: String {
        switch self {
        case .current: "checkmark.circle"
        case .warning, .danger: "exclamationmark.triangle.fill"
        case .depleted: "exclamationmark.circle.fill"
        case .stale: "clock.arrow.circlepath"
        case .refreshing: "arrow.triangle.2.circlepath"
        case .unavailable: "exclamationmark.icloud.fill"
        }
    }
}

struct ProtoQuotaWindow: Identifiable, Sendable {
    let stableID: String
    let label: String
    let display: String
    let meter: Int?
    let state: ProtoState
    /// Rust-owned pace phrase (QuotaBucketDto.pace_label): even-burn delta or
    /// exhaustion projection, limits-only — never cost data.
    var pace: String? = nil
    /// Untouched window ("Not started" in OpenUsage terms): full quota, zero
    /// consumption — distinct from merely healthy.
    var notStarted = false
    var id: String { stableID }

    /// Compact period tag for the status-item bottom line ("57% w").
    /// Layout-only projection; Rust owns the source label in the real app.
    var periodTag: String {
        switch label {
        case "Weekly": "w"
        case "Daily": "d"
        case "Monthly": "mo"
        case "Five-hour": "5h"
        case "Session": "sess"
        default: label.lowercased()
        }
    }

    /// The status bar surfaces long-range windows only — the quota that
    /// expires wholesale, so the user can spend it before it lapses.
    /// Hour-range windows (five-hour, session) stay in window surfaces.
    var isLongRange: Bool {
        switch label {
        case "Weekly", "Daily", "Monthly": true
        default: false
        }
    }
}

struct ProtoAccount: Identifiable, Sendable {
    let key: String
    let label: String
    let plan: String
    let remaining: Int?
    let resetText: String?
    let state: ProtoState
    let windows: [ProtoQuotaWindow]
    var id: String { key }
}

struct ProtoProvider: Identifiable, Sendable {
    let key: String
    let name: String
    let state: ProtoState
    let summaryPercent: Int?
    let summaryReset: String?
    let accounts: [ProtoAccount]
    let selectedAccountKey: String?
    let updatedAgo: String?
    let activityText: String?
    let errorText: String?
    var id: String { key }

    var summaryRemainingLeft: String? { summaryPercent.map { "\($0)% left" } }
    var summaryRemainingUsed: String? { summaryPercent.map { "\(100 - $0)% used" } }

    /// Icon key matches the bundled official provider mark names.
    var iconKey: String { key }
    var fallbackGlyph: String { String(name.prefix(1)) }
    var isRefreshing: Bool { state == .refreshing }

    /// One Rust-owned activity phrase for identity rows.
    var activityLabel: String {
        if let activityText { return activityText }
        return [summaryRemainingLeft, summaryReset].compactMap { $0 }.joined(separator: " · ")
    }

    /// Compact reset countdown for the dual-stack status-item title.
    var compactResetLabel: String? {
        guard let summaryReset else { return nil }
        guard summaryReset.hasPrefix("Resets in ") else { return nil }
        return String(summaryReset.dropFirst("Resets in ".count))
    }

    /// Window driving the status summary: the long-range window whose meter
    /// matches the summary percent, else the first long-range window.
    /// Hour-range windows never drive the status bar.
    var summaryWindow: ProtoQuotaWindow? {
        let longRange = accounts.flatMap(\.windows).filter(\.isLongRange)
        if let percent = summaryPercent,
            let match = longRange.first(where: { $0.meter == percent })
        {
            return match
        }
        return longRange.first
    }
}

struct ProtoChrome: Sendable {
    var refreshTitle = "Refresh"
    var openUsageTitle = "Open Usage"
    var retryTitle = "Retry"
    var locale = Locale(identifier: "en_US")
    var layoutDirection: LayoutDirection = .leftToRight
}

enum ProtoMutationScript: Sendable {
    case standard
    case acceptPercentStyle
    case rejectLowFloor
    case reorderedFloor
}

struct ProtoProjection: Sendable {
    let scenario: String
    let providers: [ProtoProvider]
    let statusRows: [String]
    let isLoading: Bool
    let globalError: String?
    let chrome: ProtoChrome
    let mutationScript: ProtoMutationScript
    let selectedProviderKey: String?
    let selectedAccountKey: String?
}

enum ProtoSymbols {
    static func provider(_ key: String) -> String {
        switch key {
        case "codex": "chevron.left.forwardslash.chevron.right"
        case "claude": "sparkle"
        case "amp": "bolt.fill"
        case "grok": "x.circle"
        case "zai": "z.circle"
        case "kimi": "k.circle"
        case "minimax": "m.circle"
        default: "circle"
        }
    }
}

enum ProtoFixtures {
    static let resetUnavailable = "Reset unavailable"

    static func load(_ name: String) -> ProtoProjection {
        switch name {
        case "default", "F02": f02()
        case "F00": f00()
        case "F01": f01()
        case "F03": f03(selected: "codex-plus")
        case "F04": f04()
        case "F05": f05()
        case "F06": f06()
        case "F07": f07()
        case "F08": f08()
        case "F09": f09()
        case "F10": f10()
        case "F11": f11()
        case "F12": f12()
        case "F13": f13()
        case "F14": f14()
        case "F15": f02(scenario: "F15", script: .acceptPercentStyle,
                        statusRows: ["claude", "amp", "codex"])
        case "F16": f02(scenario: "F16", script: .rejectLowFloor,
                        statusRows: ["claude", "amp", "codex"])
        case "F17": f02(scenario: "F17", script: .reorderedFloor,
                        statusRows: ["claude", "amp", "codex"])
        case "F18-f02": f02(scenario: "F18-f02")
        case "F18-f11": f11(scenario: "F18-f11")
        case "F19-en-US": f19(
            scenario: "F19-en-US", localeID: "en_US", direction: .leftToRight,
            provider: "OpenAI Organization Production Sandbox — Southeast Asia",
            account: "organization-production-sandbox@example.test",
            plan: "Enterprise workspace with centrally managed weekly limits",
            reset: "Resets Tuesday, 18 August 2026 at 23:59 Indochina Time",
            error: "Provider response could not be refreshed; showing the last successful quota snapshot",
            refresh: "Refresh Refresh", openUsage: "Open Usage Open Usage")
        case "F19-ar-SA": f19(
            scenario: "F19-ar-SA", localeID: "ar_SA", direction: .rightToLeft,
            provider: "أوبن إيه آي", account: "team-01@example.test", plan: "فريق",
            reset: "تتم إعادة الضبط خلال ٣ أيام",
            error: "تعذّر تحديث الاستخدام؛ تظهر آخر لقطة ناجحة",
            refresh: "تحديث", openUsage: "فتح الاستخدام")
        case "F19-ja-JP": f19(
            scenario: "F19-ja-JP", localeID: "ja_JP", direction: .leftToRight,
            provider: "OpenAI", account: "研究チーム@example.test", plan: "エンタープライズ",
            reset: "8月18日火曜日 23:59にリセット",
            error: "使用量を更新できないため、最後に成功した値を表示しています",
            refresh: "更新", openUsage: "使用状況を開く")
        case "F19-de-DE": f19(
            scenario: "F19-de-DE", localeID: "de_DE", direction: .leftToRight,
            provider: "OpenAI", account: "forschung@example.test", plan: "Unternehmen",
            reset: "Zurücksetzung am Dienstag, 18. August 2026 um 23:59 Uhr",
            error: "Schlüsselbundzugriff verweigert",
            refresh: "Aktualisieren", openUsage: "Nutzung öffnen")
        case "F20": f02(scenario: "F20")
        case "F21": f03(scenario: "F21", selected: "codex-personal", statusRows: ["codex"])
        case "F22": f22()
        case "F23": f03(scenario: "F23", selected: "codex-personal", statusRows: ["codex"])
        case "F24-f02": f02(scenario: "F24-f02")
        case "F24-f11": f11(scenario: "F24-f11")
        case "F24-f12": f12(scenario: "F24-f12")
        default: fatalError("unknown --tr-scenario \(name)")
        }
    }

    // MARK: Core records

    static let codexPersonal = ProtoAccount(
        key: "codex-personal", label: "personal@example.test", plan: "Plus",
        remaining: 57, resetText: "Resets in 3d", state: .current,
        windows: [
            ProtoQuotaWindow(
                stableID: "bucket:weekly", label: "Weekly",
                display: "57% left · Resets in 3d", meter: 57, state: .warning,
                pace: "Runs out in 2d at current pace"),
            ProtoQuotaWindow(
                stableID: "bucket:five-hour", label: "Five-hour",
                display: "63% left · Resets in 2h", meter: 63, state: .current,
                pace: "On pace"),
            ProtoQuotaWindow(
                stableID: "bucket:credits", label: "Credits",
                display: "3 manual resets available · Next expires in 3d 4h",
                meter: nil, state: .current),
        ])

    static let codexPlus = ProtoAccount(
        key: "codex-plus", label: "team@example.test", plan: "Plus",
        remaining: 0, resetText: "Resets in 3d", state: .depleted,
        windows: [
            ProtoQuotaWindow(
                stableID: "bucket:weekly", label: "Weekly",
                display: "0% left · Resets in 3d", meter: 0, state: .depleted)
        ])

    static let codexOrganization = ProtoAccount(
        key: "codex-organization", label: "organization-production-sandbox@example.test",
        plan: "Enterprise", remaining: 88, resetText: "Resets in 3d", state: .current,
        windows: [
            ProtoQuotaWindow(
                stableID: "bucket:weekly", label: "Weekly",
                display: "88% left · Resets in 3d", meter: 88, state: .current,
                pace: "On pace"),
            // Spend-control lane from the same /wham/usage payload
            // (individual_limit) — a quota-bound money cap, not spend tracking.
            ProtoQuotaWindow(
                stableID: "bucket:monthly-credit-pool", label: "Monthly credit pool",
                display: "$312 used of $500 cap · Resets Sep 1",
                meter: 38, state: .current),
        ])

    static let claudePersonal = ProtoAccount(
        key: "claude-personal", label: "personal@example.test", plan: "Pro",
        remaining: 12, resetText: "Resets in 1h", state: .danger,
        windows: [
            ProtoQuotaWindow(
                stableID: "bucket:session", label: "Session",
                display: "74% left", meter: 74, state: .current,
                pace: "On pace"),
            ProtoQuotaWindow(
                stableID: "bucket:weekly", label: "Weekly",
                display: "12% left · Resets in 1h", meter: 12, state: .danger),
        ])

    static func catalogAccount(
        _ provider: String, remaining: Int, reset: String?
    ) -> ProtoAccount {
        ProtoAccount(
            key: "\(provider)-default", label: "default", plan: "Default",
            remaining: remaining, resetText: reset, state: .current,
            windows: [
                ProtoQuotaWindow(
                    stableID: "bucket:weekly", label: "Weekly",
                    display: "\(remaining)% left · \(reset ?? resetUnavailable)",
                    meter: remaining, state: .current)
            ])
    }

    static func provider(
        _ key: String, _ name: String, percent: Int?, reset: String?,
        accounts: [ProtoAccount], selected: String? = nil,
        state: ProtoState = .current, updatedAgo: String? = nil,
        activity: String? = nil, error: String? = nil
    ) -> ProtoProvider {
        ProtoProvider(
            key: key, name: name, state: state, summaryPercent: percent,
            summaryReset: reset, accounts: accounts,
            selectedAccountKey: selected ?? accounts.first?.key,
            updatedAgo: updatedAgo, activityText: activity, errorText: error)
    }

    static func codexProvider(
        accounts: [ProtoAccount] = [codexPersonal], selected: String? = "codex-personal",
        state: ProtoState = .current, updatedAgo: String? = nil,
        activity: String? = nil, error: String? = nil
    ) -> ProtoProvider {
        provider(
            "codex", "OpenAI / Codex", percent: 57, reset: "Resets in 3d",
            accounts: accounts, selected: selected, state: state,
            updatedAgo: updatedAgo, activity: activity, error: error)
    }

    static func claudeProvider(
        state: ProtoState = .current, error: String? = nil, usable: Bool = true
    ) -> ProtoProvider {
        provider(
            "claude", "Anthropic / Claude", percent: 12, reset: "Resets in 1h",
            accounts: usable ? [claudePersonal] : [], state: state, error: error)
    }

    /// Seven desktop providers in frozen canonical order, one account each.
    static func catalog(codexState: ProtoState = .current, codexActivity: String? = nil,
                        kimiUnavailable: Bool = false) -> [ProtoProvider] {
        [
            codexProvider(state: codexState, activity: codexActivity),
            claudeProvider(),
            provider("amp", "Amp", percent: 100, reset: "Resets in 18h",
                     accounts: [
                        ProtoAccount(
                            key: "amp-default", label: "default", plan: "Amp Free",
                            remaining: 100, resetText: "Resets in 18h", state: .current,
                            windows: [
                                ProtoQuotaWindow(
                                    stableID: "bucket:daily", label: "Daily",
                                    display: "Not started · Resets in 18h",
                                    meter: 100, state: .current, notStarted: true)
                            ])
                     ]),
            provider("grok", "xAI / Grok", percent: 72, reset: nil,
                     accounts: [catalogAccount("grok", remaining: 72, reset: nil)]),
            provider("zai", "Z.AI / GLM", percent: 81, reset: nil,
                     accounts: [catalogAccount("zai", remaining: 81, reset: nil)]),
            kimiUnavailable
                ? provider("kimi", "Kimi", percent: 45, reset: nil, accounts: [],
                           state: .unavailable, error: "usage provider probe timed out")
                : provider("kimi", "Kimi", percent: 45, reset: nil,
                           accounts: [catalogAccount("kimi", remaining: 45, reset: nil)]),
            provider("minimax", "MiniMax", percent: 33, reset: nil,
                     accounts: [catalogAccount("minimax", remaining: 33, reset: nil)]),
        ]
    }

    // MARK: Scenarios

    static func projection(
        _ scenario: String, providers: [ProtoProvider], statusRows: [String],
        script: ProtoMutationScript = .standard,
        selectedProvider: String? = nil, selectedAccount: String? = nil,
        chrome: ProtoChrome = ProtoChrome()
    ) -> ProtoProjection {
        ProtoProjection(
            scenario: scenario, providers: providers, statusRows: statusRows,
            isLoading: false, globalError: nil, chrome: chrome, mutationScript: script,
            selectedProviderKey: selectedProvider, selectedAccountKey: selectedAccount)
    }

    static func f00() -> ProtoProjection {
        projection("F00", providers: [], statusRows: [])
    }

    static func f01() -> ProtoProjection {
        projection("F01", providers: [codexProvider()], statusRows: ["codex"],
                   selectedProvider: "codex", selectedAccount: "codex-personal")
    }

    static func f02(
        scenario: String = "F02", script: ProtoMutationScript = .standard,
        statusRows: [String] = ["claude", "amp", "codex"]
    ) -> ProtoProjection {
        projection(scenario, providers: catalog(), statusRows: statusRows, script: script)
    }

    static func f03(
        scenario: String = "F03", selected: String,
        statusRows: [String] = []
    ) -> ProtoProjection {
        projection(
            scenario,
            providers: [
                codexProvider(
                    accounts: [codexPersonal, codexPlus, codexOrganization],
                    selected: selected)
            ],
            statusRows: statusRows,
            selectedProvider: "codex", selectedAccount: selected)
    }

    static func f04() -> ProtoProjection {
        projection("F04", providers: [claudeProvider()], statusRows: ["claude"],
                   selectedProvider: "claude", selectedAccount: "claude-personal")
    }

    static func f05() -> ProtoProjection {
        projection(
            "F05",
            providers: [codexProvider(accounts: [codexPlus], selected: "codex-plus")],
            statusRows: [], selectedProvider: "codex", selectedAccount: "codex-plus")
    }

    static func f06() -> ProtoProjection {
        projection(
            "F06",
            providers: [
                codexProvider(
                    state: .stale, updatedAgo: "Updated 47m ago",
                    error: "Codex provider usage unavailable; cached quota is stale")
            ],
            statusRows: ["codex"], selectedProvider: "codex",
            selectedAccount: "codex-personal")
    }

    static func f07() -> ProtoProjection {
        projection(
            "F07",
            providers: catalog(codexState: .refreshing, codexActivity: "Updating…"),
            statusRows: ["claude", "amp", "codex"])
    }

    static func f08() -> ProtoProjection {
        projection("F08", providers: catalog(kimiUnavailable: true),
                   statusRows: ["claude", "amp", "codex"])
    }

    static func f09() -> ProtoProjection {
        projection(
            "F09",
            providers: [
                claudeProvider(
                    state: .unavailable, error: "Claude Keychain access denied",
                    usable: false)
            ],
            statusRows: [], selectedProvider: "claude")
    }

    static func f10() -> ProtoProjection {
        projection(
            "F10",
            providers: [
                provider(
                    "kimi", "Kimi", percent: 45, reset: nil,
                    accounts: [catalogAccount("kimi", remaining: 45, reset: nil)],
                    state: .stale, updatedAgo: "Updated 1h ago",
                    error: "Kimi billing endpoint unavailable; local presence only")
            ],
            statusRows: ["kimi"], selectedProvider: "kimi",
            selectedAccount: "kimi-default")
    }

    static func f11(scenario: String = "F11") -> ProtoProjection {
        projection(
            scenario,
            providers: [
                provider(
                    "codex",
                    "OpenAI Organization Production Sandbox — Southeast Asia",
                    percent: 57,
                    reset: "Resets Tuesday, 18 August 2026 at 23:59 Indochina Time",
                    accounts: [
                        ProtoAccount(
                            key: "codex-organization",
                            label: "organization-production-sandbox@example.test",
                            plan: "Enterprise workspace with centrally managed weekly limits",
                            remaining: 57,
                            resetText:
                                "Resets Tuesday, 18 August 2026 at 23:59 Indochina Time",
                            state: .current,
                            windows: [
                                ProtoQuotaWindow(
                                    stableID: "bucket:weekly",
                                    label: "Organization-wide weekly accelerated-model allocation",
                                    display:
                                        "57% left · Resets Tuesday, 18 August 2026 at 23:59 Indochina Time",
                                    meter: 57, state: .current)
                            ])
                    ],
                    state: .stale,
                    error:
                        "Provider response could not be refreshed; showing the last successful quota snapshot"
                )
            ],
            statusRows: ["codex"], selectedProvider: "codex",
            selectedAccount: "codex-organization")
    }

    static func f12(scenario: String = "F12") -> ProtoProjection {
        let surfaces = ["codex", "claude", "amp", "grok", "zai", "kimi", "minimax"]
        let names = [
            "OpenAI / Codex", "Anthropic / Claude", "Amp", "xAI / Grok",
            "Z.AI / GLM", "Kimi", "MiniMax",
        ]
        let plans = ["Free", "Plus", "Pro", "Team", "Enterprise", "Default"]
        let cycle: [Int?] = [88, nil, 28, 0, 12, 57, 100]
        let windowLabels = [
            "Hourly", "Daily", "Daily", "Weekly", "Monthly", "Model",
            "Organization", "Credits",
        ]
        let resets = [
            "Resets in 1h", "Resets in 6h", "Resets in 18h", "Resets in 3d",
            "Resets Sep 1", "Reset unavailable", "Resets Tuesday 23:59",
            "No reset supplied",
        ]
        var globalIndex = 0
        var providers: [ProtoProvider] = []
        for (providerIndex, surface) in surfaces.enumerated() {
            var accounts: [ProtoAccount] = []
            for ordinal in 1...6 {
                let index = globalIndex
                globalIndex += 1
                let key = "\(surface)-load-0\(ordinal)"
                let label =
                    key == "claude-load-03"
                    ? "Research workspace" : "\(surface)-0\(ordinal)@example.test"
                let remaining = cycle[index % 7]
                let windows = (0..<8).map { windowIndex -> ProtoQuotaWindow in
                    let windowRemaining = cycle[(index + windowIndex) % 7]
                    let remainingText =
                        windowRemaining.map { "\($0)% left" } ?? "Remaining unavailable"
                    return ProtoQuotaWindow(
                        stableID: "limit-0\(windowIndex + 1)",
                        label: windowLabels[windowIndex],
                        display: "\(remainingText) · \(resets[windowIndex])",
                        meter: windowRemaining,
                        state: stateFor(remaining: windowRemaining))
                }
                accounts.append(
                    ProtoAccount(
                        key: key, label: label, plan: plans[ordinal - 1],
                        remaining: remaining, resetText: resets[index % 8],
                        state: stateFor(remaining: remaining), windows: windows))
            }
            providers.append(
                ProtoProvider(
                    key: surface, name: names[providerIndex],
                    state: .current, summaryPercent: accounts[0].remaining,
                    summaryReset: accounts[0].resetText, accounts: accounts,
                    selectedAccountKey: accounts[0].key, updatedAgo: nil,
                    activityText: nil, errorText: nil))
        }
        return projection(
            scenario, providers: providers, statusRows: ["claude", "codex", "amp"],
            selectedProvider: "claude", selectedAccount: "claude-load-03")
    }

    static func stateFor(remaining: Int?) -> ProtoState {
        guard let remaining else { return .current }
        switch remaining {
        case 0: return .depleted
        case ...15: return .danger
        case ...30: return .warning
        default: return .current
        }
    }

    static func f13() -> ProtoProjection {
        ProtoProjection(
            scenario: "F13", providers: [], statusRows: [], isLoading: true,
            globalError: nil, chrome: ProtoChrome(), mutationScript: .standard,
            selectedProviderKey: nil, selectedAccountKey: nil)
    }

    static func f14() -> ProtoProjection {
        ProtoProjection(
            scenario: "F14", providers: [], statusRows: [], isLoading: false,
            globalError: "Usage presentation is unavailable", chrome: ProtoChrome(),
            mutationScript: .standard, selectedProviderKey: nil,
            selectedAccountKey: nil)
    }

    static func f19(
        scenario: String, localeID: String, direction: LayoutDirection,
        provider: String, account: String, plan: String, reset: String,
        error: String, refresh: String, openUsage: String
    ) -> ProtoProjection {
        var chrome = ProtoChrome()
        chrome.refreshTitle = refresh
        chrome.openUsageTitle = openUsage
        chrome.locale = Locale(identifier: localeID)
        chrome.layoutDirection = direction
        var providers = catalog()
        providers[0] = ProtoProvider(
            key: "codex", name: provider, state: .stale, summaryPercent: 57,
            summaryReset: reset,
            accounts: [
                ProtoAccount(
                    key: "codex-team", label: account, plan: plan, remaining: 57,
                    resetText: reset, state: .current,
                    windows: [
                        ProtoQuotaWindow(
                            stableID: "bucket:weekly", label: "Weekly",
                            display: "57% left · \(reset)", meter: 57,
                            state: .current)
                    ])
            ],
            selectedAccountKey: "codex-team", updatedAgo: nil, activityText: nil,
            errorText: error)
        return projection(
            scenario, providers: providers, statusRows: ["claude", "amp", "codex"],
            chrome: chrome)
    }

    static func f22() -> ProtoProjection {
        projection(
            "F22",
            providers: [
                provider(
                    "minimax", "MiniMax", percent: 33, reset: nil,
                    accounts: [
                        ProtoAccount(
                            key: "minimax-default", label: "default", plan: "Pro",
                            remaining: 33, resetText: nil, state: .current,
                            windows: [
                                ProtoQuotaWindow(
                                    stableID: "bucket:monthly-credit-cap",
                                    label: "Monthly credit allowance",
                                    display: "$6 available of $20 cap · Resets Sep 1",
                                    meter: nil, state: .current)
                            ])
                    ])
            ],
            statusRows: ["minimax"], selectedProvider: "minimax",
            selectedAccount: "minimax-default")
    }
}
