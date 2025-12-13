import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager

    @State private var selectedProvider: AIProvider = .anthropic
    @State private var apiKey: String = ""
    @State private var showApiKey: Bool = false
    @State private var selectedModel: String = ""
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false

    var body: some View {
        Form {
            // Provider Section
            Section {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedProvider) { _, newValue in
                    if !settingsManager.useCustomModel {
                        selectedModel = newValue.defaultModels.first?.id ?? ""
                    }
                }
            } header: {
                Text("Provider")
            }

            // API Key Section
            Section {
                HStack {
                    if showApiKey {
                        TextField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("API Key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(showApiKey ? "Hide" : "Reveal") {
                        showApiKey.toggle()
                    }
                    .buttonStyle(.bordered)
                }

                Button("Save API Key") {
                    saveApiKey()
                }
                .disabled(apiKey.isEmpty)
            } header: {
                Text("API Key")
            }

            // Model Section
            Section {
                Picker("Model", selection: $selectedModel) {
                    ForEach(selectedProvider.defaultModels) { model in
                        Text(model.name).tag(model.id)
                    }
                }
                .disabled(settingsManager.useCustomModel)
                .onChange(of: selectedModel) { _, newValue in
                    if !settingsManager.useCustomModel {
                        try? KeychainManager.setModel(newValue)
                    }
                }

                Toggle("Use custom model", isOn: $settingsManager.useCustomModel)

                if settingsManager.useCustomModel {
                    TextField("Custom model ID", text: $settingsManager.customModelId)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: settingsManager.customModelId) { _, newValue in
                            try? KeychainManager.setModel(newValue)
                        }
                }
            } header: {
                Text("Model")
            }

            // General Section
            Section {
                Toggle("Launch at login", isOn: $settingsManager.launchAtLogin)
                Toggle("Show notifications", isOn: $settingsManager.showNotifications)
            } header: {
                Text("General")
            }

            // Bundle Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(BundleInstaller.bundleVersion ?? "Unknown")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Status")
                    Spacer()
                    if BundleInstaller.isBundleInstalled {
                        Label("Installed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Not Installed", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Button("Reinstall Bundle") {
                    reinstallBundle()
                }
            } header: {
                Text("Bundle")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 500)
        .onAppear {
            loadCurrentSettings()
        }
        .alert("Saved", isPresented: $showingSaveSuccess) {
            Button("OK") { }
        } message: {
            Text("Configuration saved.")
        }
        .alert("Error", isPresented: $showingSaveError) {
            Button("OK") { }
        } message: {
            Text("Failed to save API key.")
        }
    }

    private func loadCurrentSettings() {
        if let provider = KeychainManager.provider,
           let aiProvider = AIProvider(rawValue: provider) {
            selectedProvider = aiProvider
        }

        apiKey = KeychainManager.apiKey ?? ""
        selectedModel = KeychainManager.model ?? selectedProvider.defaultModels.first?.id ?? ""
    }

    private func saveApiKey() {
        do {
            try KeychainManager.setApiKey(apiKey)
            try KeychainManager.setProvider(selectedProvider.rawValue)
            showingSaveSuccess = true
        } catch {
            showingSaveError = true
        }
    }

    private func reinstallBundle() {
        Task {
            try? BundleInstaller.install()
        }
    }
}
