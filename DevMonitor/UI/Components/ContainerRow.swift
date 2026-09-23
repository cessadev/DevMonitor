import SwiftUI

struct ContainerRow: View {
    let container: DockerContainer
    let isLocked: Bool
    let isDeleteLocked: Bool
    let onToggle: () async -> Void
    let onDelete: () async -> Void
    let onOpenTerminal: () -> Void

    @State private var isLoading = false
    @State private var isDeleting = false
    @State private var isHovered = false
    @State private var confirmDelete = false
    @State private var pendingIsOn: Bool? = nil

    private var runningBinding: Binding<Bool> {
        Binding(
            get: { pendingIsOn ?? container.isRunning },
            set: { newValue in
                guard !isLocked else { return }
                pendingIsOn = newValue
                isLoading = true
                Task {
                    await onToggle()
                    isLoading = false
                    pendingIsOn = nil
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            Image("container-icon")
                .resizable()
                .scaledToFit()
                .frame(width: AppIcon.rowIcon, height: AppIcon.rowIcon)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(container.displayName)
                    .font(AppFont.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(container.image)
                    .font(AppFont.metadata)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(-1)

            // Trailing controls group
            HStack(spacing: 6) {
                if isHovered || confirmDelete {
                    if confirmDelete {
                        Button {
                            isDeleting = true
                            Task {
                                await onDelete()
                                isDeleting    = false
                                confirmDelete = false
                            }
                        } label: {
                            if isDeleting {
                                ProgressView().controlSize(AppControl.switchControlSize)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                            } else {
                                Text("Delete")
                                    .font(AppFont.micro)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                            }
                        }
                        .buttonStyle(CapsuleButtonStyle(tint: .destructive))
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    } else {
                        // Terminal
                        if container.isRunning {
                            Button {
                                onOpenTerminal()
                            } label: {
                                Image("terminal-icon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: AppIcon.terminalIcon, height: AppIcon.terminalIcon)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 7)
                                    .padding(.top, 3)
                                    .padding(.bottom, 3)
                            }
                            .buttonStyle(CapsuleButtonStyle(tint: .neutral))
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                        }
                        // Trash
                        if !isLocked && !isDeleteLocked {
                            Button {
                                withAnimation(.spring(duration: 0.2)) {
                                    confirmDelete = true
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(AppIcon.trashIcon)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 7)
                                    .padding(.top, 3)
                                    .padding(.bottom, 4)
                            }
                            .buttonStyle(CapsuleButtonStyle(tint: .neutral))
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                        }
                    }
                }

                // Switch
                Toggle("", isOn: runningBinding)
                    .toggleStyle(.switch)
                    .controlSize(AppControl.switchControlSize)
                    .disabled(isLoading || isDeleting || isLocked)
                    .opacity(isLoading || isLocked ? 0.4 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                    .animation(.easeInOut(duration: 0.2), value: isLocked)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
                if !hovered && !isDeleting { confirmDelete = false }
            }
        }
    }
}
