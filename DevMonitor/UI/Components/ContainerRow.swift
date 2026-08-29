import SwiftUI

struct ContainerRow: View {
    let container: DockerContainer
    let onToggle: () async -> Void

    @State private var isLoading = false
    @State private var isOn: Bool

    init(container: DockerContainer, onToggle: @escaping () async -> Void) {
        self.container = container
        self.onToggle  = onToggle
        self._isOn     = State(initialValue: container.isRunning)
    }

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

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isLoading)
                .onChange(of: isOn) { _, _ in
                    isLoading = true
                    Task {
                        await onToggle()
                        isLoading = false
                    }
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .onChange(of: container.isRunning) { _, newValue in
            isOn = newValue
        }
    }
}
