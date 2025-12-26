import Foundation

enum BundleInstallerError: Error, LocalizedError {
    case bundleNotFound
    case installationFailed(String)
    case mailmateNotInstalled

    var errorDescription: String? {
        switch self {
        case .bundleNotFound:
            return "Could not find the AIAssistant bundle in app resources"
        case .installationFailed(let reason):
            return "Failed to install bundle: \(reason)"
        case .mailmateNotInstalled:
            return "MailMate does not appear to be installed"
        }
    }
}

struct BundleInstaller {
    static let bundleName = "AIAssistant.mmbundle"
    static let mailmateBundlesPath = "~/Library/Application Support/MailMate/Bundles"
        .expandingTildeInPath

    static var installedBundlePath: String {
        (mailmateBundlesPath as NSString).appendingPathComponent(bundleName)
    }

    static var isBundleInstalled: Bool {
        FileManager.default.fileExists(atPath: installedBundlePath)
    }

    static var bundleVersion: String? {
        let plistPath = (installedBundlePath as NSString).appendingPathComponent("info.plist")
        guard let plist = NSDictionary(contentsOfFile: plistPath),
            let version = plist["CFBundleVersion"] as? String
        else {
            return nil
        }
        return version
    }

    static func install() throws {
        // Find bundle in app resources
        guard let sourcePath = Bundle.main.path(forResource: "GPTAssistant", ofType: "mmbundle")
        else {
            throw BundleInstallerError.bundleNotFound
        }

        let fileManager = FileManager.default

        // Create MailMate Bundles directory if needed
        if !fileManager.fileExists(atPath: mailmateBundlesPath) {
            do {
                try fileManager.createDirectory(
                    atPath: mailmateBundlesPath,
                    withIntermediateDirectories: true
                )
            } catch {
                throw BundleInstallerError.installationFailed("Could not create Bundles directory")
            }
        }

        // Remove existing bundle if present
        if fileManager.fileExists(atPath: installedBundlePath) {
            do {
                try fileManager.removeItem(atPath: installedBundlePath)
            } catch {
                throw BundleInstallerError.installationFailed("Could not remove existing bundle")
            }
        }

        // Copy new bundle
        do {
            try fileManager.copyItem(atPath: sourcePath, toPath: installedBundlePath)
        } catch {
            throw BundleInstallerError.installationFailed(error.localizedDescription)
        }
    }

    static func uninstall() throws {
        guard FileManager.default.fileExists(atPath: installedBundlePath) else { return }
        try FileManager.default.removeItem(atPath: installedBundlePath)
    }
}

extension String {
    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }
}
