import ModManagerCore
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack(spacing: 11) {
                    BrandLogo(size: 42)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Mac NMS").font(.headline)
                        Text("Mod Manager").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                Divider().opacity(0.55)
                List(SidebarItem.allCases, selection: $model.selectedTab) { item in
                    Label(item.rawValue, systemImage: item.icon).tag(item)
                }
                .scrollContentBackground(.hidden)
            }
            .background(Brand.navy.opacity(0.055))
        } detail: {
            Group {
                switch model.selectedTab {
                case .dashboard: DashboardView()
                case .mods: ModsView()
                case .guide: GuideView()
                case .settings: SettingsView()
                }
            }
            .background(BrandBackdrop())
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { Task { await model.refresh() } } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                        .disabled(model.isWorking)
                }
            }
        }
        .tint(Brand.teal)
        .alert("Mac NMS Mod Manager", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) { Button("OK") { model.errorMessage = nil } } message: { Text(model.errorMessage ?? "") }
    }
}
