import Foundation

public struct BackupManifest: Codable, Sendable {
    public var createdAt: Date
    public var sourceExecutable: URL
    public var backupExecutable: URL
    public var sha256: String
}

public struct PatchTransaction: Sendable {
    public let directories: AppDirectories
    public let patcher: ExecutablePatcher
    public let signing: CodeSigningService

    public init(directories: AppDirectories, patcher: ExecutablePatcher = .init(), signing: CodeSigningService = .init()) {
        self.directories = directories
        self.patcher = patcher
        self.signing = signing
    }

    public func createBackup(of executableURL: URL) throws -> BackupManifest {
        try directories.create()
        let source = try Data(contentsOf: executableURL, options: .mappedIfSafe)
        let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        let folder = directories.backupsURL.appendingPathComponent(stamp, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = folder.appendingPathComponent(executableURL.lastPathComponent)
        try source.write(to: destination, options: [.atomic])
        let manifest = BackupManifest(createdAt: .now, sourceExecutable: executableURL, backupExecutable: destination, sha256: MachOReader.sha256(source))
        let manifestData = try JSONEncoder().encode(manifest)
        try manifestData.write(to: folder.appendingPathComponent("manifest.json"), options: [.atomic])
        return manifest
    }

    public func apply(recipe: PatchRecipe, to installation: GameInstallation) throws -> PatchReceipt {
        let beforeData = try Data(contentsOf: installation.executableURL, options: .mappedIfSafe)
        let before = try MachOReader.fingerprint(data: beforeData)
        let backup = try createBackup(of: installation.executableURL)
        let candidate = try patcher.makePatchedCandidate(executableData: beforeData, recipe: recipe)
        let staged = directories.stagingURL.appendingPathComponent("NoMansSky-\(UUID().uuidString)")
        try candidate.write(to: staged, options: [.atomic])
        let attributes = try FileManager.default.attributesOfItem(atPath: installation.executableURL.path)
        if let permissions = attributes[.posixPermissions] { try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: staged.path) }
        _ = try FileManager.default.replaceItemAt(installation.executableURL, withItemAt: staged)
        do {
            try signing.signAdHoc(appURL: installation.appURL)
            let validation = patcher.inspect(executableURL: installation.executableURL)
            guard validation.health == .patched else { throw PatcherError.candidateValidationFailed }
            let afterData = try Data(contentsOf: installation.executableURL, options: .mappedIfSafe)
            let after = try MachOReader.fingerprint(data: afterData)
            return PatchReceipt(recipeID: recipe.id, appliedAt: .now, before: before, after: after, backupURL: backup.backupExecutable)
        } catch {
            try? restore(backup, installation: installation)
            throw error
        }
    }

    public func restore(_ manifest: BackupManifest, installation: GameInstallation) throws {
        let data = try Data(contentsOf: manifest.backupExecutable, options: .mappedIfSafe)
        guard MachOReader.sha256(data) == manifest.sha256 else { throw PatcherError.backupChecksumMismatch }
        let staged = directories.stagingURL.appendingPathComponent("restore-\(UUID().uuidString)")
        try data.write(to: staged, options: [.atomic])
        _ = try FileManager.default.replaceItemAt(installation.executableURL, withItemAt: staged)
        try signing.signAdHoc(appURL: installation.appURL)
    }
}
