import Foundation

public struct FilePreview: Codable, Equatable, Hashable, Sendable {
    public var title: String
    public var subtitle: String
    public var textSnippet: String?

    public init(title: String, subtitle: String, textSnippet: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.textSnippet = textSnippet
    }
}

public struct PreviewService: Sendable {
    public init() {}

    public func preview(for file: ScannedFile, textLimit: Int = 4096) -> FilePreview {
        var snippet: String?
        if file.fileKind == .document || file.fileExtension.lowercased() == "txt" {
            if let data = try? Data(contentsOf: file.url, options: .mappedIfSafe) {
                snippet = String(data: data.prefix(textLimit), encoding: .utf8)
            }
        }
        return FilePreview(title: file.filename, subtitle: file.path, textSnippet: snippet)
    }
}
