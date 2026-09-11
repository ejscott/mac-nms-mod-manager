import Foundation

public enum GameLocationError: LocalizedError {
    case appMissing(URL)
    case malformedBundle(URL)
    case banksMissing(URL)

    public var errorDescription: String? {
        switch self {
        case .appMissing(let url): "No Man's Sky was not found at \(url.path)."
        case .malformedBundle(let url): "The app bundle has no valid executable: \(url.path)."
        case .banksMissing(let url): "MACOSBANKS was not found at \(url.path)."
        }
    }
}

public struct GameLocator: Sendable {
    public static let defaultAppURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Steam/steamapps/common/No Man's Sky/No Man's Sky.app", isDirectory: true)

    public init() {}

    public func locate(appURL: URL = Self.defaultAppURL) throws -> GameInstallation {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: appURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw GameLocationError.appMissing(appURL)
        }
        let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let executableName = plist["CFBundleExecutable"] as? String else {
            throw GameLocationError.malformedBundle(appURL)
        }
        let executableURL = appURL.appendingPathComponent("Contents/MacOS/\(executableName)")
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw GameLocationError.malformedBundle(appURL)
        }
        let banksURL = appURL.appendingPathComponent("Contents/Resources/GAMEDATA/MACOSBANKS", isDirectory: true)
        guard FileManager.default.fileExists(atPath: banksURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw GameLocationError.banksMissing(banksURL)
        }
        return GameInstallation(appURL: appURL, executableURL: executableURL, banksURL: banksURL)
    }
}
