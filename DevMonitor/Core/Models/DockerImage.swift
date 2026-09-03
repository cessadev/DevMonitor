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
        let kb = Double(size) / 1_000
        let mb = kb / 1_000
        let gb = mb / 1_000

        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        } else if mb >= 1 {
            return String(format: "%.0f MB", mb)
        } else {
            return String(format: "%.1f KB", kb)
        }
    }

    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var displayAge: String {
        let date = Date(timeIntervalSince1970: TimeInterval(created))
        return Self.relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
}
