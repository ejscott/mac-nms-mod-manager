import Foundation

public struct AppDirectories: Sendable {
    public let root: URL
    public var registryURL: URL { root.appendingPathComponent("registry.json") }
    public var backupsURL: URL { root.appendingPathComponent("Backups", isDirectory: true) }
    public var disabledModsURL: URL { root.appendingPathComponent("Disabled Mods", isDirectory: true) }
    public var stagingURL: URL { root.appendingPathComponent("Staging", isDirectory: true) }

    public init(root: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Mac NMS Mod Manager", isDirectory: true)) {
        self.root = root
    }

    public func create() throws {
        for directory in [root, backupsURL, disabledModsURL, stagingURL] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
