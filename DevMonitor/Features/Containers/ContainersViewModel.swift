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
}
