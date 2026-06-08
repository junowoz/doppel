import AppKit
import DoppelCore
import Foundation

enum AppUpdateInstaller {
    static func launch(stagedUpdate: StagedAppUpdate) async throws {
        let currentBundleURL = Bundle.main.bundleURL
        guard currentBundleURL.pathExtension == "app" else {
            throw AppUpdateError.unsupportedBundleLocation(currentBundleURL.path)
        }

        let helperURL = currentBundleURL
            .appendingPathComponent("Contents/Library/Helpers/DoppelUpdater.app", isDirectory: true)
        guard FileManager.default.fileExists(atPath: helperURL.path) else {
            throw AppUpdateError.missingUpdaterHelper(helperURL.path)
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.arguments = [
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--source", stagedUpdate.appBundleURL.path,
            "--destination", currentBundleURL.path,
            "--cleanup", stagedUpdate.stagingDirectory.path
        ]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: helperURL, configuration: configuration) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
