import SwiftUI

// View layer mirrors the incumbent implementation
// (native/Sources/JackinDesktop/UsageWindow/*) over fixture view models and
// lifts verbatim into the real app.

struct SidebarView: View {
    let store: ProtoStore

    private var selection: Binding<SidebarSelection?> {
        Binding(
            get: { store.sidebar },
            set: { store.sidebar = $0 ?? .overview })
    }

    var body: some View {
        VStack(spacing: 0) {
            List(selection: selection) {
                Label("Overview", systemImage: "rectangle.grid.2x2")
                    .tag(SidebarSelection.overview)
                    .accessibilityIdentifier("usage.sidebar.overview")

                Section {
                    ForEach(store.projection.providers) { provider in
                        Label {
                            Text(provider.name)
                                .foregroundStyle(.primary)
                        } icon: {
                            providerMark(provider)
                        }
                        .tag(SidebarSelection.provider(provider.key))
                        .accessibilityIdentifier("usage.sidebar.provider.\(provider.key)")
                    }
                } header: {
                    Text("Providers")
                        .accessibilityLabel("Providers")
                }
            }
            .listStyle(.sidebar)
            .accessibilityLabel("Usage providers sidebar")
            .accessibilityIdentifier("usage.sidebar")

            JackinBrandSignature()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 190, idealWidth: 220, maxWidth: 280)
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

struct OverviewRow: Identifiable {
    let id: String
    let providerKey: String
    let accountKey: String?
    let providerLabel: String
    let accountLabel: String
    let planOrStatus: String
    let remaining: String
    let reset: String
    let state: ProtoState
    let error: String?
    var children: [OverviewRow]?
}

struct OverviewContentView: View {
    let store: ProtoStore
    let onOpenSettings: () -> Void
    @State private var selection: OverviewRow.ID?
    @State private var expanded: Set<OverviewRow.ID>

    init(store: ProtoStore, onOpenSettings: @escaping () -> Void) {
        self.store = store
        self.onOpenSettings = onOpenSettings
        _expanded = State(initialValue: Set(store.projection.providers.map(\.key)))
    }

    private var rows: [OverviewRow] {
        store.projection.providers.map { provider in
            OverviewRow(
                id: provider.key,
                providerKey: provider.key,
                accountKey: nil,
                providerLabel: provider.name,
                accountLabel: "",
                planOrStatus: provider.state.label ?? "",
                remaining: "",
                reset: "",
                state: provider.state,
                error: provider.errorText,
                children: provider.accounts.map { account in
                    OverviewRow(
                        id: "\(provider.key)/\(account.key)",
                        providerKey: provider.key,
                        accountKey: account.key,
                        providerLabel: "",
                        accountLabel: account.label,
                        planOrStatus: account.state == .current
                            ? account.plan
                            : "\(account.plan) · \(account.state.label ?? "")",
                        remaining: account.remaining.map { "\($0)%" } ?? "",
                        reset: account.resetText ?? "",
                        state: account.state,
                        error: nil)
                })
        }
    }

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
        } else if rows.isEmpty {
            ContentUnavailableView {
                Label("No providers detected", systemImage: "chevron.right")
            } description: {
                Text("Add a provider in Settings to start tracking quota limits.")
            } actions: {
                Button("Open Settings…") { onOpenSettings() }
            }
            .accessibilityIdentifier("usage.overview.empty")
        } else {
            Table(of: OverviewRow.self, selection: $selection) {
                TableColumn("Provider") { row in
                    Text(row.providerLabel)
                        .lineLimit(2)
                        .accessibilityIdentifier(providerIdentifier(row))
                }
                TableColumn("Account") { row in
                    Text(row.accountLabel)
                        .lineLimit(2)
                        .accessibilityHidden(true)
                }
                TableColumn("Plan or status") { row in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.planOrStatus)
                            .foregroundStyle(.primary)
                        if let error = row.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .accessibilityIdentifier("usage.overview.error.\(row.providerKey)")
                            Button(store.chrome.retryTitle) { store.refresh() }
                                .controlSize(.small)
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("usage.overview.retry.\(row.providerKey)")
                        }
                    }
                    .accessibilityHidden(row.error == nil)
                }
                .width(min: 120, ideal: 210)
                TableColumn("Remaining") { row in
                    Text(row.remaining)
                        .monospacedDigit()
                        .accessibilityHidden(true)
                }
                .width(min: 90, ideal: 110)
                TableColumn("Reset") { row in
                    Text(row.reset)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .accessibilityHidden(true)
                }
                .width(min: 140, ideal: 210)
            } rows: {
                ForEach(rows) { row in
                    if let children = row.children {
                        DisclosureTableRow(
                            row,
                            isExpanded: expansionBinding(for: row.id)
                        ) {
                            ForEach(children) { child in
                                TableRow(child)
                            }
                        }
                    } else {
                        TableRow(row)
                    }
                }
            }
            .accessibilityLabel("Usage overview")
            .accessibilityIdentifier("usage.overview.table")
            .onChange(of: selection) { _, selectedID in
                guard let selectedID, let row = findRow(id: selectedID) else { return }
                // Selection arrives inside the table's delegate callback;
                // mutating navigation state there is reentrant — defer.
                DispatchQueue.main.async {
                    if let accountKey = row.accountKey,
                        let provider = store.provider(row.providerKey)
                    {
                        store.selectAccount(accountKey, for: provider)
                    }
                    store.sidebar = .provider(row.providerKey)
                }
            }
        }
    }

    private func findRow(id: OverviewRow.ID) -> OverviewRow? {
        for row in rows {
            if row.id == id { return row }
            if let child = row.children?.first(where: { $0.id == id }) { return child }
        }
        return nil
    }

    private func providerIdentifier(_ row: OverviewRow) -> String {
        if let accountKey = row.accountKey {
            return "usage.overview.account.\(row.providerKey).\(accountKey)"
        }
        return "usage.overview.provider.\(row.providerKey)"
    }

    private func expansionBinding(for id: OverviewRow.ID) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(id) },
            set: { isExpanded in
                // Mutating expansion state synchronously inside the table's
                // delegate callback is reentrant; defer to the next turn.
                DispatchQueue.main.async {
                    if isExpanded { expanded.insert(id) } else { expanded.remove(id) }
                }
            })
    }
}

