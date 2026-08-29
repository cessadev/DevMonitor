import Foundation

@Observable
class ServicesViewModel {

    var services: [LocalService] = [
        LocalService(name: "Docker",     processName: "Docker",      isRunning: false, icon: "shippingbox")
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
