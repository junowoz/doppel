import DoppelCore
import SwiftUI

struct ScanProgressView: View {
    var state: ScanState
    var message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.headline)
            Text(state.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
