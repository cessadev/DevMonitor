import SwiftUI

enum AppFont {

    // MARK: - Scale

    /// Panel title — "DevMonitor"
    static let title: Font         = .system(size: 14, weight: .semibold)

    /// Primary row text — container name, image tag, service name
    static let body: Font          = .system(size: 14)

    /// Primary row text with medium weight — icons, labels
    static let bodyMedium: Font    = .system(size: 13, weight: .medium)

    /// Buttons, inputs, form actions
    static let action: Font        = .system(size: 13)

    /// Section headers, badges, secondary info
    static let caption: Font       = .system(size: 11)

    /// Section labels, form section titles, metadata
    static let label: Font         = .system(size: 10, weight: .semibold)

    /// Secondary metadata — image ID, size, age
    static let metadata: Font      = .system(size: 10)

    /// Chevrons, small controls
    static let micro: Font         = .system(size: 10, weight: .medium)

    /// Build output console
    static let mono: Font          = .system(size: 9, design: .monospaced)
}

// MARK: - Icon Sizes

enum AppIcon {

    // Row SVG icons — docker, container, image, compose
    static let rowIcon: CGFloat    = 16
    
    // Action icons — trash, play, stop
    static let actionIcon: CGFloat = 11

    // Status dot — service running indicator
    static let statusDot: CGFloat  = 9

    // Compose status dot
    static let composeDot: CGFloat = 8
}

// MARK: - Control Sizes

enum AppControl {

    // Toggle switch scale relative to .mini
    // Used in ContainerRow and ComposeProjectRow
    static let switchControlSize: ControlSize = .small
}
