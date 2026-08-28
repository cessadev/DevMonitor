import SwiftUI

struct ContentView: View {

    @State private var monitor = ServiceMonitor()
    @State private var containersExpanded = false

    var body: some View {
        ZStack {
            Color.clear

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack(spacing: 8) {
                    Text("DevMonitor")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Button {
                        monitor.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Local Services section
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(title: "Local Services")

                    VStack(spacing: 2) {
                        ForEach(monitor.services) { service in
                            if service.processName == "Docker" {
                                // Docker row — tappable, toggles containers
                                Button {
                                    withAnimation(.spring(duration: 0.3)) {
                                        containersExpanded.toggle()
                                    }
                                } label: {
                                    ServiceRow(
                                        service: service,
                                        isExpandable: true,
                                        isExpanded: containersExpanded
                                    )
                                }
                                .buttonStyle(.plain)
                            } else {
                                ServiceRow(service: service, isExpandable: false, isExpanded: false)
                            }
                        }
                    }
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 6)

                // Docker Containers — collapsible
                if containersExpanded && !monitor.containers.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionLabel(title: "Docker Containers")

                        VStack(spacing: 2) {
                            ForEach(monitor.containers) { container in
                                ContainerRow(container: container) {
                                    await monitor.toggleContainer(container)
                                }
                            }
                        }
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Error state
                if let error = monitor.dockerError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .padding(10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }

                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("Refreshes every 5s")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                    .keyboardShortcut("q")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 300)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 4)
    }
}

// MARK: - Service Row

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

// MARK: - Container Row

struct ContainerRow: View {
    let container: DockerContainer
    let onToggle: () async -> Void

    @State private var isLoading = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "cube")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(container.displayName)
                    .font(.system(size: 13))
                Text(container.image)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // StatusBadge actúa como botón de toggle
            Button {
                isLoading = true
                Task {
                    await onToggle()
                    isLoading = false
                }
            } label: {
                HStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(container.isRunning ? Color.green : Color.red.opacity(0.8))
                            .frame(width: 6, height: 6)
                            .shadow(color: container.isRunning ? .green.opacity(0.6) : .clear, radius: 3)
                    }
                    Text(container.state.capitalized)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .glassEffect(.regular, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
}

// MARK: - Status Badge

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
        .glassEffect(.regular, in: Capsule())
    }
}
