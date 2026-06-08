import Foundation

@MainActor
public final class FolderSelectionViewModel: ObservableObject {
    @Published public var folders: [URL]

    public init(folders: [URL] = []) {
        self.folders = folders
    }
}
