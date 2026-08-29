import SwiftUI

struct CreateContainerSheet: View {

    let imageName: String
    let onCancel: () -> Void
    let onCreate: (String) async -> Bool

    @State private var containerName = ""
    @State private var isCreating    = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Header
            HStack(spacing: 8) {
                Image("container-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text("New Container")
                    .font(.system(size: 14, weight: .semibold))
            }

            // Image reference
            HStack(spacing: 4) {
                Text("Image:")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(imageName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Name input
            VStack(alignment: .leading, spacing: 6) {
                Text("Container name")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                TextField("e.g. my-nginx", text: $containerName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .disabled(isCreating)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white.opacity(0.18))
                            .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
                    )
                    .onSubmit { submit() }
            }

            // Actions
            HStack(spacing: 8) {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.12))
                        .strokeBorder(.white.opacity(0.30), lineWidth: 0.5)
                )
                .disabled(isCreating)
                .frame(minWidth: 70)
                .keyboardShortcut(.escape)

                Button {
                    submit()
                } label: {
                    if isCreating {
                        HStack(spacing: 4) {
                            ProgressView().controlSize(.mini)
                            Text("Creating...")
                                .font(.system(size: 12))
                        }
                    } else {
                        Text("Accept")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.22))
                        .strokeBorder(.white.opacity(0.45), lineWidth: 0.5)
                )
                .disabled(isCreating)
                .frame(minWidth: 70)
                .keyboardShortcut(.return)
            }
        }
        .padding(16)
        .frame(width: 280)
    }

    private func submit() {
        isCreating = true
        Task {
            let success = await onCreate(containerName)
            if success {
                onCancel()
            }
            isCreating = false
        }
    }
}
