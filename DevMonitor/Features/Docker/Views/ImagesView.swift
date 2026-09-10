import SwiftUI

struct ImagesView: View {

    let images: [DockerImage]
    let count: Int
    let isExpanded: Bool
    let pullExpanded: Bool
    let pullImageName: Binding<String>
    let isPulling: Bool
    let pullProgress: String
    let onHeaderTap: () -> Void
    let onPullHeaderTap: () -> Void
    let onPull: () -> Void
    let onDelete: (DockerImage) async -> Void
    let onCreateContainer: (DockerImage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // Header
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

            if isExpanded {
                if !images.isEmpty {
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

                // Pull Image section
                PullImageHeader(
                    isExpanded: pullExpanded,
                    onTap: {
                        withAnimation(.spring(duration: 0.3)) {
                            onPullHeaderTap()
                        }
                    }
                )

                if pullExpanded {
                    PullImageView(
                        imageName: pullImageName,
                        isPulling: isPulling,
                        progress: pullProgress,
                        onPull: onPull
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}

// MARK: - Pull Image Header

private struct PullImageHeader: View {
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("PULL IMAGE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 3)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.spring(duration: 0.3), value: isExpanded)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 3)
    }
}

// MARK: - Pull Image View

private struct PullImageView: View {
    @Binding var imageName: String
    let isPulling: Bool
    let progress: String
    let onPull: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 8) {
                TextField("e.g. nginx:latest", text: $imageName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .disabled(isPulling)
                    .onSubmit { onPull() }

                Text(isPulling ? "Pulling..." : "Enter")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.30))
                    .strokeBorder(.white.opacity(0.65), lineWidth: 0.5)
            )
            .padding(.horizontal, 4)

            // Progress
            if !progress.isEmpty {
                Text(progress)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 6)
        .transition(.opacity)
    }
}
