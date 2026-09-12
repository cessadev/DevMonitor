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
    @State private var portError: String?       = nil

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
                                .onChange(of: portBindings[index]) { _, _ in
                                    if portError != nil { portError = nil }
                                }

                                if portBindings.count > 1 {
                                    Button {
                                        let i = index
                                        _ = withAnimation(.easeOut(duration: 0.2)) {
                                            portBindings.remove(at: i)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red.opacity(0.7))
                                            .font(.system(size: 12))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isCreating)
                                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        if let error = portError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .transition(.opacity)
                        }

                        Button {
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                portBindings.append("")
                            }
                        } label: {
                            Label("Add Port", systemImage: "plus.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isCreating)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
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
                                        let i = index
                                        _ = withAnimation(.easeOut(duration: 0.2)) {
                                            envVars.remove(at: i)
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red.opacity(0.7))
                                            .font(.system(size: 12))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isCreating)
                                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Button {
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                envVars.append("")
                            }
                        } label: {
                            Label("Add Variable", systemImage: "plus.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isCreating)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }
                }

                // Restart policy
                FormSection(title: "Restart Policy") {
                    HStack(spacing: 6) {
                        ForEach(RestartPolicy.allCases) { policy in
                            let isActive = restartPolicy == policy
                            Button {
                                withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                                    restartPolicy = policy
                                }
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
                            .buttonStyle(RestartPolicyButtonStyle())
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
                }
                .buttonStyle(CapsuleButtonStyle())
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
                }
                .buttonStyle(CapsuleButtonStyle(
                    isDisabled: isCreating || containerName.trimmingCharacters(in: .whitespaces).isEmpty
                ))
                .keyboardShortcut(.return)
                .disabled(isCreating || containerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
    }

    private func submit() {
        let filledPorts = portBindings.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        for port in filledPorts {
            if !isValidPortBinding(port) {
                withAnimation(.easeOut(duration: 0.2)) {
                    portError = "Invalid format. Use host:container"
                }
                return
            }
        }

        portError  = nil
        isCreating = true
        Task {
            let result = await onCreate(
                containerName,
                filledPorts,
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
    
    private func isValidPortBinding(_ binding: String) -> Bool {
        // Accepts: "8080:80", "127.0.0.1:8080:80", "8080:80/tcp", "8080:80/udp"
        let parts = binding.split(separator: ":").map(String.init)

        guard parts.count == 2 || parts.count == 3 else { return false }

        let hostPort      = parts[parts.count - 2]
        let containerPart = parts[parts.count - 1]

        // Container port may have protocol suffix: "80/tcp"
        let containerPort = containerPart.split(separator: "/").first.map(String.init) ?? containerPart

        guard let host = Int(hostPort), host > 0 && host <= 65535 else { return false }
        guard let container = Int(containerPort), container > 0 && container <= 65535 else { return false }

        return true
    }
}

// MARK: - Restart Policy Button Style

private struct RestartPolicyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
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
