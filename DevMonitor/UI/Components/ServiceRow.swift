import SwiftUI

struct ServiceRow: View {
    let service: LocalService
    let isExpandable: Bool
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: service.icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(service.name)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)

            if isExpandable {
                HStack(spacing: 6) {
                    StatusBadge(isRunning: service.isRunning, label: service.isRunning ? "Running" : "Stopped")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(duration: 0.3), value: isExpanded)
                }
            } else {
                StatusBadge(isRunning: service.isRunning, label: service.isRunning ? "Running" : "Stopped")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
}
