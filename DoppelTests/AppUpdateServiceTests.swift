import Foundation
@testable import DoppelCore
import XCTest

final class AppUpdateServiceTests: XCTestCase {
    func testVersionComparisonTreatsLatestPatchAsNewer() {
        XCTAssertGreaterThan(AppVersion("0.1.2"), AppVersion("0.1.1"))
        XCTAssertGreaterThan(AppVersion("1.0.0"), AppVersion("0.9.9"))
        XCTAssertEqual(AppVersion("v0.1.1"), AppVersion("0.1.1"))
    }

    func testReleaseParserSelectsZipAndChecksumAssets() throws {
        let json = Data(
            """
            {
              "tag_name": "v0.1.2",
              "html_url": "https://github.com/junowoz/doppel/releases/tag/v0.1.2",
              "draft": false,
              "prerelease": false,
              "body": "Release notes",
              "assets": [
                {
                  "name": "Doppel.dmg",
                  "browser_download_url": "https://github.com/junowoz/doppel/releases/download/v0.1.2/Doppel.dmg"
                },
                {
                  "name": "Doppel.app.zip",
                  "browser_download_url": "https://github.com/junowoz/doppel/releases/download/v0.1.2/Doppel.app.zip"
                },
                {
                  "name": "Doppel.app.zip.sha256",
                  "browser_download_url": "https://github.com/junowoz/doppel/releases/download/v0.1.2/Doppel.app.zip.sha256"
                }
              ]
            }
            """.utf8
        )

        let release = try AppUpdateService.release(from: json)

        XCTAssertEqual(release.version, "0.1.2")
        XCTAssertEqual(release.packageURL.lastPathComponent, "Doppel.app.zip")
        XCTAssertEqual(release.checksumURL.lastPathComponent, "Doppel.app.zip.sha256")
    }

    func testChecksumValidationRejectsMismatchedPackage() throws {
        try withTemporaryDirectory { directory in
            let packageURL = try writeFile(directory, "Doppel.app.zip", makeData("package"))
            let checksumData = Data(
                "0000000000000000000000000000000000000000000000000000000000000000  Doppel.app.zip\n".utf8
            )
            let service = AppUpdateService()

            XCTAssertThrowsError(try service.validatePackage(at: packageURL, checksumData: checksumData)) { error in
                XCTAssertTrue(error is AppUpdateError)
            }
        }
    }

    func testReleaseParserRejectsNonGitHubAssets() throws {
        let json = Data(
            """
            {
              "tag_name": "v0.1.2",
              "html_url": "https://github.com/junowoz/doppel/releases/tag/v0.1.2",
              "draft": false,
              "prerelease": false,
              "assets": [
                {
                  "name": "Doppel.app.zip",
                  "browser_download_url": "https://example.com/Doppel.app.zip"
                },
                {
                  "name": "Doppel.app.zip.sha256",
                  "browser_download_url": "https://github.com/junowoz/doppel/releases/download/v0.1.2/Doppel.app.zip.sha256"
                }
              ]
            }
            """.utf8
        )

        XCTAssertThrowsError(try AppUpdateService.release(from: json))
    }
}
