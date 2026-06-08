import Foundation

@MainActor
enum AppFormatters {
    static let bytes: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter
    }()

    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func fileSize(_ value: Int64) -> String {
        bytes.string(fromByteCount: value)
    }

    static func date(_ value: Date?) -> String {
        value.map { date.string(from: $0) } ?? "Unknown"
    }
}
