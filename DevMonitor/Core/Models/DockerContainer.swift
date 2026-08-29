import Foundation

struct DockerContainer: Identifiable, Decodable {
    let id: String
    let names: [String]
    let image: String
    let state: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id     = "Id"
        case names  = "Names"
        case image  = "Image"
        case state  = "State"
        case status = "Status"
    }

    var displayName: String {
        names.first?.replacingOccurrences(of: "/", with: "") ?? id
    }

    var isRunning: Bool { state == "running" }
}
