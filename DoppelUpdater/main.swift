import Darwin
import Foundation

private struct UpdaterArguments {
    let processIdentifier: pid_t
    let sourceAppURL: URL
    let destinationAppURL: URL
    let cleanupURL: URL

    init(arguments: [String]) throws {
        var values: [String: String] = [:]
        var index = 1
        while index < arguments.count {
            let key = arguments[index]
            guard key.hasPrefix("--"), index + 1 < arguments.count else {
                throw UpdaterError.invalidArguments
            }
            values[key] = arguments[index + 1]
            index += 2
        }

        guard
            let pidString = values["--pid"],
            let pid = Int32(pidString),
            let source = values["--source"],
            let destination = values["--destination"],
            let cleanup = values["--cleanup"]
        else {
            throw UpdaterError.invalidArguments
        }

        self.processIdentifier = pid
        self.sourceAppURL = URL(fileURLWithPath: source)
        self.destinationAppURL = URL(fileURLWithPath: destination)
        self.cleanupURL = URL(fileURLWithPath: cleanup)
    }
}

private enum UpdaterError: Error, CustomStringConvertible {
    case invalidArguments
    case invalidBundle(String)
    case timeoutWaitingForApp
    case commandFailed(String)

    var description: String {
        switch self {
        case .invalidArguments:
            "Invalid updater arguments."
        case .invalidBundle(let reason):
            "Invalid bundle: \(reason)"
        case .timeoutWaitingForApp:
            "Timed out waiting for Doppel to quit."
        case .commandFailed(let output):
            "Command failed: \(output)"
        }
    }
}

@main
private enum DoppelUpdater {
    static func main() {
        do {
            let arguments = try UpdaterArguments(arguments: CommandLine.arguments)
            try run(arguments)
            exit(EXIT_SUCCESS)
        } catch {
            fputs("DoppelUpdater: \(error)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }

    private static func run(_ arguments: UpdaterArguments) throws {
        try validateAppBundle(arguments.sourceAppURL)
        try waitForAppToQuit(processIdentifier: arguments.processIdentifier)
        try replaceApp(source: arguments.sourceAppURL, destination: arguments.destinationAppURL)
        try openApp(arguments.destinationAppURL)
        cleanup(arguments.cleanupURL)
    }

    private static func waitForAppToQuit(processIdentifier: pid_t) throws {
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline {
            if kill(processIdentifier, 0) != 0 {
                return
            }
            usleep(200_000)
        }
        throw UpdaterError.timeoutWaitingForApp
    }

    private static func replaceApp(source: URL, destination: URL) throws {
        let fileManager = FileManager.default
        guard source.pathExtension == "app", destination.pathExtension == "app" else {
            throw UpdaterError.invalidBundle("Source and destination must be app bundles.")
        }

        let backupURL = fileManager.temporaryDirectory
            .appendingPathComponent("DoppelPrevious-\(UUID().uuidString).app", isDirectory: true)

        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.moveItem(at: destination, to: backupURL)
        }

        do {
            try fileManager.moveItem(at: source, to: destination)
            try validateAppBundle(destination)
            try? fileManager.removeItem(at: backupURL)
        } catch {
            if fileManager.fileExists(atPath: destination.path) {
                try? fileManager.removeItem(at: destination)
            }
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.moveItem(at: backupURL, to: destination)
            }
            throw error
        }
    }

    private static func validateAppBundle(_ appURL: URL) throws {
        let infoPlistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard
            let plist = NSDictionary(contentsOf: infoPlistURL),
            plist["CFBundleIdentifier"] as? String == "com.junowoz.doppel"
        else {
            throw UpdaterError.invalidBundle("Bundle identifier mismatch.")
        }

        let executableURL = appURL.appendingPathComponent("Contents/MacOS/Doppel")
        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            throw UpdaterError.invalidBundle("Executable is missing.")
        }

        let archs = try runProcess("/usr/bin/lipo", ["-archs", executableURL.path])
        guard archs.split(whereSeparator: \.isWhitespace) == ["arm64"] else {
            throw UpdaterError.invalidBundle("Executable is not Apple Silicon-only.")
        }

        _ = try runProcess("/usr/bin/codesign", ["--verify", "--deep", "--strict", appURL.path])
    }

    private static func openApp(_ appURL: URL) throws {
        _ = try runProcess("/usr/bin/open", [appURL.path])
    }

    private static func cleanup(_ cleanupURL: URL) {
        try? FileManager.default.removeItem(at: cleanupURL)
    }

    @discardableResult
    private static func runProcess(_ executablePath: String, _ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        guard process.terminationStatus == 0 else {
            throw UpdaterError.commandFailed(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

