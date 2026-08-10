// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Hostable provider identity + nested account rows with glance % + mini meter.
///
/// Same craft as ``UsageWindowRoot`` sidebar nest (HTML SoT: provider ≠ account).
/// Extracted so QI snapshot harnesses can render the **shipped** nest path without
/// a live ``PresentationStore`` / UniFFI bridge.
public struct UsageAccountNestView: View {
    public let providerLabel: String
    public let accounts: [PresentationStore.AccountRow]
    public let onSelectAccount: (String, String) -> Void

    public init(
        providerLabel: String,
        accounts: [PresentationStore.AccountRow],
        onSelectAccount: @escaping (String, String) -> Void = { _, _ in }
    ) {
        self.providerLabel = providerLabel
        self.accounts = accounts
        self.onSelectAccount = onSelectAccount
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(providerLabel)
                .font(.body.weight(.semibold))
                .lineLimit(1)
            if accounts.count > 1 {
                Text("\(accounts.count) accounts")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            VStack(spacing: 4) {
                ForEach(accounts) { account in
                    accountRow(account, multi: accounts.count > 1)
                }
            }
            .padding(6)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(10)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func accountRow(
        _ account: PresentationStore.AccountRow,
        multi: Bool
    ) -> some View {
        Button {
            if multi {
                onSelectAccount(account.surfaceId, account.accountKey)
            }
        } label: {
            HStack(spacing: 8) {
                if multi {
                    Image(systemName: account.selected ? "circle.inset.filled" : "circle")
                        .font(.caption2)
                        .foregroundStyle(account.selected ? Color.jackinPhosphor : .secondary)
                        .frame(width: 12)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(account.accountLabel)
                        .font(.caption.monospaced().weight(account.selected || !multi ? .semibold : .medium))
                        .lineLimit(1)
                        .foregroundStyle(account.selected || !multi ? .primary : .secondary)
                    if let plan = account.planLabel, !plan.isEmpty {
                        Text(plan)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                if let pct = account.remainingPercent {
                    VStack(alignment: .trailing, spacing: 3) {
                        // Rust UInt8 remaining only — format without banned helpers.
                        Text(verbatim: String(pct) + "%")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.secondary)
                        UsageAccountMiniMeter(percent: pct)
                    }
                }
            }
            .padding(6)
            .background(Color.primary.opacity(account.selected ? 0.08 : 0.04))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!multi)
        .accessibilityLabel(accessibilityLabel(account, multi: multi))
        .accessibilityAddTraits(account.selected || !multi ? .isSelected : [])
    }

    private func accessibilityLabel(
        _ account: PresentationStore.AccountRow,
        multi: Bool
    ) -> String {
        var parts = [account.accountLabel]
        if let plan = account.planLabel, !plan.isEmpty { parts.append(plan) }
        if let pct = account.remainingPercent { parts.append("\(pct) percent remaining") }
        if multi, account.selected { parts.append("selected") }
        return parts.joined(separator: ", ")
    }
}

/// Fixed-width remaining bar — geometry only from Rust percent.
/// Healthy fill = phosphor (`--status-high`); empty track at 0% (no minimum sliver).
public struct UsageAccountMiniMeter: View {
    public let percent: UInt8

    public init(percent: UInt8) {
        self.percent = percent
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12))
                if percent > 0 {
                    Capsule()
                        .fill(Color.jackinPhosphor.opacity(0.85))
                        .frame(width: geo.size.width * CGFloat(percent) / 100.0)
                }
            }
        }
        .frame(width: 32, height: 3)
    }
}
