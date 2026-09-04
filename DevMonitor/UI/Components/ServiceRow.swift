import SwiftUI

struct ServiceRow: View {
    let service: LocalService

    var body: some View {
        HStack(spacing: 10) {
            Image("docker-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(.secondary)

            Text(service.name)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            StatusDot(isRunning: service.isRunning)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
}

// MARK: - Status Dot

private struct StatusDot: View {
    let isRunning: Bool

    var body: some View {
        Circle()
            .fill(isRunning ? Color.green : Color.red)
            .frame(width: 8, height: 8)
            .shadow(color: isRunning ? .green.opacity(0.7) : .red.opacity(0.7), radius: 2)
    }
}
