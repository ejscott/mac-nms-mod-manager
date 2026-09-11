import ModManagerCore
import SwiftUI

struct GuideView: View {
    var body: some View {
        ScrollView {
            Text(LocalizedStringKey(AuthoringGuide.markdown))
                .textSelection(.enabled)
                .frame(maxWidth: 760, alignment: .leading)
                .padding(28)
                .brandPanel(cornerRadius: 18)
                .padding(28)
        }.navigationTitle("Authoring Guide")
    }
}
