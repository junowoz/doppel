import Foundation

public struct DuplicateGroupViewModel: Identifiable, Hashable {
    public var group: DuplicateGroup

    public var id: DuplicateGroup.ID { group.id }
    public var title: String { "\(group.files.count) files" }
    public var subtitle: String { "\(group.removableCount) removable" }

    public init(group: DuplicateGroup) {
        self.group = group
    }
}
