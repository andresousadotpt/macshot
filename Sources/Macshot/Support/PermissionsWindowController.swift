import AppKit
import SwiftUI

@MainActor
final class PermissionsWindowController: NSWindowController {
    private static var activeController: PermissionsWindowController?

    static func present(viewModel: SettingsViewModel) {
        if let activeController {
            activeController.showWindow(nil)
            activeController.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = PermissionsWindowController(viewModel: viewModel)
        activeController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private init(viewModel: SettingsViewModel) {
        let view = PermissionsOnboardingView(viewModel: viewModel) {
            Task { @MainActor in
                PermissionsWindowController.activeController?.closeWindow()
            }
        }
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Macshot Permissions"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func closeWindow() {
        close()
        Self.activeController = nil
    }

    override func close() {
        super.close()
        if Self.activeController === self {
            Self.activeController = nil
        }
    }
}
