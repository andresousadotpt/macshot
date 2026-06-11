import AppKit
import SwiftUI

@MainActor
final class PermissionsWindowController: NSWindowController {
    private static var activeController: PermissionsWindowController?
    private static let windowSize = NSSize(width: 480, height: 520)

    static func present(viewModel: SettingsViewModel, mode: PermissionsOnboardingView.Mode = .settings) {
        if let activeController {
            activeController.showWindow(nil)
            activeController.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            Task { @MainActor in
                await activeController.refreshAfterWindowIsVisible(viewModel: viewModel)
            }
            return
        }

        let controller = PermissionsWindowController(viewModel: viewModel, mode: mode)
        activeController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        Task { @MainActor in
            await controller.refreshAfterWindowIsVisible(viewModel: viewModel)
        }
    }

    private init(viewModel: SettingsViewModel, mode: PermissionsOnboardingView.Mode) {
        let view = PermissionsOnboardingView(viewModel: viewModel, mode: mode) {
            Task { @MainActor in
                PermissionsWindowController.activeController?.closeWindow()
            }
        }
        let hosting = NSHostingController(rootView: view)
        // Prevent NSHostingView from auto-resizing the window during layout. SwiftUI
        // state updates while constraints are being solved can re-enter layout and crash.
        hosting.sizingOptions = []

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.windowSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hosting
        window.title = "Macshot Permissions"
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    private func refreshAfterWindowIsVisible(viewModel: SettingsViewModel) async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(100))
        await viewModel.refreshPermissionStatus()
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
