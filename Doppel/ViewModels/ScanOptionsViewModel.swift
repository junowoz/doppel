import Foundation

@MainActor
public final class ScanOptionsViewModel: ObservableObject {
    @Published public var options: ScanOptions

    public init(options: ScanOptions = ScanOptions()) {
        self.options = options
    }
}
