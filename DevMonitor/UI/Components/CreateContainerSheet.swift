import SwiftUI

struct CreateContainerSheet: View {

    let imageName: String
    let onCancel: () -> Void
    let onCreate: (String, [String], [String], String) async -> (success: Bool, validationError: String?)

    // MARK: - Form state
    @State private var containerName            = ""
    @State private var portBindings: [String]   = [""]
    @State private var envVars: [String]        = [""]
    @State private var restartPolicy            = "no"
    @State private var isCreating               = false
    @State private var validationError: String? = nil

    private let restartOptions = ["no", "always", "unless-stopped", "on-failure"]

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

            // Container name
            FormField(label: "Container name") {
                TextField("e.g. my-nginx", text: $containerName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .disabled(isCreating)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(fieldBackground)
                    .onSubmit { submit() }
                    .onChange(of: containerName) {
                        if validationError != nil {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                validationError = nil
                            }
                        }
                    }
            }

            // Port bindings
            FormField(label: "Ports (host:container)") {
                DynamicFieldList(
                    entries: $portBindings,
                    placeholder: "e.g. 8080:80",
                    isDisabled: isCreating
                )
            }

            // Environment variables
            FormField(label: "Environment variables") {
                DynamicFieldList(
                    entries: $envVars,
                    placeholder: "e.g. DEBUG=true",
                    isDisabled: isCreating
                )
            }

            // Restart policy
            FormField(label: "Restart policy") {
                HStack(spacing: 0) {
                    ForEach(restartOptions, id: \.self) { option in
                        Button {
                            restartPolicy = option
                        } label: {
                            Text(option)
                                .font(.system(size: 10))
                                .foregroundStyle(restartPolicy == option ? .white : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            restartPolicy == option
                                ? RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accentColor.opacity(0.8))
                                : nil
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.10))
                        .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .animation(.easeInOut(duration: 0.15), value: restartPolicy)
            }

            // Validation error
            if let validationError {
                Text(validationError)
                    .font(.system(size: 11))
                    .foregroundStyle(.red.opacity(0.85))
                    .padding(.horizontal, 2)
                    .transition(.opacity)
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

    // MARK: - Helpers

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.white.opacity(0.18))
            .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
    }

    private func submit() {
        isCreating = true
        Task {
            let result = await onCreate(
                containerName,
                portBindings,
                envVars,
                restartPolicy
            )
            isCreating = false
            if result.success {
                onCancel()
            } else if let msg = result.validationError {
                withAnimation(.easeInOut(duration: 0.2)) {
                    validationError = msg
                }
            }
        }
    }
}

// MARK: - FormField wrapper

private struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            content()
        }
    }
}

// MARK: - Dynamic field list (ports / env vars)

private struct DynamicFieldList: View {
    @Binding var entries: [String]
    let placeholder: String
    let isDisabled: Bool

    var body: some View {
        VStack(spacing: 4) {
            ForEach(entries.indices, id: \.self) { index in
                HStack(spacing: 6) {
                    TextField(placeholder, text: $entries[index])
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .disabled(isDisabled)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.18))
                                .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
                        )

                    // Remove row — only show when more than one entry
                    if entries.count > 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                var updated = entries
                                updated.remove(at: index)
                                entries = updated
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isDisabled)
                    }
                }
            }

            // Add row
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        entries.append("")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 11))
                        Text("Add")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                Spacer()
            }
        }
    }
}
