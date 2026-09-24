import Foundation

class DockerBuildService {

    func build(imageName: String, contextPath: String, onOutput: @escaping (String) -> Void) throws {
        let process = Process()
        let pipe    = Pipe()

        process.executableURL  = URL(fileURLWithPath: DockerCLILocator.executablePath)
        process.arguments      = ["build", "-t", imageName, contextPath]
        process.standardOutput = pipe
        process.standardError  = pipe

        // Inject PATH
        var env     = ProcessInfo.processInfo.environment
        env["PATH"] = [
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/Applications/Docker.app/Contents/Resources/bin"
        ].joined(separator: ":")
        process.environment = env

        let throttleQueue               = DispatchQueue(label: "devmonitor.build-output-throttle")
        var pendingOutput               = ""
        var lastFlush                   = Date.distantPast
        let flushInterval: TimeInterval = 0.1

        func flushPendingOutput() {
            guard !pendingOutput.isEmpty else { return }
            let text      = pendingOutput
            pendingOutput = ""
            lastFlush     = Date()
            DispatchQueue.main.async { onOutput(text) }
        }

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            let chunk = String(data: data, encoding: .utf8) ?? ""

            throttleQueue.sync {
                pendingOutput += chunk
                if Date().timeIntervalSince(lastFlush) >= flushInterval {
                    flushPendingOutput()
                }
            }
        }

        try process.run()
        process.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil
        
        throttleQueue.sync { flushPendingOutput() }

        if process.terminationStatus != 0 {
            throw DockerError.requestFailed("Build exited with code \(process.terminationStatus)")
        }
    }

    func dockerfileExists(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path).appendingPathComponent("Dockerfile")
        return FileManager.default.fileExists(atPath: url.path)
    }
}
