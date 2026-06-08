import SwiftUI

struct ConfirmationDialogView: View {
    var selectedFileCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected files will be moved to Trash.")
                .font(.headline)
            Text("Doppel never deletes files permanently.")
            Text("At least one file is always kept.")
                .foregroundStyle(.secondary)
            Text("\(selectedFileCount) file(s) selected.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
