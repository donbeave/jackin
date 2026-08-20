import SwiftUI

// View layer mirrors the incumbent implementation
// (native/Sources/JackinDesktop/UsageWindow/*) over fixture view models and
// lifts verbatim into the real app.

struct SidebarView: View {
    let store: ProtoStore
    /// Multi-account providers render expanded by default; collapse is pure
    /// chrome state, so it lives in the view, not the store.
    @State private var expandedProviders: Set<String> = []

    private var selection: Binding<SidebarSelection?> {
        Binding(
            get: { store.sidebar },
            set: { store.navigate(to: $0 ?? .overview) })
    }

    private func expansion(for providerKey: String) -> Binding<Bool> {
        Binding(
            get: { expandedProviders.contains(providerKey) },
            set: { expanded in
                if expanded {
                    expandedProviders.insert(providerKey)
                } else {
                    expandedProviders.remove(providerKey)
                }
            })
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: selection) {
                Label("Overview", systemImage: "rectangle.grid.2x2")
                    .tag(SidebarSelection.overview)
                    .accessibilityIdentifier("usage.sidebar.overview")

                Section {
                    ForEach(store.projection.providers) { provider in
                        if provider.accounts.count > 1 {
                            DisclosureGroup(isExpanded: expansion(for: provider.key)) {
                                ForEach(provider.accounts) { account in
                                    accountRow(account, provider: provider)
                                        .tag(
                                            SidebarSelection.account(
                                                provider: provider.key, account: account.key)
                                        )
                                        .accessibilityIdentifier(
                                            "usage.sidebar.account.\(provider.key).\(account.key)")
                                }
                            } label: {
                                providerRow(provider)
                                    .tag(SidebarSelection.provider(provider.key))
                                    .accessibilityIdentifier(
                                        "usage.sidebar.provider.\(provider.key)")
                            }
                        } else {
                            providerRow(provider)
                                .tag(SidebarSelection.provider(provider.key))
                                .accessibilityIdentifier("usage.sidebar.provider.\(provider.key)")
                        }
                    }
                } header: {
                    Text("Providers")
                        .accessibilityLabel("Providers")
                }
            }
            .listStyle(.sidebar)
            .accessibilityLabel("Usage providers sidebar")
            .accessibilityIdentifier("usage.sidebar")
            .onAppear { expandAllMultiAccountProviders() }
            .onChange(of: store.projection.scenario) { expandAllMultiAccountProviders() }

            JackinBrandSignature()
                .padding(.horizontal, JackinSpace.md)
                .padding(.vertical, JackinSpace.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 190, idealWidth: 220, maxWidth: 280)
    }

    private func expandAllMultiAccountProviders() {
        expandedProviders = Set(
            store.projection.providers.filter { $0.accounts.count > 1 }.map(\.key))
    }

    @ViewBuilder
    private func providerRow(_ provider: ProtoProvider) -> some View {
        Label {
            HStack {
                Text(provider.name)
                    .foregroundStyle(.primary)
                Spacer()
                if let percent = provider.summaryPercent {
                    Text("\(percent)%")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            providerMark(provider)
        }
    }

    private func accountRow(_ account: ProtoAccount, provider: ProtoProvider) -> some View {
        HStack(spacing: JackinSpace.xs) {
            Circle()
                .fill(meterTint(account.state))
                .frame(width: 6, height: 6)
                .accessibilityHidden(true)
            Text(account.label)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            if let remaining = account.remaining {
                Text("\(remaining)%")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(meterTint(account.state))
            }
        }
    }

    @ViewBuilder
    private func providerMark(_ provider: ProtoProvider) -> some View {
        if let mark = ProviderMarks.swiftUIImage(forIconKey: provider.iconKey) {
            mark
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
        } else {
            Text(provider.fallbackGlyph)
                .font(.caption2)
        }
    }
}

struct OverviewContentView: View {
    let store: ProtoStore
    let onOpenSettings: () -> Void

    var body: some View {
        if let error = store.projection.globalError {
            ContentUnavailableView {
                Label("Usage unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button(store.chrome.retryTitle) { store.refresh() }
                    .disabled(store.refreshInProgress)
                    .accessibilityIdentifier("usage.retry")
            }
            .accessibilityIdentifier("usage.global-error")
        } else if store.projection.isLoading {
            ProgressView("Loading usage")
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("usage.loading")
        } else if store.projection.providers.isEmpty {
            ContentUnavailableView {
                Label("No providers detected", systemImage: "chevron.right")
            } description: {
                Text("Add a provider in Settings to start tracking quota limits.")
            } actions: {
                Button("Open Settings…") { onOpenSettings() }
            }
            .accessibilityIdentifier("usage.overview.empty")
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 300), spacing: JackinSpace.lg)],
                    spacing: JackinSpace.lg
                ) {
                    ForEach(store.projection.providers) { provider in
                        ProviderCardView(store: store, provider: provider)
                    }
                }
                .padding(JackinSpace.xl)
            }
            // Grouped-content stage: the gray under-page ground is what the
            // card white contrasts against, in both appearances.
            .background(JackinBrand.stage)
            .accessibilityLabel("Usage overview")
            .accessibilityIdentifier("usage.overview.grid")
        }
    }
}

