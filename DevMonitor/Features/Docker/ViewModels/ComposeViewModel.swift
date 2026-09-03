import Foundation
import AppKit
import UniformTypeIdentifiers

@Observable
class ComposeViewModel {

    var projects: [DockerComposeProject] = []
    var error: String?
    var isLoadingProjectId: UUID?
    private var manualPaths              = Set<String>()

    private let composeService = ComposeService.shared

    @MainActor
    func refresh() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Refresh statuses of manually added projects
                var updated = self.projects
                for index in updated.indices {
                    updated[index].serviceStatuses = self.composeService.refreshStatus(
                        for: updated[index]
                    )
                }

                DispatchQueue.main.async {
                    // Update statuses in place to preserve row identity and hover state
                    for index in self.projects.indices {
                        if let refreshed = updated.first(where: {
                            $0.filePath == self.projects[index].filePath
                        }) {
                            self.projects[index].serviceStatuses = refreshed.serviceStatuses
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    func up(_ project: DockerComposeProject) async {
        isLoadingProjectId = project.id
        error = nil

        // Temporarily allow app to hold focus during potential TCC dialog
        NSApp.setActivationPolicy(.regular)

        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.composeService.up(project: project)
                    Thread.sleep(forTimeInterval: 1.5)
                } catch {
                    DispatchQueue.main.async { self.error = error.localizedDescription }
                }
                continuation.resume()
            }
        }

        NSApp.setActivationPolicy(.accessory)
        await refresh()
        isLoadingProjectId = nil
    }

    @MainActor
    func down(_ project: DockerComposeProject) async {
        isLoadingProjectId = project.id
        error = nil

        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.composeService.down(project: project)
                    Thread.sleep(forTimeInterval: 1.0)
                } catch {
                    DispatchQueue.main.async { self.error = error.localizedDescription }
                }
                continuation.resume()
            }
        }

        await refresh()
        isLoadingProjectId = nil
    }
    
    @MainActor
    func remove(_ project: DockerComposeProject) {
        projects.removeAll { $0.id == project.id }
        manualPaths.remove(project.filePath)
    }

    // Add a project manually via file picker
    @MainActor
    func addManualProject() {
        let panel = NSOpenPanel()
        panel.title                 = "Select a Compose file"
        panel.allowedContentTypes   = [.yaml]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories  = false
        panel.canChooseFiles        = true

        // Bring the app to front so the panel gets proper focus
        NSApp.activate(ignoringOtherApps: true)

        panel.begin { [weak self] response in
            guard let self,
                  response == .OK,
                  let url = panel.url else { return }

            let project = DockerComposeProject(
                name: url.deletingLastPathComponent().lastPathComponent,
                filePath: url.path
            )

            // Avoid duplicates
            guard !self.manualPaths.contains(url.path) else { return }
            self.manualPaths.insert(url.path)

            Task { @MainActor in
                var enriched = project
                enriched.serviceStatuses = self.composeService.refreshStatus(for: project)
                self.projects.append(enriched)
                self.projects.sort { $0.displayName.lowercased() < $1.displayName.lowercased() }
            }
        }
    }
}
