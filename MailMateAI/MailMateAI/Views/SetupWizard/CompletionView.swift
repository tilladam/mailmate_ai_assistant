import SwiftUI

struct CompletionView: View {
    let onFinish: () -> Void
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var bundleInstalled = false
    @State private var installError: String?
    @State private var launchAtLogin = false

    var body: some View {
        VStack(spacing: 20) {
            // Status items
            VStack(alignment: .leading, spacing: 12) {
                StatusRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "API key saved to Keychain"
                )

                StatusRow(
                    icon: bundleInstalled ? "checkmark.circle.fill" :
                          (installError != nil ? "xmark.circle.fill" : "circle.dotted"),
                    color: bundleInstalled ? .green : (installError != nil ? .red : .secondary),
                    text: bundleInstalled ? "Bundle installed to MailMate" :
                          (installError ?? "Installing bundle...")
                )
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Launch at login option
            Toggle("Launch MailMate AI at login?", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    settingsManager.launchAtLogin = newValue
                }

            // Usage instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Usage")
                    .font(.headline)
                Text("Press **Ctrl+C** in MailMate's composer to generate a reply.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button("Finish Setup") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!bundleInstalled)
        }
        .padding(30)
        .onAppear {
            installBundle()
        }
    }

    private func installBundle() {
        Task {
            do {
                try BundleInstaller.install()
                await MainActor.run {
                    bundleInstalled = true
                }
            } catch {
                await MainActor.run {
                    installError = error.localizedDescription
                }
            }
        }
    }
}

struct StatusRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
        }
    }
}
