import SwiftUI

struct StatusBadge: View {
    let isRunning: Bool
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isRunning ? Color.green : Color.red.opacity(0.8))
                .frame(width: 6, height: 6)
                .shadow(color: isRunning ? .green.opacity(0.6) : .clear, radius: 3)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(.white.opacity(0.12))
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
        )
    }
}
