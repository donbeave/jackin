import SwiftUI

// Popover mirrors the incumbent PopoverRoot: brand header, grouped Form
// content (identity, Limits, Details, Provider status), fixed controls row.

/// Focused-provider glance hosted by the real system `NSPopover`.
struct PopoverView: View {
    static let contentSize = CGSize(width: 380, height: 520)

    let store: ProtoStore
    let provider: ProtoProvider
    let onOpenUsage: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            popoverBrandHeader

            Divider()

            content
                .frame(width: 380, height: Self.contentSize.height - 94)
                .clipped()

            Divider()

            controls
                .padding(.horizontal, JackinSpace.sm)
                .frame(height: 48)
        }
        .frame(width: Self.contentSize.width, height: Self.contentSize.height)
    }

    private var popoverBrandHeader: some View {
        HStack(spacing: JackinSpace.xs) {
            if let monogram = JackinBrandIdentity.templateMonogram() {
                Image(nsImage: monogram)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .accessibilityHidden(true)
            }
            Text("jackin❯ desktop")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
    }

    @ViewBuilder
    private var content: some View {
        if store.projection.isLoading {
            ProgressView("Loading usage")
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("popover.loading")
        } else if let error = store.projection.globalError {
            ContentUnavailableView {
                Label("Usage unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button(store.chrome.retryTitle) { store.refresh() }
                    .disabled(store.refreshInProgress)
                    .accessibilityIdentifier("popover.retry")
            }
            .accessibilityIdentifier("popover.global-error")
        } else {
            providerForm(provider)
        }
    }

    private func providerForm(_ provider: ProtoProvider) -> some View {
        let account = store.account(for: provider)
        return Form {
            Section {
                providerIdentity(provider, account: account)
            }

            Section {
                if let account, !account.windows.isEmpty {
                    ForEach(account.windows) { window in
                        LimitRowView(window: window, identifierPrefix: "popover.limit")
                    }
                } else if provider.errorText == nil {
                    Text("No limit details available")
                        .foregroundStyle(.secondary)
                }
            } header: {
                sectionHeader("Limits")
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

            if let error = provider.errorText {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .accessibilityIdentifier("popover.provider-error")
                    if let ago = provider.updatedAgo {
                        Text(ago)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(store.chrome.retryTitle) { store.refresh() }
                        .disabled(store.refreshInProgress)
                        .accessibilityIdentifier("popover.provider-retry")
                } header: {
                    sectionHeader("Provider status")
                }
            }
        }
        .formStyle(.grouped)
        .accessibilityLabel("\(provider.name) usage details")
        .accessibilityIdentifier("popover.provider.\(provider.key)")
    }

    private func providerIdentity(_ provider: ProtoProvider, account: ProtoAccount?) -> some View {
        HStack(spacing: JackinSpace.xs) {
            if let mark = ProviderMarks.swiftUIImage(forIconKey: provider.iconKey) {
                mark
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: JackinSpace.xxs) {
                Text(provider.name)
                    .font(.headline)
                if let account {
                    Text(account.label)
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("popover.provider-account")
                }
                Text(provider.activityLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("popover.provider-activity")
            }
            Spacer()
            if provider.isRefreshing || store.refreshInProgress {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(provider.activityLabel)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(provider.name), \(account?.label ?? ""), \(provider.activityLabel)")
        .accessibilityIdentifier("popover.provider-identity")
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .accessibilityLabel(title)
    }

    private var accountSelection: Binding<String> {
        Binding(
            get: { store.account(for: provider)?.key ?? "" },
            set: { store.selectAccount($0, for: provider) })
    }

    // Functional controls in a transient surface: real Liquid Glass button
    // styles (macOS 26.0). One prominent action only — Open Usage, the
    // row's primary. Known macOS 26 defect: .glass buttons show no hover
    // state outside a toolbar (fixed in 27); verified live.
    private var controls: some View {
        HStack(spacing: JackinSpace.sm) {
            HStack(spacing: JackinSpace.xs) {
                Button {
                    store.refresh()
                } label: {
                    Label(store.chrome.refreshTitle, systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.glass)
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(store.refreshInProgress)
                .accessibilityLabel(store.chrome.refreshTitle)
                .accessibilityIdentifier("popover.refresh")
                .help(store.chrome.refreshTitle)

                Button {
                    onOpenUsage()
                } label: {
                    Label(store.chrome.openUsageTitle, systemImage: "macwindow")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.defaultAction)
                .accessibilityLabel(store.chrome.openUsageTitle)
                .accessibilityIdentifier("popover.open-usage")
                .help(store.chrome.openUsageTitle)
            }
            Spacer(minLength: 12)

            if provider.accounts.count > 1 {
                Picker("Account", selection: accountSelection) {
                    ForEach(provider.accounts) { entry in
                        Text(entry.label)
                            .tag(entry.key)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 220, alignment: .trailing)
                .accessibilityLabel("Account")
                .accessibilityIdentifier("popover.account-picker")
                .help("Choose account")
            }
        }
    }
}

/// Settings mirrors the incumbent grouped Form over fixture-backed state.
struct SettingsView: View {
    @Bindable var store: ProtoStore

    private var percentBinding: Binding<PercentStyle> {
        Binding(
            get: { store.percentStyle },
            set: { store.setPercentStyle($0) })
    }

    private var floorBinding: Binding<Double> {
        Binding(
            get: { Double(store.refreshFloorMinutes) },
            set: { store.requestRefreshFloor(Int($0)) })
    }

    var body: some View {
        Form {
            Section("Menu bar") {
                Picker("Display", selection: $store.displayMode) {
                    Text("All providers (icon + remaining %)").tag(ProtoStore.DisplayMode.strip)
                    Text("Worst provider only").tag(ProtoStore.DisplayMode.focusPercent)
                    Text("Pinned provider").tag(ProtoStore.DisplayMode.pinnedSurface)
                    Text("Icon only").tag(ProtoStore.DisplayMode.iconOnly)
                }
                .pickerStyle(.radioGroup)
                .accessibilityLabel("Status item display mode")
                if store.displayMode == .strip {
                    Text(
                        "Detected providers use native menu-bar items with system-owned appearance."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if store.displayMode == .pinnedSurface {
                    Picker("Pinned provider", selection: $store.pinnedSurfaceKey) {
                        Text("—").tag("")
                        ForEach(store.projection.providers) { provider in
                            Text(provider.name).tag(provider.key)
                        }
                    }
                    .accessibilityLabel("Pinned provider for status item")
                }

                if store.displayMode == .strip {
                    Picker("Max providers in menu bar", selection: $store.stripMax) {
                        ForEach(1...3, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .accessibilityLabel("Maximum providers shown in menu bar strip (1–3)")
                }

                Picker("Percent style", selection: percentBinding) {
                    Text("% left (remaining)").tag(PercentStyle.left)
                    Text("% used").tag(PercentStyle.used)
                }
                .pickerStyle(.radioGroup)
                .accessibilityLabel("Percent format: remaining left or used")
                Text("Menu bar chips and compact labels use this style together.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Reset style", selection: $store.resetStyle) {
                    Text("Countdown").tag(ProtoStore.ResetStyle.countdown)
                    Text("Exact time").tag(ProtoStore.ResetStyle.exactClock)
                }
                .pickerStyle(.radioGroup)
                .accessibilityLabel("Reset time format")

                Toggle(
                    "Hide values while screen sharing",
                    isOn: $store.hideWhileScreenSharing
                )
                .accessibilityLabel("Hide values while screen sharing")
            }
            Section("Login") {
                Toggle("Launch at login", isOn: $store.launchAtLogin)
                    .accessibilityLabel("Launch at login")
            }
            Section("Surfaces") {
                ForEach(store.projection.providers) { provider in
                    Toggle(
                        provider.name,
                        isOn: Binding(
                            get: { store.surfaceEnabled[provider.key] ?? true },
                            set: { store.surfaceEnabled[provider.key] = $0 }
                        )
                    )
                    .accessibilityLabel("\(provider.name) enabled")
                }
            }
            Section("Refresh") {
                // Policy floor lives in Rust (clamped ≥ 5m here); UI projects minutes.
                Slider(
                    value: floorBinding,
                    in: 1...30,
                    step: 1
                ) {
                    Text("Minimum interval")
                } minimumValueLabel: {
                    Text("1m")
                } maximumValueLabel: {
                    Text("30m")
                }
                Text("Probe at most every \(store.refreshFloorMinutes) minutes (Rust floor).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Refresh floor \(store.refreshFloorMinutes) minutes")
                if let error = store.floorError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(JackinBrand.warning)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(store.chrome.retryTitle) {
                        store.retryRefreshFloor()
                    }
                    .accessibilityIdentifier("settings.floor-retry")
                }
            }
            Section("About") {
                Text("Account quotas from host credentials via jackin-usage (Rust).")
                    .font(.caption)
                Text(
                    "Refreshing here updates the same account snapshot every jackin❯ container reads (and vice versa)."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Text("No passwords stored. No Capsule required.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
