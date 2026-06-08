public enum RecommendationReason: String, Codable, Hashable, CaseIterable, Sendable {
    case originalNamePreferred
    case copySuffixDetected
    case shorterPathPreferred
    case olderFilePreferred
    case outsideDownloadsPreferred
    case primaryFolderPreferred
    case needsReview

    public var label: String {
        switch self {
        case .originalNamePreferred: "Original name preferred"
        case .copySuffixDetected: "Copy suffix detected"
        case .shorterPathPreferred: "Shorter path preferred"
        case .olderFilePreferred: "Older file preferred"
        case .outsideDownloadsPreferred: "Outside Downloads/temp/cache preferred"
        case .primaryFolderPreferred: "Primary folder preferred"
        case .needsReview: "Needs review"
        }
    }
}

public struct FileRecommendation: Codable, Equatable, Hashable, Sendable {
    public var keepFileID: ScannedFile.ID
    public var removalFileIDs: Set<ScannedFile.ID>
    public var reasons: [ScannedFile.ID: [RecommendationReason]]

    public init(
        keepFileID: ScannedFile.ID,
        removalFileIDs: Set<ScannedFile.ID>,
        reasons: [ScannedFile.ID: [RecommendationReason]] = [:]
    ) {
        self.keepFileID = keepFileID
        self.removalFileIDs = removalFileIDs
        self.reasons = reasons
    }
}
