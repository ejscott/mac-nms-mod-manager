import Foundation

public enum PatchHealth: String, Codable, Sendable {
    case notInspected
    case readyToPatch
    case patched
    case updateDetected
    case unsupported
    case invalid
}

public struct GameInstallation: Codable, Equatable, Sendable {
    public var appURL: URL
    public var executableURL: URL
    public var banksURL: URL
    public var modsURL: URL { banksURL.appendingPathComponent("MODS", isDirectory: true) }

    public init(appURL: URL, executableURL: URL, banksURL: URL) {
        self.appURL = appURL
        self.executableURL = executableURL
        self.banksURL = banksURL
    }
}

public struct BinaryFingerprint: Codable, Equatable, Sendable {
    public var universalSHA256: String
    public var arm64SHA256: String
    public var fileSize: UInt64

    public init(universalSHA256: String, arm64SHA256: String, fileSize: UInt64) {
        self.universalSHA256 = universalSHA256
        self.arm64SHA256 = arm64SHA256
        self.fileSize = fileSize
    }
}

public struct PatchInspection: Codable, Equatable, Sendable {
    public var health: PatchHealth
    public var recipeID: String?
    public var fingerprint: BinaryFingerprint?
    public var details: String

    public init(health: PatchHealth, recipeID: String? = nil, fingerprint: BinaryFingerprint? = nil, details: String) {
        self.health = health
        self.recipeID = recipeID
        self.fingerprint = fingerprint
        self.details = details
    }
}

public struct ModRecord: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var author: String?
    public var version: String?
    public var summary: String?
    public var sourceURL: URL?
    public var managedFilename: String
    public var sha256: String
    public var enabled: Bool
    public var installedAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), name: String, author: String? = nil, version: String? = nil, summary: String? = nil, sourceURL: URL? = nil, managedFilename: String, sha256: String, enabled: Bool = true, installedAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.author = author
        self.version = version
        self.summary = summary
        self.sourceURL = sourceURL
        self.managedFilename = managedFilename
        self.sha256 = sha256
        self.enabled = enabled
        self.installedAt = installedAt
        self.updatedAt = updatedAt
    }
}

public struct PatchReceipt: Codable, Equatable, Sendable {
    public var recipeID: String
    public var appliedAt: Date
    public var before: BinaryFingerprint
    public var after: BinaryFingerprint
    public var backupURL: URL
}

public struct RegistryState: Codable, Equatable, Sendable {
    public var schemaVersion = 1
    public var gameAppURL: URL?
    public var lastSeenFingerprint: BinaryFingerprint?
    public var patchReceipt: PatchReceipt?
    public var mods: [ModRecord] = []

    public init() {}
}
