import Foundation
import Testing
@testable import ModManagerCore

@Test func disablingAndReenablingPreservesArchiveAndRegistryRecord() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

    let banks = root.appendingPathComponent("MACOSBANKS", isDirectory: true)
    let installation = GameInstallation(
        appURL: root.appendingPathComponent("No Man's Sky.app", isDirectory: true),
        executableURL: root.appendingPathComponent("No Man's Sky"),
        banksURL: banks
    )
    let directories = AppDirectories(root: root.appendingPathComponent("Manager Data", isDirectory: true))
    let registry = RegistryStore(url: directories.registryURL)
    let installer = ModInstaller(installation: installation, directories: directories, registry: registry)
    let source = root.appendingPathComponent("Test Mod.pak")
    try Data("HGPAK-test-payload".utf8).write(to: source)

    let installed = try await installer.installHGPAK(from: source, name: "Test Mod", author: "Creator")
    let activeURL = installation.modsURL.appendingPathComponent(installed.managedFilename)
    let disabledURL = directories.disabledModsURL.appendingPathComponent(installed.managedFilename)
    #expect(FileManager.default.fileExists(atPath: activeURL.path))

    try await installer.setEnabled(false, id: installed.id)
    #expect(!FileManager.default.fileExists(atPath: activeURL.path))
    #expect(FileManager.default.fileExists(atPath: disabledURL.path))
    #expect(await registry.snapshot().mods.first?.enabled == false)
    #expect(await registry.snapshot().mods.first?.author == "Creator")
    let reloadedRegistry = RegistryStore(url: directories.registryURL)
    #expect(await reloadedRegistry.snapshot().mods.first?.enabled == false)
    #expect(await reloadedRegistry.snapshot().mods.first?.id == installed.id)

    try await installer.setEnabled(false, id: installed.id)
    #expect(FileManager.default.fileExists(atPath: disabledURL.path))

    try await installer.setEnabled(true, id: installed.id)
    #expect(FileManager.default.fileExists(atPath: activeURL.path))
    #expect(!FileManager.default.fileExists(atPath: disabledURL.path))
    #expect(await registry.snapshot().mods.first?.enabled == true)
}

@Test func enableRefusesToOverwriteAnExistingArchive() async throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

    let installation = GameInstallation(
        appURL: root.appendingPathComponent("No Man's Sky.app", isDirectory: true),
        executableURL: root.appendingPathComponent("No Man's Sky"),
        banksURL: root.appendingPathComponent("MACOSBANKS", isDirectory: true)
    )
    let directories = AppDirectories(root: root.appendingPathComponent("Manager Data", isDirectory: true))
    let registry = RegistryStore(url: directories.registryURL)
    let installer = ModInstaller(installation: installation, directories: directories, registry: registry)
    let source = root.appendingPathComponent("Collision.pak")
    try Data("HGPAK-original".utf8).write(to: source)
    let installed = try await installer.installHGPAK(from: source)
    try await installer.setEnabled(false, id: installed.id)

    let activeURL = installation.modsURL.appendingPathComponent(installed.managedFilename)
    try Data("HGPAK-different".utf8).write(to: activeURL)

    await #expect(throws: ModInstallerError.self) {
        try await installer.setEnabled(true, id: installed.id)
    }
    #expect(FileManager.default.fileExists(atPath: directories.disabledModsURL.appendingPathComponent(installed.managedFilename).path))
    #expect(await registry.snapshot().mods.first?.enabled == false)
}
