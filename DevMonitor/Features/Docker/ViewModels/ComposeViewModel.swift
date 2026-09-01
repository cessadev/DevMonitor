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
                    self.projects = sorted
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    func up(_ project: DockerComposeProject) async {
        isLoadingProjectId = project.id
        error = nil

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
