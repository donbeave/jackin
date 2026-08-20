import SwiftUI

// View layer mirrors the incumbent implementation
// (native/Sources/JackinDesktop/UsageWindow/*) over fixture view models and
// lifts verbatim into the real app.

struct SidebarView: View {
    let store: ProtoStore
    /// Multi-account providers render expanded by default; collapse is pure
    /// chrome state, so it lives in the view, not the store.
    @State private var expandedProviders: Set<String> = []

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
            List {
                sidebarButton(target: .overview) {
                    Label("Overview", systemImage: "rectangle.grid.2x2")
                }
                    .accessibilityIdentifier("usage.sidebar.overview")

                Section {
                    ForEach(store.projection.providers) { provider in
                        if provider.accounts.count > 1 {
                            DisclosureGroup(isExpanded: expansion(for: provider.key)) {
                                ForEach(provider.accounts) { account in
                                    sidebarButton(
                                        target: .account(
                                            provider: provider.key, account: account.key)
                                    ) {
                                        accountRow(account, provider: provider)
                                    }
                                        .accessibilityIdentifier(
                                            "usage.sidebar.account.\(provider.key).\(account.key)")
                                }
                            } label: {
                                sidebarButton(target: .provider(provider.key)) {
                                    providerRow(provider)
                                }
                                    .accessibilityIdentifier(
                                        "usage.sidebar.provider.\(provider.key)")
                            }
                        } else {
                            sidebarButton(target: .provider(provider.key)) {
                                providerRow(provider)
                            }
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

            Divider()
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

    private func sidebarButton<Content: View>(
        target: SidebarSelection,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let selected = store.sidebar == target
        return Button {
            store.navigate(to: target)
        } label: {
            content()
                .foregroundStyle(selected ? JackinBrand.selectionText : Color.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? JackinBrand.selectionWell : Color.clear)
                )
                .overlay(alignment: .leading) {
                    if selected {
                        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                            .fill(JackinBrand.phosphor)
                            .frame(width: 3)
                            .padding(.vertical, 5)
                    }
                }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 1, leading: 6, bottom: 1, trailing: 6))
    }

    @ViewBuilder
    private func providerRow(_ provider: ProtoProvider) -> some View {
        Label {
            HStack {
                Text(provider.name)
                Spacer()
                if let percent = provider.summaryPercent {
                    Text("\(percent)%")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(
                            store.sidebar == .provider(provider.key)
                                ? JackinBrand.selectionText
                                : sidebarMetricTint(provider.state))
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
                    .foregroundStyle(
                        store.sidebar
                            == .account(provider: provider.key, account: account.key)
                            ? JackinBrand.selectionText
                            : sidebarMetricTint(account.state))
            }
        }
    }

    private func sidebarMetricTint(_ state: ProtoState) -> Color {
        switch state {
        case .warning: JackinBrand.warning
        case .danger, .depleted: JackinBrand.danger
        default: JackinBrand.muted
        }
    }

    @ViewBuilder
    private func providerMark(_ provider: ProtoProvider) -> some View {
        if let mark = ProviderMarks.swiftUIImage(forIconKey: provider.iconKey) {
            mark
                .resizable()
                .scaledToFit()
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JackinBrand.stage)
            .accessibilityIdentifier("usage.global-error")
        } else if store.projection.isLoading {
            ProgressView("Loading usage")
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(JackinBrand.stage)
                .accessibilityIdentifier("usage.loading")
        } else if store.projection.providers.isEmpty {
            ContentUnavailableView {
                Label("No providers detected", systemImage: "chevron.right")
            } description: {
                Text("Add a provider in Settings to start tracking quota limits.")
            } actions: {
                Button("Open Settings…") { onOpenSettings() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(JackinBrand.stage)
            .accessibilityIdentifier("usage.overview.empty")
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 320), spacing: 18)],
                    spacing: 18
                ) {
                    ForEach(store.projection.providers) { provider in
                        ProviderCardView(store: store, provider: provider)
                    }
                }
                .padding(28)
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
                        .foregroundStyle(JackinBrand.muted)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: JackinSpace.xs) {
                        if let ago = provider.updatedAgo {
                            Text(ago)
                                .font(.caption)
                                .foregroundStyle(JackinBrand.quiet)
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
        .padding(JackinSpace.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ProviderCardSurface())
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
                .foregroundStyle(JackinBrand.muted)
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
                            .foregroundStyle(JackinBrand.muted)
                    }
                    Spacer(minLength: 8)
                    if let remaining = account.remaining {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(remaining)")
                                .font(JackinType.heroMetric)
                                .monospacedDigit()
                            Text("% left")
                                .font(JackinType.metadata)
                                .foregroundStyle(JackinBrand.muted)
                        }
                        .foregroundStyle(metricTint(account.state))
                    } else {
                        Text("—")
                            .font(.title2)
                            .foregroundStyle(JackinBrand.quiet)
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
                .foregroundStyle(JackinBrand.muted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(OverviewAccountButtonStyle())
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

    private func metricTint(_ state: ProtoState) -> Color {
        switch state {
        case .warning: JackinBrand.warning
        case .danger, .depleted: JackinBrand.danger
        default: .primary
        }
    }
}

private struct OverviewAccountButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        OverviewAccountButtonBody(configuration: configuration)
    }

    private struct OverviewAccountButtonBody: View {
        let configuration: Configuration
        @State private var isHovered = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let isActive = isHovered || configuration.isPressed
            configuration.label
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            isActive ? JackinBrand.hover : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            isHovered ? JackinBrand.separator : Color.clear,
                            lineWidth: 1)
                )
                .opacity(configuration.isPressed ? 0.82 : 1)
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .onHover { isHovered = $0 }
                .animation(
                    reduceMotion ? nil : .easeOut(duration: 0.12),
                    value: isActive)
        }
    }
}

