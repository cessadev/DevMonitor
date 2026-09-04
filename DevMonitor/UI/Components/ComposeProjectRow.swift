import SwiftUI

struct ComposeProjectRow: View {
    let project: DockerComposeProject
    let isLoading: Bool
    let onUp: () async -> Void
    let onDown: () async -> Void
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {

            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(project.displayName)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(-1)

            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 32, height: 24)
            } else if isHovered {
                // On hover
                HStack(spacing: 6) {
                    // Up
                    Button {
                        Task { await onUp() }
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.12))
                            .strokeBorder(.green.opacity(0.25), lineWidth: 0.5)
                    )

                    // Down
                    Button {
                        Task { await onDown() }
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(.red.opacity(0.08))
                            .strokeBorder(.red.opacity(0.25), lineWidth: 0.5)
                    )

                    // Remove
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.08))
                            .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                    )
                }
                .frame(height: 24)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            } else {
                ComposeBadge(status: project.overallStatus)
                    .frame(height: 24)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
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
