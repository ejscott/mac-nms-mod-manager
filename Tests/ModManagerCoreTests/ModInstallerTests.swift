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
    try writeTestHGPAK(to: source, paths: ["METADATA/REALITY/TABLES/TEST.MBIN"])

    let installed = try await installer.installHGPAK(from: source, name: "Test Mod", author: "Creator")
    #expect(installed.assetPaths == ["metadata/reality/tables/test.mbin"])
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
    try writeTestHGPAK(to: source, paths: ["GCPLAYERGLOBALS.GLOBAL.MBIN"])
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

func writeTestHGPAK(to url: URL, paths: [String]) throws {
    let manifest = Data((paths.joined(separator: "\r\n") + "\r\n").utf8)
    let fileCount = UInt64(paths.count + 1)
    let dataOffset = UInt64(0x30) + fileCount * 0x20
    var data = Data("HGPAK".utf8)
    data.append(Data(repeating: 0, count: 3))
    data.appendLittleEndian(UInt64(2))
    data.appendLittleEndian(fileCount)
    data.appendLittleEndian(UInt64(0))
    data.append(0)
    data.append(Data(repeating: 0, count: 7))
    data.appendLittleEndian(dataOffset)
    for index in 0..<Int(fileCount) {
        data.append(Data(repeating: 0, count: 16))
        data.appendLittleEndian(dataOffset + UInt64(index == 0 ? 0 : manifest.count))
        data.appendLittleEndian(index == 0 ? UInt64(manifest.count) : 0)
    }
    data.append(manifest)
    try data.write(to: url)
}

private extension Data {
    mutating func appendLittleEndian(_ value: UInt64) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { append(contentsOf: $0) }
    }
}
