import CryptoKit
import Foundation

public struct HashService: Sendable {
    public var chunkSize: Int
    public var partialChunkSize: Int

    public init(chunkSize: Int = 1024 * 1024, partialChunkSize: Int = 64 * 1024) {
        self.chunkSize = chunkSize
        self.partialChunkSize = partialChunkSize
    }

    public func sha256(for url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            let chunk = try handle.read(upToCount: chunkSize) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().hexString
    }

    public func partialHash(for url: URL) throws -> String {
        let size = try fileSize(for: url)
        if size <= Int64(partialChunkSize * 2) {
            return try sha256(for: url)
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        let head = try handle.read(upToCount: partialChunkSize) ?? Data()
        try handle.seek(toOffset: UInt64(size - Int64(partialChunkSize)))
        let tail = try handle.read(upToCount: partialChunkSize) ?? Data()

        var sizeBigEndian = UInt64(size).bigEndian
        let sizeData = withUnsafeBytes(of: &sizeBigEndian) { Data($0) }

        var hasher = SHA256()
        hasher.update(data: sizeData)
        hasher.update(data: head)
        hasher.update(data: tail)
        return hasher.finalize().hexString
    }

    public func fileSize(for url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        if let size = values.fileSize {
            return Int64(size)
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return attributes[.size] as? Int64 ?? 0
    }
}

private extension Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
