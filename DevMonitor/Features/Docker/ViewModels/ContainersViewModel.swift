import Foundation
import SwiftUI

@Observable
class ContainersViewModel {

    var containers: [DockerContainer] = []
    var error: String?

    private let dockerClient = DockerClient.shared

    @MainActor
    func refresh() async {
        do {
            let fetched = try await dockerClient.fetchContainers()
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                containers = fetched
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                containers = []
            }
        }
    }

    @MainActor
    func toggle(_ container: DockerContainer) async {
        do {
            if container.isRunning {
                try await dockerClient.stopContainer(id: container.id)
            } else {
                try await dockerClient.startContainer(id: container.id)
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    @MainActor
    func delete(_ container: DockerContainer) async {
        do {
            try await dockerClient.deleteContainer(id: container.id)
            try? await Task.sleep(nanoseconds: 400_000_000)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    @MainActor
    func createContainer(
        name: String,
        imageName: String,
        portBindings: [String],
        envVars: [String],
        restartPolicy: String
    ) async -> (success: Bool, validationError: String?) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return (false, "Container name cannot be empty")
        }

        guard !containerNameExists(trimmed) else {
            return (false, "A container named '\(trimmed)' already exists")
        }

        do {
            try await dockerClient.createContainer(
                name: trimmed,
                imageName: imageName,
                portBindings: portBindings,
                envVars: envVars,
                restartPolicy: restartPolicy
            )
            try? await Task.sleep(nanoseconds: 400_000_000)
            await refresh()
            return (true, nil)
        } catch {
            self.error = error.localizedDescription
            return (false, nil)
        }
    }
    
    private func containerNameExists(_ name: String) -> Bool {
        containers.map { $0.displayName.lowercased() }
                   .contains(name.trimmingCharacters(in: .whitespaces).lowercased())
    }
}
