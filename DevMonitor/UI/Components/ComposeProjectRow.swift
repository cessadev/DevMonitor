import SwiftUI

struct ComposeProjectRow: View {
    let project: DockerComposeProject
    let isLoading: Bool
    let onUp: () async -> Void
    let onDown: () async -> Void
    let onRemove: () -> Void

    @State private var isHovered = false
    @State private var isOn: Bool

    init(project: DockerComposeProject,
         isLoading: Bool,
         onUp: @escaping () async -> Void,
         onDown: @escaping () async -> Void,
         onRemove: @escaping () -> Void) {
        self.project   = project
        self.isLoading = isLoading
        self.onUp      = onUp
        self.onDown    = onDown
        self.onRemove  = onRemove
        self._isOn     = State(initialValue: project.overallStatus == .running)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image("compose-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.secondary)

            Text(project.displayName)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(-1)

            if isHovered {
                HStack(spacing: 6) {
                    // Remove
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                    }
                    .buttonStyle(CapsuleButtonStyle(tint: .neutral))

                    // Switch
                    Toggle("", isOn: $isOn)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.4 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isLoading)
                        .onChange(of: isOn) { _, newValue in
                            Task {
                                if newValue {
                                    await onUp()
                                } else {
                                    await onDown()
                                }
                            }
                        }
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
            }
        }
        .onChange(of: project.overallStatus) { _, newStatus in
            isOn = newStatus == .running
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
                .frame(width: 6, height: 6)
                .shadow(color: status == .running ? color.opacity(0.6) : .clear, radius: 3)
            Text(label)
                .font(.system(size: 11))
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
