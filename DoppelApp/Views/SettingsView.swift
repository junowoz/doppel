import AppKit
import DoppelCore
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            Picker("Default compare mode", selection: $viewModel.settings.compareMode) {
                Text("Fast").tag(CompareMode.fast)
                Text("Safe").tag(CompareMode.safe)
                Text("Paranoid").tag(CompareMode.paranoid)
            }
            Toggle("Include macOS packages", isOn: $viewModel.settings.includePackages)
            Button("Check for Updates") {
                NSWorkspace.shared.open(AppMetadata.releasesURL)
            }
            Button("Save") {
                try? viewModel.save()
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }
}
