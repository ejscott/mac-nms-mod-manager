import ModManagerCore
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmPatch = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 18) {
                    BrandLogo(size: 74)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ready for the stars").font(.largeTitle.bold())
                        Text("Patch safely, organize cleanly, and catch mod conflicts before launch.")
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 18) {
                    StatusCard(title: "Game", value: model.installation == nil ? "Not found" : "Found", symbol: "gamecontroller")
                    StatusCard(title: "Mod loader", value: healthLabel, symbol: healthSymbol, tint: healthTint)
                    StatusCard(title: "Active mods", value: "\(model.mods.filter(\.enabled).count)", symbol: "shippingbox.fill")
                    StatusCard(title: "Active conflicts", value: "\(ModCompatibilityAnalyzer.activeConflictCount(in: model.mods))", symbol: "exclamationmark.triangle.fill", tint: ModCompatibilityAnalyzer.activeConflictCount(in: model.mods) == 0 ? .green : .orange)
                }
                GroupBox("Executable status") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(model.inspection.details, systemImage: healthSymbol).foregroundStyle(healthTint)
                        if let fingerprint = model.inspection.fingerprint {
                            LabeledContent("ARM64 fingerprint", value: String(fingerprint.arm64SHA256.prefix(16)) + "…")
                            LabeledContent("Executable size", value: ByteCountFormatter.string(fromByteCount: Int64(fingerprint.fileSize), countStyle: .file))
                        }
                        if model.inspection.health == .unsupported || model.inspection.health == .updateDetected {
                            Text("For safety, this build will not be modified until its instruction signatures are reviewed and added as a recipe.")
                                .foregroundStyle(.secondary)
                        }
                        if model.inspection.health == .readyToPatch {
                            Button("Back Up and Enable Mod Loading") { confirmPatch = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(6)
                }
                GroupBox("How loading works") {
                    Text("Mac HGPAK mods are mounted from MACOSBANKS/MODS first. The game then mounts stock MACOSBANKS normally, so stock archives remain untouched and matching mod assets take precedence.")
                        .frame(maxWidth: .infinity, alignment: .leading).padding(6)
                }
            }.padding(28)
        }
        .navigationTitle("Dashboard")
        .confirmationDialog("Modify the game executable?", isPresented: $confirmPatch) {
            Button("Create Backup, Patch, and Sign") { model.applyPatch() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The manager will first save a checksummed backup outside the Steam game folder, then verify the patch and code signature.")
        }
    }

    private var healthLabel: String {
        switch model.inspection.health {
        case .patched: "Ready"
        case .readyToPatch: "Patch available"
        case .updateDetected: "Update detected"
        case .unsupported: "Unsupported build"
        case .invalid: "Needs attention"
        case .notInspected: "Checking"
        }
    }
    private var healthSymbol: String { model.inspection.health == .patched ? "checkmark.seal.fill" : "exclamationmark.triangle.fill" }
    private var healthTint: Color { model.inspection.health == .patched ? .green : .orange }
}

private struct StatusCard: View {
    let title: String
    let value: String
    let symbol: String
    var tint: Color = .accentColor
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).font(.title2).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.title3.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .brandPanel()
    }
}
