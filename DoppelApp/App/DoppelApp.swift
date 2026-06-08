import AppKit
import DoppelCore
import SwiftUI

@main
struct DoppelApp: App {
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
                    NSWorkspace.shared.open(AppMetadata.releasesURL)
                }
            }
        }
    }
}
