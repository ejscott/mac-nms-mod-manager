import ModManagerCore
import SwiftUI

struct GuideView: View {
    var body: some View {
        ScrollView {
            Text(LocalizedStringKey(AuthoringGuide.markdown))
                .textSelection(.enabled)
                .frame(maxWidth: 760, alignment: .leading)
                .padding(32)
        }.navigationTitle("Authoring Guide")
    }
}
