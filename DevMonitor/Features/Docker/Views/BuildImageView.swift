import SwiftUI

struct BuildImageView: View {

    @Bindable var vm: BuildViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Directory picker
            FormSection(title: "Dockerfile Directory") {
                HStack(spacing: 8) {
                    Text(vm.contextPath.isEmpty ? "No directory selected" : vm.contextPath)
                        .font(.system(size: 11))
                        .foregroundStyle(vm.contextPath.isEmpty ? .tertiary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        Task { await vm.selectDirectory() }
                    } label: {
                        Text("Browse")
                            .font(.system(size: 11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(CapsuleButtonStyle())
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.30))
                        .strokeBorder(.white.opacity(0.65), lineWidth: 0.5)
                )
            }

            // Image name
            FormSection(title: "Image Name") {
                TextField(
                    "",
                    text: $vm.imageName,
                    prompt: Text("e.g. my-app:latest").foregroundStyle(.tertiary)
                )
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .disabled(vm.isBuilding)
                .onSubmit {
                    Task { await vm.build() }
                }
                .onChange(of: vm.imageName) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if vm.formError != nil { vm.formError = nil }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.30))
                        .strokeBorder(.white.opacity(0.65), lineWidth: 0.5)
                )
            }

            // Error
            if let error = vm.formError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 2)
                    .transition(.opacity)
            }

            // Build output
            if vm.isBuilding || !vm.buildOutput.isEmpty {
                ScrollView {
                    Text(vm.buildOutput.isEmpty ? "Building..." : vm.buildOutput)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(6)
                }
                .frame(maxHeight: 80)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.black.opacity(0.12))
                )
                .transition(.opacity)
            }

            // Success message
            if vm.buildSuccess {
                Label("Image built successfully", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }

            // Build button
            HStack {
                Spacer()
                Button {
                    Task { await vm.build() }
                } label: {
                    Group {
                        if vm.isBuilding {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(.mini)
                                Text("Building...")
                            }
                        } else {
                            Text(vm.buildSuccess ? "Build Again" : "Build Image")
                        }
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                .buttonStyle(CapsuleButtonStyle(isDisabled: vm.isBuilding))
                .disabled(vm.isBuilding)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
        .transition(.opacity)
    }
}
