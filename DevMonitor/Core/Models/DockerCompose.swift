import Foundation

struct DockerComposeProject: Identifiable {
    let id = UUID()
    let name: String
    let filePath: String
    var serviceStatuses: [String: ComposeServiceStatus] = [:]

    enum ComposeServiceStatus {
        case running
        case stopped
        case partial
    }

    var overallStatus: ComposeServiceStatus {
        guard !serviceStatuses.isEmpty else { return .stopped }
        let statuses = serviceStatuses.values
        if statuses.allSatisfy({ $0 == .running })  { return .running }
        if statuses.allSatisfy({ $0 == .stopped })  { return .stopped }
        return .partial
    }

    var displayName: String {
        URL(fileURLWithPath: filePath)
            .deletingLastPathComponent()
            .lastPathComponent
    }
}
