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

            services[index].isRunning = processRunning
        }

        // Socket check off main thread
        Task.detached(priority: .utility) {
            let socketReachable = self.isDockerSocketReachable()
            await MainActor.run {
                if let index = self.services.indices.first(where: {
                    self.services[$0].processName.lowercased() == "docker"
                }) {
                    self.services[index].isRunning = self.services[index].isRunning && socketReachable
                }
            }
        }
    }

    private nonisolated func isDockerSocketReachable() -> Bool {
        guard let fd = try? UnixSocket.makeConnection(to: dockerSocketPath) else {
            return false
        }
        close(fd)
        return true
    }
}
