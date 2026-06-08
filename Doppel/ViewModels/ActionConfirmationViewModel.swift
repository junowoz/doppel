import Foundation

public struct ActionConfirmationViewModel: Equatable, Hashable {
    public var title: String
    public var message: String
    public var selectedFileCount: Int

    public init(title: String, message: String, selectedFileCount: Int) {
        self.title = title
        self.message = message
        self.selectedFileCount = selectedFileCount
    }
}
