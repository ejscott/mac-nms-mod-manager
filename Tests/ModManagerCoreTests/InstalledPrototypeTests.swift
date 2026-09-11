import Foundation
import Testing
@testable import ModManagerCore

@Test func recognizesInstalledPrototypeWhenPresent() throws {
    let app = GameLocator.defaultAppURL
    guard FileManager.default.fileExists(atPath: app.path) else { return }
    let installation = try GameLocator().locate(appURL: app)
    let result = ExecutablePatcher().inspect(executableURL: installation.executableURL)
    #expect(result.health == .patched)
    #expect(result.recipeID == "nms-macos-arm64-additive-v1-4.70")
}
