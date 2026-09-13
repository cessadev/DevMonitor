import SwiftUI
import Combine

struct ContentView: View {

    @State private var servicesVM                  = ServicesViewModel()
    @State private var containersVM                = ContainersViewModel()
    @State private var imagesVM                    = ImagesViewModel()
    @State private var isVisible                   = false
    @State private var pullImageName               = ""
    @State private var composeVM                   = ComposeViewModel()
    @State private var isComposeBusy               = false
    @State private var buildVM                     = BuildViewModel()
    
    @AppStorage("imagesExpanded") private var imagesExpanded = false
    @AppStorage("pullExpanded")   private var pullExpanded   = false
    @AppStorage("buildExpanded") private var buildExpanded   = false
    
    private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.clear

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack(spacing: 8) {
                    Text("DocMonitor")
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
                ServicesView(services: servicesVM.services)

                // Containers
                if !containersVM.containers.isEmpty {
                    ContainersView(
                        containers: containersVM.containers,
                        lockedComposeProject: composeVM.lockedComposeProject,
                        activeComposeProjects: composeVM.activeComposeProjects,
                        onToggle: { container in await containersVM.toggle(container) },
                        onDelete: { container in await containersVM.delete(container) }
                    )
                }

                // Compose Projects
                ComposeView(
                    projects: composeVM.projects,
                    loadingProjectId: composeVM.isLoadingProjectId,
                    onUp: { project in
                        isComposeBusy = true
                        await composeVM.up(project)
                        await containersVM.refresh()
                        isComposeBusy = false
                    },
                    onDown: { project in
                        isComposeBusy = true
                        await composeVM.down(project)
                        await containersVM.refresh()
                        isComposeBusy = false
                    },
                    onRemove:    { project in composeVM.remove(project) },
                    onAddManual: { composeVM.addManualProject() }
                )

                // Images
                ImagesView(
                    images: imagesVM.images,
                    count: imagesVM.images.count,
                    isExpanded: imagesExpanded,
                    pullExpanded: pullExpanded,
                    pullImageName: $pullImageName,
                    isPulling: imagesVM.isPulling,
                    pullProgress: imagesVM.pullProgress,
                    onHeaderTap: {
                        withAnimation(.spring(duration: 0.3)) {
                            imagesExpanded.toggle()
                            if !imagesExpanded {
                                pullExpanded  = false
                                pullImageName = ""
                            }
                        }
                    },
                    onPullHeaderTap: {
                        pullExpanded.toggle()
                    },
                    onPull: {
                        Task { await imagesVM.pull(name: pullImageName) }
                    },
                    onDelete: {
                        image in await imagesVM.delete(image)
                    },
                    buildExpanded: buildExpanded,
                    buildVM: buildVM,
                    onBuildHeaderTap: {
                        if buildExpanded { buildVM.reset() }
                        buildExpanded.toggle()
                    },
                    onCreateContainer: { image, name, ports, envVars, restartPolicy in
                        return await containersVM.createContainer(
                            name: name,
                            imageName: image.displayTag,
                            portBindings: ports,
                            envVars: envVars,
                            restartPolicy: restartPolicy
                        )
                    }
                )

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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(CapsuleButtonStyle())

                    Spacer()

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 12))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(CapsuleButtonStyle())
                    .keyboardShortcut("q")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 308)
        .fixedSize(horizontal: false, vertical: true)
        .scaleEffect(isVisible ? 1.0 : 0.92)
        .opacity(isVisible ? 1.0 : 0)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: imagesVM.images.count)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: imagesExpanded)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: pullExpanded)
        .animation(.spring(duration: 0.35, bounce: 0.15), value: buildExpanded)
        .animation(isVisible
            ? .spring(duration: 0.3, bounce: 0.2)
            : .easeIn(duration: 0.15),
            value: isVisible
        )
        .onAppear {
            isVisible = true
            refresh()
        }
        .onDisappear {
            isVisible = false
            pullImageName = ""
            buildVM.reset()
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .onReceive(timer) { _ in
            guard !isComposeBusy else { return }
            refresh()
        }
    }

    private func refresh() {
        servicesVM.refresh()
        Task {
            async let containers: () = containersVM.refresh()
            async let images: ()     = imagesVM.refresh()
            async let compose: ()    = composeVM.refresh()
            await containers
            await images
            await compose
        }
    }
}
