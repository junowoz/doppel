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
    }
}
