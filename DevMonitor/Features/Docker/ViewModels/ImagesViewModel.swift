import Foundation

@Observable
class ImagesViewModel {

    var images: [DockerImage] = []
    var error: String?

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
