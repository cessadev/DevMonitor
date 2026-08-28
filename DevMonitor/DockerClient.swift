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

class DockerClient {

    static let shared = DockerClient()
    private let socketPath = "/var/run/docker.sock"

    func fetchContainers() async throws -> [DockerContainer] {
        let responseData = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try self.sendRequest(
                        "GET /containers/json?all=true HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
                    )
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        // 1. Split headers and raw body at \r\n\r\n
        guard let separatorRange = responseData.range(of: Data("\r\n\r\n".utf8)) else {
            throw DockerError.emptyResponse
        }

        let headerData = responseData[..<separatorRange.lowerBound]
        let rawBody    = Data(responseData[separatorRange.upperBound...])

        // 2. Check if response is chunked
        let headers      = String(data: headerData, encoding: .utf8) ?? ""
        let isChunked    = headers.lowercased().contains("transfer-encoding: chunked")
        let body         = isChunked ? Self.decodeChunked(rawBody) : rawBody

        // 3. Decode JSON
        do {
            return try JSONDecoder().decode([DockerContainer].self, from: body)
        } catch {
            let raw = String(data: body, encoding: .utf8) ?? "unreadable"
            throw DockerError.decodingFailed(String(raw.prefix(300)))
        }
    }
    
    func startContainer(id: String) async throws {
        _ = try await sendRequest(
            "POST /containers/\(id)/start HTTP/1.1\r\nHost: localhost\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        )
    }

    func stopContainer(id: String) async throws {
        _ = try await sendRequest(
            "POST /containers/\(id)/stop HTTP/1.1\r\nHost: localhost\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        )
    }

    // Decode HTTP chunked transfer encoding
    private static func decodeChunked(_ data: Data) -> Data {
        var result    = Data()
        var index     = data.startIndex
        let crlf      = Data("\r\n".utf8)

        while index < data.endIndex {
            // Find end of chunk size line
            guard let lineEnd = data.range(of: crlf, in: index..<data.endIndex)
                else { break };

            let sizeLine = String(data: data[index..<lineEnd.lowerBound], encoding: .utf8)?
                .trimmingCharacters(in: .whitespaces) ?? ""

            // Parse hex size — ignore chunk extensions (after semicolon)
            let hexPart  = sizeLine.components(separatedBy: ";").first ?? sizeLine
            guard let chunkSize = Int(hexPart, radix: 16) else { break }

            // Size 0 means end of chunked body
            if chunkSize == 0 { break }

            let chunkStart = lineEnd.upperBound
            let chunkEnd   = data.index(chunkStart, offsetBy: chunkSize, limitedBy: data.endIndex)
                             ?? data.endIndex

            result.append(data[chunkStart..<chunkEnd])

            // Advance past chunk data + trailing \r\n
            index = data.index(chunkEnd, offsetBy: 2, limitedBy: data.endIndex) ?? data.endIndex
        }

        return result
    }

    private func sendRequest(_ httpRequest: String) throws -> Data {
        guard FileManager.default.fileExists(atPath: socketPath) else {
            throw DockerError.socketNotFound
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw DockerError.connectionFailed }
        defer { close(fd) }

        var addr       = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes  = socketPath.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            pathBytes.withUnsafeBytes { src in
                UnsafeMutableRawPointer(ptr)
                    .copyMemory(from: src.baseAddress!, byteCount: min(src.count, 104))
            }
        }

        let connectResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard connectResult == 0 else { throw DockerError.connectionFailed }

        var requestBytes = Array(httpRequest.utf8)
        guard write(fd, &requestBytes, requestBytes.count) >= 0 else {
            throw DockerError.connectionFailed
        }

        var response = Data()
        var buffer   = [UInt8](repeating: 0, count: 8192)
        while true {
            let n = read(fd, &buffer, buffer.count)
            if n <= 0 { break }
            response.append(contentsOf: buffer[..<n])
        }

        guard !response.isEmpty else { throw DockerError.emptyResponse }
        return response
    }
}
