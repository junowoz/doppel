import XCTest
@testable import DoppelCore

final class FileActionServiceTests: XCTestCase {
    func testValidationFailsWhenRemovalFileChanged() throws {
        try withTemporaryDirectory { directory in
            let keep = try ScannedFile(url: writeFile(directory, "keep.txt", makeData("same")))
            let removeURL = try writeFile(directory, "remove.txt", makeData("same"))
            let remove = try ScannedFile(url: removeURL)
            let group = DuplicateGroup(files: [keep, remove], sha256: try HashService().sha256(for: keep.url), verificationLevel: .byteByByteConfirmed)
            try makeData("changed").write(to: removeURL)

            XCTAssertThrowsError(
                try FileActionService().validateMovePlan(
                    group: group,
                    keepFileID: keep.id,
                    removalFileIDs: [remove.id],
                    compareMode: .paranoid
                )
            )
        }
    }

    func testValidationFailsWhenKeepFileIsMissing() throws {
        try withTemporaryDirectory { directory in
            let keepURL = try writeFile(directory, "keep.txt", makeData("same"))
            let keep = try ScannedFile(url: keepURL)
            let remove = try ScannedFile(url: writeFile(directory, "remove.txt", makeData("same")))
            let group = DuplicateGroup(files: [keep, remove], sha256: try HashService().sha256(for: keep.url), verificationLevel: .byteByByteConfirmed)
            try FileManager.default.removeItem(at: keepURL)

            XCTAssertThrowsError(
                try FileActionService().validateMovePlan(
                    group: group,
                    keepFileID: keep.id,
                    removalFileIDs: [remove.id],
                    compareMode: .safe
                )
            )
        }
    }

    func testSafeModeRepeatsByteComparisonBeforeMoving() throws {
        try withTemporaryDirectory { directory in
            let keep = try ScannedFile(url: writeFile(directory, "keep.txt", makeData("same")))
            let removeURL = try writeFile(directory, "remove.txt", makeData("same"))
            let remove = try ScannedFile(url: removeURL)
            let group = DuplicateGroup(files: [keep, remove], sha256: try HashService().sha256(for: keep.url), verificationLevel: .byteByByteConfirmed)

            try makeData("diff").write(to: removeURL)

            XCTAssertThrowsError(
                try FileActionService().validateMovePlan(
                    group: group,
                    keepFileID: keep.id,
                    removalFileIDs: [remove.id],
                    compareMode: .safe
                )
            )
        }
    }
}
