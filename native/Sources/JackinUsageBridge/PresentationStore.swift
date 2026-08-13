// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import CoreGraphics
import Foundation

/// Status-item display mode (Settings-selectable; Rust supplies every string).
public enum StatusItemDisplayMode: String, CaseIterable, Sendable {
    case iconOnly
    case focusPercent
    case pinnedSurface
    case strip
}

/// Pure mode → which Rust accessor to call (unit-testable; no bridge).
public enum StatusItemTextSelection: Equatable, Sendable {
    case empty
    case focus
    case pinned(surfaceId: String)
    case strip(max: UInt32)
}

/// Select the status-item text source from prefs.
///
/// Empty when icon-only or
/// screen-share collapse is active; pinned without an id falls back to empty.
public func statusItemTextSelection(
    mode: StatusItemDisplayMode,
    pinnedSurfaceId: String?,
    stripMax: Int,
    hideForScreenShare: Bool
) -> StatusItemTextSelection {
    if hideForScreenShare {
        return .empty
    }
    switch mode {
    case .iconOnly:
        return .empty
    case .focusPercent:
        return .focus
    case .pinnedSurface:
        guard let id = pinnedSurfaceId, !id.isEmpty else {
            return .empty
        }
        return .pinned(surfaceId: id)
    case .strip:
        // SB-3 hard-caps burn-first strip at 3.
        let cap = UInt32(max(1, min(statusBarMaxChips, stripMax)))
        return .strip(max: cap)
    }
}

/// Thin presentation store: polls Rust UniFFI snapshots; no provider probes.
@MainActor
public final class PresentationStore: ObservableObject {
    public struct SurfaceRow: Identifiable, Sendable, Equatable {
        public let id: String
        public let label: String
        public var enabled: Bool
        public var statusBarLabel: String
        public var status: String
        public var accountLabel: String
        public var username: String?
        public var planLabel: String?
        public var credentialOrigin: String?
        public var estimateCaption: String?
        public var buckets: [BucketRow]
        public var updatedLabel: String
        public var lastError: String?
        /// Rust-owned Capsule-parity provider detail.
        ///
        /// The Usage window
        /// renders these rows verbatim; other surfaces ignore it.
        public var detailPresentation: UsageDetailPresentation

        public init(
            id: String,
            label: String,
            enabled: Bool,
            statusBarLabel: String,
            status: String,
            accountLabel: String,
            username: String?,
            planLabel: String?,
            credentialOrigin: String?,
            estimateCaption: String?,
            buckets: [BucketRow],
            updatedLabel: String,
            lastError: String?,
            detailPresentation: UsageDetailPresentation
        ) {
            self.id = id
            self.label = label
            self.enabled = enabled
            self.statusBarLabel = statusBarLabel
            self.status = status
            self.accountLabel = accountLabel
            self.username = username
            self.planLabel = planLabel
            self.credentialOrigin = credentialOrigin
            self.estimateCaption = estimateCaption
            self.buckets = buckets
            self.updatedLabel = updatedLabel
            self.lastError = lastError
            self.detailPresentation = detailPresentation
        }
    }

    public struct BucketRow: Identifiable, Sendable, Equatable {
        public var id: String { label }
        public let label: String
        public let usedLabel: String?
        public let limitLabel: String?
        public let remainingPercent: UInt8?
        public let resetLabel: String?
        public let paceLabel: String?
        public let statusSlot: String?
        public let severity: String
        public let status: String
        /// Rust money fields (display-only; formatted in the shell).
        public let usedMoney: MoneyDto?
        public let limitMoney: MoneyDto?
        /// Rust-owned limits-only presentation (rendered verbatim; never recomputed).
        public let remainingLabel: String?
        public let displaySegments: [String]
        public let displayLabel: String
        public let meterPercent: UInt8?
    }

    /// One Rust-owned provider glance row projected verbatim (no computed usage
    /// values in Swift). `id == surfaceId`.
    public struct GlanceProviderRow: Identifiable, Sendable, Equatable {
        public var id: String { surfaceId }
        public let surfaceId: String
        public let iconKey: String
        public let displayLabel: String
        public let accountLabel: String
        public let planLabel: String?
        public let glanceRemainingPercent: UInt8?
        public let barLabel: String
        public let headline: String
        public let resetLabel: String?
        public let exactReset: String?
        public let statusWord: String
        public let isRefreshing: Bool
        public let statusLabel: String
        public let severity: String
        public let updatedLabel: String
        public let lastError: String?
        public let dimmed: Bool

