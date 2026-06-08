import DoppelCore
import SwiftUI

struct ScanOptionsView: View {
    @Binding var options: ScanOptions

    var body: some View {
        Form {
            Toggle("Include subfolders", isOn: $options.includeSubfolders)
            Toggle("Ignore hidden files", isOn: $options.ignoreHiddenFiles)
            Toggle("Ignore macOS packages", isOn: $options.ignorePackages)
            Toggle("Ignore symlinks", isOn: $options.ignoreSymlinks)

            TextField("Minimum file size", value: $options.minimumFileSize, format: .number)

            Picker("File types", selection: fileTypeSelection) {
                ForEach(FileTypeChoice.allCases, id: \.self) { choice in
                    Text(choice.label).tag(choice)
                }
            }

            Picker("Compare mode", selection: $options.compareMode) {
                Text("Fast").tag(CompareMode.fast)
                Text("Safe").tag(CompareMode.safe)
                Text("Paranoid").tag(CompareMode.paranoid)
            }
            .pickerStyle(.segmented)
        }
        .formStyle(.grouped)
    }

    private var fileTypeSelection: Binding<FileTypeChoice> {
        Binding {
            FileTypeChoice(filter: options.fileTypeFilter)
        } set: { choice in
            options.fileTypeFilter = choice.filter
        }
    }
}

private enum FileTypeChoice: String, CaseIterable, Hashable {
    case all
    case images
    case videos
    case audio
    case documents
    case archives

    init(filter: FileTypeFilter) {
        switch filter {
        case .images: self = .images
        case .videos: self = .videos
        case .audio: self = .audio
        case .documents: self = .documents
        case .archives: self = .archives
        case .all, .customExtensions: self = .all
        }
    }

    var filter: FileTypeFilter {
        switch self {
        case .all: .all
        case .images: .images
        case .videos: .videos
        case .audio: .audio
        case .documents: .documents
        case .archives: .archives
        }
    }

    var label: String {
        switch self {
        case .all: "All"
        case .images: "Images"
        case .videos: "Videos"
        case .audio: "Audio"
        case .documents: "Documents"
        case .archives: "Archives"
        }
    }
}
