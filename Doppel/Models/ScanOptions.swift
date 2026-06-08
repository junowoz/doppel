import Foundation

public enum CompareMode: String, Codable, Hashable, CaseIterable, Sendable {
    case fast
    case safe
    case paranoid
}

public enum FileTypeFilter: Codable, Hashable, Sendable {
    case all
    case images
    case videos
    case audio
    case documents
    case archives
    case customExtensions([String])

    public func allows(_ file: ScannedFile) -> Bool {
        switch self {
        case .all:
            true
        case .images:
            file.fileKind == .image
        case .videos:
            file.fileKind == .video
        case .audio:
            file.fileKind == .audio
        case .documents:
            file.fileKind == .document
        case .archives:
            file.fileKind == .archive
        case .customExtensions(let extensions):
            extensions.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
                .contains(file.fileExtension.lowercased())
        }
    }
}

public struct ScanOptions: Codable, Hashable, Sendable {
    public var includeSubfolders: Bool
    public var ignoreHiddenFiles: Bool
    public var ignorePackages: Bool
    public var ignoreSymlinks: Bool
    public var minimumFileSize: Int64
    public var fileTypeFilter: FileTypeFilter
    public var compareMode: CompareMode
    public var primaryFolderPaths: Set<String>

    public init(
        includeSubfolders: Bool = true,
        ignoreHiddenFiles: Bool = true,
        ignorePackages: Bool = true,
        ignoreSymlinks: Bool = true,
        minimumFileSize: Int64 = 0,
        fileTypeFilter: FileTypeFilter = .all,
        compareMode: CompareMode = .safe,
        primaryFolderPaths: Set<String> = []
    ) {
        self.includeSubfolders = includeSubfolders
        self.ignoreHiddenFiles = ignoreHiddenFiles
        self.ignorePackages = ignorePackages
        self.ignoreSymlinks = ignoreSymlinks
        self.minimumFileSize = minimumFileSize
        self.fileTypeFilter = fileTypeFilter
        self.compareMode = compareMode
        self.primaryFolderPaths = primaryFolderPaths
    }
}
