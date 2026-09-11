import AppKit
import Foundation
import ModManagerCore

@MainActor
final class AppModel: ObservableObject {
    @Published var installation: GameInstallation?
    @Published var inspection = PatchInspection(health: .notInspected, details: "Looking for No Man's Sky…")
    @Published var mods: [ModRecord] = []
    @Published var errorMessage: String?
    @Published var compatibilityCheck: CompatibilityCheckResult?
    @Published var isWorking = false
    @Published var selectedTab: SidebarItem = .dashboard

    let directories = AppDirectories()
    private lazy var registry = RegistryStore(url: directories.registryURL)
    private let patcher = ExecutablePatcher()

    func refresh() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let state = await registry.snapshot()
            let location = try GameLocator().locate(appURL: state.gameAppURL ?? GameLocator.defaultAppURL)
            installation = location
            inspection = patcher.inspect(executableURL: location.executableURL, previousFingerprint: state.lastSeenFingerprint)
            let installer = ModInstaller(installation: location, directories: directories, registry: registry)
            _ = try await installer.reconcileUntrackedArchives()
            _ = try await installer.refreshCompatibilityMetadata()
            let refreshedState = await registry.snapshot()
            mods = refreshedState.mods.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            if inspection.health == .patched || inspection.health == .readyToPatch {
                try await registry.recordInspection(gameURL: location.appURL, fingerprint: inspection.fingerprint)
            }
        } catch {
            installation = nil
            inspection = PatchInspection(health: .invalid, details: error.localizedDescription)
        }
    }

    func chooseGame() {
        let panel = NSOpenPanel()
        panel.title = "Choose No Man's Sky.app"
        panel.prompt = "Choose Game"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task {
            do {
                var state = await registry.snapshot()
                state.gameAppURL = url
                try await registry.replace(with: state)
                await refresh()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func chooseAndInstallMod() {
        guard let installation else { return }
        guard inspection.health == .patched else {
            errorMessage = "The executable patch must validate before installing a mod."
            return
        }
        let panel = NSOpenPanel()
        panel.title = "Choose a Mac HGPAK mod"
        panel.prompt = "Install"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard ModInputClassifier.classify(url) == .macHGPAK else {
            errorMessage = "This milestone accepts .hgpak files. Windows .pak and EXML/MBIN conversion is planned but not enabled yet."
            return
        }
        Task {
            isWorking = true
            defer { isWorking = false }
            do {
                let installer = ModInstaller(installation: installation, directories: directories, registry: registry)
                _ = try await installer.installHGPAK(from: url)
                await refresh()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func chooseAndCheckCompatibility() {
        let panel = NSOpenPanel()
        panel.title = "Choose a Mac mod or AMUMSS Lua script"
        panel.prompt = "Check"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let inspection = try ModAssetInspector.inspect(url)
            compatibilityCheck = CompatibilityCheckResult(
                filename: url.lastPathComponent,
                inspection: inspection,
                matches: ModCompatibilityAnalyzer.matches(paths: inspection.assetPaths, against: mods)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyPatch() {
        guard let installation,
              inspection.health == .readyToPatch,
              let recipeID = inspection.recipeID,
              let recipe = BuiltInPatchRecipes.all.first(where: { $0.id == recipeID }) else { return }
        Task {
            isWorking = true
            defer { isWorking = false }
            do {
                let receipt = try PatchTransaction(directories: directories, patcher: patcher).apply(recipe: recipe, to: installation)
                var state = await registry.snapshot()
                state.patchReceipt = receipt
                state.lastSeenFingerprint = receipt.after
                try await registry.replace(with: state)
                await refresh()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func setEnabled(_ enabled: Bool, mod: ModRecord) {
        guard let installation else { return }
        Task {
            do {
                try await ModInstaller(installation: installation, directories: directories, registry: registry).setEnabled(enabled, id: mod.id)
                await refresh()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func uninstall(_ mod: ModRecord) {
        guard let installation else { return }
        Task {
            do {
                try await ModInstaller(installation: installation, directories: directories, registry: registry).uninstall(id: mod.id)
                await refresh()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}

struct CompatibilityCheckResult: Identifiable {
    let id = UUID()
    var filename: String
    var inspection: ModAssetInspection
    var matches: [ModCompatibilityMatch]
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case mods = "Mods"
    case guide = "Authoring Guide"
    case settings = "Settings"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .dashboard: "gauge.with.dots.needle.50percent"
        case .mods: "shippingbox"
        case .guide: "book.closed"
        case .settings: "gearshape"
        }
    }
}
