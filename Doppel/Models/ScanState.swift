public enum ScanState: String, Codable, Hashable, CaseIterable, Sendable {
    case idle
    case indexing
    case groupingBySize
    case partialHashing
    case fullHashing
    case byteComparing
    case finished
    case paused
    case cancelled
    case error
    case movingToTrash
    case movingToReviewFolder
    case exportingReport
}
