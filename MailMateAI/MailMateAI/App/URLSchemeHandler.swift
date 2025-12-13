import Foundation
import AppKit
import UserNotifications

@MainActor
class URLSchemeHandler: ObservableObject {
    weak var appState: AppState?

    func handle(url: URL) {
        guard url.scheme == "mailmate-ai",
              url.host == "status" else { return }

        let status = url.pathComponents.dropFirst().first
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        let message = queryItems?.first(where: { $0.name == "message" })?.value

        switch status {
        case "started":
            appState?.setProcessing(true)
            // Dismiss any open windows when processing starts
            NSApp.windows.filter { $0.title == "Setup" }.forEach { $0.close() }

        case "finished":
            appState?.setProcessing(false)
            appState?.setError(nil)
            showNotification(title: "Draft Ready", body: "Check MailMate for your new draft")

        case "error":
            appState?.setProcessing(false)
            let errorInfo = parseError(message: message)
            appState?.setError(errorInfo)
            showNotification(title: "Failed to Generate Draft", body: "Click for details")

        default:
            break
        }
    }

    private func parseError(message: String?) -> AppError {
        guard let message = message else {
            return AppError(
                title: "Unknown Error",
                message: "An unknown error occurred",
                suggestion: "Try again or check the logs"
            )
        }

        // Parse common error patterns
        if message.contains("401") || message.lowercased().contains("invalid api key") {
            return AppError(
                title: "Authentication Failed",
                message: "The API returned error 401: Invalid API key",
                suggestion: "Check that your API key is correct in Settings."
            )
        } else if message.contains("429") || message.lowercased().contains("rate limit") {
            return AppError(
                title: "Rate Limited",
                message: "Too many requests to the API",
                suggestion: "Wait a moment and try again."
            )
        } else if message.contains("500") || message.contains("502") || message.contains("503") {
            return AppError(
                title: "API Unavailable",
                message: "The API service is temporarily unavailable",
                suggestion: "Try again in a few minutes."
            )
        } else if message.lowercased().contains("network") || message.lowercased().contains("connection") {
            return AppError(
                title: "Connection Failed",
                message: "Could not connect to the API",
                suggestion: "Check your internet connection."
            )
        } else if message.lowercased().contains("timeout") {
            return AppError(
                title: "Request Timed Out",
                message: "The API request took too long",
                suggestion: "Try again - the service may be slow."
            )
        }

        return AppError(
            title: "Error",
            message: message,
            suggestion: "Check the error details and try again."
        )
    }

    private func showNotification(title: String, body: String) {
        guard SettingsManager.shared.showNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
