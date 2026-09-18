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
    let buildExpanded: Bool
    let buildVM: BuildViewModel
    let onBuildHeaderTap: () -> Void
    let onCreateContainer: (DockerImage, String, [String], [String], String) async -> (success: Bool, validationError: String?)

    @State private var selectedImage: DockerImage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            // Header
            Button(action: onHeaderTap) {
                HStack {
                    SectionLabel(title: "Docker Images")

                    Spacer()

                    HStack(spacing: 6) {
                        Text("\(count)")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.12))
                                    .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                            )

                        Image(systemName: "chevron.right")
                            .font(AppFont.micro)
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .animation(.spring(duration: 0.3), value: isExpanded)
                    }
                    .padding(.horizontal, 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .transition(.opacity)

            if isExpanded {
                if !images.isEmpty {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 2)
                        ForEach(images) { image in
                            let isSelected = selectedImage?.id == image.id

                            if selectedImage == nil || isSelected {
                                ImageRow(
                                    image: image,
                                    isSelected: isSelected,
                                    onDelete: {
                                        await onDelete(image)
                                    },
                                    onSelect: {
                                        let index = images.firstIndex(where: { $0.id == image.id }) ?? 0
                                        let duration = min(0.2 + Double(index) * 0.035, 0.5)

                                        withAnimation(.easeOut(duration: duration)) {
                                            if isSelected {
                                                selectedImage = nil
                                            } else {
                                                selectedImage = image
                                            }
                                        }
                                    }
                                )
                                .transition(.opacity)

                                if isSelected {
                                    Divider()
                                        .padding(.horizontal, 8)

                                    CreateContainerView(
                                        imageName: image.displayTag,
                                        onCreate: { name, ports, envVars, restartPolicy in
                                            await onCreateContainer(image, name, ports, envVars, restartPolicy)
                                        },
                                        onDismiss: {
                                            let index = images.firstIndex(where: { $0.id == image.id }) ?? 0
                                            let duration = min(0.2 + Double(index) * 0.035, 0.5)

                                            withAnimation(.easeOut(duration: duration)) {
                                                selectedImage = nil
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 4)
                                    .padding(.bottom, 6)
                                    .transition(.opacity)
                                }
                            }
                        }
                        Spacer().frame(height: 4)
                    }
                    .animation(.spring(duration: 0.4, bounce: 0.1), value: images.count)
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity)
                }
                
                // Build Image collapsible
                if selectedImage == nil {
                    BuildImageHeader(
                        isExpanded: buildExpanded,
                        onTap: {
                            withAnimation(.spring(duration: 0.3)) {
                                onBuildHeaderTap()
                            }
                        }
                    )
                    .transition(.opacity)

                    if buildExpanded {
                        BuildImageView(vm: buildVM)
                            .transition(.opacity)
                    }
                }

                // Pull Image
                if selectedImage == nil {
                    PullImageHeader(
                        isExpanded: pullExpanded,
                        onTap: {
                            withAnimation(.spring(duration: 0.3)) {
                                onPullHeaderTap()
                            }
                        }
                    )
                    .transition(.opacity)

                    if pullExpanded {
                        PullImageView(
                            imageName: pullImageName,
                            isPulling: isPulling,
                            progress: pullProgress,
                            onPull: onPull
                        )
                        .transition(.opacity)
                    }
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
                    .font(AppFont.label)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AppFont.micro)
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
        VStack(alignment: .leading, spacing: 10) {

            TextField(
                "",
                text: $imageName,
                prompt: Text("e.g. nginx:latest").foregroundStyle(.tertiary)
            )
            .textFieldStyle(.plain)
            .font(AppFont.body)
            .disabled(isPulling)
            .onSubmit { onPull() }
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.30))
                    .strokeBorder(.white.opacity(0.65), lineWidth: 0.5)
            )

            if !progress.isEmpty {
                Text(progress)
                    .font(AppFont.metadata)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack {
                Spacer()
                Button {
                    onPull()
                } label: {
                    Group {
                        if isPulling {
                            HStack(spacing: 6) {
                                ProgressView().controlSize(AppControl.switchControlSize)
                                Text("Pulling...")
                            }
                        } else {
                            Text("Pull Image")
                        }
                    }
                    .font(AppFont.action)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                .buttonStyle(CapsuleButtonStyle(isDisabled: isPulling))
                .disabled(isPulling || imageName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
        .transition(.opacity)
    }
}

private struct BuildImageHeader: View {
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("BUILD IMAGE")
                    .font(AppFont.label)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 3)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(AppFont.micro)
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
