import Foundation

public struct FileScanOutput: Sendable {
    public var files: [ScannedFile]
    public var skippedFiles: [ScannedFile]

    public init(files: [ScannedFile], skippedFiles: [ScannedFile]) {
        self.files = files
        self.skippedFiles = skippedFiles
    }
}

public final class FileScannerService: @unchecked Sendable {
    public typealias FileDidIndex = (ScannedFile) -> Void

    private let fileManager: FileManager
    private let fileDidIndex: FileDidIndex?

    public init(fileManager: FileManager = .default, fileDidIndex: FileDidIndex? = nil) {
        self.fileManager = fileManager
        self.fileDidIndex = fileDidIndex
    }

    public func scan(folders: [URL], options: ScanOptions) async throws -> FileScanOutput {
        var files: [ScannedFile] = []
        var skipped: [ScannedFile] = []

        for folder in folders {
            try Task.checkCancellation()
            try await scan(url: folder, options: options, files: &files, skipped: &skipped, isRoot: true)
        }

        return FileScanOutput(files: files, skippedFiles: skipped)
    }

    private func scan(
        url: URL,
        options: ScanOptions,
        files: inout [ScannedFile],
        skipped: inout [ScannedFile],
        isRoot: Bool
    ) async throws {
        try Task.checkCancellation()

        let values = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .isRegularFileKey,
            .isHiddenKey,
            .isSymbolicLinkKey,
            .isPackageKey
        ])
        let isDirectory = values?.isDirectory ?? false
        let isSymlink = values?.isSymbolicLink ?? false
        let isHidden = values?.isHidden ?? url.lastPathComponent.hasPrefix(".")
        let isPackage = values?.isPackage ?? ScannedFile.hasPackageExtension(url)

        if options.ignoreHiddenFiles && isHidden {
            return
        }
        if options.ignoreSymlinks && isSymlink {
            return
        }

        if isDirectory {
            if !isRoot && options.ignorePackages && isPackage {
                return
            }
            let children = (try? fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .isRegularFileKey,
                    .isHiddenKey,
                    .isSymbolicLinkKey,
                    .isPackageKey,
                    .fileSizeKey
                ],
                options: []
            )) ?? []

            for child in children {
                let childValues = try? child.resourceValues(forKeys: [.isDirectoryKey])
                if childValues?.isDirectory == true {
                    if options.includeSubfolders {
                        try await scan(url: child, options: options, files: &files, skipped: &skipped, isRoot: false)
                    }
                } else {
                    try await scan(url: child, options: options, files: &files, skipped: &skipped, isRoot: false)
                }
            }
            return
        }

        do {
            let file = try ScannedFile(url: url)
            guard file.isReadable else {
                skipped.append(file.with(error: "File is not readable"))
                return
            }
            guard file.size >= options.minimumFileSize else {
                return
            }
            guard options.fileTypeFilter.allows(file) else {
                return
            }
            files.append(file)
            fileDidIndex?(file)
        } catch {
            if var skippedFile = try? ScannedFile(url: url) {
                skippedFile.error = error.localizedDescription
                skipped.append(skippedFile)
            }
        }
    }
}
