//
//  DiscoApp.swift
//  Disco
//
//  Created by Alex Cruz on 18/01/2026.
//

import SwiftUI
import UserNotifications

@main
struct DiscoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        return true
    }

    // Show banners even when the app is open
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let req = notification.request

        await MainActor.run {
            // Foreground deliveries should update the in-app badge/list immediately.
            DiscoNotificationLogStore.shared.upsertDelivered(
                identifier: req.identifier,
                title: req.content.title,
                body: req.content.body
            )
        }

        return [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let content = response.notification.request.content
        let id = response.notification.request.identifier

        await MainActor.run {
            // Log as delivered, but read, because the user explicitly tapped it.
            DiscoNotificationLogStore.shared.upsertDelivered(
                identifier: id,
                title: content.title,
                body: content.body
            )
            DiscoNotificationLogStore.shared.markRead(id)
        }
    }
}
