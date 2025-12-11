import SwiftUI

struct ErrorDetailView: View {
    let error: AppError
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Error Details")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Error info
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 8) {
                    Text(error.title)
                        .font(.headline)

                    Text(error.message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            // Suggestion
            VStack(alignment: .leading, spacing: 4) {
                Text("SUGGESTION")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(error.suggestion)
                    .font(.body)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            // Actions
            HStack {
                Button("Copy Error") {
                    let text = "\(error.title)\n\(error.message)"
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Open Settings") {
                    dismiss()
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 360, height: 280)
    }
}
