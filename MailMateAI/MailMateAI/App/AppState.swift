import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: AppError?
    @Published var hasCompletedSetup: Bool

    init() {
        self.hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedSetup")
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
