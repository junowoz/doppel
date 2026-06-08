import XCTest
@testable import DoppelCore

@MainActor
final class MainViewModelTests: XCTestCase {
    func testSelectingCurrentKeepFileForRemovalSwapsKeepFile() throws {
        try withTemporaryDirectory { directory in
            let first = try ScannedFile(url: writeFile(directory, "first.wav", makeData("same")))
            let second = try ScannedFile(url: writeFile(directory, "second.wav", makeData("same")))
            let group = DuplicateGroup(
                files: [first, second],
                sha256: "hash",
                verificationLevel: .byteByByteConfirmed,
                recommendedKeepFileID: first.id,
                recommendedRemovalFileIDs: [second.id]
            )
            let viewModel = MainViewModel()
            viewModel.scanResult = scanResult(group: group)
            viewModel.selectedRemovalFileIDs = [second.id]

            viewModel.setRemovalSelection(true, file: first, group: group)

            XCTAssertEqual(viewModel.selectedRemovalFileIDs, [first.id])
            XCTAssertEqual(viewModel.duplicateGroups[0].recommendedKeepFileID, second.id)
            XCTAssertEqual(viewModel.duplicateGroups[0].recommendedRemovalFileIDs, [first.id])
        }
    }

    func testMarkFileToKeepSelectsOtherFilesForRemoval() throws {
        try withTemporaryDirectory { directory in
            let first = try ScannedFile(url: writeFile(directory, "first.wav", makeData("same")))
            let second = try ScannedFile(url: writeFile(directory, "second.wav", makeData("same")))
            let third = try ScannedFile(url: writeFile(directory, "third.wav", makeData("same")))
            let group = DuplicateGroup(
                files: [first, second, third],
                sha256: "hash",
                verificationLevel: .byteByByteConfirmed,
                recommendedKeepFileID: first.id,
                recommendedRemovalFileIDs: [second.id, third.id]
            )
            let viewModel = MainViewModel()
            viewModel.scanResult = scanResult(group: group)
            viewModel.selectedRemovalFileIDs = [second.id, third.id]

            viewModel.markFileToKeep(second, in: group)

            XCTAssertEqual(viewModel.selectedRemovalFileIDs, [first.id, third.id])
            XCTAssertEqual(viewModel.duplicateGroups[0].recommendedKeepFileID, second.id)
            XCTAssertEqual(viewModel.reviewState(for: second, in: viewModel.duplicateGroups[0]), .keep)
            XCTAssertEqual(viewModel.reviewState(for: first, in: viewModel.duplicateGroups[0]), .remove)
        }
    }

    private func scanResult(group: DuplicateGroup) -> ScanResult {
        ScanResult(
            selectedFolders: [],
            options: ScanOptions(),
            scannedFiles: group.files,
            skippedFiles: [],
            duplicateGroups: [group]
        )
    }
}
