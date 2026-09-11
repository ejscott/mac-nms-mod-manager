import ModManagerCore
import SwiftUI

struct ModsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Mods").font(.largeTitle.bold())
                    Text("Mac HGPAK archives (.hgpak or .pak)").foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: model.chooseAndInstallMod) { Label("Install Mod", systemImage: "plus") }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.inspection.health != .patched)
            }.padding(28)
            if model.mods.isEmpty {
                ContentUnavailableView("No mods installed", systemImage: "shippingbox", description: Text("Install a Mac HGPAK archive to get started."))
            } else {
                VStack(spacing: 0) {
                    Text("Turn a mod off without uninstalling it. Disabled archives are kept safely outside the game's MODS folder and remain in this list.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 12)
                    List(model.mods) { mod in
                        HStack(spacing: 14) {
                            Toggle("Enable \(mod.name)", isOn: Binding(get: { mod.enabled }, set: { model.setEnabled($0, mod: mod) }))
                                .labelsHidden()
                                .help(mod.enabled ? "Disable \(mod.name)" : "Enable \(mod.name)")
                            VStack(alignment: .leading, spacing: 3) {
                                Text(mod.name).font(.headline)
                                Text([mod.author, mod.version].compactMap { $0 }.joined(separator: " • ").isEmpty ? mod.managedFilename : [mod.author, mod.version].compactMap { $0 }.joined(separator: " • "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Label(mod.enabled ? "Enabled" : "Disabled", systemImage: mod.enabled ? "checkmark.circle.fill" : "pause.circle.fill")
                                .foregroundStyle(mod.enabled ? .green : .secondary)
                            Menu {
                                Button(mod.enabled ? "Disable" : "Enable") { model.setEnabled(!mod.enabled, mod: mod) }
                                Divider()
                                Button("Uninstall", role: .destructive) { model.uninstall(mod) }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .menuStyle(.borderlessButton)
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }.navigationTitle("Mods")
    }
}
