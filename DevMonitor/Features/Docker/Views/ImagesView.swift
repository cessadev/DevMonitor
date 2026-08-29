import SwiftUI

struct ImagesView: View {

    let images: [DockerImage]
    let onDelete: (DockerImage) async -> Void
    let onCreateContainer: (DockerImage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(title: "Docker Images")
                .padding(.bottom, 1)

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
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
