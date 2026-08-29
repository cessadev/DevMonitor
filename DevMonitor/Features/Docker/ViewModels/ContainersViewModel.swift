import Foundation

@Observable
class ContainersViewModel {

    var containers: [DockerContainer] = []
    var error: String?

    private let dockerClient = DockerClient.shared

    @MainActor
    func refresh() async {
        do {
            containers = try await dockerClient.fetchContainers()
            error      = nil
        } catch {
            self.error  = error.localizedDescription
            containers  = []
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
    func createContainer(name: String, imageName: String) async -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        // Validation: empty or blank
        guard !trimmed.isEmpty else {
            self.error = "Container name cannot be empty"
            return false
        }

        // Validation: duplicate name
        guard !containerNameExists(trimmed) else {
            self.error = "A container named '\(trimmed)' already exists"
            return false
        }

        // Validation: delegate to DockerClient
        do {
            try await dockerClient.createContainer(name: trimmed, imageName: imageName)
            try? await Task.sleep(nanoseconds: 400_000_000)
            await refresh()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
    
    private func containerNameExists(_ name: String) -> Bool {
        containers.map { $0.displayName.lowercased() }
                   .contains(name.trimmingCharacters(in: .whitespaces).lowercased())
    }
}
