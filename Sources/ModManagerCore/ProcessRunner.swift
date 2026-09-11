import Foundation

public struct ProcessResult: Sendable {
    public var status: Int32
    public var standardOutput: String
    public var standardError: String
}

public struct ProcessRunner: Sendable {
    public init() {}

    public func run(_ executable: URL, arguments: [String]) throws -> ProcessResult {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()
        process.waitUntilExit()
        return ProcessResult(
            status: process.terminationStatus,
            standardOutput: String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
            standardError: String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        )
    }
}
