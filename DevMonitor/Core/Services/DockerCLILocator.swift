import Foundation

enum DockerCLILocator {

    static let executablePath: String = {
        let candidates = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker",
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
            ?? "/usr/local/bin/docker"
    }()
}
