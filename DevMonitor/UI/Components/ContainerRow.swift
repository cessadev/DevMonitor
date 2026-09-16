import SwiftUI

struct ContainerRow: View {
    let container: DockerContainer
    let isLocked: Bool
    let isDeleteLocked: Bool
    let onToggle: () async -> Void
    let onDelete: () async -> Void

    @State private var isLoading = false
    @State private var isDeleting = false
    @State private var isHovered = false
    @State private var confirmDelete = false
    @State private var isOn: Bool

    init(container: DockerContainer,
         isLocked: Bool,
         isDeleteLocked: Bool,
         onToggle: @escaping () async -> Void,
         onDelete: @escaping () async -> Void) {
        self.container      = container
        self.isLocked       = isLocked
        self.isDeleteLocked = isDeleteLocked
        self.onToggle       = onToggle
        self.onDelete       = onDelete
        self._isOn          = State(initialValue: container.isRunning)
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

            // Trash icon - hidden and blocked when compose is up and stopping
            if !isLocked && !isDeleteLocked && (isHovered || confirmDelete) {
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
                            ProgressView().controlSize(.mini)
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
                    // Trash button
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            confirmDelete = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(AppFont.bodyMedium)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.top, 3)
                            .padding(.bottom, 4)
                    }
                    .buttonStyle(CapsuleButtonStyle(tint: .neutral))
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
        .padding(.horizontal, 8)
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