        public init(
            surfaceId: String,
            iconKey: String,
            displayLabel: String,
            accountLabel: String,
            planLabel: String?,
            glanceRemainingPercent: UInt8?,
            barLabel: String,
            headline: String,
            resetLabel: String?,
            exactReset: String?,
            statusWord: String,
            isRefreshing: Bool,
            statusLabel: String,
            severity: String,
            updatedLabel: String,
            lastError: String?,
            dimmed: Bool
        ) {
            self.surfaceId = surfaceId
            self.iconKey = iconKey
            self.displayLabel = displayLabel
            self.accountLabel = accountLabel
            self.planLabel = planLabel
            self.glanceRemainingPercent = glanceRemainingPercent
            self.barLabel = barLabel
            self.headline = headline
            self.resetLabel = resetLabel
            self.exactReset = exactReset
            self.statusWord = statusWord
            self.isRefreshing = isRefreshing
            self.statusLabel = statusLabel
            self.severity = severity
            self.updatedLabel = updatedLabel
            self.lastError = lastError
            self.dimmed = dimmed
        }
    }

    public struct OverviewRow: Identifiable, Sendable, Equatable {
        public var id: String { surfaceId }
        public let surfaceId: String
        public let displayLabel: String
        public let headline: String
        public let resetLabel: String?
        public let exactReset: String?
        public let statusWord: String
        public let severity: String
    }

    /// Rust-owned, sanitized discovery failure. No credential location or secret.
    public struct DiscoveryDiagnostic: Identifiable, Sendable, Equatable {
        public var id: String { "\(surfaceId ?? "global")#\(scopeLabel)#\(issue)" }
        public let surfaceId: String?
        public let scopeLabel: String
        public let issue: String
        public let message: String
        public let displayLabel: String
    }

    /// Multi-account row for a host surface (Rust-owned keys/labels).
    public struct AccountRow: Identifiable, Sendable, Equatable {
        public var id: String { "\(surfaceId)#\(accountKey)" }
        public let surfaceId: String
        public let accountKey: String
        public let accountLabel: String
        public let planLabel: String?
        public let selected: Bool
        public let remainingPercent: UInt8?
        public let statusWord: String
        /// Optional presentation severity.
        ///
        /// Values are `normal`/`warn`/`danger` or HTML mid/low/high.
        /// Empty → derived from remaining via ``accountMeterSeverity``.
        public let severity: String

        public init(
            surfaceId: String,
            accountKey: String,
            accountLabel: String,
            planLabel: String?,
            selected: Bool,
            remainingPercent: UInt8?,
            statusWord: String,
            severity: String = ""
        ) {
            self.surfaceId = surfaceId
            self.accountKey = accountKey
            self.accountLabel = accountLabel
            self.planLabel = planLabel
            self.selected = selected
            self.remainingPercent = remainingPercent
            self.statusWord = statusWord
            self.severity = severity
        }

        /// Resolved meter severity for nest/overview (explicit or remaining band).
        public var meterSeverity: String {
            accountMeterSeverity(severity: severity, remainingPercent: remainingPercent)
        }
    }

    @Published public private(set) var mergedBarLabel: String = "jackin❯ usage"
    /// Rust-owned short status-item label for focus mode (e.g. `Cl 37%` remaining).
    @Published public private(set) var compactBarLabel: String = ""
    /// Mode-selected status-item text (empty = icon only).
    ///
    /// Accessibility + fallback.
    @Published public private(set) var statusItemText: String = ""
    /// OpenUsage-style menu-bar chips (Rust compact labels + remaining for mini bars).
    @Published public private(set) var statusItemChips: [StatusItemChip] = []
    /// Footer / window next-refresh string from Rust.
    @Published public private(set) var nextRefreshLabel: String = ""
    @Published public private(set) var surfaces: [SurfaceRow] = []
    /// Rust-owned seven-provider glance rows (auto-detected, catalog order).
    ///
    /// Full inventory for popover / Usage — **includes** 0% (OV-7).
    @Published public private(set) var providerGlanceRows: [GlanceProviderRow] = []
    /// Burn-first **status bar** chips only (SB-3/14/17/19): hide 0%, soonest-
    /// then-remaining, hard-cap ≤3.
    ///
    /// Popover never uses this list.
    @Published public private(set) var statusBarGlanceRows: [GlanceProviderRow] = []
    /// Presentation-only privacy flag: `false` hides the Rust status-bar values
    /// during screen sharing (it may hide a Rust label, never replace it).
    @Published public private(set) var statusBarShowsValues = true
    @Published public private(set) var overviewRows: [OverviewRow] = []
    /// Known accounts across surfaces (multi-account host logins / shared snapshots).
    @Published public private(set) var accounts: [AccountRow] = []
    @Published public private(set) var discoveryDiagnostics: [DiscoveryDiagnostic] = []
    /// Sidebar / detail selection: `nil` = Overview, else surface id.
    @Published public private(set) var usageSelection: String?
    /// Focused popover provider; nil lets the host select the first available provider.
    @Published public var popoverSelection: String?
    /// True only while an enqueued refresh request runs its bridge operation —
    /// drives the popover/footer spinner.
    ///
    /// Never clears glance rows or surfaces.
    @Published public private(set) var refreshInProgress = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var isOpen: Bool = false
    /// True from the moment a cold open is submitted until it succeeds/fails, so
    /// a second `open`/`openDefault` (e.g. `applicationDidBecomeActive` firing
    /// while the async open is still in flight) is a no-op rather than a
    /// duplicate runtime open.
    @Published public private(set) var isOpening: Bool = false
    /// Refresh floor in seconds (owned by Rust; mirrored for Settings).
    @Published public private(set) var refreshFloorSecs: UInt64 = 300

