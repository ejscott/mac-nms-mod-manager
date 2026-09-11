import Foundation
import Testing
@testable import ModManagerCore

@Test func registryRoundTrips() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: root) }
    let store = RegistryStore(url: root.appendingPathComponent("registry.json"))
    let timestamp = Date(timeIntervalSince1970: 1_000)
    let mod = ModRecord(name: "Cursor", managedFilename: "cursor.hgpak", sha256: "abc", installedAt: timestamp, updatedAt: timestamp)
    try await store.upsert(mod)
    let reloaded = RegistryStore(url: root.appendingPathComponent("registry.json"))
    #expect(await reloaded.snapshot().mods == [mod])
}
