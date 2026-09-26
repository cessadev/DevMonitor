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

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let decoder = JSONDecoder()
        let entries: [ComposeServiceEntry]

        // Try JSON array first (Docker Compose v2.21+)
        if trimmed.hasPrefix("["),
           let data       = trimmed.data(using: .utf8),
           let rawEntries = try? decoder.decode([FailableDecodable<ComposeServiceEntry>].self, from: data) {
            entries = rawEntries.compactMap(\.value)
        } else {
            // Fallback: one JSON object per line (older versions)
            entries = trimmed
                .components(separatedBy: "\n")
                .filter { $0.hasPrefix("{") }
                .compactMap { line in
                    guard let data = line.data(using: .utf8) else { return nil }
                    return try? decoder.decode(ComposeServiceEntry.self, from: data)
                }
        }

        var statuses: [String: DockerComposeProject.ComposeServiceStatus] = [:]
        for entry in entries {
            statuses[entry.service] = entry.state == "running" ? .running : .stopped
        }
        return statuses
    }

    @discardableResult
    private func runCompose(args: [String], workingDirectory: String) throws -> Data {
        let process = Process()
        let outPipe = Pipe()
        let errPipe = Pipe()

        process.executableURL       = URL(fileURLWithPath: DockerCLILocator.executablePath)
        process.arguments           = args
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        process.standardOutput      = outPipe
        process.standardError       = errPipe

        // Provide a clean environment with required PATH
        process.environment = [
            "PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/Applications/Docker.app/Contents/Resources/bin",
            "HOME": FileManager.default.homeDirectoryForCurrentUser.path,
        ]

        try process.run()

        var outputData = Data()
        var errorData  = Data()

        let outputDone = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
            outputDone.signal()
        }

        let errorDone = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            errorDone.signal()
        }

        process.waitUntilExit()
        outputDone.wait()
        errorDone.wait()

        // If exit code is non-zero, surface the stderr message
        if process.terminationStatus != 0 {
            let errMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw ComposeError.commandFailed(errMsg.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return outputData
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

    private func runComposeOutput(args: [String], workingDirectory: String) -> String? {
        guard let data = try? runCompose(args: args, workingDirectory: workingDirectory) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    private struct ComposeServiceEntry: Decodable {
        let service: String
        let state: String
        enum CodingKeys: String, CodingKey {
            case service = "Service"
            case state   = "State"
        }
    }

    private struct FailableDecodable<Wrapped: Decodable>: Decodable {
        let value: Wrapped?
        init(from decoder: Decoder) throws {
            value = try? Wrapped(from: decoder)
        }
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