/// Authored content boundary for the preferred overview cards.
///
/// This is standard opaque content material, never glass. Its compact technical
/// radius and crisp edge separate providers without ornamental depth.
private struct ProviderCardSurface: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(JackinBrand.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        contrast == .increased
                            ? JackinBrand.strongSeparator : JackinBrand.separator,
                        lineWidth: contrast == .increased ? 1.5 : 1)
            )
    }
}

/// Calibrated quota meter: a low-radius 6pt track, state-tinted fill.
///
/// Content-layer drawing, not chrome — a plain deterministic bar.
struct QuotaMeter: View {
    let percent: Int
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(JackinBrand.meterTrack)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(tint)
                    .frame(
                        width: proxy.size.width
                            * CGFloat(min(max(percent, 0), 100)) / 100)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

struct ProviderDetailView: View {
    let store: ProtoStore
    let provider: ProtoProvider

    var body: some View {
        ScrollView {
            ProviderDetailSections(
                store: store, provider: provider, identifierPrefix: "usage")
                .frame(maxWidth: 760)
                .padding(.horizontal, 28)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
        }
        .background(JackinBrand.stage)
        .accessibilityLabel("\(provider.name) usage details")
        .accessibilityIdentifier("usage.provider.\(provider.key)")
    }
}

/// Shared content projection for the Usage detail and transient popover.
///
/// Each host supplies its system-owned List/Form material; this view owns the
/// content once so labels, ordering, states, and actions cannot drift.
struct ProviderDetailSections: View {
    let store: ProtoStore
    let provider: ProtoProvider
    let identifierPrefix: String
    var compact = false

