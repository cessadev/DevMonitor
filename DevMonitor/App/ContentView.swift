import SwiftUI
import Combine

struct ContentView: View {

    @State private var servicesVM                  = ServicesViewModel()
    @State private var containersVM                = ContainersViewModel()
    @State private var imagesVM                    = ImagesViewModel()
    @State private var isVisible                   = false
    @State private var dockerExpanded              = false
    @State private var imagesExpanded              = false
    @State private var pullExpanded                = false
    @State private var pullImageName               = ""
    @State private var showCreateContainer         = false
    @State private var selectedImage: DockerImage? = nil
    @State private var composeVM                   = ComposeViewModel()
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

                // Docker subsections
                if dockerExpanded {

                    // Containers
                    if !containersVM.containers.isEmpty {
                        ContainersView(
                            containers: containersVM.containers,
                            onToggle: { container in await containersVM.toggle(container) },
                            onDelete: { container in await containersVM.delete(container) }
                        )
                    }

                    // Compose Projects
                    if !composeVM.projects.isEmpty {
                        ComposeView(
                            projects: composeVM.projects,
                            loadingProjectId: composeVM.isLoadingProjectId,
                            onUp:        { project in await composeVM.up(project) },
                            onDown:      { project in await composeVM.down(project) },
                            onAddManual: { composeVM.addManualProject() }
                        )
                    } else {
                        ComposeView(
                            projects: [],
                            loadingProjectId: nil,
                            onUp:        { _ in },
                            onDown:      { _ in },
                            onAddManual: { composeVM.addManualProject() }
                        )
                    }

                    // Images header collapsible
                    ImagesHeader(
                        count: imagesVM.images.count,
                        isExpanded: imagesExpanded,
                        onTap: {
                            withAnimation(.spring(duration: 0.3)) {
                                imagesExpanded.toggle()
                                if !imagesExpanded {
                                    pullExpanded  = false
                                    pullImageName = ""
                                }
                            }
                        }
                    )

                    if imagesExpanded {
                        if !imagesVM.images.isEmpty {
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

                        PullImageHeader(
                            isExpanded: pullExpanded,
                            onTap: {
                                withAnimation(.spring(duration: 0.3)) {
                                    pullExpanded.toggle()
                                }
                            }
                        )

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
                    Button {
                        // Preferences — static for now
                    } label: {
                        Text("Preferences")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.18))
                            .strokeBorder(.white.opacity(0.45), lineWidth: 0.5)
                    )

                    Spacer()

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.18))
                            .strokeBorder(.white.opacity(0.45), lineWidth: 0.5)
                    )
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
                        onCreate: { name, ports, envVars, restartPolicy in
                            let result = await containersVM.createContainer(
                                name: name,
                                imageName: image.displayTag,
                                portBindings: ports,
                                envVars: envVars,
                                restartPolicy: restartPolicy
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
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.regularMaterial)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12)
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
            isVisible           = false
            dockerExpanded      = false
            imagesExpanded      = false
            pullExpanded        = false
            pullImageName       = ""
            showCreateContainer = false
            selectedImage       = nil
        }
        .onReceive(timer) { _ in refresh() }
    }

    private func refresh() {
        servicesVM.refresh()
        Task {
            await containersVM.refresh()
            await imagesVM.refresh()
            await composeVM.refresh()
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
            HStack {
                Text("DOCKER IMAGES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)

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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                    .padding(.top, 2)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.spring(duration: 0.3), value: isExpanded)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
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

                Button {
                    onPull()
                } label: {
                    Text(isPulling ? "Pulling..." : "Pull")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.22))
                        .strokeBorder(.white.opacity(0.45), lineWidth: 0.5)
                )
                .disabled(isPulling || imageName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.18))
                    .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)

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
        .padding(.bottom, 10)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
