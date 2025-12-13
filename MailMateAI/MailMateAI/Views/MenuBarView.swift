import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @State private var showingErrorDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("MailMate AI")
                    .font(.headline)
                Spacer()
                statusBadge
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Menu items
            Group {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                } label: {
                    Label("Settings...", systemImage: "gear")
                }
                .keyboardShortcut(",", modifiers: .command)

                if appState.lastError != nil {
                    Button {
                        showingErrorDetail = true
                    } label: {
                        Label("View Last Error", systemImage: "exclamationmark.triangle")
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Divider()

            Group {
                Button {
                    NSApp.orderFrontStandardAboutPanel()
                } label: {
                    Label("About", systemImage: "info.circle")
                }

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "power")
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 220)
        .sheet(isPresented: $showingErrorDetail) {
            if let error = appState.lastError {
                ErrorDetailView(error: error)
            }
        }
        .task {
            // Only check setup once per app launch, not during processing
            guard !appState.hasCheckedSetup && !appState.isProcessing else { return }
            appState.hasCheckedSetup = true

            if !appState.hasCompletedSetup {
                // Double-check: if there's already an API key, mark setup complete
                if let apiKey = KeychainManager.apiKey, !apiKey.isEmpty {
                    appState.completeSetup()
                } else {
                    openWindow(id: "setup")
                }
            }
        }
    }

    @ViewBuilder
    var statusBadge: some View {
        if appState.isProcessing {
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Processing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if appState.lastError != nil {
            Text("Error")
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red.opacity(0.2))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        } else {
            Text("Ready")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
