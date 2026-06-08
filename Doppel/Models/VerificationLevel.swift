public enum VerificationLevel: String, Codable, Hashable, CaseIterable, Sendable {
    case sameSizeOnly
    case partialHashMatch
    case sha256Match
    case byteByByteConfirmed

    public var label: String {
        switch self {
        case .sameSizeOnly: "Same size only"
        case .partialHashMatch: "Partial hash match"
        case .sha256Match: "SHA-256 match"
        case .byteByByteConfirmed: "Byte-by-byte confirmed"
        }
    }
}
