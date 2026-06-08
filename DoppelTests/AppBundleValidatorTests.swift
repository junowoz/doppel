import Foundation
@testable import DoppelCore
import XCTest

final class AppBundleValidatorTests: XCTestCase {
    func testThinArm64ExecutableIsAccepted() throws {
        try withTemporaryDirectory { directory in
            let executableURL = directory.appendingPathComponent("Doppel")
            try machOHeader(cpuType: 0x0100000c).write(to: executableURL)

            XCTAssertTrue(try AppBundleValidator.executableIsAppleSiliconOnly(at: executableURL))
        }
    }

    func testThinX8664ExecutableIsRejected() throws {
        try withTemporaryDirectory { directory in
            let executableURL = directory.appendingPathComponent("Doppel")
            try machOHeader(cpuType: 0x01000007).write(to: executableURL)

            XCTAssertFalse(try AppBundleValidator.executableIsAppleSiliconOnly(at: executableURL))
        }
    }

    func testUniversalExecutableIsRejected() throws {
        try withTemporaryDirectory { directory in
            let executableURL = directory.appendingPathComponent("Doppel")
            try fatHeader(cpuTypes: [0x0100000c, 0x01000007]).write(to: executableURL)

            XCTAssertFalse(try AppBundleValidator.executableIsAppleSiliconOnly(at: executableURL))
        }
    }

    func testAppBundleUnderTestIsAcceptedWhenProvided() throws {
        guard let path = ProcessInfo.processInfo.environment["DOPPEL_APP_BUNDLE_UNDER_TEST"] else {
            throw XCTSkip("Set DOPPEL_APP_BUNDLE_UNDER_TEST to validate a signed app bundle.")
        }

        try AppBundleValidator.validateDoppelAppBundle(at: URL(fileURLWithPath: path))
    }

    private func machOHeader(cpuType: UInt32) -> Data {
        var data = Data()
        appendLittleEndian(0xfeedfacf, to: &data)
        appendLittleEndian(cpuType, to: &data)
        appendLittleEndian(0, to: &data)
        appendLittleEndian(0, to: &data)
        appendLittleEndian(0, to: &data)
        appendLittleEndian(0, to: &data)
        appendLittleEndian(0, to: &data)
        appendLittleEndian(0, to: &data)
        return data
    }

    private func fatHeader(cpuTypes: [UInt32]) -> Data {
        var data = Data()
        appendBigEndian(0xcafebabe, to: &data)
        appendBigEndian(UInt32(cpuTypes.count), to: &data)
        for cpuType in cpuTypes {
            appendBigEndian(cpuType, to: &data)
            appendBigEndian(0, to: &data)
            appendBigEndian(0, to: &data)
            appendBigEndian(0, to: &data)
            appendBigEndian(0, to: &data)
        }
        return data
    }

    private func appendLittleEndian(_ value: UInt32, to data: inout Data) {
        data.append(contentsOf: [
            UInt8(value & 0xff),
            UInt8((value >> 8) & 0xff),
            UInt8((value >> 16) & 0xff),
            UInt8((value >> 24) & 0xff)
        ])
    }

    private func appendBigEndian(_ value: UInt32, to data: inout Data) {
        data.append(contentsOf: [
            UInt8((value >> 24) & 0xff),
            UInt8((value >> 16) & 0xff),
            UInt8((value >> 8) & 0xff),
            UInt8(value & 0xff)
        ])
    }
}
