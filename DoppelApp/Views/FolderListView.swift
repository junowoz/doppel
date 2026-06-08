import SwiftUI

struct FolderListView: View {
    var folders: [URL]
    @Binding var selectedFolder: URL?
    var addFolder: () -> Void
    var removeFolder: () -> Void
    var clearFolders: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            List(selection: $selectedFolder) {
                Section("Folders") {
                    ForEach(folders, id: \.self) { folder in
                        Label(folder.lastPathComponent, systemImage: "folder")
                            .tag(folder as URL?)
                            .help(folder.path)
                    }
                }
            }
            .listStyle(.sidebar)

            HStack {
                Button(action: addFolder) {
                    Label("Add Folder", systemImage: "plus")
                }
                Button(action: removeFolder) {
                    Label("Remove Folder", systemImage: "minus")
                }
                .disabled(selectedFolder == nil)
                Button(action: clearFolders) {
                    Label("Clear", systemImage: "trash.slash")
                }
                .disabled(folders.isEmpty)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .padding([.horizontal, .bottom], 10)
        }
    }
}
