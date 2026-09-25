import SwiftUI

struct ComposeProjectRow: View {
    let project: DockerComposeProject
    let isLoading: Bool
    let onUp: () async -> Void
    let onDown: () async -> Void
    let onRemove: () -> Void

    @State private var isHovered = false
    @State private var confirmDelete = false
    @State private var pendingIsOn: Bool? = nil

    private var runningBinding: Binding<Bool> {
        Binding(
            get: { pendingIsOn ?? (project.overallStatus == .running) },
            set: { newValue in
                pendingIsOn = newValue
                Task {
                    if newValue {
                        await onUp()
                    } else {
                        await onDown()
                    }
                    pendingIsOn = nil
                }
            }
        )
    }

    var body: some View {
        HStack(spacing: 10) {
            Image("compose-icon")
                .resizable()
                .scaledToFit()
                .frame(width: AppIcon.rowIcon, height: AppIcon.rowIcon)
                .foregroundStyle(.secondary)

            Text(project.displayName)
                .font(AppFont.body)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(-1)

            if confirmDelete || isHovered {
                HStack(spacing: 6) {
                    if confirmDelete {
                        // Delete confirmation
                        Button {
                            onRemove()
                        } label: {
                            Text("Delete")
                                .font(AppFont.micro)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                        }
                        .buttonStyle(CapsuleButtonStyle(tint: .destructive))
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    } else {
                        // Remove
                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                confirmDelete = true
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(AppIcon.trashIcon)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                        }
                        .buttonStyle(CapsuleButtonStyle(tint: .neutral))
                        .disabled(isLoading)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }

                    // Switch
                    Toggle("", isOn: runningBinding)
                        .toggleStyle(.switch)
                        .controlSize(AppControl.switchControlSize)
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.4 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isLoading)
                }
                .frame(height: 24)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                ComposeBadge(status: project.overallStatus)
                    .frame(height: 24)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
                if !hovered { confirmDelete = false }
            }
        }
    }
}

// MARK: - Compose Status Badge

private struct ComposeBadge: View {
    let status: DockerComposeProject.ComposeServiceStatus

    var color: Color {
        switch status {
        case .running: return .green
        case .stopped: return .red
        case .partial: return .orange
        }
    }

    var label: String {
        switch status {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .partial: return "Partial"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(status == .stopped ? 0.8 : 1.0))
                .frame(width: AppIcon.composeDot, height: AppIcon.composeDot)
                .shadow(color: status == .running ? color.opacity(0.6) : .clear, radius: 3)
            Text(label)
                .font(AppFont.statusCompose)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(.white.opacity(0.12))
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
        )
    }
}
