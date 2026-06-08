import DoppelCore
import SwiftUI

struct DuplicateGroupRowView: View {
    var group: DuplicateGroup

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: group.containsSameUnderlyingFile ? "link" : "doc.on.doc")
                .foregroundStyle(group.containsSameUnderlyingFile ? .gray : .blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(group.files.count) matching files")
                    .font(.headline)
                Text("\(group.removableCount) removable · \(AppFormatters.fileSize(group.size)) each · saves \(AppFormatters.fileSize(group.totalLogicalWastedBytes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(group.verificationLevel.label)
                .font(.caption)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.blue.opacity(0.12), in: Capsule())
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}
