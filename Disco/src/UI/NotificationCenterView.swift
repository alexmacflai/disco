//
//  NotificationCenterView.swift
//  Disco
//
//  Created by Alex Cruz on 18/01/2026.
//

import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject var controller: DisconnectController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if controller.state.notificationLog.isEmpty {
                    emptyState
                } else {
                    ForEach(controller.state.notificationLog, id: \.id) { entry in
                        row(for: entry)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Read") {
                                    controller.markNotificationRead(entry.id)
                                }
                                .tint(.primary)
                            }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("Nothing here yet")
                .font(.headline)
            Text("We haven’t tried to reach you.")
                .font(.subheadline)
                .opacity(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
    }

    private func row(for entry: DiscoNotificationLogEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                statusPill(entry.status)

                if !entry.isRead {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 6, height: 6)
                }
            }

            Text(entry.title)
                .font(.headline)

            Text(entry.body)
                .font(.subheadline)
                .opacity(0.8)
        }
        .padding(.vertical, 8)
    }

    private func statusPill(_ status: DiscoNotificationDeliveryStatus) -> some View {
        Text(status == .delivered ? "Delivered" : "Attempted")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial)
            .clipShape(Capsule())
    }
}

#Preview {
    NotificationCenterView(controller: DisconnectController())
}
