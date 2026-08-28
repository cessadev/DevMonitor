import SwiftUI

struct ContentView: View {
    
    @State private var monitor = ServiceMonitor()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header
            HStack {
                Image(systemName: "server.rack")
                    .foregroundStyle(.secondary)
                Text("DevMonitor")
                    .font(.headline)
                Spacer()
                Button {
                    monitor.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Service list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(monitor.services) { service in
                    ServiceRow(service: service)
                }
            }
            .padding()

            // Docker Containers section
            if !monitor.containers.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Containers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 4)
                    
                    ForEach(monitor.containers) { container in
                        ContainerRow(container: container)
                    }
                }
                .padding(.bottom, 8)
            }

            // Error state
            if let error = monitor.dockerError {
                Divider()
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("Auto-refresh: 5s")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }
}

struct ServiceRow: View {
    let service: LocalService
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: service.icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(service.name)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(service.isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(service.isRunning ? "Running" : "Stopped")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ContainerRow: View {
    let container: DockerContainer
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "cube")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(container.displayName)
                    .font(.callout)
                Text(container.image)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(container.isRunning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(container.state.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }
}
