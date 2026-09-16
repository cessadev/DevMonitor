import SwiftUI

struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(AppFont.label)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 4)
    }
}
