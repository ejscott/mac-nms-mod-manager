import Foundation
import Testing
@testable import ModManagerCore

@Test func extractsArm64FromFatMachO() throws {
    var bytes: [UInt8] = []
    bytes += be32(0xcafebabe)
    bytes += be32(1)
    bytes += be32(0x0100000c)
    bytes += be32(0)
    bytes += be32(32)
    bytes += be32(8)
    bytes += be32(0)
    bytes += Array(repeating: 0, count: 4)
    bytes += [0xcf, 0xfa, 0xed, 0xfe, 0x0c, 0x00, 0x00, 0x01]

    let slice = try MachOReader.arm64Slice(in: Data(bytes))
    #expect(slice.offset == 32)
    #expect(slice.size == 8)
}

@Test func rejectsFatMachOWithoutArm64() {
    var bytes: [UInt8] = []
    bytes += be32(0xcafebabe)
    bytes += be32(1)
    bytes += be32(0x01000007)
    bytes += be32(3)
    bytes += be32(32)
    bytes += be32(4)
    bytes += be32(0)
    bytes += Array(repeating: 0, count: 8)
    #expect(throws: MachOError.self) { try MachOReader.arm64Slice(in: Data(bytes)) }
}

private func be32(_ value: UInt32) -> [UInt8] {
    [UInt8(value >> 24), UInt8((value >> 16) & 0xff), UInt8((value >> 8) & 0xff), UInt8(value & 0xff)]
}
