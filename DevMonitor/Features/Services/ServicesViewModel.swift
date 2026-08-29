import Foundation

@Observable
class ServicesViewModel {

    var services: [LocalService] = [
        LocalService(name: "Docker",     processName: "Docker",      isRunning: false, icon: "shippingbox"),
        LocalService(name: "PostgreSQL", processName: "postgres",    isRunning: false, icon: "cylinder"),
        LocalService(name: "Redis",      processName: "redis-server", isRunning: false, icon: "bolt"),
    ]

    private let processService = SystemProcessService()

    func refresh() {
        for index in services.indices {
            services[index].isRunning = processService.isRunning(
                processName: services[index].processName
            )
        }
    }
}
