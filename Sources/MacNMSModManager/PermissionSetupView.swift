import SwiftUI

struct PermissionSetupView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Brand.teal)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Allow game modifications")
                        .font(.title2.bold())
                    Text("macOS protects one app from changing another app.")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 14) {
                PermissionStep(number: 1, text: "Open App Management in System Settings.")
                PermissionStep(number: 2, text: "Turn on Mac NMS Mod Manager. If it is not listed, use the + button and select this app.")
                PermissionStep(number: 3, text: "Return here and click Check Access. Reopen the manager first if macOS asks you to.")
            }

            Text("This grants access only through macOS. The manager still backs up the game executable before patching and never changes stock game archives.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Button("Show This App in Finder", action: model.revealThisApp)
                Spacer()
                Button("Not Now", action: dismiss.callAsFunction)
                Button("Open App Management", action: model.openAppManagementSettings)
                Button("Check Access", action: model.checkGameAccess)
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isWorking)
            }
        }
        .padding(28)
        .frame(width: 610)
    }
}

private struct PermissionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Brand.teal, in: Circle())
            Text(text)
                .padding(.top, 4)
        }
    }
}
