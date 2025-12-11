import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("MailMate AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Compose smarter emails with AI")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text("This app integrates Claude and GPT with MailMate's composer to help you write better emails faster.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            Spacer()

            Button("Get Started") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
                .frame(height: 40)
        }
    }
}
