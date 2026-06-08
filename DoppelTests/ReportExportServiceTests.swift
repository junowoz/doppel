import XCTest
@testable import DoppelCore

final class ReportExportServiceTests: XCTestCase {
    func testExportsJSONReport() throws {
        try withTemporaryDirectory { directory in
            let file = try ScannedFile(url: writeFile(directory, "a.txt", makeData("same")))
            let group = DuplicateGroup(files: [file], sha256: "hash", verificationLevel: .sha256Match)
            let result = ScanResult(
                selectedFolders: [directory],
                options: .init(),
                scannedFiles: [file],
                skippedFiles: [],
                duplicateGroups: [group]
            )

            let data = try ReportExportService().jsonData(for: result)
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            XCTAssertEqual(object?["appVersion"] as? String, "0.1.0")
            XCTAssertNotNil(object?["groups"])
        }
    }

    func testExportsCSVReportWithEscapedPaths() throws {
        try withTemporaryDirectory { directory in
            let file = try ScannedFile(url: writeFile(directory, "emoji 😀.txt", makeData("same")))
            let group = DuplicateGroup(files: [file], sha256: "hash", verificationLevel: .sha256Match)
            let result = ScanResult(
                selectedFolders: [directory],
                options: .init(),
                scannedFiles: [file],
                skippedFiles: [],
                duplicateGroups: [group]
            )

            let csv = try ReportExportService().csvString(for: result)

            XCTAssertTrue(csv.contains("\"emoji 😀.txt\""))
            XCTAssertTrue(csv.contains("group_id"))
        }
    }
}
