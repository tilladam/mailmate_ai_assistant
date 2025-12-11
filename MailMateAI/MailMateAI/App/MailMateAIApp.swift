import SwiftUI

@main
struct MailMateAIApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isProcessing ? "envelope.badge.clock" : "envelope")
                .symbolRenderingMode(.hierarchical)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        Window("Setup", id: "setup") {
            SetupWizardView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
