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

    @Environment(\.dismiss) private var dismiss

    enum RestartPolicy: String, CaseIterable, Identifiable {
        case no             = "no"
        case always         = "always"
        case unlessStopped  = "unless-stopped"
        case onFailure      = "on-failure"

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

            // Form
            Form {

                // Image
                Section {
                    LabeledContent("Image") {
                        Text(imageName)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                // Container name
                Section {
                    TextField("e.g. my-nginx", text: $containerName)
                        .disabled(isCreating)
                        .onChange(of: containerName) {
                            if validationError != nil {
                                validationError = nil
                            }
                        }
                } header: {
                    Text("Container Name")
                } footer: {
                    if let error = validationError {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                // Ports
                Section("Port Bindings (host:container)") {
                    ForEach(portBindings.indices, id: \.self) { index in
                        HStack {
                            TextField("e.g. 8080:80", text: $portBindings[index])
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
                    }
                    .disabled(isCreating)
                }

                // Environment variables
                Section("Environment Variables") {
                    ForEach(envVars.indices, id: \.self) { index in
                        HStack {
                            TextField("e.g. DEBUG=true", text: $envVars[index])
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
                    }
                    .disabled(isCreating)
                }

                // Restart policy
                Section("Restart Policy") {
                    Picker("Policy", selection: $restartPolicy) {
                        ForEach(RestartPolicy.allCases) { policy in
                            Text(policy.label).tag(policy)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .disabled(isCreating)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.visible)

            Divider()

            // Footer actions
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

    // MARK: - Actions

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
