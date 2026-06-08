import Foundation

public struct RecommendationService: Sendable {
    public init() {}

    public func recommendation(for group: DuplicateGroup, options: ScanOptions) -> FileRecommendation {
        if group.containsSameUnderlyingFile, let keep = group.files.first {
            let reasons = Dictionary(uniqueKeysWithValues: group.files.map { file in
                (file.id, [RecommendationReason.needsReview])
            })
            return FileRecommendation(keepFileID: keep.id, removalFileIDs: [], reasons: reasons)
        }

        guard let keep = group.files.min(by: { score(for: $0, options: options) < score(for: $1, options: options) }) else {
            return FileRecommendation(keepFileID: UUID(), removalFileIDs: [])
        }

        let removalIDs = Set(group.files.map(\.id).filter { $0 != keep.id })
        var reasons: [ScannedFile.ID: [RecommendationReason]] = [:]

        for file in group.files {
            var fileReasons: [RecommendationReason] = []
            if hasCopySuffix(file) { fileReasons.append(.copySuffixDetected) }
            if file.id == keep.id {
                fileReasons.append(.originalNamePreferred)
                fileReasons.append(.shorterPathPreferred)
            }
            if options.primaryFolderPaths.contains(where: { file.path.hasPrefix($0) }) {
                fileReasons.append(.primaryFolderPreferred)
            }
            if fileReasons.isEmpty {
                fileReasons.append(.needsReview)
            }
            reasons[file.id] = fileReasons
        }

        return FileRecommendation(keepFileID: keep.id, removalFileIDs: removalIDs, reasons: reasons)
    }

    private func score(for file: ScannedFile, options: ScanOptions) -> RecommendationScore {
        RecommendationScore(
            copyPenalty: hasCopySuffix(file) ? 100 : 0,
            riskyFolderPenalty: isInEphemeralFolder(file) ? 20 : 0,
            primaryFolderBonus: options.primaryFolderPaths.contains(where: { file.path.hasPrefix($0) }) ? -50 : 0,
            pathLength: file.path.count,
            creationTimestamp: file.creationDate?.timeIntervalSince1970 ?? file.modificationDate?.timeIntervalSince1970 ?? 0,
            filename: file.normalizedFilename
        )
    }

    private func hasCopySuffix(_ file: ScannedFile) -> Bool {
        let baseName = (file.filename as NSString).deletingPathExtension.normalizedForRecommendation
        let suffixes = [
            " 2",
            " copy",
            " copy 2",
            " copia",
            " cópia",
            " duplicate",
            " duplicado"
        ].map(\.normalizedForRecommendation)

        return suffixes.contains { baseName.hasSuffix($0) }
    }

    private func isInEphemeralFolder(_ file: ScannedFile) -> Bool {
        let path = file.path.normalizedForRecommendation
        return ["/downloads/", "/tmp/", "/temp/", "/cache/", "/caches/", "/imports/"].contains { path.contains($0) }
    }
}

private struct RecommendationScore: Comparable {
    var copyPenalty: Int
    var riskyFolderPenalty: Int
    var primaryFolderBonus: Int
    var pathLength: Int
    var creationTimestamp: TimeInterval
    var filename: String

    static func < (lhs: RecommendationScore, rhs: RecommendationScore) -> Bool {
        let lhsTuple = (
            lhs.copyPenalty + lhs.riskyFolderPenalty + lhs.primaryFolderBonus,
            lhs.pathLength,
            lhs.creationTimestamp,
            lhs.filename
        )
        let rhsTuple = (
            rhs.copyPenalty + rhs.riskyFolderPenalty + rhs.primaryFolderBonus,
            rhs.pathLength,
            rhs.creationTimestamp,
            rhs.filename
        )
        if lhsTuple.0 != rhsTuple.0 { return lhsTuple.0 < rhsTuple.0 }
        if lhsTuple.1 != rhsTuple.1 { return lhsTuple.1 < rhsTuple.1 }
        if lhsTuple.2 != rhsTuple.2 { return lhsTuple.2 < rhsTuple.2 }
        return lhsTuple.3 < rhsTuple.3
    }
}
