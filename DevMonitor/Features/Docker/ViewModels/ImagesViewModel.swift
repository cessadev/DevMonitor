import Foundation

@Observable
class ImagesViewModel {

    var images: [DockerImage] = []
    var error: String?
    
    var pullProgress: String = ""
    var isPulling: Bool      = false

    private let dockerClient = DockerClient.shared

    @MainActor
    func refresh() async {
        do {
            let all = try await dockerClient.fetchImages()
            images  = all.filter { image in
                guard let tags = image.repoTags, !tags.isEmpty else { return false }
                return !tags.allSatisfy { $0 == "<none>:<none>" }
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
            images     = []
        }
    }
    
    @MainActor
    func pull(name: String) async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isPulling    = true
        pullProgress = "Connecting..."
        error        = nil

        do {
            try await dockerClient.pullImage(name: name) { [weak self] message in
                self?.pullProgress = message
            }
            pullProgress = "Done"
            try? await Task.sleep(nanoseconds: 800_000_000)
            pullProgress = ""
            isPulling    = false
            await refresh()
        } catch {
            self.error   = error.localizedDescription
            pullProgress = ""
            isPulling    = false
        }
    }

    @MainActor
    func delete(_ image: DockerImage) async {
        do {
            try await dockerClient.deleteImage(id: image.id)
            try? await Task.sleep(nanoseconds: 400_000_000)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
