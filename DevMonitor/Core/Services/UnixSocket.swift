import Foundation

enum UnixSocketError: Error {
    case notFound
    case connectFailed
}

enum UnixSocket {
    nonisolated static func makeConnection(to path: String) throws -> Int32 {
        guard FileManager.default.fileExists(atPath: path) else {
            throw UnixSocketError.notFound
        }

        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw UnixSocketError.connectFailed }

        var addr        = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes   = path.utf8CString
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            pathBytes.withUnsafeBytes { src in
                UnsafeMutableRawPointer(ptr)
                    .copyMemory(from: src.baseAddress!, byteCount: min(src.count, 104))
            }
        }

        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard result == 0 else {
            close(fd)
            throw UnixSocketError.connectFailed
        }

        return fd
    }
}
