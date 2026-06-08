import DoppelCore
import SwiftUI

struct BottomSummaryBar: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        HStack(spacing: 16) {
            summary("Files", "\(viewModel.totalScannedFiles)")
            summary("Groups", "\(viewModel.totalDuplicateGroups)")
            summary("Removable", "\(viewModel.totalRemovableFiles)")
            summary("Potential", AppFormatters.fileSize(viewModel.potentialSavings))
            Spacer()
            Text(viewModel.statusMessage)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.bar)
    }

    private func summary(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }
}
