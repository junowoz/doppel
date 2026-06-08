import Foundation
import XCTest

@discardableResult
func withTemporaryDirectory<T>(
    named name: String = UUID().uuidString,
    _ body: (URL) throws -> T
) throws -> T {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("DoppelTests", isDirectory: true)
        .appendingPathComponent(name, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    return try body(root)
}

@discardableResult
func withTemporaryDirectory<T>(
    named name: String = UUID().uuidString,
    _ body: (URL) async throws -> T
) async throws -> T {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("DoppelTests", isDirectory: true)
        .appendingPathComponent(name, isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    return try await body(root)
}

@discardableResult
func writeFile(_ directory: URL, _ name: String, _ contents: Data) throws -> URL {
    let url = directory.appendingPathComponent(name)
    try contents.write(to: url, options: .atomic)
    return url
}

func makeData(_ string: String) -> Data {
    Data(string.utf8)
}
