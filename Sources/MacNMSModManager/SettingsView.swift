import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        Form {
            Section("Game installation") {
                LabeledContent("Location", value: model.installation?.appURL.path ?? "Not found")
                Button("Choose Game…", action: model.chooseGame)
            }
            Section("macOS permission") {
                LabeledContent("Game access", value: model.gameAccess.status == .ready ? "Ready" : "Needs attention")
                Text("App Management allows this manager to patch No Man's Sky.app and place mods inside it. Full Disk Access is not normally required.")
                    .foregroundStyle(.secondary)
                HStack {
                    Button("Open App Management", action: model.openAppManagementSettings)
                    Button("Check Access", action: model.checkGameAccess)
                        .disabled(model.installation == nil || model.isWorking)
                }
            }
            Section("Safety") {
                Text("Executable backups and disabled mods are stored under Application Support, outside the Steam game bundle.")
                Text("Unknown executable fingerprints are never patched automatically.")
            }
            Section("Windows conversion") {
                Text("The import pipeline has a conversion-provider interface. PSARC unpacking, HGPAK rebuilding, and sparse EXML/MBIN merging are the next implementation phase.")
                    .foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).padding(20).navigationTitle("Settings")
    }
}
