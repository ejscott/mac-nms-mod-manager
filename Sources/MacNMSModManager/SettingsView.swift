import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        Form {
            Section("Game installation") {
                LabeledContent("Location", value: model.installation?.appURL.path ?? "Not found")
                Button("Choose Game…", action: model.chooseGame)
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
