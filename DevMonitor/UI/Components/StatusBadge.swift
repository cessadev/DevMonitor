import SwiftUI

struct StatusBadge: View {
    let isRunning: Bool
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isRunning ? Color.green : Color.red.opacity(0.8))
                .frame(width: 8, height: 8)
                .shadow(color: isRunning ? .green.opacity(0.6) : .clear, radius: 3)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }
}
