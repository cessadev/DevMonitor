import Foundation
import AppKit

class SystemProcessService {

    func runningProcessNames() -> [String] {
        let process = Process()
        let pipe    = Pipe()
        process.executableURL  = URL(fileURLWithPath: "/bin/ps")
        process.arguments      = ["-eo", "comm"]
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch { return [] }

        let data   = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    func isRunning(processName: String) -> Bool {
        let name = processName.lowercased()

        let foundInApps = NSWorkspace.shared.runningApplications
            .compactMap { $0.localizedName?.lowercased() }
            .contains(where: { $0.contains(name) })

        let foundInProcesses = runningProcessNames()
            .contains(where: { $0.lowercased().contains(name) })

        return foundInApps || foundInProcesses
    }
}
