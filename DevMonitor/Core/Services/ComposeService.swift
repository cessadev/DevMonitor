import Foundation
import AppKit

class ComposeService {

    static let shared = ComposeService()

    func up(project: DockerComposeProject) throws {
        let projectDir = URL(fileURLWithPath: project.filePath)
            .deletingLastPathComponent().path
        try runCompose(args: ["compose", "up", "-d"], workingDirectory: projectDir)
    }

    func down(project: DockerComposeProject) throws {
        let projectDir = URL(fileURLWithPath: project.filePath)
            .deletingLastPathComponent().path
        try runCompose(args: ["compose", "down"], workingDirectory: projectDir)
    }

    func refreshStatus(for project: DockerComposeProject) -> [String: DockerComposeProject.ComposeServiceStatus] {
        let projectDir = URL(fileURLWithPath: project.filePath)
            .deletingLastPathComponent().path

        guard let output = runComposeOutput(
            args: ["compose", "ps", "--format", "json"],
            workingDirectory: projectDir
        ), !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return [:]
        }

        var statuses: [String: DockerComposeProject.ComposeServiceStatus] = [:]
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try JSON array first (Docker Compose v2.21+)
        if trimmed.hasPrefix("["),
           let data   = trimmed.data(using: .utf8),
           let array  = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in array {
                if let service = item["Service"] as? String,
                   let state   = item["State"] as? String {
                    statuses[service] = state == "running" ? .running : .stopped
                }
            }
            return statuses
        }

        // Fallback: one JSON object per line (older versions)
        let lines = trimmed.components(separatedBy: "\n").filter { $0.hasPrefix("{") }
        for line in lines {
            guard let data    = line.data(using: .utf8),
                  let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let service = json["Service"] as? String,
                  let state   = json["State"] as? String else { continue }
            statuses[service] = state == "running" ? .running : .stopped
        }

        return statuses
    }

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
    private func runCompose(args: [String], workingDirectory: String) throws -> Data {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        process.executableURL       = URL(fileURLWithPath: dockerPath)
        process.arguments           = args
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        process.standardOutput      = outPipe
        process.standardError       = errPipe

        // Provide a clean environment with required PATH
        process.environment = [
            "PATH": "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin",
            "HOME": FileManager.default.homeDirectoryForCurrentUser.path,
        ]

        try process.run()
        process.waitUntilExit()

        // If exit code is non-zero, surface the stderr message
        if process.terminationStatus != 0 {
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg  = String(data: errData, encoding: .utf8) ?? "Unknown error"
            throw ComposeError.commandFailed(errMsg.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return outPipe.fileHandleForReading.readDataToEndOfFile()
    }

    private func runComposeOutput(args: [String], workingDirectory: String) -> String? {
        guard let data = try? runCompose(args: args, workingDirectory: workingDirectory) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

enum ComposeError: Error, LocalizedError {
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return msg
        }
    }
}
