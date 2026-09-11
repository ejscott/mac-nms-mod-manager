import Foundation

public struct PatchLandmark: Sendable {
    public enum Kind: String, Sendable { case selector, hook, stub }
    public var kind: Kind
    public var diagnosticVirtualAddress: UInt64
    public var vanilla: BytePattern?
    public var patched: BytePattern
    public var searchWindow: Range<Int>?
}

public struct PatchRecipe: Sendable {
    public var id: String
    public var description: String
    public var knownVanillaUniversalHashes: Set<String>
    public var knownPatchedUniversalHashes: Set<String>
    public var knownPatchedArm64Hashes: Set<String>
    public var landmarks: [PatchLandmark]

    public init(id: String, description: String, knownVanillaUniversalHashes: Set<String> = [], knownPatchedUniversalHashes: Set<String> = [], knownPatchedArm64Hashes: Set<String> = [], landmarks: [PatchLandmark]) {
        self.id = id
        self.description = description
        self.knownVanillaUniversalHashes = knownVanillaUniversalHashes
        self.knownPatchedUniversalHashes = knownPatchedUniversalHashes
        self.knownPatchedArm64Hashes = knownPatchedArm64Hashes
        self.landmarks = landmarks
    }
}

public enum BuiltInPatchRecipes {
    // Fingerprints and bytes were collected read-only from the launch-tested 4.70 prototype.
    // The instruction contexts make the state detectable without treating the addresses as authoritative.
    public static let verified470Prototype = PatchRecipe(
        id: "nms-macos-arm64-additive-v1-4.70",
        description: "Mount MODS before stock MACOSBANKS using the verified ARM64 dual-mount hook.",
        knownPatchedUniversalHashes: ["1c0f4442278fc999f5d9751d7ea7ac1830858667884e9e1099f5899ea15fe175"],
        knownPatchedArm64Hashes: ["98766d12eebf6dd5f5e2fdeeaa4ef74a6c191fefc3241fd9f6ee7e4a6a55e324"],
        landmarks: [
            PatchLandmark(
                kind: .selector,
                diagnosticVirtualAddress: 0x1030d1078,
                vanilla: BytePattern(hex: "60 02 40 f9 ff 7f 01 a9 89 d3 88 52 e8 03 00 91 01 00 09 8b 4e 00 00 94"),
                patched: BytePattern(hex: "60 02 40 f9 ff 7f 01 a9 89 d3 88 52 e8 03 00 91 01 00 09 8b 4e 00 00 94"),
                searchWindow: 0x2fd0000..<0x31d0000
            ),
            PatchLandmark(
                kind: .hook,
                diagnosticVirtualAddress: 0x1030d109c,
                vanilla: BytePattern(hex: "e0 03 00 91 39 f5 3c 97 60 02 40 f9"),
                patched: BytePattern(hex: "e0 03 00 91 39 f5 3c 97 85 c5 b0 97"),
                searchWindow: 0x2fd0000..<0x31d0000
            ),
            PatchLandmark(
                kind: .stub,
                diagnosticVirtualAddress: 0x101d026b0,
                vanilla: nil,
                patched: BytePattern(hex: "f4 7b bf a9 60 02 40 f9 89 f3 88 d2 01 00 09 8b e8 43 00 91 be 3a 4f 94 60 02 40 f9 e1 43 00 91 02 00 80 52 39 3b 4f 94 e0 43 00 91 a8 2f 8c 97 f4 7b c1 a8 60 02 40 f9 c0 03 5f d6"),
                searchWindow: 0x1c00000..<0x1e00000
            )
        ]
    )

    public static let all = [verified470Prototype]
}
