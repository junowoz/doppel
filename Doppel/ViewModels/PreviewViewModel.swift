import Foundation

@MainActor
public final class PreviewViewModel: ObservableObject {
    @Published public var preview: FilePreview?
    private let service: PreviewService

    public init(service: PreviewService = PreviewService()) {
        self.service = service
    }

    public func load(file: ScannedFile?) {
        preview = file.map { service.preview(for: $0) }
    }
}