    @Published public var displayMode: StatusItemDisplayMode {
        didSet {
            UserDefaults.standard.set(displayMode.rawValue, forKey: Self.displayModeKey)
            Task { [weak self] in await self?.applyStatusItemText() }
        }
    }

    @Published public var pinnedSurfaceId: String {
        didSet {
            UserDefaults.standard.set(pinnedSurfaceId, forKey: Self.pinnedSurfaceKey)
            Task { [weak self] in await self?.applyStatusItemText() }
        }
    }

    @Published public var stripMax: Int {
        didSet {
            // SB-3: never more than three burn-first chips.
            let clamped = max(1, min(statusBarMaxChips, stripMax))
            if clamped != stripMax {
                stripMax = clamped
                return
            }
            UserDefaults.standard.set(stripMax, forKey: Self.stripMaxKey)
            Task { [weak self] in await self?.applyStatusItemText() }
        }
    }

    /// Rust `percent_style`: `left` | `used`.
    @Published public var percentStyle: String {
        didSet {
            UserDefaults.standard.set(percentStyle, forKey: Self.percentStyleKey)
            Task { [weak self] in
                guard let self else { return }
                await self.pushFormatPrefs()
                if self.isOpen { await self.applySnapshots() }
            }
        }
    }

    /// Rust `reset_style`: `countdown` | `exact_clock`.
    @Published public var resetStyle: String {
        didSet {
            UserDefaults.standard.set(resetStyle, forKey: Self.resetStyleKey)
            Task { [weak self] in
                guard let self else { return }
                await self.pushFormatPrefs()
                if self.isOpen { await self.applySnapshots() }
            }
        }
    }

    @Published public var hideWhileScreenSharing: Bool {
        didSet {
            UserDefaults.standard.set(hideWhileScreenSharing, forKey: Self.hideScreenShareKey)
            Task { [weak self] in await self?.applyStatusItemText() }
        }
    }

    private static let displayModeKey = "jackin.desktop.displayMode"
    private static let pinnedSurfaceKey = "jackin.desktop.pinnedSurfaceId"
    private static let stripMaxKey = "jackin.desktop.stripMax"
    private static let percentStyleKey = "jackin.desktop.percentStyle"
    private static let resetStyleKey = "jackin.desktop.resetStyle"
    private static let hideScreenShareKey = "jackin.desktop.hideWhileScreenSharing"

    /// All bridge access is serialized off the main actor through this scheduler
    /// so a Keychain consent sheet can never freeze the UI. `PresentationStore`
    /// itself holds no bridge reference and makes no direct `bridge.` calls.
    private let scheduler: RefreshScheduler
    /// Per-surface compact status-bar label captured during the last projection,
    /// so status-item chip building needs no further bridge round-trips on main.
    private var compactLabelBySurface: [String: String] = [:]
    private var eventCursor: UInt64 = 0
    private var pollTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var screenShareActive: Bool = false
    private var fixtureMode = false
    private var launchConfiguration: LaunchConfiguration = .production

    public var usesFixture: Bool { fixtureMode }

    public convenience init() {
        self.init(scheduler: RefreshScheduler())
    }

