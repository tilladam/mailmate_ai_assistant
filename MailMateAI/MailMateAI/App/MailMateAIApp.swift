import SwiftUI
import UserNotifications

@main
struct MailMateAIApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var urlHandler = URLSchemeHandler()
    @StateObject private var settingsManager = SettingsManager.shared
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
                .onOpenURL { url in
                    urlHandler.appState = appState
                    urlHandler.handle(url: url)
                }
                .task {
                    // Request notification permissions after app is ready
                    try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                }
        } label: {
            Image(systemName: appState.isProcessing ? "envelope.badge.clock" :
                  (appState.lastError != nil ? "envelope.badge.exclamationmark" : "envelope"))
                .symbolRenderingMode(.hierarchical)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        }

        Window("Setup", id: "setup") {
            SetupWizardView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
