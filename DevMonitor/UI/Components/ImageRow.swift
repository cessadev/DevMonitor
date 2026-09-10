import SwiftUI

struct ImageRow: View {
    let image: DockerImage
    let isSelected: Bool
    let onDelete: () async -> Void
    let onSelect: () -> Void

    @State private var isDeleting    = false
    @State private var isHovered     = false
    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.stack")
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? .primary : .secondary)
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

            // Action area
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
                    HStack(spacing: 16) {
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
                        .contentShape(Rectangle())
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .padding(.horizontal, 7)
                    }
                }
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !confirmDelete else { return }
            withAnimation(.spring(duration: 0.3)) {
                onSelect()
            }
        }
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
                if !hovered && !isDeleting { confirmDelete = false }
            }
        }
    }
}