    /// Designated initializer.
    ///
    /// Tests inject a scheduler wrapping a fake bridge.
    public init(scheduler: RefreshScheduler) {
        self.scheduler = scheduler
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: Self.displayModeKey),
            let mode = StatusItemDisplayMode(rawValue: raw)
        {
            self.displayMode = mode
        } else if defaults.object(forKey: "jackin.desktop.showPercent") != nil {
            // Pre-release migration: old boolean → mode (no long-term shim).
            self.displayMode =
                defaults.bool(forKey: "jackin.desktop.showPercent")
                ? .focusPercent
                : .iconOnly
            defaults.removeObject(forKey: "jackin.desktop.showPercent")
        } else {
            // Burn-first multi-chip strip by default (SB-3 ≤3).
            self.displayMode = .strip
        }
        self.pinnedSurfaceId = defaults.string(forKey: Self.pinnedSurfaceKey) ?? ""
        // SB-3 hard-caps at 3; migrate older UserDefaults >3 down.
        let strip = defaults.object(forKey: Self.stripMaxKey) as? Int ?? statusBarMaxChips
        self.stripMax = max(1, min(statusBarMaxChips, strip))
        let percent = defaults.string(forKey: Self.percentStyleKey) ?? "left"
        self.percentStyle = (percent == "used") ? "used" : "left"
        let reset = defaults.string(forKey: Self.resetStyleKey) ?? "countdown"
        self.resetStyle = (reset == "exact_clock") ? "exact_clock" : "countdown"
        self.hideWhileScreenSharing = defaults.bool(forKey: Self.hideScreenShareKey)
    }

    /// True when every enabled surface is stale/unavailable/error (dims status item).
    public var allEnabledSurfacesDegraded: Bool {
        let enabled = surfaces.filter(\.enabled)
        guard !enabled.isEmpty else { return true }
        return enabled.allSatisfy { row in
            switch row.status {
            case "fresh", "refreshing":
                return false
            default:
                return true
            }
        }
    }

    /// How this launch should open the runtime.
    ///
    /// Smoke mode is defense-in-depth
    /// for the isolated launch test: a non-home data root and no live probes.
    public enum LaunchConfiguration: Sendable, Equatable {
        case production
        case ephemeralSmoke(dataDir: String)

        /// Resolve from the environment: an absolute, non-home
        /// `JACKIN_DESKTOP_SMOKE_DATA_DIR` selects ephemeral smoke; else production.
        public static func resolve(
            environment: [String: String],
            homeDirectory: String
        ) -> LaunchConfiguration {
            if let dir = environment["JACKIN_DESKTOP_SMOKE_DATA_DIR"],
                dir.hasPrefix("/"),
                !dir.hasPrefix(homeDirectory)
            {
                return .ephemeralSmoke(dataDir: dir)
            }
            return .production
        }
    }

    public func openForLaunch(_ configuration: LaunchConfiguration) {
        launchConfiguration = configuration
        switch configuration {
        case .production:
            openDefault()
        case .ephemeralSmoke(let dataDir):
            openSmoke(dataDir: dataDir)
        }
    }

    public func openDefault() {
        open(
            dataDirOverride: nil,
            configRootOverride: nil,
            refreshFloorSecs: 300,
            enabled: [],
            allowLiveProbes: true
        )
    }

    /// Retry the failed cold open, or refresh when the runtime is already open.
    public func retryLastOperation() {
        guard !fixtureMode else { return }
        if isOpen {
            refreshAll()
        } else {
            openForLaunch(launchConfiguration)
        }
    }

    /// Ephemeral smoke open: isolated path, live probes disabled, exactly one
    /// snapshot application, and no initial/manual/periodic refresh or polling.
    private func openSmoke(dataDir: String) {
        guard !isOpen, !isOpening else { return }
        isOpening = true
        let config = OpenConfig(
            dataDirOverride: dataDir,
            configRootOverride: URL(fileURLWithPath: dataDir)
                .appendingPathComponent("config").path,
            refreshFloorSecs: 300,
            enabledSurfaceIds: [],
            allowLiveProbes: false
        )
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.scheduler.run { handle -> UInt64 in
                    try handle.openRuntime(config: config)
                    return try handle.refreshFloorSecs()
                }
                self.isOpen = true
                self.isOpening = false
                self.lastError = nil
                await self.applySnapshots()
            } catch {
                self.lastError = String(describing: error)
                self.isOpen = false
                self.isOpening = false
            }
        }
    }

    public func open(dataDir: String, refreshFloorSecs: UInt64, enabled: [String]) {
        open(
            dataDirOverride: dataDir,
            configRootOverride: URL(fileURLWithPath: dataDir)
                .appendingPathComponent("config").path,
            refreshFloorSecs: refreshFloorSecs,
            enabled: enabled,
            allowLiveProbes: true
        )
    }

    private func open(
        dataDirOverride: String?,
        configRootOverride: String?,
        refreshFloorSecs: UInt64,
        enabled: [String],
        allowLiveProbes: Bool
    ) {
        // Coalesce duplicate cold-opens: a second open while one is in flight
        // (or already open) is a no-op, so `applicationDidBecomeActive` firing
        // during the async open cannot start a second runtime.
        guard !isOpen, !isOpening else { return }
        isOpening = true
        let config = OpenConfig(
            dataDirOverride: dataDirOverride,
            configRootOverride: configRootOverride,
            refreshFloorSecs: refreshFloorSecs,
            enabledSurfaceIds: enabled,
            allowLiveProbes: allowLiveProbes
        )
        Task { [weak self] in
            guard let self else { return }
            do {
                let floor = try await self.scheduler.run { handle -> UInt64 in
                    try handle.openRuntime(config: config)
                    return try handle.refreshFloorSecs()
                }
                self.isOpen = true
                self.isOpening = false
                self.lastError = nil
                self.refreshFloorSecs = floor
                await self.pushFormatPrefs()
                // First load forces network so the bar is not stuck on "refreshing".
                await self.refreshAll(force: true)
                self.startPolling()
            } catch {
                self.lastError = String(describing: error)
                self.isOpen = false
                self.isOpening = false
            }
        }
    }

    public func shutdown() {
        pollTask?.cancel()
        pollTask = nil
        refreshTask?.cancel()
        refreshTask = nil
        // Non-blocking: shutdown runs on the serial queue behind any in-flight
        // bridge op; the main actor never waits on the Rust mutex.
        scheduler.invalidateAndShutdown()
        isOpen = false
        isOpening = false
    }

    public func setEnabled(surfaceId: String, enabled: Bool) {
        guard !fixtureMode else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.scheduler.run {
                    try $0.setEnabled(surfaceId: surfaceId, enabled: enabled)
                }
                await self.refreshAll(force: true)
            } catch {
                self.lastError = String(describing: error)
            }
        }
    }

    /// Select multi-account identity for a surface (Rust-persisted).
    public func setSelectedAccount(surfaceId: String, accountKey: String) {
        if fixtureMode {
            accounts = accounts.map { account in
                guard account.surfaceId == surfaceId else { return account }
                return AccountRow(
                    surfaceId: account.surfaceId,
                    accountKey: account.accountKey,
                    accountLabel: account.accountLabel,
                    planLabel: account.planLabel,
                    selected: account.accountKey == accountKey,
                    remainingPercent: account.remainingPercent,
                    statusWord: account.statusWord,
                    severity: account.severity
                )
            }
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.scheduler.run {
                    try $0.setSelectedAccount(surfaceId: surfaceId, accountKey: accountKey)
                }
                await self.applySnapshots()
            } catch {
                self.lastError = String(describing: error)
            }
        }
    }

    /// Accounts for one surface (empty when none known).
    public func accountsForSurface(_ surfaceId: String) -> [AccountRow] {
        accounts.filter { $0.surfaceId == surfaceId }
    }

    /// Inject frozen DATA_CONTRACT / QI presentation without a live bridge poll.
    ///
    /// Used by explicit visual-QA launches so UI automation drives the same
    /// ``PresentationStore`` + SwiftUI surfaces as production.
    /// Does not invent strings — caller supplies Rust-shaped fixtures.
    public func applyQIFixture(
        glanceRows: [GlanceProviderRow],
        statusBarGlanceRows: [GlanceProviderRow]? = nil,
        surfaces: [SurfaceRow],
        accounts: [AccountRow],
        popoverSelection: String?,
        usageSelection: String?,
        nextRefreshLabel: String = "next update 4m",
        isLoading: Bool = false,
        isRefreshing: Bool = false,
        lastError: String? = nil
    ) {
        fixtureMode = true
        self.providerGlanceRows = glanceRows
        self.statusBarGlanceRows =
            statusBarGlanceRows
            ?? selectStatusBarGlanceRows(from: glanceRows, maxCount: min(3, stripMax))
        self.surfaces = surfaces
        self.accounts = accounts
        self.popoverSelection = popoverSelection
        self.usageSelection = usageSelection
        self.nextRefreshLabel = nextRefreshLabel
        self.refreshInProgress = isRefreshing
        self.isOpen = true
        self.isOpening = isLoading
        self.lastError = lastError
        reconcileSelections()
    }

    public func setRefreshFloorSecs(_ secs: UInt64) {
        guard !fixtureMode else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let floor = try await self.scheduler.run { handle -> UInt64 in
                    try handle.setRefreshFloorSecs(secs: secs)
                    return try handle.refreshFloorSecs()
                }
                self.refreshFloorSecs = floor
            } catch {
                self.lastError = String(describing: error)
            }
        }
    }

    /// Manual Refresh button — bypasses floor.
    public func refreshAll() {
        guard !fixtureMode else { return }
        Task { [weak self] in await self?.refreshAll(force: true) }
    }

    /// Coalesce overlapping refresh requests into one in-flight task so a
    /// consent sheet cannot build a prompt storm.
    private func refreshAll(force: Bool) async {
        refreshTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            // Refresh-request activity drives the spinner; other bridge commands
            // (open/poll/settings/account/shutdown) never set it.
            self.refreshInProgress = true
            do {
                try await self.scheduler.run { try $0.refresh(surfaceId: nil, force: force) }
            } catch {
                self.lastError = String(describing: error)
            }
            await self.applySnapshots()
            self.refreshInProgress = false
        }
        refreshTask = task
        await task.value
    }

    public func refresh(surfaceId: String) {
        guard !fixtureMode else { return }
        Task { [weak self] in
            guard let self else { return }
            self.refreshInProgress = true
            do {
                try await self.scheduler.run { try $0.refresh(surfaceId: surfaceId, force: true) }
                await self.applySnapshots()
            } catch {
                self.lastError = String(describing: error)
            }
            self.refreshInProgress = false
        }
    }

    private func pushFormatPrefs() async {
        guard !fixtureMode, isOpen else { return }
        let prefs = UsageFormatPrefsDto(percentStyle: percentStyle, resetStyle: resetStyle)
        do {
            try await scheduler.run { try $0.setFormatPrefs(prefs: prefs) }
        } catch {
            lastError = String(describing: error)
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await self?.pollOnce()
            }
        }
    }

    private func pollOnce() async {
        guard !fixtureMode, isOpen else { return }
        if hideWhileScreenSharing {
            screenShareActive = Self.isScreenCurrentlyShared()
        } else {
            screenShareActive = false
        }
        statusBarShowsValues = !(hideWhileScreenSharing && screenShareActive)
        // Always-on: ask Rust to refresh when the floor allows (force: false).
        // Rust no-ops inside the floor so this is poll-safe every 5s. The whole
        // due-check + refresh + event-drain runs as one serialized bridge op off
        // the main actor, so a consent sheet cannot freeze the UI or queue polls.
        let cursor = eventCursor
        do {
            let nextCursor = try await scheduler.run { handle -> UInt64 in
                if try handle.refreshDue() {
                    try handle.refresh(surfaceId: nil, force: false)
                }
                return try handle.nextEvents(cursor: cursor, max: 64).nextCursor
            }
            eventCursor = nextCursor
            await applySnapshots()
        } catch {
            lastError = String(describing: error)
        }
    }

    /// Poll CGSession for active screen share (privacy collapse).
    ///
    /// AppKit-free.
    public static func isScreenCurrentlyShared() -> Bool {
        guard let dict = CGSessionCopyCurrentDictionary() as? [String: Any] else {
            return false
        }
        if let shared = dict["CGSSessionScreenIsShared"] as? Bool {
            return shared
        }
        if let shared = dict["CGSSessionScreenIsShared"] as? NSNumber {
            return shared.boolValue
        }
        return false
    }

    private func applySnapshots() async {
        guard !fixtureMode else { return }
        let projection: BridgeProjection
        // Capture off MainActor before the Sendable bridge batch (SB-3 ≤3).
        let barMax = UInt32(max(1, min(statusBarMaxChips, stripMax)))
        do {
            projection = try await scheduler.run { handle -> BridgeProjection in
                let merged = try handle.mergedStatusBarLabel()
                let compact = try handle.compactStatusBarLabel()
                let nextRefresh = try handle.nextRefreshLabel()
                let listed = try handle.listSurfaces()
                var surfaces: [SurfaceProjection] = []
                for surface in listed {
                    let view = surface.enabled ? try? handle.snapshot(surfaceId: surface.id) : nil
                    let compactFor =
                        surface.enabled
                        ? ((try? handle.compactStatusBarLabelFor(surfaceId: surface.id)) ?? "")
                        : ""
                    surfaces.append(
                        SurfaceProjection(info: surface, view: view, compactLabel: compactFor)
                    )
                }
                let overview = try handle.overviewRows()
                let diagnostics = try handle.discoveryDiagnostics()
                let accounts = (try? handle.listAccounts(surfaceId: nil)) ?? []
                let glanceRows = (try? handle.providerGlanceRows()) ?? []
                let statusBarRows =
                    (try? handle.statusBarProviderGlanceRows(max: barMax)) ?? []
                return BridgeProjection(
                    mergedBarLabel: merged,
                    compactBarLabel: compact,
                    nextRefreshLabel: nextRefresh,
                    surfaces: surfaces,
                    overviewRows: overview,
                    discoveryDiagnostics: diagnostics,
                    accounts: accounts,
                    glanceRows: glanceRows,
                    statusBarGlanceRows: statusBarRows
                )
            }
        } catch {
            lastError = String(describing: error)
            return
        }

        mergedBarLabel = projection.mergedBarLabel
        compactBarLabel = projection.compactBarLabel
        nextRefreshLabel = projection.nextRefreshLabel
        discoveryDiagnostics = projection.discoveryDiagnostics.map { diagnostic in
            DiscoveryDiagnostic(
                surfaceId: diagnostic.surfaceId,
                scopeLabel: diagnostic.scopeLabel,
                issue: diagnostic.issue,
                message: diagnostic.message,
                displayLabel: diagnostic.displayLabel
            )
        }
        let diagnosticBySurface = Dictionary(
            projection.discoveryDiagnostics.compactMap { diagnostic in
                diagnostic.surfaceId.map { ($0, diagnostic.displayLabel) }
            },
            uniquingKeysWith: { first, _ in first }
        )
        var labelBySurface: [String: String] = [:]
        surfaces = projection.surfaces.map { entry in
            let surface = entry.info
            labelBySurface[surface.id] = entry.compactLabel
            guard surface.enabled else {
                return SurfaceRow(
                    id: surface.id,
                    label: surface.label,
                    enabled: false,
                    statusBarLabel: "",
                    status: "disabled",
                    accountLabel: "",
                    username: nil,
                    planLabel: nil,
                    credentialOrigin: nil,
                    estimateCaption: nil,
                    buckets: [],
                    updatedLabel: "",
                    lastError: diagnosticBySurface[surface.id],
                    detailPresentation: .empty
                )
            }
            guard let view = entry.view else {
                return SurfaceRow(
                    id: surface.id,
                    label: surface.label,
                    enabled: true,
                    statusBarLabel: "unavailable",
                    status: "unavailable",
                    accountLabel: "",
                    username: nil,
                    planLabel: nil,
                    credentialOrigin: nil,
                    estimateCaption: nil,
                    buckets: [],
                    updatedLabel: "",
                    lastError: diagnosticBySurface[surface.id],
                    detailPresentation: .empty
                )
            }
            return SurfaceRow(
                id: surface.id,
                label: surface.label,
                enabled: true,
                statusBarLabel: view.statusBarLabel,
                status: view.status,
                accountLabel: view.accountLabel,
                username: view.username,
                planLabel: view.planLabel,
                credentialOrigin: view.credentialOrigin,
                estimateCaption: view.estimateCaption,
                buckets: view.buckets.map { bucket in
                    BucketRow(
                        label: bucket.label,
                        usedLabel: bucket.usedLabel,
                        limitLabel: bucket.limitLabel,
                        remainingPercent: bucket.remainingPercent,
                        resetLabel: bucket.resetLabel,
                        paceLabel: bucket.paceLabel,
                        statusSlot: bucket.statusSlot,
                        severity: bucket.severity,
                        status: bucket.status,
                        usedMoney: bucket.usedMoney,
                        limitMoney: bucket.limitMoney,
                        remainingLabel: bucket.remainingLabel,
                        displaySegments: bucket.displaySegments,
                        displayLabel: bucket.displayLabel,
                        meterPercent: bucket.meterPercent
                    )
                },
                updatedLabel: view.updatedLabel,
                lastError: view.lastError ?? diagnosticBySurface[surface.id],
                detailPresentation: UsageDetailPresentation(dto: view.detailPresentation)
            )
        }
        compactLabelBySurface = labelBySurface
        overviewRows = projection.overviewRows.map { row in
            OverviewRow(
                surfaceId: row.surfaceId,
                displayLabel: row.displayLabel,
                headline: row.headline,
                resetLabel: row.resetLabel,
                exactReset: row.exactReset,
                statusWord: row.statusWord,
                severity: row.severity
            )
        }
        accounts = projection.accounts.map { row in
            AccountRow(
                surfaceId: row.surfaceId,
                accountKey: row.accountKey,
                accountLabel: row.accountLabel,
                planLabel: row.planLabel,
                selected: row.selected,
                remainingPercent: row.remainingPercent,
                statusWord: row.statusWord,
                // Account DTO has no severity yet — band from Rust remaining %.
                severity: row.remainingPercent.map { remainingPercentMeterSeverity($0) } ?? "normal"
            )
        }
        // Rust owns detection, ordering, and every string — project verbatim.
        providerGlanceRows = projection.glanceRows.map(Self.mapGlanceDto)
        statusBarGlanceRows = projection.statusBarGlanceRows.map(Self.mapGlanceDto)
        reconcileSelections()
        lastError = projection.discoveryDiagnostics
            .first(where: { $0.surfaceId == nil })?
            .displayLabel
        await applyStatusItemText()
    }

    private static func mapGlanceDto(_ row: ProviderGlanceRowDto) -> GlanceProviderRow {
        GlanceProviderRow(
            surfaceId: row.surfaceId,
            iconKey: row.iconKey,
            displayLabel: row.displayLabel,
            accountLabel: row.accountLabel,
            planLabel: row.planLabel,
            glanceRemainingPercent: row.glanceRemainingPercent,
            barLabel: row.barLabel,
            headline: row.headline,
            resetLabel: row.resetLabel,
            exactReset: row.exactReset,
            statusWord: row.statusWord,
            isRefreshing: row.isRefreshing,
            statusLabel: row.statusLabel,
            severity: row.severity,
            updatedLabel: row.updatedLabel,
            lastError: row.lastError,
            dimmed: row.dimmed
        )
    }

    /// Open the Usage window on Overview or a specific surface.
    public func selectUsageSurface(_ surfaceId: String?) {
        guard let surfaceId else {
            usageSelection = nil
            return
        }
        usageSelection = isNavigableSurface(surfaceId) ? surfaceId : nil
    }

    private func reconcileSelections() {
        if let usageSelection, !isNavigableSurface(usageSelection) {
            self.usageSelection = nil
        }
        if let popoverSelection,
            !providerGlanceRows.contains(where: { $0.surfaceId == popoverSelection })
        {
            self.popoverSelection = providerGlanceRows.first?.surfaceId
        }
    }

    private func isNavigableSurface(_ surfaceId: String) -> Bool {
        providerGlanceRows.contains(where: { $0.surfaceId == surfaceId })
            && surfaces.contains(where: { $0.id == surfaceId && $0.enabled })
    }

    private func applyStatusItemText() async {
        guard !fixtureMode else { return }
        let selection = statusItemTextSelection(
            mode: displayMode,
            pinnedSurfaceId: pinnedSurfaceId.isEmpty ? nil : pinnedSurfaceId,
            stripMax: stripMax,
            hideForScreenShare: hideWhileScreenSharing && screenShareActive
        )
        guard isOpen else {
            statusItemText = ""
            statusItemChips = []
            return
        }
        do {
            switch selection {
            case .empty:
                statusItemText = ""
                statusItemChips = []
            case .focus:
                // Single worst provider preview (still a per-provider chip).
                statusItemText = try await scheduler.run { try $0.compactStatusBarLabel() }
                statusItemChips = chipsForProviderPreview(maxCount: 1, preferWorstFirst: true)
            case .pinned(let surfaceId):
                if let cached = compactLabelBySurface[surfaceId] {
                    statusItemText = cached
                } else {
                    statusItemText =
                        (try await scheduler.run {
                            try $0.compactStatusBarLabelFor(surfaceId: surfaceId)
                        }) ?? ""
                }
                statusItemChips = chipsForPinned(surfaceId: surfaceId)
            case .strip(let max):
                // CodexBar-style: one chip per provider (catalog order).
                statusItemText = try await scheduler.run { try $0.compactStatusBarStrip(max: max) }
                statusItemChips = chipsForProviderPreview(
                    maxCount: Int(max),
                    preferWorstFirst: false
                )
            }
        } catch {
            lastError = String(describing: error)
            statusItemText = ""
            statusItemChips = []
        }
    }

    private func chipsForPinned(surfaceId: String) -> [StatusItemChip] {
        let label = compactLabelBySurface[surfaceId] ?? ""
        guard !label.isEmpty else {
            return []
        }
        guard let row = surfaces.first(where: { $0.id == surfaceId && $0.enabled }) else {
            return [
                StatusItemChip(
                    surfaceId: surfaceId,
                    glyph: statusItemGlyph(compactLabel: label, surfaceId: surfaceId),
                    systemImage: statusItemSystemImage(surfaceId: surfaceId),
                    percentLines: [],
                    compactLabel: label,
                    remainingPercent: nil,
                    remainingPerLine: [],
                    severity: "ok"
                )
            ]
        }
        return [makeChip(row: row, compactLabel: label)]
    }

    /// One status-item chip per enabled provider (OpenUsage strip: icon + remaining %).
    ///
    /// Strip mode includes all enabled hosts (cap `maxCount`); focus mode only those
    /// with numeric remaining / preview data, worst-first. Uses the per-surface
    /// compact labels captured during the last projection — no bridge round-trip.
    private func chipsForProviderPreview(
        maxCount: Int, preferWorstFirst: Bool
    )
        -> [StatusItemChip]
    {
        let snaps = surfaceSnapshotsForStatusItem()
        return buildStatusItemChips(
            surfaces: snaps,
            maxCount: maxCount,
            preferWorstFirst: preferWorstFirst,
            percentStyle: percentStyle,
            // Catalog strip: show every enabled provider icon; focus: data only.
            includeAllEnabled: !preferWorstFirst
        )
    }

    private func surfaceSnapshotsForStatusItem() -> [StatusItemSurfaceSnapshot] {
        var snaps: [StatusItemSurfaceSnapshot] = []
        for row in surfaces {
            let compact = compactLabelBySurface[row.id] ?? ""
            let pairs: [(UInt8, String)] = row.buckets.compactMap { bucket in
                guard let rem = bucket.remainingPercent else { return nil }
                return (rem, bucket.severity)
            }
            snaps.append(
                StatusItemSurfaceSnapshot(
                    surfaceId: row.id,
                    label: row.label,
                    enabled: row.enabled,
                    statusBarLabel: row.statusBarLabel,
                    status: row.status,
                    compactLabel: compact,
                    remainings: pairs.map(\.0),
                    severities: pairs.map(\.1)
                )
            )
        }
        return snaps
    }

    private func makeChip(row: SurfaceRow, compactLabel: String) -> StatusItemChip {
        let pairs: [(UInt8, String)] = row.buckets.compactMap { bucket in
            guard let rem = bucket.remainingPercent else { return nil }
            return (rem, bucket.severity)
        }
        let snap = StatusItemSurfaceSnapshot(
            surfaceId: row.id,
            label: row.label,
            enabled: row.enabled,
            statusBarLabel: row.statusBarLabel,
            status: row.status,
            compactLabel: compactLabel,
            remainings: pairs.map(\.0),
            severities: pairs.map(\.1)
        )
        return buildStatusItemChips(
            surfaces: [snap],
            maxCount: 1,
            preferWorstFirst: false,
            percentStyle: percentStyle
        ).first
            ?? StatusItemChip(
                surfaceId: row.id,
                glyph: statusItemGlyph(compactLabel: compactLabel, surfaceId: row.id),
                systemImage: statusItemSystemImage(surfaceId: row.id),
                percentLines: [],
                compactLabel: compactLabel,
                remainingPercent: nil,
                remainingPerLine: [],
                severity: "ok"
            )
    }
}

/// One surface's raw bridge projection: descriptor, snapshot (nil when
/// disabled/unavailable), and its compact status-bar label — all captured in a
/// single serialized off-main bridge batch.
private struct SurfaceProjection: Sendable {
    let info: SurfaceDescriptorDto
    let view: UsageViewDto?
    let compactLabel: String
}

/// The full set of raw bridge outputs `applySnapshots` needs, collected in one
/// serialized off-main batch so the `@MainActor` mapping does zero bridge work.
private struct BridgeProjection: Sendable {
    let mergedBarLabel: String
    let compactBarLabel: String
    let nextRefreshLabel: String
    let surfaces: [SurfaceProjection]
    let overviewRows: [OverviewRowDto]
    let discoveryDiagnostics: [DiscoveryDiagnosticDto]
    let accounts: [AccountDescriptorDto]
    let glanceRows: [ProviderGlanceRowDto]
    let statusBarGlanceRows: [ProviderGlanceRowDto]
}
