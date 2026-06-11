import AppKit
import MacshotCore
import SwiftUI

@main
struct MacshotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Macshot", systemImage: "camera.viewfinder") {
            MenuBarView()
                .environment(appDelegate)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(viewModel: appDelegate.settingsViewModel)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, Observable {
    let settingsStore = SettingsStore()
    lazy var settingsViewModel = SettingsViewModel(settingsStore: settingsStore)
    lazy var captureCoordinator = CaptureCoordinator(settingsStore: settingsStore)
    private var hotkeyService: HotkeyService?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let service = HotkeyService { [weak self] action in
            Task { @MainActor in
                guard let self else { return }
                switch action {
                case .screenshot:
                    await self.captureCoordinator.captureScreenshot()
                case .gif:
                    await self.captureCoordinator.captureGIF()
                }
            }
        }
        hotkeyService = service

        settingsViewModel.onHotkeysChanged = { [weak self] settings in
            self?.hotkeyService?.register(screenshot: settings.screenshotHotkey, gif: settings.gifHotkey)
        }

        Task { @MainActor in
            await applyLaunchAtLoginPreference()
            await runPermissionOnboarding()
        }
    }

    private func applyLaunchAtLoginPreference() async {
        let settings = await settingsStore.current()
        guard settings.launchAtLogin != LaunchAtLoginService.isEnabled else { return }
        try? LaunchAtLoginService.setEnabled(settings.launchAtLogin)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService?.unregister()
    }

    private func runPermissionOnboarding() async {
        let settings = await settingsStore.current()
        hotkeyService?.register(screenshot: settings.screenshotHotkey, gif: settings.gifHotkey)

        try? await Task.sleep(for: .seconds(1))

        let status = await PermissionManager.currentStatus()
        let isFirstRun = !settings.hasCompletedPermissionOnboarding
        let shouldShowWindow = isFirstRun || status.anyMissing
        if shouldShowWindow {
            let mode: PermissionsOnboardingView.Mode = isFirstRun ? .onboarding : .settings
            PermissionsWindowController.present(viewModel: settingsViewModel, mode: mode)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            await settingsViewModel.refreshPermissionStatus()
        }

        hotkeyService?.register(screenshot: settings.screenshotHotkey, gif: settings.gifHotkey)
    }
}

private struct MenuBarView: View {
    @Environment(AppDelegate.self) private var appDelegate
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Capture Screenshot") {
            Task { await appDelegate.captureCoordinator.captureScreenshot() }
        }

        Button("Record GIF") {
            Task { await appDelegate.captureCoordinator.captureGIF() }
        }

        Divider()

        Button("Permissions…") {
            PermissionsWindowController.present(viewModel: appDelegate.settingsViewModel)
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("Settings…") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button("Quit Macshot") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
