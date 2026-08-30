import SwiftUI

struct ImageRow: View {
    let image: DockerImage
    let onDelete: () async -> Void
    let onCreateContainer: () -> Void

    @State private var isDeleting    = false
    @State private var isHovered     = false
    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.stack")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(image.displayTag)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: 4) {
                    Text(image.shortId)
                    Text("·")
                    Text(image.displaySize)
                    Text("·")
                    Text(image.displayAge)
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(-1)

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
                    HStack(spacing: 8) {
                        // Trash
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
                        .transition(.scale(scale: 0.85).combined(with: .opacity))

                        // Container icon
                        Button {
                            onCreateContainer()
                        } label: {
                            Image("container-icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .opacity(0.5)
                        }
                        .buttonStyle(.plain)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
                if !hovered { confirmDelete = false }
            }
        }
    }
}
