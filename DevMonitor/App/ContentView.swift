import SwiftUI
import Combine

struct ContentView: View {

    @State private var servicesVM    = ServicesViewModel()
    @State private var containersVM  = ContainersViewModel()
    @State private var containersExpanded = false
    private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.clear

            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack(spacing: 8) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 14, weight: .medium))
                    Text("DevMonitor")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Button {
                        refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                // Local Services
                ServicesView(
                    services: servicesVM.services,
                    containersExpanded: containersExpanded,
                    onDockerTap: { containersExpanded.toggle() }
                )

                // Docker Containers
                if containersExpanded && !containersVM.containers.isEmpty {
                    ContainersView(
                        containers: containersVM.containers,
                        onToggle: { container in
                            await containersVM.toggle(container)
                        }
                    )
                }

                // Error
                if let error = containersVM.error {
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
        .onReceive(timer) { _ in refresh() }
        .task { refresh() }
    }

    private func refresh() {
        servicesVM.refresh()
        Task { await containersVM.refresh() }
    }
}

