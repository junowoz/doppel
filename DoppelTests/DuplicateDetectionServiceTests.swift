import XCTest
@testable import DoppelCore

final class DuplicateDetectionServiceTests: XCTestCase {
    func testDetectsByteConfirmedDuplicates() async throws {
        try await withTemporaryDirectory { directory in
            _ = try writeFile(directory, "IMG_4472.HEIC", makeData("photo bytes"))
            _ = try writeFile(directory, "IMG_4472 2.heic", makeData("photo bytes"))
            _ = try writeFile(directory, "different.txt", makeData("other bytes"))

            let result = try await DuplicateDetectionService().scan(
                folders: [directory],
                options: ScanOptions(compareMode: .safe)
            )

            XCTAssertEqual(result.duplicateGroups.count, 1)
            XCTAssertEqual(result.duplicateGroups[0].verificationLevel, .byteByByteConfirmed)
            XCTAssertEqual(result.duplicateGroups[0].files.count, 2)
        }
    }

    func testSameSizedDifferentFilesAreNotDuplicates() async throws {
        try await withTemporaryDirectory { directory in
            _ = try writeFile(directory, "one.txt", makeData("abc123"))
            _ = try writeFile(directory, "two.txt", makeData("xyz789"))

            let result = try await DuplicateDetectionService().scan(
                folders: [directory],
                options: ScanOptions(compareMode: .safe)
            )

            XCTAssertTrue(result.duplicateGroups.isEmpty)
        }
    }

    func testScannerSkipsPackagesByDefault() async throws {
        try await withTemporaryDirectory { directory in
            let package = directory.appendingPathComponent("Example.app", isDirectory: true)
            try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
            _ = try writeFile(package, "duplicate.txt", makeData("same"))
            _ = try writeFile(directory, "duplicate.txt", makeData("same"))

            let result = try await DuplicateDetectionService().scan(
                folders: [directory],
                options: ScanOptions(ignorePackages: true)
            )

            XCTAssertTrue(result.duplicateGroups.isEmpty)
        }
    }

    func testFileRemovedDuringScanIsSkipped() async throws {
        try await withTemporaryDirectory { directory in
            let disappearing = try writeFile(directory, "gone.txt", makeData("same"))
            _ = try writeFile(directory, "still.txt", makeData("same"))

            let scanner = FileScannerService(fileDidIndex: { file in
                if file.filename == disappearing.lastPathComponent {
                    try? FileManager.default.removeItem(at: disappearing)
                }
            })

            let result = try await DuplicateDetectionService(scanner: scanner).scan(
                folders: [directory],
                options: ScanOptions(compareMode: .safe)
            )

            XCTAssertTrue(result.duplicateGroups.isEmpty)
            XCTAssertEqual(result.skippedFiles.count, 1)
        }
    }
}
