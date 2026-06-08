import Foundation

public struct AppSettings: Codable, Equatable, Hashable, Sendable {
    public var compareMode: CompareMode
    public var includePackages: Bool
    public var primaryFolderPaths: Set<String>

    public init(
        compareMode: CompareMode = .safe,
        includePackages: Bool = false,
        primaryFolderPaths: Set<String> = []
    ) {
        self.compareMode = compareMode
        self.includePackages = includePackages
        self.primaryFolderPaths = primaryFolderPaths
    }
}
