import SwiftUI

struct ContainerRow: View {
    let container: DockerContainer
    let isLocked: Bool
    let onToggle: () async -> Void
    let onDelete: () async -> Void

    @State private var isLoading = false
    @State private var isDeleting = false
    @State private var isHovered = false
    @State private var confirmDelete = false
    @State private var isOn: Bool

    init(container: DockerContainer,
         isLocked: Bool,
         onToggle: @escaping () async -> Void,
         onDelete: @escaping () async -> Void) {
        self.container = container
        self.isLocked  = isLocked
        self.onToggle  = onToggle
        self.onDelete  = onDelete
        self._isOn     = State(initialValue: container.isRunning)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image("container-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(container.displayName)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(container.image)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(-1)

            // Trash icon - hidden and blocked when compose is stopping
            if isHovered || confirmDelete {
                if confirmDelete {
                    HStack(spacing: 4) {
                        Button {
                            isDeleting = true
                            Task {
                                await onDelete()
                                isDeleting    = false
                                confirmDelete = false
                            }
                        } label: {
                            if isDeleting {
                                ProgressView().controlSize(.mini)
                            } else {
                                Text("Delete")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.red)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Capsule())
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.red.opacity(0.08))
                            .strokeBorder(.red.opacity(0.25), lineWidth: 0.5)
                    )
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                } else {
                    // Trash button
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            confirmDelete = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }

            // Toggle switch - disabled and dimmed when compose is stopping
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .disabled(isLoading || isDeleting || isLocked)
                .opacity(isLoading || isLocked ? 0.4 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isLoading)
                .animation(.easeInOut(duration: 0.2), value: isLocked)
                .onChange(of: isOn) { _, _ in
                    guard !isLocked else { return }
                    isLoading = true
                    Task {
                        await onToggle()
                        isLoading = false
                    }
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
                if !hovered && !isDeleting { confirmDelete = false }
            }
        }
        .onChange(of: container.isRunning) { _, newValue in
            isOn = newValue
        }
    }
}
