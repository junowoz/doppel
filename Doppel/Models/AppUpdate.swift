import Foundation

public struct AppVersion: Comparable, Hashable, Sendable {
    public let rawValue: String
    private let components: [Int]

    public init(_ rawValue: String) {
        self.rawValue = rawValue
        self.components = rawValue
            .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            .split { !$0.isNumber }
            .map { Int($0) ?? 0 }
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.compare(to: rhs) == 0
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.compare(to: rhs) < 0
    }

    private func compare(to other: AppVersion) -> Int {
        let count = max(components.count, other.components.count)
        for index in 0..<count {
            let left = index < components.count ? components[index] : 0
            let right = index < other.components.count ? other.components[index] : 0
            if left < right { return -1 }
            if left > right { return 1 }
        }
        return 0
    }
}

public struct AppRelease: Equatable, Sendable {
    public let version: String
    public let tagName: String
    public let pageURL: URL
    public let packageURL: URL
    public let checksumURL: URL
    public let releaseNotes: String?

    public init(
        version: String,
        tagName: String,
        pageURL: URL,
        packageURL: URL,
        checksumURL: URL,
        releaseNotes: String? = nil
    ) {
        self.version = version
        self.tagName = tagName
        self.pageURL = pageURL
        self.packageURL = packageURL
        self.checksumURL = checksumURL
        self.releaseNotes = releaseNotes
    }
}

public struct StagedAppUpdate: Equatable, Sendable {
    public let release: AppRelease
    public let stagingDirectory: URL
    public let appBundleURL: URL

    public init(release: AppRelease, stagingDirectory: URL, appBundleURL: URL) {
        self.release = release
        self.stagingDirectory = stagingDirectory
        self.appBundleURL = appBundleURL
    }
}

public enum AppUpdateError: Error, LocalizedError {
    case draftOrPrerelease
    case invalidReleaseResponse
    case missingReleaseAsset(String)
    case invalidChecksumFile
    case checksumMismatch(expected: String, actual: String)
    case invalidAppBundle(String)
    case unsupportedBundleLocation(String)
    case missingUpdaterHelper(String)
    case commandFailed(command: String, output: String)
    case networkResponse(Int)

    public var errorDescription: String? {
        switch self {
        case .draftOrPrerelease:
            "The latest GitHub release is not a stable public release."
        case .invalidReleaseResponse:
            "The GitHub release response could not be read."
        case .missingReleaseAsset(let name):
            "The GitHub release is missing \(name)."
        case .invalidChecksumFile:
            "The update checksum file is invalid."
        case .checksumMismatch:
            "The downloaded update did not match its published checksum."
        case .invalidAppBundle(let reason):
            "The downloaded app bundle is invalid: \(reason)."
        case .unsupportedBundleLocation:
            "Doppel must be running from a .app bundle to update itself."
        case .missingUpdaterHelper:
            "The updater helper is missing from the app bundle."
        case .commandFailed(let command, let output):
            "\(command) failed. \(output)"
        case .networkResponse(let statusCode):
            "GitHub returned HTTP \(statusCode)."
        }
    }
}

