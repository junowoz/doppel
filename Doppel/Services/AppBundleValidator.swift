import Foundation
import Security

public enum AppBundleValidator {
    public static func validateDoppelAppBundle(
        at appBundleURL: URL,
        expectedVersion: String? = nil,
        fileManager: FileManager = .default
    ) throws {
        guard appBundleURL.pathExtension == "app" else {
            throw AppUpdateError.invalidAppBundle("The update is not an app bundle.")
        }
        guard let bundle = Bundle(url: appBundleURL) else {
            throw AppUpdateError.invalidAppBundle("The bundle metadata could not be read.")
        }
        guard bundle.bundleIdentifier == AppMetadata.bundleIdentifier else {
            throw AppUpdateError.invalidAppBundle("The bundle identifier does not match Doppel.")
        }
        if let expectedVersion {
            guard let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                  AppVersion(version) == AppVersion(expectedVersion) else {
                throw AppUpdateError.invalidAppBundle("The bundle version does not match the release.")
            }
        }

        let executableURL = appBundleURL.appendingPathComponent("Contents/MacOS/Doppel")
        guard fileManager.fileExists(atPath: executableURL.path) else {
            throw AppUpdateError.invalidAppBundle("The app executable is missing.")
        }
        guard try executableIsAppleSiliconOnly(at: executableURL) else {
            throw AppUpdateError.invalidAppBundle("The app is not Apple Silicon-only.")
        }

        try validateCodeSignature(at: appBundleURL)
    }

    public static func executableIsAppleSiliconOnly(at executableURL: URL) throws -> Bool {
        let data = try Data(contentsOf: executableURL, options: [.mappedIfSafe])
        let architectures = try machOArchitectures(in: data)
        return architectures == [machOCPUTypeARM64]
    }

    private static func validateCodeSignature(at appBundleURL: URL) throws {
        var staticCode: SecStaticCode?
        let createStatus = SecStaticCodeCreateWithPath(appBundleURL as CFURL, SecCSFlags(), &staticCode)
        guard createStatus == errSecSuccess, let staticCode else {
            throw AppUpdateError.invalidAppBundle("The app signature could not be read.")
        }

        var error: Unmanaged<CFError>?
        let flags = SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckAllArchitectures)
        let verifyStatus = SecStaticCodeCheckValidityWithErrors(staticCode, flags, nil, &error)
        guard verifyStatus == errSecSuccess else {
            let retainedError = error?.takeRetainedValue()
            let message = retainedError.map { CFErrorCopyDescription($0) as String? } ?? nil
            throw AppUpdateError.invalidAppBundle(message ?? "The app signature is invalid.")
        }
    }

    private static func machOArchitectures(in data: Data) throws -> Set<UInt32> {
        guard data.count >= 8 else {
            throw AppUpdateError.invalidAppBundle("The app executable is too small.")
        }

        let magicLittleEndian = try uint32(in: data, at: 0, endian: .little)
        let magicBigEndian = try uint32(in: data, at: 0, endian: .big)

        if machOThinMagics.contains(magicLittleEndian) {
            return [try uint32(in: data, at: 4, endian: .little)]
        }
        if machOThinMagics.contains(magicBigEndian) {
            return [try uint32(in: data, at: 4, endian: .big)]
        }
        if magicBigEndian == fatMagic || magicBigEndian == fatMagic64 {
            return try fatArchitectures(in: data, endian: .big, uses64BitRecords: magicBigEndian == fatMagic64)
        }
        if magicBigEndian == fatCigam || magicBigEndian == fatCigam64 {
            return try fatArchitectures(in: data, endian: .little, uses64BitRecords: magicBigEndian == fatCigam64)
        }

        throw AppUpdateError.invalidAppBundle("The app executable is not a Mach-O binary.")
    }

    private static func fatArchitectures(in data: Data, endian: Endian, uses64BitRecords: Bool) throws -> Set<UInt32> {
        let count = Int(try uint32(in: data, at: 4, endian: endian))
        let recordSize = uses64BitRecords ? 32 : 20
        guard count > 0, data.count >= 8 + count * recordSize else {
            throw AppUpdateError.invalidAppBundle("The app executable has an invalid fat Mach-O header.")
        }

        var architectures = Set<UInt32>()
        for index in 0..<count {
            let offset = 8 + index * recordSize
            architectures.insert(try uint32(in: data, at: offset, endian: endian))
        }
        return architectures
    }

    private static func uint32(in data: Data, at offset: Int, endian: Endian) throws -> UInt32 {
        guard offset >= 0, offset + 4 <= data.count else {
            throw AppUpdateError.invalidAppBundle("The app executable has an invalid Mach-O header.")
        }

        let value = data[offset..<offset + 4].reduce(UInt32(0)) { partial, byte in
            (partial << 8) | UInt32(byte)
        }
        switch endian {
        case .big:
            return value
        case .little:
            return value.byteSwapped
        }
    }

    private enum Endian {
        case big
        case little
    }

    private static let machOCPUTypeARM64: UInt32 = 0x0100000c
    private static let machOThinMagics: Set<UInt32> = [
        0xfeedface,
        0xfeedfacf
    ]
    private static let fatMagic: UInt32 = 0xcafebabe
    private static let fatCigam: UInt32 = 0xbebafeca
    private static let fatMagic64: UInt32 = 0xcafebabf
    private static let fatCigam64: UInt32 = 0xbfbafeca
}
