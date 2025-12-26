import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: AppError?
    @Published var hasCompletedSetup: Bool
    var hasCheckedSetup = false

    init() {
        // Check if setup was previously completed
        if UserDefaults.standard.bool(forKey: "hasCompletedSetup") {
            self.hasCompletedSetup = true
        } else {
            // Auto-detect existing configuration (Keychain or config.ini)
            let hasExistingConfig = Self.detectExistingConfiguration()
            self.hasCompletedSetup = hasExistingConfig
            if hasExistingConfig {
                UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
            }
        }
    }

    /// Check if there's already a valid API key in config file or config.ini
    private static func detectExistingConfiguration() -> Bool {
        // Check ~/.mailmateai/config.json first
        if let apiKey = KeychainManager.apiKey, !apiKey.isEmpty {
            return true
        }

        // Check config.ini in the installed bundle location
        let configPath = ("~/Library/Application Support/MailMate/Bundles/AIAssistant.mmbundle/Support/bin/config.ini" as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: configPath) {
            // Try to read and check if it has an API key
            if let contents = try? String(contentsOfFile: configPath, encoding: .utf8) {
                // Check if there's a non-placeholder API key
                if contents.contains("ApiKey") &&
                   !contents.contains("YOUR_") &&
                   !contents.contains("YOUR_API_KEY") {
                    return true
                }
            }
        }

        return false
    }

    func setProcessing(_ processing: Bool) {
        isProcessing = processing
    }

    func setError(_ error: AppError?) {
        lastError = error
    }

    func completeSetup() {
        hasCompletedSetup = true
        UserDefaults.standard.set(true, forKey: "hasCompletedSetup")
    }
}

struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let suggestion: String
}
