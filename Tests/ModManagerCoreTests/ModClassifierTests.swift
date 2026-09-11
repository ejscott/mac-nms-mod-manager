import Foundation
import Testing
@testable import ModManagerCore

@Test func recognizesHGPAKMagicEvenWithPakExtension() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-\(UUID().uuidString).pak")
    defer { try? FileManager.default.removeItem(at: url) }
    try Data("HGPAK\0\0\0".utf8).write(to: url)
    #expect(ModInputClassifier.classify(url) == .macHGPAK)
}

@Test func routesNonHGPAKPakToFutureWindowsConverter() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("test-\(UUID().uuidString).pak")
    defer { try? FileManager.default.removeItem(at: url) }
    try Data("PSAR".utf8).write(to: url)
    #expect(ModInputClassifier.classify(url) == .windowsPAK)
}

@Test func recognizesAMUMSSLuaScript() {
    let url = URL(fileURLWithPath: "/tmp/example.lua")
    #expect(ModInputClassifier.classify(url) == .amumssLua)
}
