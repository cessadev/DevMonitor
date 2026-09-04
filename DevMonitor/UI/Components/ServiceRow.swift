import SwiftUI

struct ServiceRow: View {
    let service: LocalService
    let isExpandable: Bool
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 10) {
            if isExpandable {
                Image("docker-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: service.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
            }

            Text(service.name)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            if isExpandable {
                HStack(spacing: 6) {
                    StatusDot(isRunning: service.isRunning)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
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
