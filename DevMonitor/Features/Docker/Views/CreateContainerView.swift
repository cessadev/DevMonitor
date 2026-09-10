import SwiftUI

struct CreateContainerView: View {

    let imageName: String
    let onCreate: (String, [String], [String], String) async -> (success: Bool, validationError: String?)

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

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Image
                    FormSection(title: "Image") {
                        HStack {
                            Text(imageName)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    // Container name
                    FormSection(title: "Container Name") {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField(
                                "",
                                text: $containerName,
                                prompt: Text("e.g. my-nginx").foregroundStyle(.tertiary)
                            )
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
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
                        VStack(spacing: 6) {
                            ForEach(portBindings.indices, id: \.self) { index in
                                HStack(spacing: 6) {
                                    TextField(
                                        "",
                                        text: $portBindings[index],
                                        prompt: Text("e.g. 8080:80").foregroundStyle(.tertiary)
                                    )
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .disabled(isCreating)

                                    if portBindings.count > 1 {
                                        Button {
                                            portBindings.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
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
                                    .font(.callout)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                            .disabled(isCreating)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Environment variables
                    FormSection(title: "Environment Variables") {
                        VStack(spacing: 6) {
                            ForEach(envVars.indices, id: \.self) { index in
                                HStack(spacing: 6) {
                                    TextField(
                                        "",
                                        text: $envVars[index],
                                        prompt: Text("e.g. DEBUG=true").foregroundStyle(.tertiary)
                                    )
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .disabled(isCreating)

                                    if envVars.count > 1 {
                                        Button {
                                            envVars.remove(at: index)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
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
                                    .font(.callout)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.accentColor)
                            .disabled(isCreating)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Restart policy
                    FormSection(title: "Restart Policy") {
                        Picker("", selection: $restartPolicy) {
                            ForEach(RestartPolicy.allCases) { policy in
                                Text(policy.label).tag(policy)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .disabled(isCreating)
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    closeWindow()
                }
                .keyboardShortcut(.escape)
                .disabled(isCreating)

                Button {
                    submit()
                } label: {
                    if isCreating {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Creating...")
                        }
                    } else {
                        Text("Create Container")
                    }
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(isCreating || containerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
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
                closeWindow()
            } else if let msg = result.validationError {
                validationError = msg
            }
        }
    }

    private func closeWindow() {
        NSApplication.shared.keyWindow?.close()
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
