import Foundation

public struct ActionLog: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var date: Date
    public var actions: [FileAction]
    public var summary: String

    public init(id: UUID = UUID(), date: Date = Date(), actions: [FileAction], summary: String) {
        self.id = id
        self.date = date
        self.actions = actions
        self.summary = summary
    }
}
