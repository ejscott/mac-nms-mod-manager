import Foundation

public enum CodeSigningError: LocalizedError {
    case commandFailed(String)
    public var errorDescription: String? {
        if case .commandFailed(let message) = self { return message }
        return nil
    }
}

public struct CodeSigningService: Sendable {
    private let runner = ProcessRunner()
    public init() {}

    public func signAdHoc(appURL: URL) throws {
        let result = try runner.run(URL(fileURLWithPath: "/usr/bin/codesign"), arguments: ["--force", "--deep", "--sign", "-", appURL.path])
        guard result.status == 0 else { throw CodeSigningError.commandFailed(result.standardError) }
        try verify(appURL: appURL)
    }

    public func verify(appURL: URL) throws {
        let result = try runner.run(URL(fileURLWithPath: "/usr/bin/codesign"), arguments: ["--verify", "--deep", "--strict", "--verbose=2", appURL.path])
        guard result.status == 0 else { throw CodeSigningError.commandFailed(result.standardError) }
    }
}
