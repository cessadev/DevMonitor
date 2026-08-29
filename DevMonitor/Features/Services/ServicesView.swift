import SwiftUI

struct ServicesView: View {

    let services: [LocalService]
    let containersExpanded: Bool
    let onDockerTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(title: "Local Services")

            VStack(spacing: 2) {
                ForEach(services) { service in
                    if service.processName == "Docker" {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                onDockerTap()
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
    }
}
