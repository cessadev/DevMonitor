import SwiftUI
import Combine

struct ContentView: View {

    @State private var servicesVM      = ServicesViewModel()
    @State private var containersVM    = ContainersViewModel()
    @State private var imagesVM        = ImagesViewModel()
    @State private var isVisible       = false
    @State private var dockerExpanded  = false
    @State private var imagesExpanded  = false
    @State private var pullExpanded    = false
    @State private var pullImageName   = ""
    @State private var showCreateContainer = false
    @State private var selectedImage: DockerImage? = nil
    private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private func dismissModal() {
        guard showCreateContainer else { return }
        withAnimation(.spring(duration: 0.25)) {
            showCreateContainer = false
            selectedImage       = nil
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack(spacing: 8) {
                    Text("DevMonitor")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Local Services
                ServicesView(
                    services: servicesVM.services,
                    dockerExpanded: dockerExpanded,
                    onDockerTap: { dockerExpanded.toggle() }
                )

                // Docker subsections — solo visibles si Docker está expandido
                if dockerExpanded {

                    // Containers
                    if !containersVM.containers.isEmpty {
                        ContainersView(
                            containers: containersVM.containers,
                            onToggle: { container in await containersVM.toggle(container) },
                            onDelete: { container in await containersVM.delete(container) }
                        )
                    }

                    // Images header colapsable
                    ImagesHeader(
                        count: imagesVM.images.count,
                        isExpanded: imagesExpanded,
                        onTap: {
                            withAnimation(.spring(duration: 0.3)) {
                                imagesExpanded.toggle()
                            }
                        }
                    )

                    if imagesExpanded && !imagesVM.images.isEmpty {
                        ImagesView(
                            images: imagesVM.images,
                            onDelete: { image in await imagesVM.delete(image) },
                            onCreateContainer: { image in
                                selectedImage = image
                                withAnimation(.spring(duration: 0.25)) {
                                    showCreateContainer = true
                                }
                            }
                        )
                    }
                    
                    // Pull Image header
                    PullImageHeader(
                        isExpanded: pullExpanded,
                        onTap: {
                            withAnimation(.spring(duration: 0.3)) {
                                pullExpanded.toggle()
                            }
                        }
                    )

                    // Pull Image form
                    if pullExpanded {
                        PullImageView(
                            imageName: $pullImageName,
                            isPulling: imagesVM.isPulling,
                            progress: imagesVM.pullProgress,
                            onPull: {
                                Task { await imagesVM.pull(name: pullImageName) }
                            }
                        )
                    }
                }

                // Error
                if let error = containersVM.error ?? imagesVM.error {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }

                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("Refreshes every 5s")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                    .keyboardShortcut("q")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .disabled(showCreateContainer)
            
            if showCreateContainer {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissModal()
                    }
            }
            
            if showCreateContainer, let image = selectedImage {
                ZStack {
                    CreateContainerSheet(
                        imageName: image.displayTag,
                        onCancel: {
                            withAnimation(.spring(duration: 0.25)) {
                                showCreateContainer = false
                                selectedImage       = nil
                            }
                        },
                        onCreate: { name in
                            let result = await containersVM.createContainer(
                                name: name,
                                imageName: image.displayTag
                            )
                            if result.success {
                                withAnimation(.spring(duration: 0.25)) {
                                    showCreateContainer = false
                                    selectedImage       = nil
                                }
                            }
                            return result
                        }
                    )
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.25), radius: 20)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
        }
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: containersVM.containers.count)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: imagesVM.images.count)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: dockerExpanded)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: imagesExpanded)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: pullExpanded)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9, anchor: .top)
        .animation(.spring(duration: 0.4, bounce: 0.35), value: isVisible)
        .onAppear {
            isVisible = true
            refresh()
        }
        .onDisappear {
            isVisible      = false
            dockerExpanded = false
            imagesExpanded = false
            pullExpanded   = false
            pullImageName  = ""
        }
        .onReceive(timer) { _ in refresh() }
    }

    private func refresh() {
        servicesVM.refresh()
        Task {
            await containersVM.refresh()
            await imagesVM.refresh()
        }
    }
}

// MARK: - Images Header

private struct ImagesHeader: View {
    let count: Int
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 22)

                Text("Images")
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)

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
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 22)

                Text("Pull Image")
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.spring(duration: 0.3), value: isExpanded)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
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
                    .font(.system(size: 12))
                    .disabled(isPulling)
                    .onSubmit { onPull() }

                Button {
                    onPull()
                } label: {
                    Text(isPulling ? "Pulling..." : "Pull")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.glass)
                .controlSize(.small)
                .disabled(isPulling || imageName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)

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
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
