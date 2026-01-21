//
//  HomeView.swift
//  Disco
//
//  Created by Alex Cruz on 18/01/2026.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var controller = DisconnectController()

    @Environment(\.scenePhase) private var scenePhase

    private enum ActiveSheet: Identifiable {
        case notifications
        case info

        var id: Int {
            switch self {
            case .notifications: return 0
            case .info: return 1
            }
        }
    }

    @State private var activeSheet: ActiveSheet?

    var body: some View {
        VStack(spacing: 24) {
            topBar

            Spacer()

            stateCopy

            timerText

            mainButton
                .padding(.top, 24)

            Spacer()
        }
        .padding(24)
        .onAppear {
            controller.syncDeliveredNotifications()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                controller.syncDeliveredNotifications()
            }
        }
        .onChange(of: activeSheet) { newSheet in
            if newSheet == .notifications {
                controller.syncDeliveredNotifications()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .notifications:
                NotificationCenterView(controller: controller)
            case .info:
                InfoView()
            }
        }
    }

    // MARK: - UI Pieces

    private var topBar: some View {
        HStack {
            Button {
                activeSheet = .notifications
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bell")
                    Text("Notifications")
                    if controller.state.unreadCount > 0 {
                        Text("\(controller.state.unreadCount)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .contentShape(Rectangle())
            }

            Spacer()

            Button {
                activeSheet = .info
            } label: {
                Image(systemName: "info.circle")
                    .imageScale(.large)
            }
            .accessibilityLabel("About")
        }
    }

    @ViewBuilder
    private var stateCopy: some View {
        switch controller.state.phase {
        case .idle:
            Text("Tap to start disconnecting.")
                .font(.subheadline)
                .opacity(0.8)
                .multilineTextAlignment(.center)

        case .disconnecting:
            VStack(spacing: 10) {
                Text("Disconnecting…")
                    .font(.title2.weight(.semibold))
                Text("Lock your phone manually. iOS won’t let apps auto-lock.")
                    .font(.subheadline)
                    .opacity(0.8)
            }
            .multilineTextAlignment(.center)

        case .aftermath(let summary):
            VStack(spacing: 10) {
                Text("\"Great job.\"")
                    .font(.title2.weight(.semibold))
                Text("Your performance has been recorded.")
                    .font(.subheadline)
                    .opacity(0.8)

                Text("Total: \(formatDuration(summary.totalSeconds))")
                    .font(.headline)
                    .padding(.top, 8)
            }
            .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var timerText: some View {
        switch controller.state.phase {
        case .disconnecting(let session):
            Text(formatDuration(session.elapsedSeconds))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
        default:
            EmptyView()
        }
    }

    private var mainButton: some View {
        Button {
            handleMainButtonTap()
        } label: {
            Text(mainButtonTitle)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.red)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var mainButtonTitle: String {
        switch controller.state.phase {
        case .idle:
            return "Ready to disconnect."
        case .disconnecting:
            return "End disconnect"
        case .aftermath:
            return "Back home"
        }
    }

    private func handleMainButtonTap() {
        switch controller.state.phase {
        case .idle:
            controller.startDisconnect()

        case .disconnecting:
            controller.stopDisconnect()

        case .aftermath:
            controller.finishAftermathAndReturnHome()
        }
    }

    private func formatDuration(_ totalSeconds: Int) -> String {
        let s = max(0, totalSeconds)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let seconds = s % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    HomeView()
}
