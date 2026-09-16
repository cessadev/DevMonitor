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
            Image("imagen-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(isSelected ? .primary : .secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(image.displayTag)
                    .font(AppFont.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack(spacing: 4) {
                    Text(image.shortId)
                    Text("·")
                    Text(image.displaySize)
                    Text("·")
                    Text(image.displayAge)
                }
                .font(AppFont.metadata)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(-1)

            // Action area
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
                    HStack(spacing: 16) {
                        if !isSelected {
                            // Trash
                            Button {
                                withAnimation(.spring(duration: 0.2)) {
                                    confirmDelete = true
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(AppFont.bodyMedium)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                            }
                            .buttonStyle(CapsuleButtonStyle(tint: .neutral))
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                            .padding(.horizontal, 3)
                        }
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
