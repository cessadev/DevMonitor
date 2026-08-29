import SwiftUI

struct ImageRow: View {
    let image: DockerImage
    let onDelete: () async -> Void

    @State private var isDeleting   = false
    @State private var isHovered    = false
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
                HStack(spacing: 6) {
                    Text(image.shortId)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(image.displaySize)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text(image.displayAge)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(-1)

            // Hover actions
            if isHovered || confirmDelete {
                if confirmDelete {
                    HStack(spacing: 4) {
                        Button {
                            isDeleting = true
                            Task {
                                await onDelete()
                                isDeleting   = false
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
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            confirmDelete = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
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
