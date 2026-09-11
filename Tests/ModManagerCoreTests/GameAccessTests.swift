import Foundation
import Testing
@testable import ModManagerCore

@Test func gameAccessInspectorRecognizesWritableInstallation() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let executable = root.appendingPathComponent("Contents/MacOS/NMS")
    let banks = root.appendingPathComponent("Contents/Resources/GAMEDATA/MACOSBANKS")
    try FileManager.default.createDirectory(at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: banks, withIntermediateDirectories: true)
    try Data([0]).write(to: executable)

    let installation = GameInstallation(appURL: root, executableURL: executable, banksURL: banks)
    let inspector = GameAccessInspector()

    #expect(inspector.inspect(installation).status == .ready)
    try inspector.verifyWriteAccess(installation)
    let leftovers = try FileManager.default.contentsOfDirectory(atPath: banks.path)
    #expect(leftovers.isEmpty)
}

@Test func gameAccessInspectorRejectsIncompleteInstallation() {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let installation = GameInstallation(
        appURL: root,
        executableURL: root.appendingPathComponent("Contents/MacOS/NMS"),
        banksURL: root.appendingPathComponent("Contents/Resources/GAMEDATA/MACOSBANKS")
    )

    #expect(GameAccessInspector().inspect(installation).status == .unavailable)
}
