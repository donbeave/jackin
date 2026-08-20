import SwiftUI

enum PercentStyle: String, Sendable {
    case left, used
}

enum SidebarSelection: Hashable, Sendable {
    case overview
    case provider(String)
}

/// Stands in for the Rust-owned PresentationStore: every value change here is
/// an accepted/rejected mutation round-trip, never optimistic local state.
@MainActor
@Observable
final class ProtoStore {
    let projection: ProtoProjection
    private(set) var percentStyle: PercentStyle = .left
    private(set) var refreshFloorMinutes = 5
    private(set) var floorError: String?
    var sidebar: SidebarSelection
    var accountSelection: [String: String]
    private(set) var refreshGeneration = 0
    private(set) var refreshInProgress = false
    private var acceptedFloorRevision = 0
    private var issuedFloorRevision = 40

    // Settings surface state (fixture-backed mock; no persistence).
    var displayMode: DisplayMode = .strip
    var pinnedSurfaceKey = ""
    var stripMax = 3
    var resetStyle: ResetStyle = .countdown
    var hideWhileScreenSharing = false
    var launchAtLogin = false
    var surfaceEnabled: [String: Bool]

    enum DisplayMode: String, Sendable { case strip, focusPercent, pinnedSurface, iconOnly }
    enum ResetStyle: String, Sendable { case countdown, exactClock }

    init(projection: ProtoProjection) {
        self.projection = projection
        sidebar =
            projection.selectedProviderKey.map { .provider($0) } ?? .overview
        accountSelection = Dictionary(
            uniqueKeysWithValues: projection.providers.compactMap { provider in
                provider.selectedAccountKey.map { (provider.key, $0) }
            })
        surfaceEnabled = Dictionary(
            uniqueKeysWithValues: projection.providers.map { ($0.key, true) })
        if let providerKey = projection.selectedProviderKey,
            let accountKey = projection.selectedAccountKey
        {
            accountSelection[providerKey] = accountKey
        }
    }

    var chrome: ProtoChrome { projection.chrome }

    /// A removed/disabled provider normalizes to Overview here, not in a view.
    var resolvedSidebar: SidebarSelection {
        if case .provider(let key) = sidebar,
            !projection.providers.contains(where: { $0.key == key })
        {
            return .overview
        }
        return sidebar
    }

    func provider(_ key: String) -> ProtoProvider? {
        projection.providers.first(where: { $0.key == key })
    }

    func account(for provider: ProtoProvider) -> ProtoAccount? {
        let key = accountSelection[provider.key] ?? provider.selectedAccountKey
        return provider.accounts.first(where: { $0.key == key })
            ?? provider.accounts.first
    }

    func selectAccount(_ key: String, for provider: ProtoProvider) {
        accountSelection[provider.key] = key
    }

    func summaryRemaining(_ provider: ProtoProvider) -> String? {
        switch percentStyle {
        case .left: return provider.summaryRemainingLeft
        case .used: return provider.summaryRemainingUsed
        }
    }

    func statusPercent(_ provider: ProtoProvider) -> String? {
        guard let percent = provider.summaryPercent else { return nil }
        // Bottom line is the bare percent; the top line's countdown already
        // carries the period context. The summary itself stays driven by
        // long-range windows only (see ProtoProvider.summaryWindow).
        switch percentStyle {
        case .left: return "\(percent)%"
        case .used: return "\(100 - percent)%"
        }
    }

    /// Status-item percent tint — same severity law as the window meters:
    /// danger/depleted red, warning orange, otherwise phosphor.
    func statusTint(_ provider: ProtoProvider) -> NSColor {
        switch provider.summaryWindow?.state ?? provider.state {
        case .danger, .depleted: .systemRed
        case .warning: .systemOrange
        default: JackinBrand.phosphorNSColor
        }
    }

    func setPercentStyle(_ style: PercentStyle) {
        // F15: Rust accepts and returns the next projection with used strings.
        percentStyle = style
    }

    func requestRefreshFloor(_ minutes: Int) {
        switch projection.mutationScript {
        case .rejectLowFloor where minutes < 5:
            // F16: typed recoverable rejection; accepted value never moved.
            floorError =
                "Refresh floor of \(minutes) minute(s) rejected: minimum is 5 minutes"
        case .reorderedFloor:
            // F17: later intent (15 min) completes before earlier intent
            // (10 min); an older revision can never overwrite a newer one.
            issuedFloorRevision += 1
            let revision = issuedFloorRevision
            floorError = nil
            let delay: Duration = minutes == 10 ? .milliseconds(800) : .milliseconds(400)
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: delay)
                guard let self, revision > self.acceptedFloorRevision else { return }
                self.acceptedFloorRevision = revision
                self.refreshFloorMinutes = minutes
            }
        default:
            issuedFloorRevision += 1
            acceptedFloorRevision = issuedFloorRevision
            refreshFloorMinutes = minutes
            floorError = nil
        }
    }

    /// F16: the exact failed mutation is retried verbatim beside the settings.
    func retryRefreshFloor() {
        floorError = nil
        requestRefreshFloor(1)
    }

    /// Refresh intent joins existing broker work; repeated calls never fork.
    /// The busy window is a fixed 900 ms fixture so the spinner swap is
    /// visible live without real probe latency.
    func refresh() {
        refreshGeneration += 1
        guard !refreshInProgress else { return }
        refreshInProgress = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            self?.refreshInProgress = false
        }
    }
}
