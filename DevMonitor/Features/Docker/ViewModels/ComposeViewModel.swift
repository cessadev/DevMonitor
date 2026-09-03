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
                var scanned = self.composeService.scanProjects()

                // Merge manual projects not found by auto-scan
                let scannedPaths = Set(scanned.map { $0.filePath })
                for path in self.manualPaths where !scannedPaths.contains(path) {
                    let url = URL(fileURLWithPath: path)
                    scanned.append(DockerComposeProject(
                        name: url.deletingLastPathComponent().lastPathComponent,
                        filePath: path
                    ))
                }

                // Enrich with live statuses
                for index in scanned.indices {
                    scanned[index].serviceStatuses = self.composeService.refreshStatus(
                        for: scanned[index]
                    )
                }

                let sorted = scanned.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }

                DispatchQueue.main.async {
                    // Merge instead of replace — preserves SwiftUI row identity
                    let existingPaths = Set(self.projects.map { $0.filePath })
                    let newPaths      = Set(sorted.map { $0.filePath })

                    // Update statuses of existing projects in place
                    for index in self.projects.indices {
                        if let updated = sorted.first(where: { $0.filePath == self.projects[index].filePath }) {
                            self.projects[index].serviceStatuses = updated.serviceStatuses
                        }
                    }

                    // Add new projects not yet in the list
                    for project in sorted where !existingPaths.contains(project.filePath) {
                        self.projects.append(project)
                        self.projects.sort { $0.displayName.lowercased() < $1.displayName.lowercased() }
                    }

                    // Remove projects that no longer exist
                    self.projects.removeAll { project in
                        !newPaths.contains(project.filePath) &&
                        !self.manualPaths.contains(project.filePath)
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
