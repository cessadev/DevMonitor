import Foundation
import AppKit

@Observable
class ServicesViewModel {

    var services: [LocalService] = [
        LocalService(name: "Docker", processName: "Docker", isRunning: false, icon: "shippingbox")
    ]

    private let processService = SystemProcessService()

    func refresh() {
        let processNames = processService.runningProcessNames()
        let runningApps  = NSWorkspace.shared.runningApplications
            .compactMap { $0.localizedName?.lowercased() }

        for index in services.indices {
            let name = services[index].processName.lowercased()
            services[index].isRunning =
                runningApps.contains(where: { $0.contains(name) }) ||
                processNames.contains(where: { $0.lowercased().contains(name) })
        }
    }
}