/// One provider card in the Overview grid.
///
/// Content layer: standard material,
/// no glass. Every canonical account renders as its own block — the overview
/// never collapses multi-account providers to one row. A tap focuses the
/// account in the sidebar detail.
///
/// Visual hierarchy per account block: the remaining percent is the hero
/// (largest type, state-tinted), the identity line is secondary, the meter
/// is a hairline with a visible track, and metadata is a single quiet
/// caption row. Healthy states render no badge — silence means fine.
struct ProviderCardView: View {
    let store: ProtoStore
    let provider: ProtoProvider

    var body: some View {
        VStack(alignment: .leading, spacing: JackinSpace.sm) {
            HStack(spacing: JackinSpace.xs) {
                BrandMarkChip(iconKey: provider.iconKey, fallbackGlyph: provider.fallbackGlyph)
                Text(provider.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let stateLabel = provider.state.label {
                    Label(stateLabel, systemImage: provider.state.symbol)
                        .font(.caption)
                        .foregroundStyle(badgeTint(provider.state))
                        .labelStyle(.titleAndIcon)
                        .accessibilityHidden(true)
                }
            }

            if provider.accounts.isEmpty {
                emptyAccountsBlock
            } else {
                ForEach(Array(provider.accounts.enumerated()), id: \.element.id) {
                    index, account in
                    if index > 0 {
                        Divider()
                            .padding(.vertical, 2)
                    }
                    accountBlock(account)
                }
            }

            if let error = provider.errorText {
                VStack(alignment: .leading, spacing: JackinSpace.xs) {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: JackinSpace.xs) {
                        if let ago = provider.updatedAgo {
                            Text(ago)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button(store.chrome.retryTitle) { store.refresh() }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                            .disabled(store.refreshInProgress)
                            .accessibilityIdentifier("usage.overview.retry.\(provider.key)")
                    }
                }
                .accessibilityIdentifier("usage.overview.error.\(provider.key)")
            }
        }
        .padding(JackinSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(JackinBrand.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(JackinBrand.separator, lineWidth: 0.5)
        )
        // Grid rows size to the tallest card; short cards pin to the top of
        // their cell instead of floating centered.
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("usage.overview.provider.\(provider.key)")
    }

    @ViewBuilder
    private var emptyAccountsBlock: some View {
        if provider.errorText != nil {
            EmptyView()
        } else {
            Text("No accounts discovered")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private func accountBlock(_ account: ProtoAccount) -> some View {
        Button {
            store.navigate(to: .account(provider: provider.key, account: account.key))
        } label: {
            VStack(alignment: .leading, spacing: JackinSpace.xs) {
                HStack(alignment: .firstTextBaseline) {
                    if provider.accounts.count > 1 {
                        Text(account.label)
                            .font(.callout)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text(account.plan)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if let remaining = account.remaining {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(remaining)")
                                .font(JackinType.heroMetric)
                                .monospacedDigit()
                            Text("% left")
                                .font(JackinType.metadata)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(meterTint(account.state))
                    } else {
                        Text("—")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                    }
                }

                if let remaining = account.remaining {
                    QuotaMeter(percent: remaining, tint: meterTint(account.state))
                        .accessibilityHidden(true)
                }

                HStack(spacing: JackinSpace.xs) {
                    if provider.accounts.count > 1 {
                        Text(account.plan)
                    }
                    if let stateLabel = account.state.label {
                        Label(stateLabel, systemImage: account.state.symbol)
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(badgeTint(account.state))
                    }
                    Spacer()
                    if let reset = account.resetText {
                        Text(reset)
                    }
                }
                .font(JackinType.metadata)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(provider.name), \(account.label), \(account.remaining.map { "\($0) percent left" } ?? "remaining unavailable")"
        )
        .accessibilityIdentifier("usage.overview.account.\(provider.key).\(account.key)")
    }

    private func badgeTint(_ state: ProtoState) -> Color {
        switch state {
        case .warning: JackinBrand.warning
        case .danger, .depleted: JackinBrand.danger
        case .stale, .rateLimited: JackinBrand.warning
        case .needsLogin, .needsSecret, .unsupported, .unavailable: .secondary
        default: .secondary
        }
    }
}

/// Hairline quota meter: 4pt capsule, visible track, state-tinted fill.
///
/// Content-layer drawing, not chrome — a plain deterministic bar.
struct QuotaMeter: View {
    let percent: Int
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(JackinBrand.meterTrack)
                Capsule()
                    .fill(tint)
                    .frame(
                        width: proxy.size.width
                            * CGFloat(min(max(percent, 0), 100)) / 100)
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

struct ProviderDetailView: View {
    let store: ProtoStore
    let provider: ProtoProvider

    var body: some View {
        let account = store.account(for: provider)
        List {
            Section {
                HStack(spacing: JackinSpace.sm) {
                    BrandMarkChip(
                        iconKey: provider.iconKey, fallbackGlyph: provider.fallbackGlyph,
                        markSize: 26, chipSize: 40)
                    VStack(alignment: .leading, spacing: JackinSpace.xxs) {
                        Text(provider.name)
                            .font(.title2)
                        if let account {
                            Text(account.label)
                                .foregroundStyle(.primary)
                                .accessibilityIdentifier("usage.provider-account")
                        }
                        Text(provider.activityLabel)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("usage.provider-activity")
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(provider.name), \(account?.label ?? ""), \(provider.activityLabel)"
                )
                .accessibilityIdentifier("usage.provider-identity")
            }

            // Account switching lives in the sidebar (per-account rows);
            // a second picker here would duplicate the control.
            Section {
                if let plan = account?.plan {
                    LabeledContent {
                        Text(plan).foregroundStyle(.primary)
                    } label: {
                        Text("Plan").foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Plan, \(plan)")
                }
                if let reset = account?.resetText ?? provider.summaryReset {
                    LabeledContent {
                        Text(reset).foregroundStyle(.primary)
                    } label: {
                        Text("Reset").foregroundStyle(.primary)
                    }
                    .accessibilityLabel("Reset, \(reset)")
                }
            } header: {
                sectionHeader("Details")
            }

            Section {
                if let account, !account.windows.isEmpty {
                    ForEach(account.windows) { window in
                        LimitRowView(window: window)
                    }
                } else if provider.errorText == nil {
                    Text("No limit details available")
                        .foregroundStyle(.secondary)
                }
            } header: {
                sectionHeader("Limits")
            }

            if let error = provider.errorText {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .accessibilityIdentifier("usage.provider-error")
                    if let ago = provider.updatedAgo {
                        Text(ago)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(store.chrome.retryTitle) { store.refresh() }
                        .disabled(store.refreshInProgress)
                        .accessibilityIdentifier("usage.provider-retry")
                } header: {
                    sectionHeader("Provider status")
                }
            }
        }
        .listStyle(.inset)
        .accessibilityLabel("\(provider.name) usage details")
        .accessibilityIdentifier("usage.provider.\(provider.key)")
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(.primary)
            .accessibilityLabel(title)
            .accessibilityIdentifier(
                "usage.section.\(title.lowercased().replacingOccurrences(of: " ", with: "-"))"
            )
    }
}

/// One limit-window row — shared by the Usage-window detail and the popover
/// so both surfaces render the same Rust-owned fields identically (DRY).
struct LimitRowView: View {
    let window: ProtoQuotaWindow
    /// Accessibility identifier prefix (`usage.limit` / `popover.limit`).
    var identifierPrefix = "usage.limit"

    var body: some View {
        VStack(alignment: .leading, spacing: JackinSpace.xs) {
            LabeledContent(window.label) {
                Text(window.display)
                    .monospacedDigit()
                    .foregroundStyle(window.notStarted ? .secondary : .primary)
            }
            if let meter = window.meter {
                QuotaMeter(percent: meter, tint: meterTint(window.state))
                    .accessibilityHidden(true)
            }
            if let pace = window.pace {
                Text(pace)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityRepresentation {
            Text(window.display)
                .accessibilityLabel("\(window.label), \(window.display)")
                .accessibilityIdentifier("\(identifierPrefix).\(window.stableID)")
        }
    }
}

struct DetailRootView: View {
    let store: ProtoStore
    let onOpenSettings: () -> Void

    var body: some View {
        switch store.resolvedSidebar {
        case .overview:
            OverviewContentView(store: store, onOpenSettings: onOpenSettings)
        case .provider(let key):
            if let provider = store.provider(key) {
                ProviderDetailView(store: store, provider: provider)
            } else {
                OverviewContentView(store: store, onOpenSettings: onOpenSettings)
            }
        case .account(let providerKey, _):
            if let provider = store.provider(providerKey) {
                ProviderDetailView(store: store, provider: provider)
            } else {
                OverviewContentView(store: store, onOpenSettings: onOpenSettings)
            }
        }
    }
}

/// Trailing Refresh in the window toolbar: spinner swaps in while the
/// broker round-trip runs.
///
/// The toolbar owns the material; `.glass` inside a
/// toolbar gets the correct hover treatment (the macOS 26 hover defect only
/// affects glass outside toolbars).
struct RefreshToolbarButton: View {
    let store: ProtoStore

    var body: some View {
        Button {
            store.refresh()
        } label: {
            ZStack {
                Image(systemName: "arrow.clockwise")
                    .opacity(store.refreshInProgress ? 0 : 1)
                ProgressView()
                    .controlSize(.small)
                    .opacity(store.refreshInProgress ? 1 : 0)
            }
            .frame(width: 16, height: 16)
        }
        .buttonStyle(.glass)
        .help(store.chrome.refreshTitle)
        .disabled(store.refreshInProgress)
        .accessibilityLabel(store.chrome.refreshTitle)
        .accessibilityValue(store.refreshInProgress ? "In progress" : "")
        .accessibilityIdentifier("usage.refresh")
    }
}
