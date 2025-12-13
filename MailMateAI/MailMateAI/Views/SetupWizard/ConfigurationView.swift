import SwiftUI

struct ConfigurationView: View {
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var selectedProvider: AIProvider = .anthropic
    @State private var apiKey: String = ""
    @State private var selectedModel: String = ""
    @State private var useCustomModel: Bool = false
    @State private var customModelId: String = ""
    @State private var showingApiKeyError = false

    var body: some View {
        VStack(spacing: 20) {
            // Provider selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Provider")
                    .font(.headline)

                Picker("Provider", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedProvider) { _, newValue in
                    selectedModel = newValue.defaultModels.first?.id ?? ""
                }
            }

            // API Key
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.headline)

                SecureField("Enter your API key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)

                Text("Stored in ~/.mailmateai/config.json")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Model selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Model")
                    .font(.headline)

                Picker("Model", selection: $selectedModel) {
                    ForEach(selectedProvider.defaultModels) { model in
                        Text(model.name).tag(model.id)
                    }
                }
                .disabled(useCustomModel)

                Toggle("Use custom model", isOn: $useCustomModel)

                if useCustomModel {
                    TextField("Custom model ID", text: $customModelId)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Spacer()

            // Navigation
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Continue") {
                    saveConfiguration()
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding(30)
        .onAppear {
            loadExistingConfiguration()
        }
        .alert("Configuration Error", isPresented: $showingApiKeyError) {
            Button("OK") { }
        } message: {
            Text("Failed to save configuration. Please try again.")
        }
    }

    private func loadExistingConfiguration() {
        // Load provider
        if let providerString = KeychainManager.provider,
           let provider = AIProvider(rawValue: providerString) {
            selectedProvider = provider
        }

        // Load API key
        if let existingKey = KeychainManager.apiKey {
            apiKey = existingKey
        }

        // Load model
        if let existingModel = KeychainManager.model {
            // Check if it's a custom model (not in default list)
            let isDefaultModel = selectedProvider.defaultModels.contains { $0.id == existingModel }
            if isDefaultModel {
                selectedModel = existingModel
            } else {
                useCustomModel = true
                customModelId = existingModel
                selectedModel = selectedProvider.defaultModels.first?.id ?? ""
            }
        } else {
            selectedModel = selectedProvider.defaultModels.first?.id ?? ""
        }

        // Load custom model settings
        useCustomModel = SettingsManager.shared.useCustomModel
        if useCustomModel {
            customModelId = SettingsManager.shared.customModelId
        }
    }

    private func saveConfiguration() {
        do {
            try KeychainManager.setApiKey(apiKey)
            try KeychainManager.setProvider(selectedProvider.rawValue)

            let modelToSave = useCustomModel ? customModelId : selectedModel
            try KeychainManager.setModel(modelToSave)

            SettingsManager.shared.useCustomModel = useCustomModel
            SettingsManager.shared.customModelId = customModelId

            onContinue()
        } catch {
            showingApiKeyError = true
        }
    }
}
