import Foundation

struct DockerBuild: Identifiable {
    let id = UUID()
    let imageName: String
    let contextPath: String
    var status: BuildStatus
    var output: String

    enum BuildStatus {
        case idle
        case building
        case success
        case failed(String)
    }
}
