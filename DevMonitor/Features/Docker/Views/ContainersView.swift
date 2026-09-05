import SwiftUI

struct ContainersView: View {

    let containers: [DockerContainer]
    let lockedContainersNames: Set<String>
    let onToggle: (DockerContainer) async -> Void
    let onDelete: (DockerContainer) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(title: "Docker Containers")
                .padding(.vertical, 4)

            VStack(spacing: 2) {
                ForEach(containers) { container in
                    let isLocked = lockedContainersNames.contains(where: {
                        container.displayName.hasPrefix($0) || container.displayName == $0
                    })
                    ContainerRow(
                        container: container,
                        isLocked: isLocked,
                        onToggle: { await onToggle(container) },
                        onDelete: { await onDelete(container) }
                    )
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
