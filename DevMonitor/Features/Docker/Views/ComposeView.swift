import SwiftUI

struct ComposeView: View {
    let projects: [DockerComposeProject]
    let loadingProjectId: UUID?
    let onUp: (DockerComposeProject) async -> Void
    let onDown: (DockerComposeProject) async -> Void
    let onAddManual: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(title: "Compose Projects")
                .padding(.vertical, 4)

            // Lista con fondo glass
            if !projects.isEmpty {
                VStack(spacing: 2) {
                    ForEach(projects) { project in
                        ComposeProjectRow(
                            project: project,
                            isLoading: loadingProjectId == project.id,
                            onUp:   { await onUp(project) },
                            onDown: { await onDown(project) }
                        )
                    }
                }
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            }

            // Button
            Button(action: onAddManual) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text("Add compose file...")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
