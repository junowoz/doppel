import AppKit
import DoppelCore
import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var selectedFolder: URL?

    var body: some View {
        VStack(spacing: 0) {
            FolderListView(
                folders: viewModel.folders,
                selectedFolder: $selectedFolder,
                addFolder: chooseFolder,
                removeFolder: { viewModel.removeSelectedFolder(selectedFolder) },
                clearFolders: viewModel.clearFolders
            )

            Divider()

            ScanOptionsView(options: $viewModel.options)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.prompt = "Add Folder"

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            viewModel.addFolder(url)
        }
        selectedFolder = panel.urls.first
    }
}
