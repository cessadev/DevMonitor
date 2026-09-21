import Foundation

class TerminalService {
    func openShell(containerName: String) {
        let escapedName = containerName.replacingOccurrences(of: "\"", with: "\\\"")
        let dockerCommand = "docker exec -it \(escapedName) bash || docker exec -it \(escapedName) sh"
        let escapedCommand = dockerCommand.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Terminal"
            activate
            do script "\(escapedCommand)"
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        do {
            try process.run()
        } catch {
        }
    }
}
