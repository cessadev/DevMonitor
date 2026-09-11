import SwiftUI

struct CollapsibleHeader: View {
    let title: String
    let count: Int
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)

                Spacer()

                HStack(spacing: 6) {
                    Text("\(count)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.12))
                                .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
                        )

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(duration: 0.3), value: isExpanded)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.bottom, 6)
    }
}
