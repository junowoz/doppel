import Foundation

public enum FileActionError: Error, LocalizedError, Equatable {
    case keepFileMissing(String)
    case removalFileMissing(String)
    case allFilesSelected
    case sizeChanged(String)
    case hashChanged(String)
    case byteComparisonFailed(String)
    case unknownFileID

    public var errorDescription: String? {
        switch self {
        case .keepFileMissing(let path): "Keep file is missing: \(path)"
        case .removalFileMissing(let path): "Removal file is missing: \(path)"
        case .allFilesSelected: "At least one file must be kept."
        case .sizeChanged(let path): "File size changed before action: \(path)"
        case .hashChanged(let path): "File hash changed before action: \(path)"
        case .byteComparisonFailed(let path): "Byte comparison failed before action: \(path)"
        case .unknownFileID: "Selected file was not found in the duplicate group."
        }
    }
}

public struct FileActionService {
    private let hashService: HashService
    private let byteCompareService: ByteCompareService
    private let fileManager: FileManager

    public init(
        hashService: HashService = HashService(),
        byteCompareService: ByteCompareService = ByteCompareService(),
        fileManager: FileManager = .default
    ) {
        self.hashService = hashService
        self.byteCompareService = byteCompareService
        self.fileManager = fileManager
    }

    public func validateMovePlan(
        group: DuplicateGroup,
        keepFileID: ScannedFile.ID,
        removalFileIDs: Set<ScannedFile.ID>,
        compareMode: CompareMode
    ) throws {
        guard !removalFileIDs.isEmpty else { return }
        guard removalFileIDs.count < group.files.count else {
            throw FileActionError.allFilesSelected
        }
        guard let keepFile = group.files.first(where: { $0.id == keepFileID }) else {
            throw FileActionError.unknownFileID
        }
        guard fileManager.fileExists(atPath: keepFile.path) else {
            throw FileActionError.keepFileMissing(keepFile.path)
        }

        let currentKeepSize = try hashService.fileSize(for: keepFile.url)
        guard currentKeepSize == group.size else {
            throw FileActionError.sizeChanged(keepFile.path)
        }
        let currentKeepHash = try hashService.sha256(for: keepFile.url)
        guard currentKeepHash == group.sha256 else {
            throw FileActionError.hashChanged(keepFile.path)
        }

        for removalID in removalFileIDs {
            guard let removalFile = group.files.first(where: { $0.id == removalID }) else {
                throw FileActionError.unknownFileID
            }
            guard fileManager.fileExists(atPath: removalFile.path) else {
                throw FileActionError.removalFileMissing(removalFile.path)
            }
            guard try hashService.fileSize(for: removalFile.url) == group.size else {
                throw FileActionError.sizeChanged(removalFile.path)
            }
            guard try hashService.sha256(for: removalFile.url) == group.sha256 else {
                throw FileActionError.hashChanged(removalFile.path)
            }
            if compareMode != .fast {
                guard try byteCompareService.contentsAreEqual(keepFile.url, removalFile.url) else {
                    throw FileActionError.byteComparisonFailed(removalFile.path)
                }
            }
        }
    }

    public func moveSelectedToTrash(
        group: DuplicateGroup,
        keepFileID: ScannedFile.ID,
        removalFileIDs: Set<ScannedFile.ID>,
        compareMode: CompareMode
    ) throws -> ActionLog {
        try validateMovePlan(
            group: group,
            keepFileID: keepFileID,
            removalFileIDs: removalFileIDs,
            compareMode: compareMode
        )

        var actions: [FileAction] = []
        for removalID in removalFileIDs {
            guard let file = group.files.first(where: { $0.id == removalID }) else {
                throw FileActionError.unknownFileID
            }
            var trashedURL: NSURL?
            try fileManager.trashItem(at: file.url, resultingItemURL: &trashedURL)
            actions.append(FileAction(
                kind: .moveToTrash,
                fileID: file.id,
                sourcePath: file.path,
                destinationPath: trashedURL?.path
            ))
        }

        return ActionLog(actions: actions, summary: "Moved \(actions.count) file(s) to Trash.")
    }
}
