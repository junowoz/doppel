import XCTest
@testable import DoppelCore

final class HashServiceTests: XCTestCase {
    func testSHA256MatchesKnownDigest() throws {
        try withTemporaryDirectory { directory in
            let file = try writeFile(directory, "hello.txt", makeData("hello"))
            let digest = try HashService().sha256(for: file)

            XCTAssertEqual(digest, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        }
    }

    func testPartialHashChangesWhenTailChanges() throws {
        try withTemporaryDirectory { directory in
            let service = HashService(partialChunkSize: 4)
            let first = try writeFile(directory, "first.bin", makeData("abcd-middle-wxyz"))
            let second = try writeFile(directory, "second.bin", makeData("abcd-middle-zzzz"))

            XCTAssertNotEqual(try service.partialHash(for: first), try service.partialHash(for: second))
        }
    }

    func testZeroByteFilesHaveStableHash() throws {
        try withTemporaryDirectory { directory in
            let file = try writeFile(directory, "empty", Data())

            XCTAssertEqual(try HashService().sha256(for: file), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        }
    }
}
