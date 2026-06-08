import Foundation

public enum AppUpdateStatus: Equatable {
    case idle
    case checking
    case upToDate(version: String)
    case updateAvailable(AppRelease)
    case downloading(AppRelease)
    case readyToInstall(StagedAppUpdate)
    case installing(AppRelease)
    case failed(String)
}

@MainActor
public final class AppUpdateViewModel: ObservableObject {
    @Published public private(set) var status: AppUpdateStatus = .idle

    private let service: AppUpdateService
    private var stagedUpdate: StagedAppUpdate?

    public init(service: AppUpdateService = AppUpdateService()) {
        self.service = service
    }

    public var isBusy: Bool {
        switch status {
        case .checking, .downloading, .installing:
            true
        case .idle, .upToDate, .updateAvailable, .readyToInstall, .failed:
            false
        }
    }

    public func checkForUpdates() async {
        service.cleanup(stagedUpdate)
        stagedUpdate = nil
        status = .checking

        do {
            let release = try await service.latestRelease()
            if service.isUpdateAvailable(release) {
                status = .updateAvailable(release)
            } else {
                status = .upToDate(version: AppMetadata.version)
            }
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    public func downloadAvailableUpdate() async -> StagedAppUpdate? {
        guard case .updateAvailable(let release) = status else { return nil }
        status = .downloading(release)

        do {
            let staged = try await service.downloadAndStage(release)
            stagedUpdate = staged
            status = .readyToInstall(staged)
            return staged
        } catch {
            status = .failed(error.localizedDescription)
            return nil
        }
    }

    public func markInstalling(_ stagedUpdate: StagedAppUpdate) {
        status = .installing(stagedUpdate.release)
    }

    public func fail(_ error: Error) {
        status = .failed(error.localizedDescription)
    }

    public func cleanupStagedUpdate() {
        service.cleanup(stagedUpdate)
        stagedUpdate = nil
        if case .readyToInstall = status {
            status = .idle
        }
    }
}

