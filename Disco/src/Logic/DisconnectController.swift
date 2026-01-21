//
//  DisconnectController.swift
//  Disco
//
//  Created by Alex Cruz on 18/01/2026.
//

import Foundation
import Combine
import UserNotifications
import UIKit

/// Single source of truth that drives the app state machine.
/// - Owns the disconnect session lifecycle
/// - Ticks elapsed time once per second while disconnecting
final class DisconnectController: ObservableObject {
    @Published private(set) var state: AppState

    private var timer: Timer?

    private var cancellables = Set<AnyCancellable>()

    private let notificationScheduler = NotificationScheduler()
    @MainActor private let logStore = DiscoNotificationLogStore.shared
    private var hasRequestedNotificationAuth = false

    init(initialState: AppState = AppState()) {
        self.state = initialState
        state.notificationLog = logStore.entries
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(logStore.unreadCount) }

        logStore.$entries
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                guard let self else { return }
                self.state.notificationLog = entries
                Task { try? await UNUserNotificationCenter.current().setBadgeCount(self.logStore.unreadCount) }
            }
            .store(in: &cancellables)
    }

    deinit {
        stopTimer()
        notificationScheduler.stop()
    }

    // MARK: - Session lifecycle

    /// Starts disconnect mode (timer resets to 0).
    func startDisconnect() {
        stopTimer()

        let session = DisconnectSession(startedAt: Date(), elapsedSeconds: 0)
        state.phase = .disconnecting(session)

        startTimer()
        ensureNotificationAuthThenSchedule()
    }

    /// Ends disconnect mode and moves to aftermath screen.
    /// Badge is NOT reset here (residue). It resets when the user explicitly finishes aftermath.
    func stopDisconnect() {
        stopTimer()
        notificationScheduler.stop()

        guard case let .disconnecting(session) = state.phase else { return }

        let endedAt = Date()
        let totalSeconds = max(0, Int(endedAt.timeIntervalSince(session.startedAt)))

        state.phase = .aftermath(
            AftermathSummary(
                sessionId: session.id,
                startedAt: session.startedAt,
                endedAt: endedAt,
                totalSeconds: totalSeconds
            )
        )
    }

    /// User explicitly finishes the flow (aftermath button) and returns home.
    /// This is where the badge resets (per spec).
    func finishAftermathAndReturnHome() {
        state.phase = .idle
        // Do NOT reset badges here. Unread count is persistent.
        // The app icon badge is continuously mirrored from logStore.unreadCount.
    }

    // MARK: - Notifications (logged in-app)

    func logNotificationAttempt(identifier: String, title: String, body: String, copyId: String? = nil) {
        logStore.upsertAttempt(identifier: identifier, title: title, body: body, copyId: copyId)
        state.notificationLog = logStore.entries
    }

    func logNotificationDelivered(identifier: String, title: String, body: String, copyId: String? = nil) {
        logStore.upsertDelivered(identifier: identifier, title: title, body: body, copyId: copyId)
        state.notificationLog = logStore.entries
    }

    func markNotificationRead(_ id: String) {
        logStore.markRead(id)
        state.notificationLog = logStore.entries
    }

    func syncDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                for n in notifications {
                    let req = n.request
                    self.logNotificationDelivered(
                        identifier: req.identifier,
                        title: req.content.title,
                        body: req.content.body,
                        copyId: nil
                    )
                }
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard case var .disconnecting(session) = state.phase else { return }

        let now = Date()
        session.elapsedSeconds = max(0, Int(now.timeIntervalSince(session.startedAt)))
        state.phase = .disconnecting(session)
    }

    // MARK: - Real notification scheduling

    private func ensureNotificationAuthThenSchedule() {
        guard case let .disconnecting(session) = state.phase else { return }

        let schedule = { [weak self] in
            guard let self else { return }
            self.notificationScheduler.start(
                sessionStartedAt: session.startedAt,
                startingBadge: self.logStore.unreadCount
            )
        }

        if hasRequestedNotificationAuth {
            schedule()
            return
        }

        hasRequestedNotificationAuth = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            // Schedule regardless. The in-app center is populated only via delivered notifications.
            schedule()
        }
    }
}
