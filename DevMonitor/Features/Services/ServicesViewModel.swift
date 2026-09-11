import Foundation
import AppKit

@Observable
class ServicesViewModel {

    var services: [LocalService] = [
        LocalService(name: "Docker", processName: "Docker", isRunning: false, icon: "shippingbox")
    ]

    private let processService = SystemProcessService()
    private let dockerSocketPath = "/var/run/docker.sock"

    func refresh() {
        let processNames = processService.runningProcessNames()
        let runningApps  = NSWorkspace.shared.runningApplications
            .compactMap { $0.localizedName?.lowercased() }

        for index in services.indices {
            let name = services[index].processName.lowercased()
            
            let processRunning =
                runningApps.contains(where: { $0.contains(name) }) ||
                processNames.contains(where: { $0.lowercased().contains(name) })

            // Docker Desktop can be running but with the engine stopped
            if name == "docker" {
                services[index].isRunning = processRunning && isDockerSocketReachable()
            } else {
                services[index].isRunning = processRunning
            }
        }
    }

    private func isDockerSocketReachable() -> Bool {
        guard FileManager.default.fileExists(atPath: dockerSocketPath) else {
            return false
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return false }
        defer { close(fd) }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = dockerSocketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            pathBytes.withUnsafeBytes { src in
                UnsafeMutableRawPointer(ptr)
                    .copyMemory(from: src.baseAddress!, byteCount: min(src.count, 104))
            }
        }

        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        return result == 0
    }
}
