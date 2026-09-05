import Foundation
import AppKit
import UniformTypeIdentifiers

@Observable
class ComposeViewModel {

    var projects: [DockerComposeProject] = []
    var error: String?
    var isLoadingProjectId: UUID?
    
    // Names of containers belonging to the project currently being stopped
    var lockedContainerNames: Set<String> {
        guard let loadingId = isLoadingProjectId,
              let project = projects.first(where: { $0.id == loadingId }) else {
            return []
        }
        return Set(project.serviceStatuses.keys.map { "\(project.displayName)-\($0)" })
    }
    
    private var manualPaths = Set<String>()

    private let composeService = ComposeService.shared

    @MainActor
    func refresh() async {
        let snapshot = projects
        
        let updated: [DockerComposeProject] = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result = snapshot
                for index in result.indices {
                    result[index].serviceStatuses = self.composeService.refreshStatus(for: result[index])
                }
                continuation.resume(returning: result)
            }
        }
        
        // Merge back on main thread
        for index in projects.indices {
            if let refreshed = updated.first(where: { $0.filePath == projects[index].filePath }) {
                projects[index].serviceStatuses = refreshed.serviceStatuses
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
                    Thread.sleep(forTimeInterval: 2.5)
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