    var body: some View {
        let account = store.account(for: provider)

        VStack(alignment: .leading, spacing: compact ? 16 : 28) {
            if compact {
                compactProviderIdentity(account)
                compactLimits(account)
            } else {
                providerIdentity(account)
                if let account { currentPressure(account) }
                fullLimits(account)
            }

            if !compact {
                TechnicalPanel(title: "Account", detail: "Credential source") {
                    if let username = account?.username {
                        DetailFactItem(
                            icon: "person.text.rectangle", label: "Username", value: username)
                        Divider()
                    }
                    if let plan = account?.plan {
                        DetailFactItem(
                            icon: "checkmark.seal", label: "Plan", value: plan)
                        if account?.auth != nil { Divider() }
                    }
                    if let auth = account?.auth {
                        DetailFactItem(
                            icon: "key", label: "Authentication", value: auth)
                    }
                }
            }

            if let error = provider.errorText {
                TechnicalPanel(title: "Provider status", detail: "Attention required") {
                    VStack(alignment: .leading, spacing: JackinSpace.sm) {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(JackinBrand.warning)
                            .accessibilityIdentifier("\(identifierPrefix).provider-error")
                        if let ago = provider.updatedAgo {
                            Text(ago)
                                .font(JackinType.metadata)
                                .foregroundStyle(JackinBrand.muted)
                        }
                        Button(store.chrome.retryTitle) { store.refresh() }
                            .disabled(store.refreshInProgress)
                            .accessibilityIdentifier("\(identifierPrefix).provider-retry")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func fullLimits(_ account: ProtoAccount?) -> some View {
        VStack(alignment: .leading, spacing: JackinSpace.sm) {
            technicalSectionHeader("Limits", detail: "\(account?.windows.count ?? 0) limits")
            if let account, !account.windows.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 260), spacing: JackinSpace.sm)],
                    spacing: JackinSpace.sm
                ) {
                    ForEach(account.windows) { window in
                        LimitModule(
                            window: window,
                            identifierPrefix: "\(identifierPrefix).limit")
                    }
                }
            } else if provider.errorText == nil {
                Text("No limit details available")
                    .foregroundStyle(JackinBrand.muted)
            }
        }
    }

    @ViewBuilder
    private func compactLimits(_ account: ProtoAccount?) -> some View {
        if let account, !account.windows.isEmpty {
            let ranked = rankedWindows(account.windows)
            VStack(alignment: .leading, spacing: JackinSpace.sm) {
                technicalSectionHeader("Limits", detail: "\(account.windows.count) limits")
                LimitModule(
                    window: ranked[0],
                    identifierPrefix: "\(identifierPrefix).limit")
                ForEach(ranked.dropFirst().prefix(2)) { window in
                    CompactLimitRow(
                        window: window,
                        identifierPrefix: "\(identifierPrefix).limit")
                }
                if account.windows.count > 3 {
                    Text("+\(account.windows.count - 3) more limits in Usage")
                        .font(JackinType.metadata)
                        .foregroundStyle(JackinBrand.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, JackinSpace.xxs)
                }
            }
        } else if provider.errorText == nil {
            Text("No limit details available")
                .foregroundStyle(JackinBrand.muted)
        }
    }

    private func rankedWindows(_ windows: [ProtoQuotaWindow]) -> [ProtoQuotaWindow] {
        windows.enumerated().sorted { left, right in
            let leftRank = severityRank(left.element.state)
            let rightRank = severityRank(right.element.state)
            if leftRank != rightRank { return leftRank > rightRank }
            let leftMeter = left.element.meter ?? 101
            let rightMeter = right.element.meter ?? 101
            if leftMeter != rightMeter { return leftMeter < rightMeter }
            return left.offset < right.offset
        }.map(\.element)
    }

    private func severityRank(_ state: ProtoState) -> Int {
        switch state {
        case .depleted: 5
        case .danger: 4
        case .warning, .rateLimited: 3
        case .stale, .unavailable, .needsLogin, .needsSecret: 2
        default: 1
        }
    }

    private func technicalSectionHeader(_ title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(JackinType.sectionTitle)
                .tracking(0.45)
            Spacer()
            Text(detail)
                .font(JackinType.tertiary)
                .foregroundStyle(JackinBrand.quiet)
        }
    }

