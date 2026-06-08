import DoppelCore
import SwiftUI

struct DuplicateGroupsView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        Group {
            if viewModel.scanState == .indexing {
                ScanProgressView(state: viewModel.scanState, message: viewModel.statusMessage)
            } else if viewModel.duplicateGroups.isEmpty {
                EmptyStateView(
                    title: "No duplicate groups",
                    message: "Add a folder, scan it, and review exact duplicate matches before moving anything to Trash."
                )
            } else {
                List(selection: $viewModel.selectedGroupID) {
                    ForEach(viewModel.duplicateGroups) { group in
                        Section {
                            DuplicateGroupRowView(
                                group: group,
                                selectedRemovalCount: viewModel.selectedRemovalCount(in: group),
                                selectedSavings: viewModel.selectedSavings(in: group)
                            )
                                .tag(group.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.select(group: group)
                                }

                            ForEach(group.files) { file in
                                DuplicateFileRowView(
                                    file: file,
                                    isSelectedForRemoval: viewModel.isSelectedForRemoval(file),
                                    reviewState: viewModel.reviewState(for: file, in: group),
                                    toggleRemoval: {
                                        viewModel.toggleRemovalSelection(for: file, in: group)
                                    },
                                    keepFile: {
                                        viewModel.markFileToKeep(file, in: group)
                                    }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.select(file: file, in: group)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
}
