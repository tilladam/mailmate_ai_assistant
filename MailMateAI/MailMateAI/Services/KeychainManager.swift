import Foundation

/// Stores configuration in ~/.mailmateai/config.json
struct KeychainManager {
    private static let configDir = ("~/.mailmateai" as NSString).expandingTildeInPath
    private static let configFile = ("~/.mailmateai/config.json" as NSString).expandingTildeInPath

    private struct Config: Codable {
        var apiKey: String?
        var provider: String?
        var model: String?
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
}
