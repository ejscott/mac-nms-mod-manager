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
                List(model.mods) { mod in
                    HStack(spacing: 14) {
                        Toggle("", isOn: Binding(get: { mod.enabled }, set: { model.setEnabled($0, mod: mod) })).labelsHidden()
                        VStack(alignment: .leading, spacing: 3) {
                            Text(mod.name).font(.headline)
                            Text([mod.author, mod.version].compactMap { $0 }.joined(separator: " • ").isEmpty ? mod.managedFilename : [mod.author, mod.version].compactMap { $0 }.joined(separator: " • "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(mod.enabled ? "Enabled" : "Disabled").foregroundStyle(mod.enabled ? .green : .secondary)
                        Menu { Button("Uninstall", role: .destructive) { model.uninstall(mod) } } label: { Image(systemName: "ellipsis.circle") }.menuStyle(.borderlessButton)
                    }.padding(.vertical, 5)
                }
            }
        }.navigationTitle("Mods")
    }
}
