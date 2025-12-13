import Foundation

/// Stores configuration in ~/.mailmateai/config.json
struct KeychainManager {
    private static let configDir = ("~/.mailmateai" as NSString).expandingTildeInPath
    private static let configFile = ("~/.mailmateai/config.json" as NSString).expandingTildeInPath

    private struct Config: Codable {
        var apiKey: String?
        var provider: String?
        var model: String?
        var customPrompt: String?
    }

    private static func loadConfig() -> Config {
        guard FileManager.default.fileExists(atPath: configFile),
              let data = try? Data(contentsOf: URL(fileURLWithPath: configFile)),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return Config()
        }
        return config
    }

    private static func saveConfig(_ config: Config) throws {
        // Create directory if needed
        if !FileManager.default.fileExists(atPath: configDir) {
            try FileManager.default.createDirectory(atPath: configDir, withIntermediateDirectories: true)
        }

        let data = try JSONEncoder().encode(config)
        try data.write(to: URL(fileURLWithPath: configFile))
    }

    // MARK: - Public API (same interface as before)

    static var apiKey: String? {
        loadConfig().apiKey
    }

    static func setApiKey(_ value: String) throws {
        var config = loadConfig()
        config.apiKey = value
        try saveConfig(config)
    }

    static var provider: String? {
        loadConfig().provider
    }

    static func setProvider(_ value: String) throws {
        var config = loadConfig()
        config.provider = value
        try saveConfig(config)
    }

    static var model: String? {
        loadConfig().model
    }

    static func setModel(_ value: String) throws {
        var config = loadConfig()
        config.model = value
        try saveConfig(config)
    }

    static var customPrompt: String? {
        loadConfig().customPrompt
    }

    static func setCustomPrompt(_ value: String) throws {
        var config = loadConfig()
        config.customPrompt = value.isEmpty ? nil : value
        try saveConfig(config)
    }

    static let defaultPrompt = """
Your task is to rewrite email text so it is clearer, more concise, and more professional, while maintaining the original message and intent.

Guidelines:
- Use simple, direct language
- Ensure a professionally friendly tone
- Use active voice where appropriate
- Remove unnecessary repetition
- Correct any grammar or spelling errors

Output ONLY the revised email text, nothing else.
"""
}
