import Foundation

public enum FileActionKind: String, Codable, Hashable, Sendable {
    case moveToTrash
    case moveToReviewFolder
    case exportReportOnly
}

public struct FileAction: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var kind: FileActionKind
    public var fileID: ScannedFile.ID
    public var sourcePath: String
    public var destinationPath: String?
    public var date: Date

    public init(
        id: UUID = UUID(),
        kind: FileActionKind,
        fileID: ScannedFile.ID,
        sourcePath: String,
        destinationPath: String? = nil,
        date: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.fileID = fileID
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.date = date
    }
}
