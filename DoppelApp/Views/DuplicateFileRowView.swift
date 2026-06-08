import DoppelCore
import SwiftUI

struct DuplicateFileRowView: View {
    var file: ScannedFile
    var group: DuplicateGroup
    var isSelectedForRemoval: Bool
    var toggleRemoval: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: toggleRemoval) {
                Image(systemName: isSelectedForRemoval ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelectedForRemoval ? .red : .secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 20)
                .disabled(file.id == group.recommendedKeepFileID)

            Image(systemName: iconName)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.filename)
                        .lineLimit(1)
                    badge
                }
                Text(file.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(AppFormatters.fileSize(file.size)) · Created \(AppFormatters.date(file.creationDate)) · Modified \(AppFormatters.date(file.modificationDate))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.leading, 18)
        .padding(.vertical, 3)
    }

    private var badge: some View {
        Group {
            if file.id == group.recommendedKeepFileID {
                Text("Keep")
                    .foregroundStyle(.green)
                    .background(.green.opacity(0.12), in: Capsule())
            } else if isSelectedForRemoval {
                Text("Remove")
                    .foregroundStyle(.red)
                    .background(.red.opacity(0.12), in: Capsule())
            } else {
                Text("Needs review")
                    .foregroundStyle(.yellow)
                    .background(.yellow.opacity(0.15), in: Capsule())
            }
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch file.fileKind {
        case .image: "photo"
        case .video: "film"
        case .audio: "waveform"
        case .document: "doc.text"
        case .archive: "archivebox"
        case .folder: "folder"
        case .other: "doc"
        }
    }
}
