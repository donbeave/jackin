// SPDX-FileCopyrightText: 2026 Alexey Zhokhov
// SPDX-License-Identifier: Apache-2.0

import JackinUsageBridge
import SwiftUI

/// Native account inventory for the A1 Overview destination.
public struct OverviewListView: View {
    public let model: UsageWindowModel
    public let accounts: [PresentationStore.AccountRow]
    public var onSelect: (String, String?) -> Void
    @State private var selectedRowID: OverviewInventoryRow.ID?

    public init(
        model: UsageWindowModel,
        accounts: [PresentationStore.AccountRow],
        onSelect: @escaping (String, String?) -> Void
    ) {
        self.model = model
        self.accounts = accounts
        self.onSelect = onSelect
    }

    private var inventory: [OverviewInventoryRow] {
        OverviewInventory.rows(accounts: accounts, glanceRows: model.sidebar)
    }

    public var body: some View {
        if inventory.isEmpty {
            ContentUnavailableView(
                "No providers detected",
                systemImage: "chevron.right",
                description: Text(UsageWindowModel.emptyHint)
            )
            .accessibilityIdentifier("usage.overview.empty")
        } else {
            Table(inventory, selection: $selectedRowID) {
                TableColumn("Provider and account") { row in
                    Text(row.title)
                        .lineLimit(2)
                }
                TableColumn("Plan") { row in
                    Text(row.planLabel ?? "—")
                        .foregroundStyle(row.planLabel == nil ? .secondary : .primary)
                }
                .width(min: 100, ideal: 150)
                TableColumn("Remaining") { row in
                    Text(row.barLabel)
                        .monospacedDigit()
                }
                .width(min: 90, ideal: 110)
                TableColumn("Reset") { row in
                    Text(row.resetLabel ?? "—")
                        .foregroundStyle(row.resetLabel == nil ? .secondary : .primary)
                        .lineLimit(2)
                }
                .width(min: 140, ideal: 210)
            }
            .accessibilityIdentifier("usage.overview.table")
            .onChange(of: selectedRowID) { _, selectedID in
                guard let selectedID, let row = inventory.first(where: { $0.id == selectedID })
                else { return }
                onSelect(row.surfaceId, row.accountKey)
            }
        }
    }
}
