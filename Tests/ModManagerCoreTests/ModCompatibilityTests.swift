import Foundation
import Testing
@testable import ModManagerCore

@Test func readsPathsFromUncompressedMacHGPAK() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let archive = root.appendingPathComponent("sample.pak")
    try writeTestHGPAK(to: archive, paths: [
        "METADATA\\REALITY\\TABLES\\NMS_REALITY_GCRECIPETABLE.MBIN",
        "GCPLAYERGLOBALS.GLOBAL.MBIN"
    ])

    let inspection = try ModAssetInspector.inspectMacHGPAK(archive)
    #expect(inspection.assetPaths == [
        "gcplayerglobals.global.mbin",
        "metadata/reality/tables/nms_reality_gcrecipetable.mbin"
    ])
}

@Test func detectsActiveAndPotentialFileOverlap() {
    let recipePath = "metadata/reality/tables/nms_reality_gcrecipetable.mbin"
    let active = ModRecord(name: "Instant Refiners", managedFilename: "instant.pak", sha256: "1", assetPaths: [recipePath])
    let disabled = ModRecord(name: "Recipe Rebalance", managedFilename: "recipes.pak", sha256: "2", assetPaths: [recipePath], enabled: false)
    let unrelated = ModRecord(name: "Cursor", managedFilename: "cursor.pak", sha256: "3", assetPaths: ["ui/cursor.mbin"])

    let matches = ModCompatibilityAnalyzer.matches(paths: [recipePath], against: [active, disabled, unrelated])
    #expect(matches.count == 2)
    #expect(matches.first(where: { $0.modID == active.id })?.active == true)
    #expect(matches.first(where: { $0.modID == disabled.id })?.active == false)
    #expect(ModCompatibilityAnalyzer.activeConflictCount(in: [active, disabled, unrelated]) == 0)
    var secondActive = disabled
    secondActive.enabled = true
    #expect(ModCompatibilityAnalyzer.activeConflictCount(in: [active, secondActive, unrelated]) == 1)
}

@Test func extractsDeclaredTargetsFromAMUMSSLua() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let script = root.appendingPathComponent("recipe.lua")
    let contents = #"""
    NMS_MOD_DEFINITION_CONTAINER = {
      ["MOD_FILENAME"] = "Example.pak",
      ["MODIFICATIONS"] = {{
        ["MBIN_CHANGE_TABLE"] = {{
          ["MBIN_FILE_SOURCE"] = {
            "METADATA\\REALITY\\TABLES\\NMS_REALITY_GCRECIPETABLE.MBIN",
            "GCPLAYERGLOBALS.GLOBAL.MBIN"
          }
        }}
      }}
    }
    """#
    try Data(contents.utf8).write(to: script)

    let inspection = try ModAssetInspector.inspectAMUMSSLua(script)
    #expect(inspection.source == .amumssLuaDeclarations)
    #expect(inspection.assetPaths == [
        "gcplayerglobals.global.mbin",
        "metadata/reality/tables/nms_reality_gcrecipetable.mbin"
    ])
    #expect(!inspection.warnings.isEmpty)
}

@Test func readsLocalConvertedMacArchiveWhenAvailable() throws {
    let archive = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("outputs/Instant Refiners Mac/Instant.Refiners.Mac.pak")
    guard FileManager.default.fileExists(atPath: archive.path) else { return }
    let inspection = try ModAssetInspector.inspectMacHGPAK(archive)
    #expect(inspection.assetPaths == ["metadata/reality/tables/nms_reality_gcrecipetable.mbin"])
}

@Test func readsLocalMultiFileMacArchiveWhenAvailable() throws {
    let archive = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("outputs/Prepare to Sky Edition Mac 701.0.1/PTSd Enemies and Hazards Mac.pak")
    guard FileManager.default.fileExists(atPath: archive.path) else { return }
    let inspection = try ModAssetInspector.inspectMacHGPAK(archive)
    #expect(inspection.assetPaths.count == 35)
    #expect(inspection.assetPaths.contains("gcenvironmentglobals.global.mbin"))
}
