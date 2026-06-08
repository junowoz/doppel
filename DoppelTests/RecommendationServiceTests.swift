import XCTest
@testable import DoppelCore

final class RecommendationServiceTests: XCTestCase {
    func testKeepsIPhonePhotoWithoutCopySuffix() throws {
        try withTemporaryDirectory { directory in
            let original = try ScannedFile(url: writeFile(directory, "IMG_4472.HEIC", makeData("same")))
            let copy = try ScannedFile(url: writeFile(directory, "IMG_4472 2.heic", makeData("same")))
            let group = DuplicateGroup(files: [copy, original], sha256: "hash", verificationLevel: .byteByByteConfirmed)

            let recommendation = RecommendationService().recommendation(for: group, options: .init())

            XCTAssertEqual(recommendation.keepFileID, original.id)
            XCTAssertEqual(recommendation.removalFileIDs, [copy.id])
        }
    }

    func testNeverMarksEveryFileForRemoval() throws {
        try withTemporaryDirectory { directory in
            let only = try ScannedFile(url: writeFile(directory, "only.txt", makeData("same")))
            let group = DuplicateGroup(files: [only], sha256: "hash", verificationLevel: .sha256Match)

            let recommendation = RecommendationService().recommendation(for: group, options: .init())

            XCTAssertEqual(recommendation.keepFileID, only.id)
            XCTAssertTrue(recommendation.removalFileIDs.isEmpty)
        }
    }

    func testHardlinkedFilesAreNotRecommendedForRemoval() throws {
        try withTemporaryDirectory { directory in
            let originalURL = try writeFile(directory, "original.txt", makeData("same"))
            let hardlinkURL = directory.appendingPathComponent("hardlink.txt")
            try FileManager.default.linkItem(at: originalURL, to: hardlinkURL)

            let original = try ScannedFile(url: originalURL)
            let hardlink = try ScannedFile(url: hardlinkURL)
            let group = DuplicateGroup(files: [original, hardlink], sha256: "hash", verificationLevel: .byteByByteConfirmed)

            let recommendation = RecommendationService().recommendation(for: group, options: .init())

            XCTAssertEqual(recommendation.keepFileID, original.id)
            XCTAssertTrue(recommendation.removalFileIDs.isEmpty)
        }
    }
}
