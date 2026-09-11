import CryptoKit
import Foundation

public enum MachOError: LocalizedError {
    case tooSmall
    case unsupportedContainer
    case arm64SliceMissing
    case malformedSlice

    public var errorDescription: String? {
        switch self {
        case .tooSmall: "The executable is too small to be a Mach-O file."
        case .unsupportedContainer: "Only universal and thin 64-bit Mach-O executables are supported."
        case .arm64SliceMissing: "The executable has no ARM64 slice."
        case .malformedSlice: "The ARM64 slice extends outside the executable."
        }
    }
}

public struct MachOSlice: Equatable, Sendable {
    public var offset: Int
    public var size: Int
    public var data: Data
}

public enum MachOReader {
    private static let fatMagic: UInt32 = 0xcafebabe
    private static let fatMagic64: UInt32 = 0xcafebabf
    private static let mhMagic64LE: UInt32 = 0xfeedfacf
    private static let cpuTypeARM64: UInt32 = 0x0100000c

    public static func arm64Slice(in data: Data) throws -> MachOSlice {
        guard data.count >= 8 else { throw MachOError.tooSmall }
        let bigMagic = readUInt32(data, 0, .big)
        if bigMagic == fatMagic || bigMagic == fatMagic64 {
            let count = Int(readUInt32(data, 4, .big))
            let is64 = bigMagic == fatMagic64
            let entrySize = is64 ? 32 : 20
            guard count >= 1, count <= 64, data.count >= 8 + count * entrySize else { throw MachOError.malformedSlice }
            for index in 0..<count {
                let base = 8 + index * entrySize
                guard readUInt32(data, base, .big) == cpuTypeARM64 else { continue }
                let offset: UInt64 = is64 ? readUInt64(data, base + 8, .big) : UInt64(readUInt32(data, base + 8, .big))
                let size: UInt64 = is64 ? readUInt64(data, base + 16, .big) : UInt64(readUInt32(data, base + 12, .big))
                guard offset <= Int.max, size <= Int.max, offset + size <= data.count else { throw MachOError.malformedSlice }
                let range = Int(offset)..<Int(offset + size)
                return MachOSlice(offset: Int(offset), size: Int(size), data: data.subdata(in: range))
            }
            throw MachOError.arm64SliceMissing
        }

        let littleMagic = readUInt32(data, 0, .little)
        guard littleMagic == mhMagic64LE else { throw MachOError.unsupportedContainer }
        guard readUInt32(data, 4, .little) == cpuTypeARM64 else { throw MachOError.arm64SliceMissing }
        return MachOSlice(offset: 0, size: data.count, data: data)
    }

    public static func fingerprint(data: Data) throws -> BinaryFingerprint {
        let slice = try arm64Slice(in: data)
        return BinaryFingerprint(
            universalSHA256: sha256(data),
            arm64SHA256: sha256(slice.data),
            fileSize: UInt64(data.count)
        )
    }

    public static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private enum Endian { case big, little }
    private static func readUInt32(_ data: Data, _ offset: Int, _ endian: Endian) -> UInt32 {
        let bytes = data[offset..<(offset + 4)]
        return bytes.enumerated().reduce(0) { partial, item in
            let shift = endian == .big ? (3 - item.offset) * 8 : item.offset * 8
            return partial | UInt32(item.element) << UInt32(shift)
        }
    }
    private static func readUInt64(_ data: Data, _ offset: Int, _ endian: Endian) -> UInt64 {
        let bytes = data[offset..<(offset + 8)]
        return bytes.enumerated().reduce(0) { partial, item in
            let shift = endian == .big ? (7 - item.offset) * 8 : item.offset * 8
            return partial | UInt64(item.element) << UInt64(shift)
        }
    }
}
