import SwiftUI

enum CapsuleButtonTint {
    case neutral
    case destructive
    case positive
}

struct CapsuleButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    var tint: CapsuleButtonTint = .neutral

    func makeBody(configuration: Configuration) -> some View {
        CapsuleButtonBody(
            configuration: configuration,
            isDisabled: isDisabled,
            tint: tint
        )
    }
}

private struct CapsuleButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let isDisabled: Bool
    let tint: CapsuleButtonTint

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
            .onHover { isHovered = $0 }
    }

    private var backgroundColor: Color {
        if isDisabled { return baseColor.opacity(0.06) }
        if configuration.isPressed { return baseColor.opacity(pressedFill) }
        if isHovered { return baseColor.opacity(hoverFill) }
        return baseColor.opacity(defaultFill)
    }

    private var borderColor: Color {
        if isDisabled { return baseColor.opacity(0.15) }
        if configuration.isPressed || isHovered { return baseColor.opacity(pressedBorder) }
        return baseColor.opacity(defaultBorder)
    }

    private var baseColor: Color {
        switch tint {
        case .neutral:     return .white
        case .destructive: return .red
        case .positive:    return .green
        }
    }

    private var defaultFill: Double {
        switch tint {
        case .neutral:     return 0.08
        case .destructive: return 0.08
        case .positive:    return 0.12
        }
    }

    private var hoverFill: Double {
        switch tint {
        case .neutral:     return 0.16
        case .destructive: return 0.14
        case .positive:    return 0.20
        }
    }

    private var pressedFill: Double {
        switch tint {
        case .neutral:     return 0.22
        case .destructive: return 0.20
        case .positive:    return 0.28
        }
    }

    private var defaultBorder: Double {
        switch tint {
        case .neutral:     return 0.18
        case .destructive: return 0.25
        case .positive:    return 0.25
        }
    }

    private var pressedBorder: Double {
        switch tint {
        case .neutral:     return 0.45
        case .destructive: return 0.45
        case .positive:    return 0.55
        }
    }
}
