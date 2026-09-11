import Foundation

public enum PatcherError: LocalizedError {
    case unsupportedBuild(String)
    case ambiguousLandmark(PatchLandmark.Kind, Int)
    case noVanillaSignature(PatchLandmark.Kind)
    case candidateValidationFailed
    case backupChecksumMismatch

    public var errorDescription: String? {
        switch self {
        case .unsupportedBuild(let reason): reason
        case .ambiguousLandmark(let kind, let count): "Expected one \(kind.rawValue) landmark, found \(count)."
        case .noVanillaSignature(let kind): "The recipe has no validated vanilla signature for the \(kind.rawValue) edit."
        case .candidateValidationFailed: "The patched candidate did not pass post-patch validation."
        case .backupChecksumMismatch: "The backup checksum does not match the patch receipt."
        }
    }
}

public struct PatchDiscovery: Sendable {
    public var recipe: PatchRecipe
    public var fingerprint: BinaryFingerprint
    public var arm64Slice: MachOSlice
    public var vanillaOffsets: [PatchLandmark.Kind: Int]
    public var patchedOffsets: [PatchLandmark.Kind: Int]
}

public struct ExecutablePatcher: Sendable {
    public let recipes: [PatchRecipe]

    public init(recipes: [PatchRecipe] = BuiltInPatchRecipes.all) {
        self.recipes = recipes
    }

    public func inspect(executableURL: URL, previousFingerprint: BinaryFingerprint? = nil) -> PatchInspection {
        do {
            let data = try Data(contentsOf: executableURL, options: .mappedIfSafe)
            let fingerprint = try MachOReader.fingerprint(data: data)
            for recipe in recipes {
                let discovery = try discover(recipe: recipe, in: data)
                if isFullyPatched(discovery) {
                    return PatchInspection(health: .patched, recipeID: recipe.id, fingerprint: fingerprint, details: "Validated additive MODS-first patch.")
                }
                if isReadyToPatch(discovery) {
                    return PatchInspection(health: .readyToPatch, recipeID: recipe.id, fingerprint: fingerprint, details: "This build matches a validated vanilla patch recipe.")
                }
            }
            if let previousFingerprint, previousFingerprint != fingerprint {
                return PatchInspection(health: .updateDetected, fingerprint: fingerprint, details: "The executable changed and no installed recipe validates it. Steam may have updated the game.")
            }
            return PatchInspection(health: .unsupported, fingerprint: fingerprint, details: "No patch recipe matches this ARM64 build. No changes were made.")
        } catch {
            return PatchInspection(health: .invalid, details: error.localizedDescription)
        }
    }

    public func discover(recipe: PatchRecipe, in universalData: Data) throws -> PatchDiscovery {
        let fingerprint = try MachOReader.fingerprint(data: universalData)
        let slice = try MachOReader.arm64Slice(in: universalData)
        var vanilla: [PatchLandmark.Kind: Int] = [:]
        var patched: [PatchLandmark.Kind: Int] = [:]
        for landmark in recipe.landmarks {
            let patchedMatches = landmark.patched.findAll(in: slice.data, range: landmark.searchWindow)
            if patchedMatches.count == 1 { patched[landmark.kind] = patchedMatches[0] }
            if let pattern = landmark.vanilla {
                let vanillaMatches = pattern.findAll(in: slice.data, range: landmark.searchWindow)
                if vanillaMatches.count == 1 { vanilla[landmark.kind] = vanillaMatches[0] }
            }
        }
        return PatchDiscovery(recipe: recipe, fingerprint: fingerprint, arm64Slice: slice, vanillaOffsets: vanilla, patchedOffsets: patched)
    }

    public func makePatchedCandidate(executableData: Data, recipe: PatchRecipe) throws -> Data {
        let discovery = try discover(recipe: recipe, in: executableData)
        guard recipe.knownVanillaUniversalHashes.contains(discovery.fingerprint.universalSHA256) else {
            throw PatcherError.unsupportedBuild("The vanilla fingerprint is not approved by recipe \(recipe.id).")
        }
        var candidate = executableData
        for landmark in recipe.landmarks {
            guard let vanillaPattern = landmark.vanilla else { throw PatcherError.noVanillaSignature(landmark.kind) }
            let matches = vanillaPattern.findAll(in: discovery.arm64Slice.data, range: landmark.searchWindow)
            guard matches.count == 1 else { throw PatcherError.ambiguousLandmark(landmark.kind, matches.count) }
            let absolute = discovery.arm64Slice.offset + matches[0]
            candidate.replaceSubrange(absolute..<(absolute + landmark.patched.bytes.count), with: landmark.patched.bytes)
        }
        let post = try discover(recipe: recipe, in: candidate)
        guard isFullyPatched(post) else { throw PatcherError.candidateValidationFailed }
        return candidate
    }

    private func isFullyPatched(_ discovery: PatchDiscovery) -> Bool {
        let allLandmarks = Set(discovery.recipe.landmarks.map(\.kind))
        let patternsValidate = Set(discovery.patchedOffsets.keys) == allLandmarks
        return patternsValidate
    }

    private func isReadyToPatch(_ discovery: PatchDiscovery) -> Bool {
        discovery.recipe.knownVanillaUniversalHashes.contains(discovery.fingerprint.universalSHA256)
            && discovery.recipe.landmarks.allSatisfy { discovery.vanillaOffsets[$0.kind] != nil }
    }
}