    private func providerIdentity(_ account: ProtoAccount?) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: JackinSpace.md) {
                providerIdentityMark
                providerIdentityCopy(account)
                Spacer(minLength: JackinSpace.md)
                providerActivity
            }
            .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: JackinSpace.sm) {
                HStack(alignment: .top, spacing: JackinSpace.md) {
                    providerIdentityMark
                    providerIdentityCopy(account)
                }
                providerActivity
                    .padding(.leading, 60)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(provider.name), \(account?.label ?? ""), \(provider.activityLabel)"
        )
        .accessibilityIdentifier("\(identifierPrefix).provider-identity")
    }

    private var providerIdentityMark: some View {
        BrandMarkChip(
            iconKey: provider.iconKey, fallbackGlyph: provider.fallbackGlyph,
            markSize: 28, chipSize: 44)
    }

    private func providerIdentityCopy(_ account: ProtoAccount?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("PROVIDER")
                .font(JackinType.technicalLabel)
                .tracking(0.45)
                .foregroundStyle(JackinBrand.quiet)
            Text(provider.name)
                .font(.title2.weight(.semibold))
            if let account {
                Text([account.label, account.plan].joined(separator: "  ·  "))
                    .font(.callout)
                    .foregroundStyle(JackinBrand.muted)
                    .accessibilityIdentifier("\(identifierPrefix).provider-account")
            }
        }
    }

    @ViewBuilder
    private var providerActivity: some View {
        if provider.isRefreshing || store.refreshInProgress {
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel(provider.activityLabel)
        } else {
            Label(provider.activityLabel, systemImage: provider.state.symbol)
                .font(JackinType.metadata)
                .foregroundStyle(JackinBrand.muted)
                .labelStyle(.titleAndIcon)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("\(identifierPrefix).provider-activity")
        }
    }

    private func compactProviderIdentity(_ account: ProtoAccount?) -> some View {
        VStack(alignment: .leading, spacing: JackinSpace.sm) {
            HStack(spacing: JackinSpace.sm) {
                BrandMarkChip(
                    iconKey: provider.iconKey, fallbackGlyph: provider.fallbackGlyph,
                    markSize: 24, chipSize: 40)
                VStack(alignment: .leading, spacing: JackinSpace.xxs) {
                    Text(provider.name)
                        .font(.headline)
                    if let account {
                        Text(account.label)
                            .font(.callout)
                            .foregroundStyle(JackinBrand.muted)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            Label(provider.activityLabel, systemImage: provider.state.symbol)
                .font(JackinType.metadata)
                .foregroundStyle(JackinBrand.muted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(provider.name), \(account?.label ?? ""), \(provider.activityLabel)")
    }

    private func currentPressure(_ account: ProtoAccount) -> some View {
        HStack(spacing: 0) {
            pressureFact(
                "CURRENT PRESSURE",
                account.remaining.map { "\($0)% left" } ?? "Unavailable",
                tint: pressureTint(account.state))
            Divider().frame(height: 38)
            pressureFact("NEXT RESET", account.resetText ?? "Unavailable")
            Divider().frame(height: 38)
            pressureFact("STATE", account.state.label ?? "Available")
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(JackinBrand.inset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(JackinBrand.separator, lineWidth: 1)
        )
    }

    private func pressureFact(_ label: String, _ value: String, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(JackinType.technicalLabel)
                .tracking(0.45)
                .foregroundStyle(JackinBrand.quiet)
            Text(value)
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pressureTint(_ state: ProtoState) -> Color {
        switch state {
        case .warning: JackinBrand.warning
        case .danger, .depleted: JackinBrand.danger
        default: .primary
        }
    }

}

/// Raised technical dossier panel. The native window/popover remains the
/// structural glass host; authored quota content stays opaque and precise.
private struct TechnicalPanel<Content: View>: View {
    let title: String
    let detail: String
    @ViewBuilder let content: Content

    init(
        title: String, detail: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(title.uppercased())
                    .font(JackinType.sectionTitle)
                    .tracking(0.45)
                    .foregroundStyle(.primary)
                Spacer()
                Text(detail)
                    .font(JackinType.tertiary)
                    .foregroundStyle(JackinBrand.quiet)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(JackinBrand.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(JackinBrand.separator, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct LimitModule: View {
    let window: ProtoQuotaWindow
    let identifierPrefix: String

    var body: some View {
        LimitRowView(window: window, identifierPrefix: identifierPrefix)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(JackinBrand.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(JackinBrand.separator, lineWidth: 1)
            )
    }
}

private struct CompactLimitRow: View {
    let window: ProtoQuotaWindow
    let identifierPrefix: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: JackinSpace.xs) {
                Text(window.label)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Text(window.primaryValue)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
            }
            if let reset = window.resetLabel {
                Text(reset)
                    .font(JackinType.metadata)
                    .monospacedDigit()
                    .foregroundStyle(JackinBrand.muted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(JackinBrand.inset)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(window.accessibilitySummary)
        .accessibilityIdentifier("\(identifierPrefix).\(window.stableID)")
    }
}

/// One limit-window row — shared by the Usage-window detail and the popover
/// so both surfaces render the same Rust-owned fields identically (DRY).
struct LimitRowView: View {
    let window: ProtoQuotaWindow
    /// Accessibility identifier prefix (`usage.limit` / `popover.limit`).
    var identifierPrefix = "usage.limit"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: JackinSpace.sm) {
                Text(window.label.uppercased())
                    .font(JackinType.technicalLabel)
                    .tracking(0.45)
                    .foregroundStyle(JackinBrand.quiet)
                Spacer()
                if let reset = window.resetLabel {
                    Text(reset)
                        .font(JackinType.metadata)
                        .monospacedDigit()
                        .foregroundStyle(JackinBrand.muted)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: JackinSpace.sm) {
                Text(window.primaryValue)
                    .font(JackinType.detailMetric)
                    .monospacedDigit()
                    .foregroundStyle(window.notStarted ? .secondary : .primary)
                Spacer()
                if let secondary = window.secondaryValue {
                    Text(secondary)
                        .font(JackinType.metadata)
                        .monospacedDigit()
                        .foregroundStyle(JackinBrand.muted)
                }
            }
            if let meter = window.meter {
                QuotaMeter(percent: meter, tint: meterTint(window.state))
                    .accessibilityHidden(true)
            }
            HStack(alignment: .firstTextBaseline, spacing: JackinSpace.sm) {
                if let supplemental = window.supplementalValue {
                    Text(supplemental)
                }
                Spacer(minLength: 0)
                if let pace = window.pace {
                    Text(pace)
                }
            }
            .font(JackinType.metadata)
                .foregroundStyle(JackinBrand.quiet)
        }
        .padding(.vertical, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityRepresentation {
            Text(window.display)
                .accessibilityLabel(window.accessibilitySummary)
                .accessibilityIdentifier("\(identifierPrefix).\(window.stableID)")
        }
    }
}

/// A readable account fact, deliberately stacked instead of compressed into a
/// small two-column table. Long provider values receive the full content width.
private struct DetailFactItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: JackinSpace.sm) {
            Image(systemName: icon)
                .foregroundStyle(JackinBrand.muted)
                .frame(width: 18)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: JackinSpace.xxs) {
                Text(label.uppercased())
                    .font(JackinType.technicalLabel)
                    .tracking(0.45)
                    .foregroundStyle(JackinBrand.quiet)
                Text(value)
                    .foregroundStyle(.primary)
                    .textSelection(.enabled)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
        .padding(.vertical, 12)
    }
}

struct DetailRootView: View {
    let store: ProtoStore
    let onOpenSettings: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topLeading) {
            JackinBrand.stage
                .ignoresSafeArea()
            Group {
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
            .id(transitionKey)
            .transition(
                reduceMotion
                    ? .identity
                    : .asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 5)),
                        removal: .opacity))
        }
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.15),
            value: transitionKey)
    }

    private var transitionKey: String {
        switch store.resolvedSidebar {
        case .overview: "overview"
        case .provider(let key): "provider:\(key)"
        case .account(let provider, _): "provider:\(provider)"
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.14),
                value: store.refreshInProgress)
        }
        .buttonStyle(.glass)
        .tint(JackinBrand.muted)
        .help(store.chrome.refreshTitle)
        .disabled(store.refreshInProgress)
        .accessibilityLabel(store.chrome.refreshTitle)
        .accessibilityValue(store.refreshInProgress ? "In progress" : "")
        .accessibilityIdentifier("usage.refresh")
    }
}
