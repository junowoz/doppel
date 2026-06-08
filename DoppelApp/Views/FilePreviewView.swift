import AppKit
import DoppelCore
import SwiftUI

struct FilePreviewView: View {
    @ObservedObject var viewModel: MainViewModel

    private var file: ScannedFile? {
        viewModel.selectedFile
    }

    private var group: DuplicateGroup? {
        viewModel.selectedGroup
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let file {
                preview(for: file)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text(file.filename)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(file.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    metadata(label: "Size", value: AppFormatters.fileSize(file.size))
                    metadata(label: "SHA-256", value: group?.sha256 ?? file.sha256 ?? "Not available")
                    metadata(label: "Verification", value: group?.verificationLevel.label ?? "Not available")

                    HStack {
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([file.url])
                        } label: {
                            Label("Reveal in Finder", systemImage: "finder")
                        }

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(file.path, forType: .string)
                        } label: {
                            Label("Copy Path", systemImage: "doc.on.doc")
                        }
                    }

                    if let group {
                        HStack {
                            Button {
                                viewModel.markFileToKeep(file, in: group)
                            } label: {
                                Label("Keep This File", systemImage: "checkmark.circle")
                            }
                            .disabled(viewModel.reviewState(for: file, in: group) == .keep && viewModel.selectedRemovalCount(in: group) == group.files.count - 1)

                            Button(role: .destructive) {
                                viewModel.setRemovalSelection(true, file: file, group: group)
                            } label: {
                                Label("Move File to Trash", systemImage: "trash")
                            }
                            .disabled(viewModel.isSelectedForRemoval(file))
                        }
                    }
                }
            } else {
                EmptyStateView(
                    title: "Select a file",
                    message: "Review before moving files."
                )
            }
            Spacer()
        }
        .padding(16)
    }

    @ViewBuilder
    private func preview(for file: ScannedFile) -> some View {
        if file.fileKind == .image, let image = NSImage(contentsOf: file.url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 260)
                .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        } else if let snippet = PreviewService().preview(for: file).textSnippet, !snippet.isEmpty {
            ScrollView {
                Text(snippet)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .frame(minHeight: 160, maxHeight: 240)
            .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        } else {
            VStack(spacing: 10) {
                Image(systemName: "doc")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text(file.fileKind.rawValue.capitalized)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func metadata(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }
}
