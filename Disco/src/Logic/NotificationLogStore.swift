//
//  NotificationLogStore.swift
//  Disco
//
//  Created by Alex Cruz on 18/01/2026.
//

import Foundation
import Combine

enum DiscoNotificationDeliveryStatus: String, Codable {
    case attempted
    case delivered
}

struct DiscoNotificationLogEntry: Identifiable, Codable, Equatable {
    /// Use the UNNotificationRequest identifier so we can dedupe.
    let id: String
    let createdAt: Date
    let status: DiscoNotificationDeliveryStatus
    let title: String
    let body: String
    var isRead: Bool
    var copyId: String?

    init(
        id: String,
        createdAt: Date = Date(),
        status: DiscoNotificationDeliveryStatus,
        title: String,
        body: String,
        isRead: Bool = false,
        copyId: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.status = status
        self.title = title
        self.body = body
        self.isRead = isRead
        self.copyId = copyId
    }
}

@MainActor
final class DiscoNotificationLogStore: ObservableObject {
    static let shared = DiscoNotificationLogStore()

    @Published private(set) var entries: [DiscoNotificationLogEntry] = []

    private let storageKey = "disco.notificationLog.v2"

    private init() {
        load()
    }

    var unreadCount: Int {
        entries.reduce(0) { $0 + ($1.isRead ? 0 : 1) }
    }

    func upsertAttempt(identifier: String, title: String, body: String, copyId: String? = nil) {
        upsert(identifier: identifier, status: .attempted, title: title, body: body, copyId: copyId)
    }

    func upsertDelivered(identifier: String, title: String, body: String, copyId: String? = nil) {
        upsert(identifier: identifier, status: .delivered, title: title, body: body, copyId: copyId)
    }

    func markRead(_ id: String) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].isRead = true
        save()
    }

    private func upsert(identifier: String, status: DiscoNotificationDeliveryStatus, title: String, body: String, copyId: String?) {
        if let idx = entries.firstIndex(where: { $0.id == identifier }) {
            // Upgrade attempted -> delivered if needed, keep read state.
            let wasRead = entries[idx].isRead
            let createdAt = entries[idx].createdAt
            entries[idx] = DiscoNotificationLogEntry(
                id: identifier,
                createdAt: createdAt,
                status: status == .delivered ? .delivered : entries[idx].status,
                title: title,
                body: body,
                isRead: wasRead,
                copyId: copyId ?? entries[idx].copyId
            )
        } else {
            entries.insert(DiscoNotificationLogEntry(id: identifier, status: status, title: title, body: body, isRead: false, copyId: copyId), at: 0)
        }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DiscoNotificationLogEntry].self, from: data)
        else {
            entries = []
            return
        }
        entries = decoded
    }
}
