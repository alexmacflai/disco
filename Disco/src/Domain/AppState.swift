

import Foundation

/// High-level app phase. This is the state machine.
enum AppPhase: Equatable {
    case idle
    case disconnecting(DisconnectSession)
    case aftermath(AftermathSummary)
}

/// A single disconnect session.
struct DisconnectSession: Equatable {
    let id: UUID
    let startedAt: Date

    /// Cached elapsed seconds, updated by a 1s tick.
    var elapsedSeconds: Int

    init(id: UUID = UUID(), startedAt: Date = Date(), elapsedSeconds: Int = 0) {
        self.id = id
        self.startedAt = startedAt
        self.elapsedSeconds = elapsedSeconds
    }
}

/// Summary shown after ending disconnect mode.
struct AftermathSummary: Equatable {
    let sessionId: UUID
    let startedAt: Date
    let endedAt: Date
    let totalSeconds: Int
}

/// Single source of truth for UI.
struct AppState: Equatable {
    var phase: AppPhase = .idle

    /// Everything the user can see inside the app notification center.
    var notificationLog: [DiscoNotificationLogEntry] = []

    /// App icon badge count: total attempted + delivered since disconnect started.
    /// Does NOT reset automatically.
    var badgeCount: Int = 0

    /// Unread count shown in the UI button.
    var unreadCount: Int {
        notificationLog.reduce(into: 0) { $0 += $1.isRead ? 0 : 1 }
    }

    /// Convenience: are we currently in disconnect mode?
    var isDisconnecting: Bool {
        if case .disconnecting = phase { return true }
        return false
    }

    mutating func markNotificationRead(_ id: String) {
        guard let idx = notificationLog.firstIndex(where: { $0.id == id }) else { return }
        notificationLog[idx].isRead = true
    }

    mutating func appendNotification(_ entry: DiscoNotificationLogEntry) {
        notificationLog.insert(entry, at: 0)
        badgeCount += 1
    }

    mutating func resetForNewDisconnect() {
        // Aftermath residue rule:
        // - Log stays (emotional residue)
        // - Badge resets ONLY when disconnect mode is explicitly ended
        // Here, starting a new session does NOT reset the badge.
        // If you want a full wipe for v1, change this deliberately.
    }
}
