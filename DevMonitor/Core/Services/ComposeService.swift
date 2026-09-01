import Foundation
import AppKit

class ComposeService {

    static let shared = ComposeService()

    // Common directories to scan for compose files
    private let searchDirectories: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            home,
            "\(home)/Projects",
            "\(home)/Developer",
            "\(home)/Development",
            "\(home)/Code",
            "\(home)/Documents",
            "\(home)/Desktop",
        ]
    }()

    private let composeFileNames = [
        "docker-compose.yml",
        "docker-compose.yaml",
        "compose.yml",
        "compose.yaml",
    ]

    // Scan known directories for compose files (non-recursive, one level deep)
    func scanProjects() -> [DockerComposeProject] {
        var found: [DockerComposeProject] = []
        var seenPaths = Set<String>()

        for dir in searchDirectories {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) else {
                continue
            }

            for entry in contents {
                let entryPath = "\(dir)/\(entry)"

                // Check directly in the directory
                for fileName in composeFileNames {
                    let filePath = "\(entryPath)/\(fileName)"
                    if FileManager.default.fileExists(atPath: filePath),
                       !seenPaths.contains(filePath) {
                        seenPaths.insert(filePath)
                        found.append(DockerComposeProject(name: entry, filePath: filePath))
                    }
                }
            }

            // Also check the root of each search directory itself
            for fileName in composeFileNames {
                let filePath = "\(dir)/\(fileName)"
                if FileManager.default.fileExists(atPath: filePath),
                   !seenPaths.contains(filePath) {
                    seenPaths.insert(filePath)
                    let name = URL(fileURLWithPath: dir).lastPathComponent
                    found.append(DockerComposeProject(name: name, filePath: filePath))
                }
            }
        }

        return found.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
    }

    // Run docker compose up -d
    func up(project: DockerComposeProject) throws {
        try runCompose(args: ["-f", project.filePath, "up", "-d"])
    }

    // Run docker compose down
    func down(project: DockerComposeProject) throws {
        try runCompose(args: ["-f", project.filePath, "down"])
    }

    // Query status of each service in the project
    func refreshStatus(for project: DockerComposeProject) -> [String: DockerComposeProject.ComposeServiceStatus] {
        guard let output = runComposeOutput(args: ["-f", project.filePath, "ps", "--format", "json"]),
              !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return [:]
        }

        var statuses: [String: DockerComposeProject.ComposeServiceStatus] = [:]

        // docker compose ps --format json returns one JSON object per line
        let lines = output.components(separatedBy: "\n").filter { $0.hasPrefix("{") }
        for line in lines {
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let service = json["Service"] as? String,
                  let state   = json["State"] as? String else { continue }

            statuses[service] = state == "running" ? .running : .stopped
        }

        return statuses
    }

    // Locate the docker binary
    private var dockerPath: String {
        let candidates = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker",
        ]
        return candidates.first {
            FileManager.default.fileExists(atPath: $0)
        } ?? "/usr/local/bin/docker"
    }

    @discardableResult
    private func runCompose(args: [String]) throws -> Data {
        let process = Process()
        let pipe    = Pipe()

        process.executableURL  = URL(fileURLWithPath: dockerPath)
        process.arguments      = ["compose"] + args
        process.standardOutput = pipe
        process.standardError  = pipe

        try process.run()
        process.waitUntilExit()

        return pipe.fileHandleForReading.readDataToEndOfFile()
    }

    private func runComposeOutput(args: [String]) -> String? {
        guard let data = try? runCompose(args: args) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
