import Compression
import Foundation

public enum ModInspectionSource: String, Codable, Sendable {
    case macHGPAKManifest
    case amumssLuaDeclarations
}

public struct ModAssetInspection: Equatable, Sendable {
    public var source: ModInspectionSource
    public var assetPaths: [String]
    public var warnings: [String]

    public init(source: ModInspectionSource, assetPaths: [String], warnings: [String] = []) {
        self.source = source
        self.assetPaths = assetPaths
        self.warnings = warnings
    }
}

public struct ModCompatibilityMatch: Identifiable, Equatable, Sendable {
    public var modID: UUID
    public var modName: String
    public var sharedPaths: [String]
    public var active: Bool
    public var id: UUID { modID }
}

public enum ModCompatibilityAnalyzer {
    public static func matches(paths: [String], against mods: [ModRecord], excluding excludedID: UUID? = nil) -> [ModCompatibilityMatch] {
        let candidate = Set(paths.map(normalizeAssetPath))
        guard !candidate.isEmpty else { return [] }
        return mods.compactMap { mod in
            guard mod.id != excludedID, let paths = mod.assetPaths else { return nil }
            let shared = candidate.intersection(paths.map(normalizeAssetPath)).sorted()
            guard !shared.isEmpty else { return nil }
            return ModCompatibilityMatch(modID: mod.id, modName: mod.name, sharedPaths: shared, active: mod.enabled)
        }
        .sorted { $0.modName.localizedCaseInsensitiveCompare($1.modName) == .orderedAscending }
    }

    public static func activeConflictCount(in mods: [ModRecord]) -> Int {
        var pairs = Set<String>()
        for mod in mods where mod.enabled {
            for match in matches(paths: mod.assetPaths ?? [], against: mods.filter(\.enabled), excluding: mod.id) {
                let ids = [mod.id.uuidString, match.modID.uuidString].sorted()
                pairs.insert(ids.joined(separator: ":"))
            }
        }
        return pairs.count
    }
}

public enum ModAssetInspector {
    public static func inspect(_ url: URL) throws -> ModAssetInspection {
        switch ModInputClassifier.classify(url) {
        case .macHGPAK:
            return try inspectMacHGPAK(url)
        case .amumssLua:
            return try inspectAMUMSSLua(url)
        default:
            throw ModInspectionError.unsupportedInput
        }
    }

    public static func inspectMacHGPAK(_ url: URL) throws -> ModAssetInspection {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        guard data.count >= 0x30, data.prefix(5) == Data("HGPAK".utf8) else { throw ModInspectionError.invalidHGPAK }
        let version = try data.uint64LE(at: 8)
        let fileCount = try data.uint64LE(at: 16)
        let chunkCount = try data.uint64LE(at: 24)
        let isCompressed = data[32] != 0
        let dataOffset = try data.uint64LE(at: 40)
        guard version == 2, fileCount > 0, fileCount <= 1_000_000, chunkCount <= 1_000_000 else {
            throw ModInspectionError.invalidHGPAK
        }
        let fileIndexEnd = try checkedInt(0x30 + fileCount * 0x20)
        guard fileIndexEnd <= data.count else { throw ModInspectionError.truncatedHGPAK }
        let manifestSize = try data.uint64LE(at: 0x30 + 24)
        guard manifestSize <= 64 * 1024 * 1024 else { throw ModInspectionError.invalidHGPAK }

        let manifestData: Data
        if isCompressed {
            let chunkIndexStart = fileIndexEnd
            let chunkIndexEnd = try checkedInt(UInt64(chunkIndexStart) + chunkCount * 8)
            let payloadStart = try checkedInt(dataOffset)
            guard chunkIndexEnd <= data.count, payloadStart >= chunkIndexEnd, payloadStart <= data.count else {
                throw ModInspectionError.truncatedHGPAK
            }
            let chunksNeeded = Int((manifestSize + 0x1FFFF) / 0x20000)
            guard chunksNeeded <= Int(chunkCount) else { throw ModInspectionError.truncatedHGPAK }
            var decoded = Data()
            var chunkOffset = payloadStart
            for index in 0..<chunksNeeded {
                let compressedSize = try checkedInt(try data.uint64LE(at: chunkIndexStart + index * 8))
                guard compressedSize > 0, compressedSize <= 0x20000 else { throw ModInspectionError.invalidHGPAK }
                let storedSize = roundUp16(compressedSize)
                guard chunkOffset <= data.count, storedSize <= data.count - chunkOffset else { throw ModInspectionError.truncatedHGPAK }
                let chunk = data.subdata(in: chunkOffset..<(chunkOffset + compressedSize))
                if compressedSize == 0x20000 {
                    decoded.append(chunk)
                } else {
                    decoded.append(try decodeLZ4Block(chunk))
                }
                chunkOffset += storedSize
            }
            guard manifestSize <= decoded.count else { throw ModInspectionError.truncatedHGPAK }
            manifestData = decoded.prefix(Int(manifestSize))
        } else {
            let start = try checkedInt(dataOffset)
            guard start <= data.count, Int(manifestSize) <= data.count - start else { throw ModInspectionError.truncatedHGPAK }
            let end = start + Int(manifestSize)
            manifestData = data.subdata(in: start..<end)
        }

        guard let manifest = String(data: manifestData, encoding: .utf8) else { throw ModInspectionError.invalidManifest }
        let paths = manifest.split(whereSeparator: \.isNewline).map { normalizeAssetPath(String($0)) }.filter { !$0.isEmpty }
        guard paths.count == Int(fileCount) - 1 else { throw ModInspectionError.invalidManifest }
        return ModAssetInspection(source: .macHGPAKManifest, assetPaths: Array(Set(paths)).sorted())
    }

