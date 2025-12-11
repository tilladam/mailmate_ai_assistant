import Foundation
import ServiceManagement

enum AIProvider: String, CaseIterable, Identifiable {
    case anthropic = "anthropic"
    case openai = "openai"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: return "Anthropic"
        case .openai: return "OpenAI"
        }
    }

    var defaultModels: [ModelOption] {
        switch self {
        case .anthropic:
            return [
                ModelOption(id: "claude-sonnet-4-20250514", name: "Claude Sonnet 4"),
                ModelOption(id: "claude-opus-4-20250514", name: "Claude Opus 4"),
                ModelOption(id: "claude-3-5-haiku-20241022", name: "Claude Haiku 3.5")
            ]
        case .openai:
            return [
                ModelOption(id: "gpt-4o", name: "GPT-4o"),
                ModelOption(id: "gpt-4o-mini", name: "GPT-4o mini"),
                ModelOption(id: "gpt-4-turbo", name: "GPT-4 Turbo")
            ]
        }
    }
}

struct ModelOption: Identifiable, Hashable {
    let id: String
    let name: String
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    @Published var showNotifications: Bool {
        didSet {
            UserDefaults.standard.set(showNotifications, forKey: "showNotifications")
        }
    }

    @Published var useCustomModel: Bool {
        didSet {
            UserDefaults.standard.set(useCustomModel, forKey: "useCustomModel")
        }
    }

    @Published var customModelId: String {
        didSet {
            UserDefaults.standard.set(customModelId, forKey: "customModelId")
        }
    }

    init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.showNotifications = UserDefaults.standard.object(forKey: "showNotifications") as? Bool ?? true
        self.useCustomModel = UserDefaults.standard.bool(forKey: "useCustomModel")
        self.customModelId = UserDefaults.standard.string(forKey: "customModelId") ?? ""
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }

    var currentProvider: AIProvider {
        get {
            guard let providerString = KeychainManager.provider,
                  let provider = AIProvider(rawValue: providerString) else {
                return .anthropic
            }
            return provider
        }
    }

    var currentModel: String {
        get {
            if useCustomModel && !customModelId.isEmpty {
                return customModelId
            }
            return KeychainManager.model ?? currentProvider.defaultModels.first?.id ?? ""
        }
    }

    var hasValidConfiguration: Bool {
        KeychainManager.apiKey != nil && !KeychainManager.apiKey!.isEmpty
    }
}
