import Foundation

public final class AppUpdateService: @unchecked Sendable {
    private let session: URLSession
    private let fileManager: FileManager
    private let hashService: HashService
    private let latestReleaseAPIURL: URL

    public init(
        latestReleaseAPIURL: URL = AppMetadata.latestReleaseAPIURL,
        session: URLSession = URLSession(configuration: AppUpdateService.ephemeralConfiguration()),
        fileManager: FileManager = .default,
        hashService: HashService = HashService()
    ) {
        self.latestReleaseAPIURL = latestReleaseAPIURL
        self.session = session
        self.fileManager = fileManager
        self.hashService = hashService
    }

    public static func ephemeralConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        return configuration
    }

    public static func release(from data: Data) throws -> AppRelease {
        let response = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)
        guard !response.draft, !response.prerelease else {
            throw AppUpdateError.draftOrPrerelease
        }

        guard
            let package = response.assets.first(where: { $0.name == "Doppel.app.zip" }),
            let checksum = response.assets.first(where: { $0.name == "Doppel.app.zip.sha256" })
        else {
            throw AppUpdateError.missingReleaseAsset("Doppel.app.zip and Doppel.app.zip.sha256")
        }
        guard
            response.htmlURL.host == "github.com",
            package.browserDownloadURL.host == "github.com",
            checksum.browserDownloadURL.host == "github.com"
        else {
            throw AppUpdateError.invalidReleaseResponse
        }

        let version = response.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        return AppRelease(
            version: version,
            tagName: response.tagName,
            pageURL: response.htmlURL,
            packageURL: package.browserDownloadURL,
            checksumURL: checksum.browserDownloadURL,
            releaseNotes: response.body
        )
    }

    public static func checksum(from data: Data) throws -> String {
        guard let text = String(data: data, encoding: .utf8) else {
            throw AppUpdateError.invalidChecksumFile
        }

        guard let token = text.split(whereSeparator: \.isWhitespace).first else {
            throw AppUpdateError.invalidChecksumFile
        }

        let checksum = String(token).lowercased()
        let hexCharacters = CharacterSet(charactersIn: "0123456789abcdef")
        guard checksum.count == 64, checksum.unicodeScalars.allSatisfy({ hexCharacters.contains($0) }) else {
            throw AppUpdateError.invalidChecksumFile
        }
        return checksum
    }

    public func latestRelease() async throws -> AppRelease {
        var request = URLRequest(url: latestReleaseAPIURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("Doppel/\(AppMetadata.version)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
        return try Self.release(from: data)
    }

    public func isUpdateAvailable(_ release: AppRelease, currentVersion: String = AppMetadata.version) -> Bool {
        AppVersion(release.version) > AppVersion(currentVersion)
    }

    public func downloadAndStage(_ release: AppRelease) async throws -> StagedAppUpdate {
        try cleanupTemporaryFiles()

        let stagingDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("DoppelUpdate-\(UUID().uuidString)", isDirectory: true)
        let extractedDirectory = stagingDirectory.appendingPathComponent("Extracted", isDirectory: true)
        let packageURL = stagingDirectory.appendingPathComponent("Doppel.app.zip")

        do {
            try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: extractedDirectory, withIntermediateDirectories: true)
            try await download(release.packageURL, to: packageURL)
            let checksumData = try await data(from: release.checksumURL)
            try validatePackage(at: packageURL, checksumData: checksumData)
            try unzip(packageURL, to: extractedDirectory)

            let appBundleURL = try extractedAppBundle(in: extractedDirectory)
            try validateAppBundle(appBundleURL, expectedVersion: release.version)
            return StagedAppUpdate(
                release: release,
                stagingDirectory: stagingDirectory,
                appBundleURL: appBundleURL
            )
        } catch {
            try? fileManager.removeItem(at: stagingDirectory)
            throw error
        }
    }

    public func validatePackage(at packageURL: URL, checksumData: Data) throws {
        let expected = try Self.checksum(from: checksumData)
        let actual = try hashService.sha256(for: packageURL)
        guard expected == actual else {
            throw AppUpdateError.checksumMismatch(expected: expected, actual: actual)
        }
    }

    public func cleanup(_ stagedUpdate: StagedAppUpdate?) {
        guard let stagedUpdate else { return }
        try? fileManager.removeItem(at: stagedUpdate.stagingDirectory)
    }

    public func cleanupTemporaryFiles() throws {
        let temporaryDirectory = fileManager.temporaryDirectory
        let contents = try fileManager.contentsOfDirectory(
            at: temporaryDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        for url in contents where isDoppelTemporaryDirectory(url) {
            try? fileManager.removeItem(at: url)
        }
    }

    private func download(_ url: URL, to destinationURL: URL) async throws {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("Doppel/\(AppMetadata.version)", forHTTPHeaderField: "User-Agent")

        let (downloadedURL, response) = try await session.download(for: request)
        try validateHTTPResponse(response)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: downloadedURL, to: destinationURL)
    }

    private func data(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("Doppel/\(AppMetadata.version)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)
        return data
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AppUpdateError.networkResponse(httpResponse.statusCode)
        }
    }

    private func unzip(_ packageURL: URL, to destinationURL: URL) throws {
        try runProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/ditto"),
            arguments: ["-x", "-k", packageURL.path, destinationURL.path]
        )
    }

    private func extractedAppBundle(in directory: URL) throws -> URL {
        let directURL = directory.appendingPathComponent("Doppel.app", isDirectory: true)
        if fileManager.fileExists(atPath: directURL.path) {
            return directURL
        }

        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        if let appURL = contents.first(where: { $0.lastPathComponent == "Doppel.app" && $0.pathExtension == "app" }) {
            return appURL
        }

        throw AppUpdateError.invalidAppBundle("Doppel.app was not found in the archive.")
    }

    private func validateAppBundle(_ appBundleURL: URL, expectedVersion: String) throws {
        try AppBundleValidator.validateDoppelAppBundle(
            at: appBundleURL,
            expectedVersion: expectedVersion,
            fileManager: fileManager
        )
    }

    @discardableResult
    private func runProcess(executableURL: URL, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            throw AppUpdateError.commandFailed(
                command: ([executableURL.path] + arguments).joined(separator: " "),
                output: output.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isDoppelTemporaryDirectory(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        return name.hasPrefix("DoppelUpdate-") || name.hasPrefix("DoppelPrevious-")
    }
}

private struct GitHubReleaseResponse: Decodable {
    let tagName: String
    let htmlURL: URL
    let draft: Bool
    let prerelease: Bool
    let body: String?
    let assets: [GitHubReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case draft
        case prerelease
        case body
        case assets
    }
}

private struct GitHubReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}
