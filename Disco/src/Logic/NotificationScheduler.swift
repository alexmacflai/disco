//
//  NotificationScheduler.swift
//  Disco
//
//  Created by Alex Cruz on 18/01/2026.
//

import Foundation
import UserNotifications

/// Pre-schedules a batch of local notifications so they can fire while the app is backgrounded.
///
/// Contract:
/// - Caller is responsible for requesting notification permission before calling `start`.
/// - Scheduler is responsible for setting the app icon badge via notification payloads.
final class NotificationScheduler {

    struct Config {
        /// How many notifications to schedule ahead.
        var maxScheduled: Int = 20

        /// iOS requires timeInterval >= 1.
        var minTriggerSeconds: Int = 1
    }

    private let copy: CopyEngine
    private let center: UNUserNotificationCenter
    private let config: Config

    private var scheduledIdentifiers: [String] = []

    init(
        copy: CopyEngine = CopyEngine(),
        center: UNUserNotificationCenter = .current(),
        config: Config = Config()
    ) {
        self.copy = copy
        self.center = center
        self.config = config
    }

    /// Clears pending notifications created by this scheduler and schedules a fresh batch.
    func start(
        sessionStartedAt: Date,
        startingBadge: Int
    ) {
        stop()

        let now = Date()
        let elapsedNow = max(0, Int(now.timeIntervalSince(sessionStartedAt)))

        var cumulativeDelay = 0

        for _ in 0..<config.maxScheduled {
            let projectedElapsed = elapsedNow + cumulativeDelay

            let nextDelay = copy.nextInterval(elapsedSeconds: projectedElapsed)
            cumulativeDelay += max(config.minTriggerSeconds, nextDelay)

            let msg = copy.makeMessage(elapsedSeconds: elapsedNow + cumulativeDelay)
            let identifier = UUID().uuidString

            scheduleLocalNotification(
                identifier: identifier,
                inSeconds: cumulativeDelay,
                title: msg.title,
                body: msg.body,
                badge: startingBadge + scheduledIdentifiers.count + 1
            )

            scheduledIdentifiers.append(identifier)
        }
    }

    /// Removes any pending notifications that were scheduled by this scheduler.
    func stop() {
        guard !scheduledIdentifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: scheduledIdentifiers)
        scheduledIdentifiers.removeAll()
    }

    // MARK: - Private

    private func scheduleLocalNotification(
        identifier: String,
        inSeconds: Int,
        title: String,
        body: String,
        badge: Int
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.badge = NSNumber(value: badge)
        content.sound = .default

        let triggerSeconds = max(config.minTriggerSeconds, inSeconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(triggerSeconds), repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
}
