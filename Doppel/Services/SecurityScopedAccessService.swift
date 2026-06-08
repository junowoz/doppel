import Foundation

public struct SecurityScopedAccessService: Sendable {
    public init() {}

    public func access<T>(_ url: URL, body: () throws -> T) rethrows -> T {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try body()
    }
}
