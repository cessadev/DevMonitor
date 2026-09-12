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
}
