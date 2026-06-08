import SwiftUI

struct EmptyStateView: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