    public static func inspectAMUMSSLua(_ url: URL) throws -> ModAssetInspection {
        let text = try String(contentsOf: url, encoding: .utf8)
        let regex = try NSRegularExpression(pattern: #"[\"']([^\"'\r\n]+?\.MBIN)[\"']"#, options: [.caseInsensitive])
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let paths = regex.matches(in: text, range: range).compactMap { match -> String? in
            guard let swiftRange = Range(match.range(at: 1), in: text) else { return nil }
            return normalizeAssetPath(String(text[swiftRange]))
        }
        let uniquePaths = Array(Set(paths)).sorted()
        var warnings = ["Lua scripts are build recipes. They must be applied to current vanilla assets and compiled into a Mac HGPAK before the game can load them."]
        if text.contains("MBIN_FILE_SOURCE") && uniquePaths.isEmpty {
            warnings.append("The target path appears to be generated dynamically, so static analysis could not identify it.")
        } else {
            warnings.append("Static Lua analysis is conservative; dynamically constructed paths and exact edit-level merge safety require an AMUMSS-aware conversion step.")
        }
        return ModAssetInspection(source: .amumssLuaDeclarations, assetPaths: uniquePaths, warnings: warnings)
    }
}

public enum ModInspectionError: LocalizedError {
    case unsupportedInput
    case invalidHGPAK
    case truncatedHGPAK
    case invalidManifest
    case decompressionFailed
    case integerOverflow

    public var errorDescription: String? {
        switch self {
        case .unsupportedInput: "Choose a Mac HGPAK archive or an AMUMSS Lua script."
        case .invalidHGPAK: "The selected file is not a supported HGPAK v2 archive."
        case .truncatedHGPAK: "The selected archive is incomplete or damaged."
        case .invalidManifest: "The archive's internal file list is invalid."
        case .decompressionFailed: "The Mac HGPAK file list could not be decompressed."
        case .integerOverflow: "The archive contains unsafe size values."
        }
    }
}

private func normalizeAssetPath(_ path: String) -> String {
    var normalized = path.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\\", with: "/")
        .lowercased()
    while normalized.contains("//") {
        normalized = normalized.replacingOccurrences(of: "//", with: "/")
    }
    return normalized
}

private func checkedInt(_ value: UInt64) throws -> Int {
    guard value <= UInt64(Int.max) else { throw ModInspectionError.integerOverflow }
    return Int(value)
}

private func roundUp16(_ value: Int) -> Int { (value + 15) & ~15 }

private func decodeLZ4Block(_ source: Data) throws -> Data {
    var destination = Data(count: 0x20000)
    let decodedSize = destination.withUnsafeMutableBytes { destinationBuffer in
        source.withUnsafeBytes { sourceBuffer in
            guard let destinationAddress = destinationBuffer.bindMemory(to: UInt8.self).baseAddress,
                  let sourceAddress = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(destinationAddress, 0x20000, sourceAddress, source.count, nil, COMPRESSION_LZ4_RAW)
        }
    }
    guard decodedSize > 0 else { throw ModInspectionError.decompressionFailed }
    destination.count = decodedSize
    return destination
}

private extension Data {
    func uint64LE(at offset: Int) throws -> UInt64 {
        guard offset >= 0, offset + 8 <= count else { throw ModInspectionError.truncatedHGPAK }
        return withUnsafeBytes { bytes in
            UInt64(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: UInt64.self))
        }
    }
}
