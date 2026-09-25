import Foundation

class DockerClient {

    static let shared = DockerClient()
    private let socketPath = "/var/run/docker.sock"
    
    private static let jsonDecoder = JSONDecoder()

    // Containers
    func fetchContainers() async throws -> [DockerContainer] {
        let responseData = try await performBlocking {
            try self.sendRequest(
                "GET /containers/json?all=true HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
            )
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
            return try Self.jsonDecoder.decode([DockerContainer].self, from: body)
        } catch {
            let raw = String(data: body, encoding: .utf8) ?? "unreadable"
            throw DockerError.decodingFailed(String(raw.prefix(300)))
        }
    }

    func startContainer(id: String) async throws {
        _ = try await performBlocking {
            try self.sendRequest("POST /containers/\(id)/start HTTP/1.1\r\nHost: localhost\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
        }
    }

    func stopContainer(id: String) async throws {
        _ = try await performBlocking {
            try self.sendRequest("POST /containers/\(id)/stop HTTP/1.1\r\nHost: localhost\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
        }
    }

    func deleteContainer(id: String) async throws {
        _ = try await performBlocking {
            try self.sendRequest("DELETE /containers/\(id)?force=true HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")
        }
    }
    
    func createContainer(
        name: String,
        imageName: String,
        portBindings: [String],
        envVars: [String],
        restartPolicy: String
    ) async throws {
        let containerName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
 
        // Build PortBindings dict: {"80/tcp": [{"HostPort": "8080"}, ...]}
        // Accepts "host:container", "host:container/udp" and "hostIP:host:container"
        var bindingsByKey: [String: [[String: String]]] = [:]
        var exposedPorts: [String: Any]                 = [:]
        for binding in portBindings where !binding.trimmingCharacters(in: .whitespaces).isEmpty {
            let parts = binding.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 || parts.count == 3 else { continue }
 
            let hostIP: String?
            let hostPort: String
            let containerPart: String
            if parts.count == 3 {
                hostIP        = parts[0]
                hostPort      = parts[1]
                containerPart = parts[2]
            } else {
                hostIP        = nil
                hostPort      = parts[0]
                containerPart = parts[1]
            }
 
            // containerPart may already carry a protocol suffix, e.g. "80/udp"
            let containerProtoParts = containerPart.components(separatedBy: "/")
            let containerPort       = containerProtoParts[0]
            let proto               = containerProtoParts.count > 1
                                     ? containerProtoParts[1].lowercased()
                                     : "tcp"
            let key = "\(containerPort)/\(proto)"
 
            var hostBinding: [String: String] = ["HostPort": hostPort]
            if let hostIP { hostBinding["HostIp"] = hostIP }
 
            bindingsByKey[key, default: []].append(hostBinding)
            exposedPorts[key] = [:]
        }
        let portBindingsDict: [String: Any] = bindingsByKey
 
        let filteredEnv = envVars.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
 
        let body: [String: Any] = [
            "Image": imageName,
            "Env": filteredEnv,
            "ExposedPorts": exposedPorts,
            "HostConfig": [
                "PortBindings": portBindingsDict,
                "RestartPolicy": ["Name": restartPolicy]
            ]
        ]
 
        let bodyData  = try JSONSerialization.data(withJSONObject: body)
        let bodyJSON  = String(data: bodyData, encoding: .utf8) ?? "{}"
        let bodyBytes = bodyJSON.utf8.count
 
        let request = "POST /containers/create?name=\(containerName) HTTP/1.1\r\n" +
                      "Host: localhost\r\n" +
                      "Content-Type: application/json\r\n" +
                      "Content-Length: \(bodyBytes)\r\n" +
                      "Connection: close\r\n\r\n" +
                      bodyJSON
 
        let responseData = try await performBlocking {
            try self.sendRequest(request)
        }
 
        guard let headerEnd = responseData.range(of: Data("\r\n\r\n".utf8)) else {
            throw DockerError.emptyResponse
        }
        let headerString = String(data: responseData[..<headerEnd.lowerBound], encoding: .utf8) ?? ""
        let statusLine   = headerString.components(separatedBy: "\r\n").first ?? ""
        let statusCode   = Int(statusLine.components(separatedBy: " ").dropFirst().first ?? "") ?? 0
 
        switch statusCode {
        case 201: return
        case 404: throw DockerError.requestFailed("Image '\(imageName)' not found locally")
        case 409: throw DockerError.requestFailed("Container name '\(name)' already exists")
        default:  throw DockerError.requestFailed("Unexpected status: \(statusCode)")
        }
    }
    
    // Images
    func fetchImages() async throws -> [DockerImage] {
        let responseData = try await performBlocking {
            try self.sendRequest(
                "GET /images/json?dangling=false HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
            )
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
            return try Self.jsonDecoder.decode([DockerImage].self, from: body)
        } catch {
            let raw = String(data: body, encoding: .utf8) ?? "unreadable"
            throw DockerError.decodingFailed(String(raw.prefix(300)))
        }
    }

    func deleteImage(id: String) async throws {
        _ = try await performBlocking {
            try self.sendRequest("DELETE /images/\(id)?force=false HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")
        }
    }
    
    func pullImage(name: String, onProgress: @escaping @MainActor (String) -> Void) async throws {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let request = "POST /images/create?fromImage=\(encoded) HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"

        try await performBlocking {
            let fd = try self.openDockerSocket()
            defer { close(fd) }

            var requestBytes = Array(request.utf8)
            guard write(fd, &requestBytes, requestBytes.count) >= 0 else {
                throw DockerError.connectionFailed
            }

            var headerBuffer = Data()
            var bigBuffer    = [UInt8](repeating: 0, count: 4096)
            let separator    = Data("\r\n\r\n".utf8)

            while !headerBuffer.contains(separator) {
                let n = read(fd, &bigBuffer, bigBuffer.count)
                if n <= 0 { break }
                headerBuffer.append(contentsOf: bigBuffer[..<n])
            }

            var lineBuffer = ""
            var readBuf    = [UInt8](repeating: 0, count: 512)
            while true {
                let n = read(fd, &readBuf, readBuf.count)
                if n <= 0 { break }
                let chunk = String(bytes: readBuf[..<n], encoding: .utf8) ?? ""
                lineBuffer += chunk

                while let newline = lineBuffer.firstIndex(of: "\n") {
                    let line = String(lineBuffer[..<newline]).trimmingCharacters(in: .whitespaces)
                    lineBuffer = String(lineBuffer[lineBuffer.index(after: newline)...])

                    if !line.isEmpty && line.hasPrefix("{") {
                        if let data   = line.data(using: .utf8),
                           let json   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let status = json["status"] as? String {
                            let prog = json["progress"] as? String ?? ""
                            let msg  = prog.isEmpty ? status : "\(status) \(prog)"
                            Task { @MainActor in onProgress(msg) }
                        }
                    }
                }
            }
        }
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
        let fd = try openDockerSocket()
        defer { close(fd) }

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
    
    private func openDockerSocket() throws -> Int32 {
        do {
            return try UnixSocket.makeConnection(to: socketPath)
        } catch UnixSocketError.notFound {
            throw DockerError.socketNotFound
        } catch {
            throw DockerError.connectionFailed
        }
    }
    
    private func performBlocking<T: Sendable>(
        _ work: @escaping @Sendable () throws -> T
    ) async throws -> T {
        try await Task.detached(priority: .userInitiated) {
            try work()
        }.value
    }
}
