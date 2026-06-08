import XCTest
@testable import DoppelCore

final class ByteCompareServiceTests: XCTestCase {
    func testIdenticalFilesCompareEqual() throws {
        try withTemporaryDirectory { directory in
            let first = try writeFile(directory, "a file.txt", makeData("same bytes"))
            let second = try writeFile(directory, "cópia.txt", makeData("same bytes"))

            XCTAssertTrue(try ByteCompareService().contentsAreEqual(first, second))
        }
    }

    func testSameSizedFilesWithDifferentBytesCompareDifferent() throws {
        try withTemporaryDirectory { directory in
            let first = try writeFile(directory, "IMG_4472.HEIC", makeData("abc123"))
            let second = try writeFile(directory, "IMG_4472 2.heic", makeData("abc124"))

            XCTAssertFalse(try ByteCompareService().contentsAreEqual(first, second))
        }
    }
}
