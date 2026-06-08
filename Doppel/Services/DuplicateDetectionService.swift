import Foundation

public final class DuplicateDetectionService: @unchecked Sendable {
    private let scanner: FileScannerService
    private let hashService: HashService
    private let byteCompareService: ByteCompareService
    private let recommendationService: RecommendationService

    public init(
        scanner: FileScannerService = FileScannerService(),
        hashService: HashService = HashService(),
        byteCompareService: ByteCompareService = ByteCompareService(),
        recommendationService: RecommendationService = RecommendationService()
    ) {
        self.scanner = scanner
        self.hashService = hashService
        self.byteCompareService = byteCompareService
        self.recommendationService = recommendationService
    }

    public func scan(folders: [URL], options: ScanOptions) async throws -> ScanResult {
        let indexed = try await scanner.scan(folders: folders, options: options)
        var skipped = indexed.skippedFiles
        var groups: [DuplicateGroup] = []

        let filesBySize = Dictionary(grouping: indexed.files, by: \.size)
            .filter { $0.value.count > 1 }

        for (_, sameSizeFiles) in filesBySize {
            try Task.checkCancellation()
            let partialCandidates = try partialHashGroups(for: sameSizeFiles, options: options, skipped: &skipped)

            for candidateFiles in partialCandidates {
                try Task.checkCancellation()
                let shaGroups = try shaGroups(for: candidateFiles, skipped: &skipped)

                for (sha, shaFiles) in shaGroups where shaFiles.count > 1 {
                    try Task.checkCancellation()
                    if options.compareMode == .fast {
                        groups.append(group(files: shaFiles, sha256: sha, level: .sha256Match, options: options))
                    } else {
                        let clusters = try byteConfirmedClusters(shaFiles)
                        for cluster in clusters where cluster.count > 1 {
                            groups.append(group(files: cluster, sha256: sha, level: .byteByByteConfirmed, options: options))
                        }
                    }
                }
            }
        }

        return ScanResult(
            selectedFolders: folders,
            options: options,
            scannedFiles: indexed.files,
            skippedFiles: skipped,
            duplicateGroups: groups.sorted { $0.totalLogicalWastedBytes > $1.totalLogicalWastedBytes }
        )
    }

    private func partialHashGroups(
        for files: [ScannedFile],
        options: ScanOptions,
        skipped: inout [ScannedFile]
    ) throws -> [[ScannedFile]] {
        if options.compareMode == .fast {
            return [files]
        }

        var hashedFiles: [ScannedFile] = []
        for file in files {
            do {
                hashedFiles.append(file.with(partialHash: try hashService.partialHash(for: file.url)))
            } catch {
                skipped.append(file.with(error: error.localizedDescription))
            }
        }

        return Dictionary(grouping: hashedFiles, by: \.partialHash)
            .values
            .filter { $0.count > 1 }
    }

    private func shaGroups(for files: [ScannedFile], skipped: inout [ScannedFile]) throws -> [String: [ScannedFile]] {
        var hashedFiles: [ScannedFile] = []
        for file in files {
            do {
                hashedFiles.append(file.with(sha256: try hashService.sha256(for: file.url)))
            } catch {
                skipped.append(file.with(error: error.localizedDescription))
            }
        }
        return Dictionary(grouping: hashedFiles) { $0.sha256 ?? "" }
            .filter { !$0.key.isEmpty }
    }

    private func byteConfirmedClusters(_ files: [ScannedFile]) throws -> [[ScannedFile]] {
        var clusters: [[ScannedFile]] = []

        fileLoop: for file in files {
            for index in clusters.indices {
                if try byteCompareService.contentsAreEqual(clusters[index][0].url, file.url) {
                    clusters[index].append(file)
                    continue fileLoop
                }
            }
            clusters.append([file])
        }

        return clusters.filter { $0.count > 1 }
    }

    private func group(files: [ScannedFile], sha256: String, level: VerificationLevel, options: ScanOptions) -> DuplicateGroup {
        let base = DuplicateGroup(files: files, sha256: sha256, verificationLevel: level)
        let recommendation = recommendationService.recommendation(for: base, options: options)
        return DuplicateGroup(
            id: base.id,
            files: files,
            sha256: sha256,
            verificationLevel: level,
            recommendedKeepFileID: recommendation.keepFileID,
            recommendedRemovalFileIDs: recommendation.removalFileIDs,
            recommendationReasons: recommendation.reasons
        )
    }
}
