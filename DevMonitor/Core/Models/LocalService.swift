import Foundation

struct LocalService: Identifiable {
    let id = UUID()
    let name: String
    let processName: String
    var isRunning: Bool
    var icon: String
}
