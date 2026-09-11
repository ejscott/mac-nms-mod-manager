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
                Button(action: model.chooseAndCheckCompatibility) {
                    Label("Check Compatibility", systemImage: "checkmark.shield")
                }
                Button(action: model.chooseAndInstallMod) {
                    Label("Install Mod", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.inspection.health != .patched)
            }
            .padding(28)

            if model.mods.isEmpty {
                ContentUnavailableView("No mods installed", systemImage: "shippingbox", description: Text("Install a Mac HGPAK archive to get started."))
            } else {
                VStack(spacing: 0) {
                    Text("Compatibility is based on game-file overlap. Sharing a file means the later-loaded mod can replace the earlier mod's changes; it does not always mean the two changes are impossible to merge.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 12)
                    List(model.mods) { mod in
                        ModRow(mod: mod)
                    }
                }
            }
        }
        .navigationTitle("Mods")
        .sheet(item: $model.compatibilityCheck) { result in
            CompatibilityResultView(result: result)
        }
    }
}

private struct ModRow: View {
    @EnvironmentObject private var model: AppModel
    let mod: ModRecord

    private var matches: [ModCompatibilityMatch] {
        ModCompatibilityAnalyzer.matches(paths: mod.assetPaths ?? [], against: model.mods, excluding: mod.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 14) {
                Toggle("Enable \(mod.name)", isOn: Binding(get: { mod.enabled }, set: { model.setEnabled($0, mod: mod) }))
                    .labelsHidden()
                    .help(mod.enabled ? "Disable \(mod.name)" : "Enable \(mod.name)")
                VStack(alignment: .leading, spacing: 3) {
                    Text(mod.name).font(.headline)
                    Text(metadataText).font(.caption).foregroundStyle(.secondary)
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
            compatibilityLabel
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private var compatibilityLabel: some View {
        if !matches.isEmpty {
            let activeMatches = matches.filter(\.active)
            let names = matches.map(\.modName).joined(separator: ", ")
            let sharedCount = Set(matches.flatMap(\.sharedPaths)).count
            Label("\(activeMatches.isEmpty ? "Potential conflict" : "Active conflict") with \(names) — \(sharedCount) shared game file\(sharedCount == 1 ? "" : "s")", systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(activeMatches.isEmpty ? Color.secondary : Color.orange)
                .help(matches.flatMap(\.sharedPaths).joined(separator: "\n"))
        } else if let paths = mod.assetPaths {
            Label("\(paths.count) game file\(paths.count == 1 ? "" : "s") analyzed — no overlap", systemImage: "checkmark.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Label("Compatibility data unavailable", systemImage: "questionmark.diamond")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var metadataText: String {
        let metadata = [mod.author, mod.version].compactMap { $0 }.joined(separator: " • ")
        return metadata.isEmpty ? mod.managedFilename : metadata
    }
}

private struct CompatibilityResultView: View {
    let result: CompatibilityCheckResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: result.matches.isEmpty ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(result.matches.isEmpty ? Color.green : Color.orange)
                VStack(alignment: .leading) {
                    Text("Compatibility Check").font(.title2.bold())
                    Text(result.filename).foregroundStyle(.secondary)
                }
            }

            if result.inspection.assetPaths.isEmpty {
                Text("No static game-file targets could be identified, so compatibility is unknown.")
            } else if result.matches.isEmpty {
                Text("No file overlap was found with the mods currently in your library.")
                Text("\(result.inspection.assetPaths.count) game file\(result.inspection.assetPaths.count == 1 ? " was" : "s were") analyzed.")
                    .foregroundStyle(.secondary)
            } else {
                Text("This mod touches the same game files as:").font(.headline)
                List(result.matches) { match in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.modName).font(.headline)
                        Text("\(match.sharedPaths.count) shared file\(match.sharedPaths.count == 1 ? "" : "s") • \(match.active ? "currently enabled" : "currently disabled")")
                            .font(.caption)
                            .foregroundStyle(match.active ? Color.orange : Color.secondary)
                        ForEach(match.sharedPaths.prefix(5), id: \.self) { path in
                            Text(path).font(.caption.monospaced()).textSelection(.enabled)
                        }
                        if match.sharedPaths.count > 5 {
                            Text("and \(match.sharedPaths.count - 5) more…").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(minHeight: 160)
            }

            ForEach(result.inspection.warnings, id: \.self) { warning in
                Label(warning, systemImage: "info.circle").font(.callout).foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 620, minHeight: 360)
    }
}
