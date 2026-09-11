import SwiftUI

@main
struct MacNMSModManagerApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 920, minHeight: 620)
                .task { await model.refresh() }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Install Mod…") { model.chooseAndInstallMod() }
                    .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}
