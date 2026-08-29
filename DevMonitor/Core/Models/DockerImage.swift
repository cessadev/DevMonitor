import Foundation

struct DockerImage: Identifiable, Decodable {
    let id: String
    let repoTags: [String]?
    let size: Int
    let created: Int

    enum CodingKeys: String, CodingKey {
        case id       = "Id"
        case repoTags = "RepoTags"
        case size     = "Size"
        case created  = "Created"
    }

    var shortId: String {
        let raw = id.replacingOccurrences(of: "sha256:", with: "")
        return String(raw.prefix(12))
    }

    var displayTag: String {
        guard let tag = repoTags?.first, tag != "<none>:<none>" else {
            return "Untagged"
        }
        return tag
    }

    var name: String {
        let tag = displayTag
        return tag.components(separatedBy: ":").first ?? tag
    }

    var version: String {
        let tag = displayTag
        let parts = tag.components(separatedBy: ":")
        return parts.count > 1 ? parts[1] : ""
    }

    var displaySize: String {
        let mb = Double(size) / 1_000_000
        if mb >= 1000 {
            return String(format: "%.1f GB", mb / 1000)
        }
        return String(format: "%.0f MB", mb)
    }

    var displayAge: String {
        let date = Date(timeIntervalSince1970: TimeInterval(created))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
