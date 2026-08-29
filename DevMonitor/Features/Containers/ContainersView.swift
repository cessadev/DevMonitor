import SwiftUI

struct ContainersView: View {

    let containers: [DockerContainer]
    let onToggle: (DockerContainer) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(title: "Docker Containers")

            VStack(spacing: 2) {
                ForEach(containers) { container in
                    ContainerRow(container: container) {
                        await onToggle(container)
                    }
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
