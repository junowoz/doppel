import Foundation

public struct ByteCompareService: Sendable {
    public var chunkSize: Int

    public init(chunkSize: Int = 1024 * 1024) {
        self.chunkSize = chunkSize
    }

    public func contentsAreEqual(_ first: URL, _ second: URL) throws -> Bool {
        let firstSize = try HashService().fileSize(for: first)
        let secondSize = try HashService().fileSize(for: second)
        guard firstSize == secondSize else { return false }

        let firstHandle = try FileHandle(forReadingFrom: first)
        let secondHandle = try FileHandle(forReadingFrom: second)
        defer {
            try? firstHandle.close()
            try? secondHandle.close()
        }

        while true {
            let firstChunk = try firstHandle.read(upToCount: chunkSize) ?? Data()
            let secondChunk = try secondHandle.read(upToCount: chunkSize) ?? Data()
            if firstChunk.isEmpty && secondChunk.isEmpty { return true }
            if firstChunk != secondChunk { return false }
        }
    }
}
