import Foundation

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var settings: AppSettings
    private let service: AppSettingsService

    public init(service: AppSettingsService = AppSettingsService()) {
        self.service = service
        self.settings = service.load()
    }

    public func save() throws {
        try service.save(settings)
    }
}
