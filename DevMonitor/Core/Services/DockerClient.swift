import Foundation

class DockerClient {

    static let shared = DockerClient()
    private let socketPath = "/var/run/docker.sock"

    // Containers
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

        guard let separatorRange = responseData.range(of: Data("\r\n\r\n".utf8)) else {
            throw DockerError.emptyResponse
        }

        let headerData = responseData[..<separatorRange.lowerBound]
        let rawBody    = Data(responseData[separatorRange.upperBound...])
        let headers    = String(data: headerData, encoding: .utf8) ?? ""
        let isChunked  = headers.lowercased().contains("transfer-encoding: chunked")
        let body       = isChunked ? Self.decodeChunked(rawBody) : rawBody

        do {
            return try JSONDecoder().decode([DockerContainer].self, from: body)
        } catch {
            let raw = String(data: body, encoding: .utf8) ?? "unreadable"
            throw DockerError.decodingFailed(String(raw.prefix(300)))
        }
    }

    func startContainer(id: String) async throws {
        _ = try sendRequest(
            "POST /containers/\(id)/start HTTP/1.1\r\nHost: localhost\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        )
    }

    func stopContainer(id: String) async throws {
        _ = try sendRequest(
            "POST /containers/\(id)/stop HTTP/1.1\r\nHost: localhost\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        )
    }
    
    func deleteContainer(id: String) async throws {
        _ = try sendRequest(
            "DELETE /containers/\(id)?force=true HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
        )
    }
    
    // Images
    func fetchImages() async throws -> [DockerImage] {
        let responseData = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let data = try self.sendRequest(
                        "GET /images/json?dangling=false HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
                    )
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        guard let separatorRange = responseData.range(of: Data("\r\n\r\n".utf8)) else {
            throw DockerError.emptyResponse
        }

        let headerData = responseData[..<separatorRange.lowerBound]
        let rawBody    = Data(responseData[separatorRange.upperBound...])
        let headers    = String(data: headerData, encoding: .utf8) ?? ""
        let isChunked  = headers.lowercased().contains("transfer-encoding: chunked")
        let body       = isChunked ? Self.decodeChunked(rawBody) : rawBody

        do {
            return try JSONDecoder().decode([DockerImage].self, from: body)
        } catch {
            let raw = String(data: body, encoding: .utf8) ?? "unreadable"
            throw DockerError.decodingFailed(String(raw.prefix(300)))
        }
    }

    func deleteImage(id: String) async throws {
        _ = try sendRequest(
            "DELETE /images/\(id)?force=false HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
        )
    }

    private static func decodeChunked(_ data: Data) -> Data {
        var result = Data()
        var index  = data.startIndex
        let crlf   = Data("\r\n".utf8)

        while index < data.endIndex {
            guard let lineEnd = data.range(of: crlf, in: index..<data.endIndex) else { break }

            let sizeLine = String(data: data[index..<lineEnd.lowerBound], encoding: .utf8)?
                .trimmingCharacters(in: .whitespaces) ?? ""
            let hexPart  = sizeLine.components(separatedBy: ";").first ?? sizeLine

            guard let chunkSize = Int(hexPart, radix: 16) else { break }
            if chunkSize == 0 { break }

            let chunkStart = lineEnd.upperBound
            let chunkEnd   = data.index(chunkStart, offsetBy: chunkSize, limitedBy: data.endIndex) ?? data.endIndex

            result.append(data[chunkStart..<chunkEnd])
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

        var addr        = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes   = socketPath.utf8CString
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
