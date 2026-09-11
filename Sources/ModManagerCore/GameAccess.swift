import Foundation

public enum GameAccessStatus: String, Codable, Sendable {
    case notChecked
    case ready
    case needsPermission
    case unavailable
}

public struct GameAccessInspection: Equatable, Sendable {
    public var status: GameAccessStatus
    public var details: String

    public init(status: GameAccessStatus, details: String) {
        self.status = status
        self.details = details
    }
}

public struct GameAccessInspector: Sendable {
    public init() {}

    public func inspect(_ installation: GameInstallation) -> GameAccessInspection {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: installation.executableURL.path),
              fileManager.fileExists(atPath: installation.banksURL.path) else {
            return GameAccessInspection(
                status: .unavailable,
                details: "The selected game installation is incomplete or unavailable."
            )
        }

        let executableDirectory = installation.executableURL.deletingLastPathComponent()
        guard fileManager.isWritableFile(atPath: executableDirectory.path),
              fileManager.isWritableFile(atPath: installation.banksURL.path) else {
            return GameAccessInspection(
                status: .needsPermission,
                details: "macOS is not allowing changes inside No Man's Sky.app."
            )
        }

        return GameAccessInspection(
            status: .ready,
            details: "The game folder is available for patching and mod installation."
        )
    }

    /// Performs a reversible write inside the game bundle. Unlike POSIX permission checks,
    /// this also catches macOS App Management privacy restrictions.
    public func verifyWriteAccess(_ installation: GameInstallation) throws {
        let marker = installation.banksURL
            .appendingPathComponent(".mac-nms-mod-manager-access-check-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: marker) }
        try Data().write(to: marker, options: .withoutOverwriting)
        try FileManager.default.removeItem(at: marker)
    }
}
