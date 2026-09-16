import SwiftUI

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(AppFont.label)
                .foregroundStyle(.tertiary)
            content()
        }
    }
}
