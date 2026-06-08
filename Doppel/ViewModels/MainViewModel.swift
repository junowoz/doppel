import Combine
import Foundation

@MainActor
public final class MainViewModel: ObservableObject {
    @Published public var folders: [URL]
    @Published public var options: ScanOptions
    @Published public var scanState: ScanState
    @Published public var scanResult: ScanResult?
    @Published public var selectedGroupID: DuplicateGroup.ID?
    @Published public var selectedFileID: ScannedFile.ID?
    @Published public var selectedRemovalFileIDs: Set<ScannedFile.ID>
    @Published public var statusMessage: String
    @Published public var actionLogs: [ActionLog]
    @Published public var currentFileDescription: String

    private let duplicateDetectionService: DuplicateDetectionService
    private let fileActionService: FileActionService
    private let reportExportService: ReportExportService
    private var scanTask: Task<Void, Never>?

    public init(
        folders: [URL] = [],
        options: ScanOptions = ScanOptions(),
        duplicateDetectionService: DuplicateDetectionService = DuplicateDetectionService(),
        fileActionService: FileActionService = FileActionService(),
        reportExportService: ReportExportService = ReportExportService()
    ) {
        self.folders = folders
        self.options = options
        self.scanState = .idle
        self.scanResult = nil
        self.selectedGroupID = nil
        self.selectedFileID = nil
        self.selectedRemovalFileIDs = []
        self.statusMessage = "Ready"
        self.actionLogs = []
        self.currentFileDescription = ""
        self.duplicateDetectionService = duplicateDetectionService
        self.fileActionService = fileActionService
        self.reportExportService = reportExportService
    }

    public var duplicateGroups: [DuplicateGroup] {
        scanResult?.duplicateGroups ?? []
    }

    public var selectedGroup: DuplicateGroup? {
        duplicateGroups.first { $0.id == selectedGroupID }
    }

    public var selectedFile: ScannedFile? {
        if let selectedFileID {
            return duplicateGroups.flatMap(\.files).first { $0.id == selectedFileID }
        }
        return selectedGroup?.files.first
    }

    public var totalScannedFiles: Int {
        scanResult?.scannedFiles.count ?? 0
    }

    public var totalDuplicateGroups: Int {
        scanResult?.duplicateGroups.count ?? 0
    }

    public var totalRemovableFiles: Int {
        scanResult?.removableFileCount ?? 0
    }

    public var potentialSavings: Int64 {
        scanResult?.potentialSavings ?? 0
    }

    public var canMoveSelectedFiles: Bool {
        !selectedRemovalFileIDs.isEmpty && scanState != .movingToTrash
    }

    public func addFolder(_ folder: URL) {
        guard !folders.contains(folder) else { return }
        folders.append(folder)
        statusMessage = "Folder added"
    }

    public func removeSelectedFolder(_ folder: URL?) {
        guard let folder else { return }
        folders.removeAll { $0 == folder }
        statusMessage = "Folder removed"
    }

    public func clearFolders() {
        folders.removeAll()
        scanResult = nil
        selectedGroupID = nil
        selectedFileID = nil
        selectedRemovalFileIDs.removeAll()
        statusMessage = "Cleared"
    }