struct ProviderDetailView: View {
    let store: ProtoStore
    let provider: ProtoProvider

    private var accountBinding: Binding<String> {
        Binding(
            get: { store.account(for: provider)?.key ?? "" },
            set: { store.selectAccount($0, for: provider) })
    }

    var body: some View {
        let account = store.account(for: provider)
        List {
            Section {
                HStack(spacing: 12) {
                    if let mark = ProviderMarks.swiftUIImage(forIconKey: provider.iconKey) {
                        mark
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .accessibilityHidden(true)
                    } else {
                        Text(provider.fallbackGlyph)
                            .font(.headline)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 2) {
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
                .accessibilityLabel("\(provider.name), \(account?.label ?? ""), \(provider.activityLabel)")
                .accessibilityIdentifier("usage.provider-identity")
            }

            if provider.accounts.count > 1 {
                Section {
                    Picker("Account", selection: accountBinding) {
                        ForEach(provider.accounts) { entry in
                            Text(entry.label).tag(entry.key)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Account")
                    .accessibilityIdentifier("usage.account-picker")
                } header: {
                    sectionHeader("Account")
                }
            }

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
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent(window.label) {
                Text(window.display)
                    .monospacedDigit()
                    .foregroundStyle(window.notStarted ? .secondary : .primary)
            }
            if let meter = window.meter {
                ProgressView(value: Double(meter), total: 100)
                    .tint(meterTint(window.state))
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
        }
    }
}

/// Native split-item top accessory: centered identity, trailing Refresh with
/// the in-progress spinner swap. The system owns the material.
struct DetailAccessoryView: View {
    let store: ProtoStore

    var body: some View {
        ZStack {
            Text("jackin❯ desktop")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("usage.brand-title")

            HStack {
                Spacer()
                refreshButton
            }
        }
        .frame(minHeight: 40)
    }

    private var refreshButton: some View {
        Button {
            store.refresh()
        } label: {
            Label {
                Text(store.chrome.refreshTitle)
            } icon: {
                ZStack {
                    Image(systemName: "arrow.clockwise")
                        .opacity(store.refreshInProgress ? 0 : 1)
                    ProgressView()
                        .controlSize(.small)
                        .opacity(store.refreshInProgress ? 1 : 0)
                }
                .frame(width: 16, height: 16)
            }
        }
        .buttonStyle(.glass)
        .keyboardShortcut("r", modifiers: [.command])
        .disabled(store.refreshInProgress)
        .accessibilityValue(store.refreshInProgress ? "In progress" : "")
        .accessibilityIdentifier("usage.refresh")
    }
}
