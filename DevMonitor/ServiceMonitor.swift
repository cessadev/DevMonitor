import Foundation
import AppKit

struct LocalService: Identifiable {
    let id = UUID()
    let name: String
    let processName: String
    var isRunning: Bool
    var icon: String
}

@Observable
class ServiceMonitor {
    
    var services: [LocalService] = [
        LocalService(name: "Docker",      processName: "Docker",      isRunning: false, icon: "shippingbox"),
        LocalService(name: "PostgreSQL",  processName: "postgres",    isRunning: false, icon: "cylinder"),
        LocalService(name: "Redis",       processName: "redis-server", isRunning: false, icon: "bolt"),
    ]
    
    var containers: [DockerContainer] = []
    var dockerError: String?
    
    private var timer: Timer?
    
    init() {
        refresh()
        startAutoRefresh()
    }
    
    func refresh() {
        refreshServices()
        Task { await refreshContainers() }
    }
    
    private func refreshServices() {
        let runningApps = NSWorkspace.shared.runningApplications
            .map { $0.localizedName ?? "" }
        let runningProcesses = runningProcessNames()
        
        for index in services.indices {
            let name = services[index].processName.lowercased()
            let foundInApps      = runningApps.map { $0.lowercased() }.contains(where: { $0.contains(name) })
            let foundInProcesses = runningProcesses.contains(where: { $0.lowercased().contains(name) })
            services[index].isRunning = foundInApps || foundInProcesses
        }
    }
    
    @MainActor
    private func refreshContainers() async {
        do {
            containers  = try await DockerClient.shared.fetchContainers()
            dockerError = nil
        } catch {
            dockerError = error.localizedDescription
            containers  = []
        }
    }
    
    private func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.refresh()
        }
    }
    
    private func runningProcessNames() -> [String] {
        let process = Process()
        let pipe    = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments     = ["-eo", "comm"]
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