    public func startScan() {
        guard !folders.isEmpty else {
            statusMessage = "Add a folder first"
            return
        }
        scanTask?.cancel()
        scanState = .indexing
        statusMessage = "Scanning"
        scanResult = nil
        selectedGroupID = nil
        selectedFileID = nil
        selectedRemovalFileIDs.removeAll()

        let folders = folders
        let options = options
        let service = duplicateDetectionService

        scanTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let result = try await service.scan(folders: folders, options: options)
                await MainActor.run {
                    self?.applyScanResult(result)
                }
            } catch is CancellationError {
                await MainActor.run {
                    self?.scanState = .cancelled
                    self?.statusMessage = "Cancelled"
                }
            } catch {
                await MainActor.run {
                    self?.scanState = .error
                    self?.statusMessage = error.localizedDescription
                }
            }
        }
    }

    public func pauseScan() {
        guard scanState != .finished else { return }
        scanState = .paused
        statusMessage = "Paused"
    }

    public func resumeScan() {
        guard scanState == .paused else { return }
        scanState = .indexing
        statusMessage = "Resumed"
    }

    public func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        scanState = .cancelled
        statusMessage = "Cancelled"
    }

    public func select(group: DuplicateGroup) {
        selectedGroupID = group.id
        selectedFileID = group.files.first?.id
    }

    public func select(file: ScannedFile, in group: DuplicateGroup) {
        selectedGroupID = group.id
        selectedFileID = file.id
        currentFileDescription = file.filename
    }

    public func isSelectedForRemoval(_ file: ScannedFile) -> Bool {
        selectedRemovalFileIDs.contains(file.id)
    }

    public func setRemovalSelection(_ selected: Bool, file: ScannedFile, group: DuplicateGroup) {
        if selected {
            let currentlySelectedInGroup = selectedRemovalFileIDs.intersection(Set(group.files.map(\.id)))
            guard currentlySelectedInGroup.count < group.files.count - 1 else {
                statusMessage = "At least one file is always kept."
                return
            }
            selectedRemovalFileIDs.insert(file.id)
        } else {
            selectedRemovalFileIDs.remove(file.id)
        }
    }

    public func moveSelectedToTrash() async {
        guard let result = scanResult else { return }
        scanState = .movingToTrash
        statusMessage = "Selected files will be moved to Trash."

        let selectedIDs = selectedRemovalFileIDs
        let options = result.options
        let actionService = fileActionService
        var logs: [ActionLog] = []
        var movedIDs: Set<ScannedFile.ID> = []

        do {
            for group in result.duplicateGroups {
                let removalIDs = selectedIDs.intersection(Set(group.files.map(\.id)))
                guard !removalIDs.isEmpty else { continue }
                let keepID = group.recommendedKeepFileID ?? group.files.first(where: { !removalIDs.contains($0.id) })?.id
                guard let keepID else { continue }

                let log = try actionService.moveSelectedToTrash(
                    group: group,
                    keepFileID: keepID,
                    removalFileIDs: removalIDs,
                    compareMode: options.compareMode
                )
                logs.append(log)
                movedIDs.formUnion(removalIDs)
            }

            actionLogs.append(contentsOf: logs)
            selectedRemovalFileIDs.subtract(movedIDs)
            removeMovedFilesFromResult(movedIDs)
            scanState = .finished
            statusMessage = "Moved \(movedIDs.count) file(s) to Trash."
        } catch {
            scanState = .error
            statusMessage = error.localizedDescription
        }
    }

    public func exportJSON(to url: URL) throws {
        guard let result = scanResult else { return }
        let data = try reportExportService.jsonData(for: result)
        try data.write(to: url, options: .atomic)
        statusMessage = "Exported JSON"
    }

    private func applyScanResult(_ result: ScanResult) {
        scanResult = result
        selectedGroupID = result.duplicateGroups.first?.id
        selectedFileID = result.duplicateGroups.first?.files.first?.id
        selectedRemovalFileIDs = Set(result.duplicateGroups.flatMap(\.recommendedRemovalFileIDs))
        scanState = .finished
        statusMessage = result.duplicateGroups.isEmpty ? "No exact duplicates found" : "Finished"
    }

    private func removeMovedFilesFromResult(_ movedIDs: Set<ScannedFile.ID>) {
        guard var result = scanResult else { return }
        result.duplicateGroups = result.duplicateGroups.compactMap { group in
            let remainingFiles = group.files.filter { !movedIDs.contains($0.id) }
            guard remainingFiles.count > 1 else { return nil }
            return DuplicateGroup(
                id: group.id,
                files: remainingFiles,
                sha256: group.sha256,
                verificationLevel: group.verificationLevel,
                recommendedKeepFileID: group.recommendedKeepFileID,
                recommendedRemovalFileIDs: group.recommendedRemovalFileIDs.subtracting(movedIDs),
                recommendationReasons: group.recommendationReasons
            )
        }
        scanResult = result
    }
}
