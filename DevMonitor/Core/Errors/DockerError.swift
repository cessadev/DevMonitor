import Foundation

enum DockerError: Error, LocalizedError {
    case socketNotFound
    case connectionFailed
    case emptyResponse
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .socketNotFound:        return "Docker socket not found. Is Docker running?"
        case .connectionFailed:      return "Cannot connect to Docker socket"
        case .emptyResponse:         return "Empty response from Docker"
        case .decodingFailed(let m): return "Decode error: \(m)"
        }
    }
}
