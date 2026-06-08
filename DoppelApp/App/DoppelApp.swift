import AppKit
import DoppelCore
import SwiftUI

@main
struct DoppelApp: App {
    init() {
        try? AppUpdateService().cleanupTemporaryFiles()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1_100, minHeight: 680)
        }

        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("Doppel Help") {
                    NSWorkspace.shared.open(AppMetadata.repositoryURL)
                }
                Button("Check for Updates") {
                    NotificationCenter.default.post(name: .doppelShowUpdater, object: nil)
                }
            }
        }
    }
}
