import Foundation

public struct ReportExportService: Sendable {
    private let encoder: JSONEncoder

    public init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    public func jsonData(for result: ScanResult) throws -> Data {
        try encoder.encode(Report(result: result))
    }

    public func csvString(for result: ScanResult) throws -> String {
        var rows: [[String]] = [[
            "group_id",
            "kept",
            "filename",
            "path",
            "size",
            "sha256",
            "verification",
            "recommendation"
        ]]

        for group in result.duplicateGroups {
            for file in group.files {
                rows.append([
                    group.id.uuidString,
                    file.id == group.recommendedKeepFileID ? "true" : "false",
                    file.filename,
                    file.path,
                    String(file.size),
                    group.sha256,
                    group.verificationLevel.rawValue,
                    group.recommendedRemovalFileIDs.contains(file.id) ? "remove" : "keep"
                ])
            }
        }

        return rows.map { $0.map(csvEscape).joined(separator: ",") }.joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

private struct Report: Encodable {
    var appVersion: String
    var scanDate: Date
    var selectedFolders: [String]
    var scanOptions: ScanOptions
    var groups: [Group]
    var skippedFiles: [Skipped]

    init(result: ScanResult) {
        self.appVersion = result.appVersion
        self.scanDate = result.scanDate
        self.selectedFolders = result.selectedFolders.map(\.path)
        self.scanOptions = result.options
        self.groups = result.duplicateGroups.map(Group.init)
        self.skippedFiles = result.skippedFiles.map(Skipped.init)
    }

    struct Group: Encodable {
        var id: UUID
        var keptFileID: UUID?
        var duplicateFileIDs: [UUID]
        var size: Int64
        var sha256: String
        var verification: VerificationLevel
        var files: [File]

        init(group: DuplicateGroup) {
            self.id = group.id
            self.keptFileID = group.recommendedKeepFileID
            self.duplicateFileIDs = Array(group.recommendedRemovalFileIDs)
            self.size = group.size
            self.sha256 = group.sha256
            self.verification = group.verificationLevel
            self.files = group.files.map { File(file: $0, group: group) }
        }
    }

    struct File: Encodable {
        var id: UUID
        var filename: String
        var path: String
        var size: Int64
        var sha256: String?
        var actionRecommendation: String

        init(file: ScannedFile, group: DuplicateGroup) {
            self.id = file.id
            self.filename = file.filename
            self.path = file.path
            self.size = file.size
            self.sha256 = file.sha256
            self.actionRecommendation = group.recommendedRemovalFileIDs.contains(file.id) ? "remove" : "keep"
        }
    }

    struct Skipped: Encodable {
        var path: String
        var error: String?

        init(file: ScannedFile) {
            self.path = file.path
            self.error = file.error
        }
    }
}
