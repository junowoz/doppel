import AppKit
import DoppelCore
import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @StateObject private var updateViewModel = AppUpdateViewModel()
    @State private var selectedFolder: URL?
    @State private var showTrashConfirmation = false
    @State private var showUpdater = false

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel, selectedFolder: $selectedFolder)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
        } content: {
            DuplicateGroupsView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 420, ideal: 640)
        } detail: {
            FilePreviewView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 300, ideal: 380, max: 520)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.startScan()
                } label: {
                    Label("Scan", systemImage: "play.fill")
                }
                .disabled(viewModel.folders.isEmpty || viewModel.scanState == .indexing)

                Button {
                    viewModel.pauseScan()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(viewModel.scanState != .indexing)

                Button {
                    viewModel.resumeScan()
                } label: {
                    Label("Resume", systemImage: "forward.fill")
                }
                .disabled(viewModel.scanState != .paused)

                Button {
                    viewModel.cancelScan()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
                .disabled(viewModel.scanState != .indexing && viewModel.scanState != .paused)
            }

            ToolbarItemGroup {
                Button(role: .destructive) {
                    showTrashConfirmation = true
                } label: {
                    Label("Move selected to Trash", systemImage: "trash")
                }
                .disabled(!viewModel.canMoveSelectedFiles)

                Button {
                    chooseJSONExport()
                } label: {
                    Label("Export JSON", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.scanResult == nil)

                Button {
                    showUpdater = true
                } label: {
                    Label("Check for Updates", systemImage: "arrow.down.circle")
                }
                .help("Check GitHub Releases and install a verified Doppel update.")

                Button {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            BottomSummaryBar(viewModel: viewModel)
        }
        .animation(.snappy(duration: 0.22), value: viewModel.scanState)
        .animation(.snappy(duration: 0.22), value: viewModel.totalDuplicateGroups)
        .alert("Selected files will be moved to Trash.", isPresented: $showTrashConfirmation) {
            Button("Move to Trash", role: .destructive) {
                Task {
                    await viewModel.moveSelectedToTrash()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Doppel never deletes files permanently. Review before moving files.")
        }
        .sheet(isPresented: $showUpdater) {
            AppUpdateSheetView(viewModel: updateViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .doppelShowUpdater)) { _ in
            showUpdater = true
        }
    }

    private func chooseJSONExport() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "doppel-report.json"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try viewModel.exportJSON(to: url)
        } catch {
            viewModel.statusMessage = error.localizedDescription
        }
    }
}
