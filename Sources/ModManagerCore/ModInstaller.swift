import Foundation

public enum ModInstallerError: LocalizedError {
    case sourceMissing
    case nameCollision(String)
    case trackedFileMissing(String)

    public var errorDescription: String? {
        switch self {
        case .sourceMissing: "The selected mod archive no longer exists."
        case .nameCollision(let name): "A different mod already uses \(name)."
        case .trackedFileMissing(let name): "The tracked archive \(name) could not be found."
        }
    }
}

public actor ModInstaller {
    private let installation: GameInstallation
    private let directories: AppDirectories
    private let registry: RegistryStore

    public init(installation: GameInstallation, directories: AppDirectories, registry: RegistryStore) {
        self.installation = installation
        self.directories = directories
        self.registry = registry
    }

    public func installHGPAK(from source: URL, name: String? = nil, author: String? = nil, version: String? = nil) async throws -> ModRecord {
        guard FileManager.default.fileExists(atPath: source.path) else { throw ModInstallerError.sourceMissing }
        try directories.create()
        try FileManager.default.createDirectory(at: installation.modsURL, withIntermediateDirectories: true)
        let filename = sanitizedFilename(source.lastPathComponent)
        let destination = installation.modsURL.appendingPathComponent(filename)
        let snapshot = await registry.snapshot()
        if let existing = snapshot.mods.first(where: { $0.managedFilename.caseInsensitiveCompare(filename) == .orderedSame }) {
            let sourceHash = MachOReader.sha256(try Data(contentsOf: source))
            guard existing.sha256 == sourceHash else { throw ModInstallerError.nameCollision(filename) }
            return existing
        }
        let staged = directories.stagingURL.appendingPathComponent("mod-\(UUID().uuidString)-\(filename)")
        try FileManager.default.copyItem(at: source, to: staged)
        try FileManager.default.moveItem(at: staged, to: destination)
        let hash = MachOReader.sha256(try Data(contentsOf: destination, options: .mappedIfSafe))
        let record = ModRecord(name: name ?? source.deletingPathExtension().lastPathComponent, author: author, version: version, sourceURL: source, managedFilename: filename, sha256: hash)
        try await registry.upsert(record)
        return record
    }

    @discardableResult
    public func reconcileUntrackedArchives() async throws -> [ModRecord] {
        try directories.create()
        try FileManager.default.createDirectory(at: installation.modsURL, withIntermediateDirectories: true)
        var snapshot = await registry.snapshot()
        let tracked = Set(snapshot.mods.map { $0.managedFilename.lowercased() })
        let files = try FileManager.default.contentsOfDirectory(at: installation.modsURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        var additions: [ModRecord] = []
        for file in files where !tracked.contains(file.lastPathComponent.lowercased()) && ModInputClassifier.classify(file) == .macHGPAK {
            let hash = MachOReader.sha256(try Data(contentsOf: file, options: .mappedIfSafe))
            additions.append(ModRecord(name: file.deletingPathExtension().lastPathComponent, sourceURL: nil, managedFilename: file.lastPathComponent, sha256: hash))
        }
        if !additions.isEmpty {
            snapshot.mods.append(contentsOf: additions)
            try await registry.replace(with: snapshot)
        }
        return additions
    }

    public func setEnabled(_ enabled: Bool, id: UUID) async throws {
        var snapshot = await registry.snapshot()
        guard let index = snapshot.mods.firstIndex(where: { $0.id == id }) else { return }
        let record = snapshot.mods[index]
        let from = (record.enabled ? installation.modsURL : directories.disabledModsURL).appendingPathComponent(record.managedFilename)
        let to = (enabled ? installation.modsURL : directories.disabledModsURL).appendingPathComponent(record.managedFilename)
        guard FileManager.default.fileExists(atPath: from.path) else { throw ModInstallerError.trackedFileMissing(record.managedFilename) }
        try FileManager.default.createDirectory(at: to.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: from, to: to)
        snapshot.mods[index].enabled = enabled
        snapshot.mods[index].updatedAt = .now
        try await registry.replace(with: snapshot)
    }

    public func uninstall(id: UUID) async throws {
        let snapshot = await registry.snapshot()
        guard let record = snapshot.mods.first(where: { $0.id == id }) else { return }
        let file = (record.enabled ? installation.modsURL : directories.disabledModsURL).appendingPathComponent(record.managedFilename)
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        try await registry.remove(id: id)
    }

    private func sanitizedFilename(_ input: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_. "))
        let cleaned = input.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        return String(cleaned)
    }
}
