import SwiftUI

struct ContainersView: View {

    let containers: [DockerContainer]
    let lockedComposeProject: String?
    let activeComposeProjects: Set<String>
    let onToggle: (DockerContainer) async -> Void
    let onDelete: (DockerContainer) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(title: "Docker Containers")
                .padding(.vertical, 4)

            VStack(spacing: 2) {
                ForEach(containers) { container in
                    let isLocked: Bool = {
                        guard let locked = lockedComposeProject,
                              let containerProject = container.composeProject else {
                            return false
                        }
                        return containerProject.lowercased() == locked
                    }()
                    
                    // Trash locked when container belongs to an active compose project
                    let isDeleteLocked: Bool = {
                        guard let containerProject = container.composeProject else {
                            return false
                        }
                        return activeComposeProjects.contains(containerProject.lowercased())
                    }()
                    
                    ContainerRow(
                        container: container,
                        isLocked: isLocked,
                        isDeleteLocked: isDeleteLocked,
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
