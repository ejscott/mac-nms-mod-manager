import Foundation

public enum ModInputKind: String, Codable, Sendable {
    case macHGPAK
    case windowsPAK
    case sparseEXMLOrMBIN
    case unknown
}

public struct ConversionContext: Sendable {
    public var installation: GameInstallation
    public var stagingURL: URL
}

public struct ConvertedMod: Sendable {
    public var archiveURL: URL
    public var name: String
    public var author: String?
    public var version: String?
}

public protocol ModConversionProvider: Sendable {
    var identifier: String { get }
    func supports(_ kind: ModInputKind) -> Bool
    func convert(input: URL, context: ConversionContext) async throws -> ConvertedMod
}

public enum ConversionError: LocalizedError {
    case unsupported(ModInputKind)
    public var errorDescription: String? {
        if case .unsupported(let kind) = self {
            return "\(kind.rawValue) conversion is not available yet. The architecture is ready for a converter plug-in."
        }
        return nil
    }
}

public struct NativeHGPAKProvider: ModConversionProvider {
    public let identifier = "native-hgpak"
    public init() {}
    public func supports(_ kind: ModInputKind) -> Bool { kind == .macHGPAK }
    public func convert(input: URL, context: ConversionContext) async throws -> ConvertedMod {
        ConvertedMod(archiveURL: input, name: input.deletingPathExtension().lastPathComponent)
    }
}

public enum ModInputClassifier {
    public static func classify(_ url: URL) -> ModInputKind {
        let extensionName = url.pathExtension.lowercased()
        if ["hgpak", "pak"].contains(extensionName) {
            if let handle = try? FileHandle(forReadingFrom: url) {
                defer { try? handle.close() }
                if let magic = try? handle.read(upToCount: 5), magic == Data("HGPAK".utf8) { return .macHGPAK }
            }
            return extensionName == "hgpak" ? .unknown : .windowsPAK
        }
        if ["exml", "mbin", "mxml"].contains(extensionName) { return .sparseEXMLOrMBIN }
        return .unknown
    }
}
