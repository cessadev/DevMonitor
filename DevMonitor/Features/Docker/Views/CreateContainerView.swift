import SwiftUI

struct CreateContainerView: View {

    let imageName: String
    let onCreate: (String, [String], [String], String) async -> (success: Bool, validationError: String?)
    let onDismiss: () -> Void

    @State private var containerName            = ""
    @State private var portBindings: [String]   = [""]
    @State private var envVars: [String]        = [""]
    @State private var restartPolicy            = RestartPolicy.no
    @State private var isCreating               = false
    @State private var validationError: String? = nil

    enum RestartPolicy: String, CaseIterable, Identifiable {
        case no            = "no"
        case always        = "always"
        case unlessStopped = "unless-stopped"
        case onFailure     = "on-failure"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .no:            return "No"
            case .always:        return "Always"
            case .unlessStopped: return "Unless Stopped"
            case .onFailure:     return "On Failure"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            
            VStack(alignment: .leading, spacing: 16) {

                // Container name
                FormSection(title: "Container Name") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(
                            "",
                            text: $containerName,
                            prompt: Text("e.g. my-nginx").foregroundStyle(.tertiary)
                        )
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(0.30))
                                .strokeBorder(.white.opacity(0.65), lineWidth: 0.5)
                        )
                        .disabled(isCreating)
                        .onChange(of: containerName) {
                            if validationError != nil { validationError = nil }
                        }

                        if let error = validationError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 2)
                        }
                    }
                }

                // Port bindings
                FormSection(title: "Port Bindings (host:container)") {
                    VStack(spacing: 4) {
                        ForEach(portBindings.indices, id: \.self) { index in
                            HStack(spacing: 6) {
                                TextField(
                                    "",
                                    text: $portBindings[index],
                                    prompt: Text("e.g. 8080:80").foregroundStyle(.tertiary)
                                )
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white.opacity(0.30))
                                        .strokeBorder(.white.opacity(0.65), lineWidth: 0.5)
                                )
                                .disabled(isCreating)

                                if portBindings.count > 1 {
                                    Button {
                                        portBindings.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red.opacity(0.7))
                                            .font(.system(size: 12))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isCreating)
                                }
                            }
                        }

                        Button {
                            portBindings.append("")
                        } label: {
                            Label("Add Port", systemImage: "plus.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isCreating)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Environment variables
                FormSection(title: "Environment Variables") {
                    VStack(spacing: 4) {
                        ForEach(envVars.indices, id: \.self) { index in
                            HStack(spacing: 6) {
                                TextField(
                                    "",
                                    text: $envVars[index],
                                    prompt: Text("e.g. DEBUG=true").foregroundStyle(.tertiary)
                                )
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(.white.opacity(0.30))
                                        .strokeBorder(.white.opacity(0.65), lineWidth: 0.5)
                                )
                                .disabled(isCreating)

                                if envVars.count > 1 {
                                    Button {
                                        envVars.remove(at: index)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red.opacity(0.7))
                                            .font(.system(size: 12))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isCreating)
                                }
                            }
                        }

                        Button {
                            envVars.append("")
                        } label: {
                            Label("Add Variable", systemImage: "plus.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isCreating)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Restart policy
                FormSection(title: "Restart Policy") {
                    HStack(spacing: 6) {
                        ForEach(RestartPolicy.allCases) { policy in
                            let isActive = restartPolicy == policy
                            Button {
                                restartPolicy = policy
                            } label: {
                                Text(policy.label)
                                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                                    .foregroundStyle(isActive ? .primary : .secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isActive ? .white.opacity(0.2) : .clear)
                                            .strokeBorder(
                                                isActive ? .white.opacity(0.35) : .white.opacity(0.1),
                                                lineWidth: 0.5
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(isCreating)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 12)

            Divider()
                .padding(.top, 4)

            // Footer
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 12))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.18))
                        .strokeBorder(.white.opacity(0.45), lineWidth: 0.5)
                )
                .keyboardShortcut(.escape)
                .disabled(isCreating)

                Spacer()

                Button {
                    submit()
                } label: {
                    Group {
                        if isCreating {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.mini)
                                Text("Creating...")
                            }
                        } else {
                            Text("Create Container")
                        }
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .background(
                    Capsule()
                        .fill(.white.opacity(isCreating || containerName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.08 : 0.18))
                        .strokeBorder(.white.opacity(isCreating || containerName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.2 : 0.45), lineWidth: 0.5)
                )
                .keyboardShortcut(.return)
                .disabled(isCreating || containerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
    }

    private func submit() {
        isCreating = true
        Task {
            let result = await onCreate(
                containerName,
                portBindings.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                envVars.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                restartPolicy.rawValue
            )
            isCreating = false
            if result.success {
                onDismiss()
            } else if let msg = result.validationError {
                validationError = msg
            }
        }
    }
}

// MARK: - FormSection

private struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
            content()
        }
    }
}
