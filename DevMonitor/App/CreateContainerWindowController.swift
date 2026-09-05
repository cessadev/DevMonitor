import AppKit
import SwiftUI

class CreateContainerWindowController: NSWindowController {

    static func open(
        imageName: String,
        onCreate: @escaping (String, [String], [String], String) async -> (success: Bool, validationError: String?)
    ) {
        let view       = CreateContainerView(imageName: imageName, onCreate: onCreate)
        let hosting    = NSHostingController(rootView: view)
        let window     = NSWindow(contentViewController: hosting)

        window.title                         = "New Container"
        window.styleMask                     = [.titled, .closable]
        window.titlebarAppearsTransparent    = false
        window.isMovableByWindowBackground   = true
        window.center()
        window.setContentSize(NSSize(width: 320, height: 480))
        window.minSize                       = NSSize(width: 320, height: 380)

        let controller = CreateContainerWindowController(window: window)
        controller.showWindow(nil)

        // Bring window to front
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // Store strong reference so window isn't deallocated
        WindowRegistry.shared.register(controller)

        // Clean up when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            WindowRegistry.shared.unregister(controller)
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

// Keeps a strong reference to open windows
class WindowRegistry {
    static let shared = WindowRegistry()
    private var controllers: [NSWindowController] = []

    func register(_ controller: NSWindowController) {
        controllers.append(controller)
    }

    func unregister(_ controller: NSWindowController) {
        controllers.removeAll { $0 === controller }
    }
}
