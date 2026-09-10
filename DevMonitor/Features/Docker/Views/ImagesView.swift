import SwiftUI

struct ImagesView: View {

    let images: [DockerImage]
    let count: Int
    let isExpanded: Bool
    let onHeaderTap: () -> Void
    let onDelete: (DockerImage) async -> Void
    let onCreateContainer: (DockerImage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: onHeaderTap) {
                HStack {
                    SectionLabel(title: "Docker Images")

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(count)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.12))
                                    .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                            )

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .animation(.spring(duration: 0.3), value: isExpanded)
                    }
                    .padding(.horizontal, 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded && !images.isEmpty {
                VStack(spacing: 2) {
                    ForEach(images) { image in
                        ImageRow(
                            image: image,
                            onDelete: { await onDelete(image) },
                            onCreateContainer: { onCreateContainer(image) }
                        )
                    }
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}
