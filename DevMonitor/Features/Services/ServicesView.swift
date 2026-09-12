import SwiftUI

struct ServicesView: View {

    let services: [LocalService]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel(title: "Local Service")
            
            VStack(spacing: 2) {
                ForEach(services) { service in
                    ServiceRow(service: service)
                }
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }
}
