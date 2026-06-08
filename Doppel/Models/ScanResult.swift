import Foundation

public struct ScanResult: Codable, Equatable, Hashable, Sendable {
    public var appVersion: String
    public var scanDate: Date
    public var selectedFolders: [URL]
    public var options: ScanOptions
    public var scannedFiles: [ScannedFile]
    public var skippedFiles: [ScannedFile]
    public var duplicateGroups: [DuplicateGroup]

    public init(
        appVersion: String = "0.1.0",
        scanDate: Date = Date(),
        selectedFolders: [URL],
        options: ScanOptions,
        scannedFiles: [ScannedFile],
        skippedFiles: [ScannedFile],
        duplicateGroups: [DuplicateGroup]
    ) {
        self.appVersion = appVersion
        self.scanDate = scanDate
        self.selectedFolders = selectedFolders
        self.options = options
        self.scannedFiles = scannedFiles
        self.skippedFiles = skippedFiles
        self.duplicateGroups = duplicateGroups
    }

    public var removableFileCount: Int {
        duplicateGroups.reduce(0) { $0 + $1.recommendedRemovalFileIDs.count }
    }

    public var potentialSavings: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.totalLogicalWastedBytes }
    }
}
