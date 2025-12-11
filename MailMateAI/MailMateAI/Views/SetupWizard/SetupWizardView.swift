import SwiftUI

enum SetupStep: Int, CaseIterable {
    case welcome
    case configuration
    case completion
}

struct SetupWizardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var currentStep: SetupStep = .welcome
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(SetupStep.allCases, id: \.self) { step in
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            // Content
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeView(onContinue: { currentStep = .configuration })
                case .configuration:
                    ConfigurationView(
                        onBack: { currentStep = .welcome },
                        onContinue: { currentStep = .completion }
                    )
                case .completion:
                    CompletionView(onFinish: {
                        appState.completeSetup()
                        dismiss()
                    })
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 440, height: 380)
    }
}
