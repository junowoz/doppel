import Foundation

public struct ScannedFile: Identifiable, Codable, Equatable, Hashable, Sendable {
    public typealias ID = UUID

    public var id: ID
    public var url: URL
    public var path: String
    public var filename: String
    public var fileExtension: String
    public var normalizedFilename: String
    public var size: Int64
    public var allocatedSize: Int64?
    public var creationDate: Date?
    public var modificationDate: Date?
    public var typeIdentifier: String?
    public var isHidden: Bool
    public var isSymlink: Bool
    public var isPackage: Bool
    public var isReadable: Bool
    public var fileKind: FileKind
    public var partialHash: String?
    public var sha256: String?
    public var fileResourceIdentifier: String?
    public var error: String?

    public init(
        id: ID = UUID(),
        url: URL,
        partialHash: String? = nil,
        sha256: String? = nil,
        error: String? = nil
    ) throws {
        let keys: Set<URLResourceKey> = [
            .fileSizeKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .typeIdentifierKey,
            .isHiddenKey,
            .isSymbolicLinkKey,
            .isPackageKey,
            .isReadableKey,
            .fileResourceIdentifierKey
        ]
        let values = try url.resourceValues(forKeys: keys)
        let filename = url.lastPathComponent

        self.id = id
        self.url = url
        self.path = url.path
        self.filename = filename
        self.fileExtension = url.pathExtension
        self.normalizedFilename = filename.normalizedForRecommendation
        self.size = Int64(values.fileSize ?? 0)
        self.allocatedSize = values.totalFileAllocatedSize.map(Int64.init) ?? values.fileAllocatedSize.map(Int64.init)
        self.creationDate = values.creationDate
        self.modificationDate = values.contentModificationDate
        self.typeIdentifier = values.typeIdentifier
        self.isHidden = values.isHidden ?? filename.hasPrefix(".")
        self.isSymlink = values.isSymbolicLink ?? false
        self.isPackage = values.isPackage ?? Self.hasPackageExtension(url)
        self.isReadable = values.isReadable ?? FileManager.default.isReadableFile(atPath: url.path)
        self.fileKind = FileKind.classify(url: url, typeIdentifier: values.typeIdentifier)
        self.partialHash = partialHash
        self.sha256 = sha256
        self.fileResourceIdentifier = values.fileResourceIdentifier.map { String(describing: $0) }
        self.error = error
    }

    public func with(partialHash: String? = nil, sha256: String? = nil, error: String? = nil) -> ScannedFile {
        var copy = self
        if let partialHash { copy.partialHash = partialHash }
        if let sha256 { copy.sha256 = sha256 }
        if let error { copy.error = error }
        return copy
    }

    public static func hasPackageExtension(_ url: URL) -> Bool {
        let packageExtensions: Set<String> = [
            "app",
            "photoslibrary",
            "musiclibrary",
            "library",
            "framework",
            "bundle",
            "plugin"
        ]
        return packageExtensions.contains(url.pathExtension.lowercased())
    }
}

extension String {
    var normalizedForRecommendation: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }
}
