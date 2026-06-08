import Foundation
import UniformTypeIdentifiers

public enum FileKind: String, Codable, Hashable, CaseIterable, Sendable {
    case image
    case video
    case audio
    case document
    case archive
    case folder
    case other

    public static func classify(url: URL, typeIdentifier: String?) -> FileKind {
        if let typeIdentifier, let type = UTType(typeIdentifier) {
            if type.conforms(to: .image) { return .image }
            if type.conforms(to: .movie) { return .video }
            if type.conforms(to: .audio) { return .audio }
            if type.conforms(to: .pdf) || type.conforms(to: .text) { return .document }
        }

        let ext = url.pathExtension.lowercased()
        if ["heic", "heif", "jpg", "jpeg", "png", "gif", "tiff", "webp"].contains(ext) { return .image }
        if ["mov", "mp4", "m4v", "avi", "mkv"].contains(ext) { return .video }
        if ["mp3", "m4a", "wav", "aiff", "flac"].contains(ext) { return .audio }
        if ["pdf", "txt", "rtf", "doc", "docx", "pages", "md"].contains(ext) { return .document }
        if ["zip", "tar", "gz", "bz2", "xz", "7z", "rar"].contains(ext) { return .archive }
        return .other
    }
}
