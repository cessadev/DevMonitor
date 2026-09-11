import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        CapsuleButtonBody(
            configuration: configuration,
            isDisabled: isDisabled
        )
    }
}

private struct CapsuleButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let isDisabled: Bool

    @State private var isHovered = false

    var body: some View {
        configuration.label
            .background(
                Capsule()
                    .fill(backgroundColor)
                    .strokeBorder(borderColor, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .brightness(isHovered && !isDisabled ? 0.06 : 0.0)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovered in
                isHovered = hovered
            }
    }

    private var backgroundColor: Color {
        if isDisabled {
            return .white.opacity(0.06)
        }
        if configuration.isPressed {
            return .white.opacity(0.28)
        }
        if isHovered {
            return .white.opacity(0.24)
        }
        return .white.opacity(0.18)
    }

    private var borderColor: Color {
        if isDisabled {
            return .white.opacity(0.15)
        }
        if configuration.isPressed || isHovered {
            return .white.opacity(0.65)
        }
        return .white.opacity(0.45)
    }
}
