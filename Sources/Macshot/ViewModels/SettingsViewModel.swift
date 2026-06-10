import AppKit
import MacshotCore
import ScreenCaptureKit

enum HotkeyRecordingTarget: Equatable {
    case screenshot
    case gif
}

@MainActor
@Observable
final class SettingsViewModel {
    var settings: AppSettings
    var screenRecordingGranted = false
    var accessibilityGranted = false
    var notificationsGranted = false
    var saveMessage: String?
    var recordingTarget: HotkeyRecordingTarget?
    var onHotkeysChanged: ((AppSettings) -> Void)?

    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.settings = .default
    }

    var allPermissionsGranted: Bool {
        accessibilityGranted && screenRecordingGranted && notificationsGranted
    }

    func load() async {
        settings = await settingsStore.current()
        await refreshPermissionStatus()
        onHotkeysChanged?(settings)
    }

    func save() async {
        guard settings.screenshotHotkey.isValid, settings.gifHotkey.isValid else {
            saveMessage = "Each hotkey needs at least one modifier and a key."
            return
        }
        guard !settings.hotkeysConflict else {
            saveMessage = "Screenshot and GIF hotkeys cannot be the same."
            return
        }

        do {
            try await settingsStore.save(settings)
            onHotkeysChanged?(settings)
            saveMessage = "Settings saved."
        } catch {
            saveMessage = "Could not save settings."
        }
    }

    func refreshPermissionStatus() async {
        let status = await PermissionManager.currentStatus()
        accessibilityGranted = status.accessibility
        screenRecordingGranted = status.screenRecording
        notificationsGranted = status.notifications
    }

    func requestAllPermissions() async {
        await PermissionManager.requestAll()
        await refreshPermissionStatus()
        onHotkeysChanged?(settings)
    }

    func requestAccessibilityPermission() {
        PermissionManager.requestAccessibility()
        accessibilityGranted = HotkeyService.isAccessibilityGranted
        onHotkeysChanged?(settings)
    }

    func requestScreenRecordingPermission() async {
        await PermissionManager.requestScreenRecording()
        await refreshPermissionStatus()
    }

    func requestNotificationPermission() async {
        await PermissionManager.requestNotifications()
        await refreshPermissionStatus()
    }

    func openScreenRecordingSettings() {
        PermissionManager.openScreenRecordingSettings()
    }

    func openAccessibilitySettings() {
        PermissionManager.openAccessibilitySettings()
    }

    func openNotificationSettings() {
        PermissionManager.openNotificationSettings()
    }

    func markPermissionOnboardingCompleted() async {
        settings.hasCompletedPermissionOnboarding = true
        await save()
    }

    var screenshotHotkeyDescription: String {
        settings.screenshotHotkey.displayString()
    }

    var gifHotkeyDescription: String {
        settings.gifHotkey.displayString()
    }

    func startRecording(_ target: HotkeyRecordingTarget) {
        recordingTarget = target
        HotkeyRecorder.shared.startRecording { [weak self] binding in
            guard let self else { return }
            switch target {
            case .screenshot:
                self.settings.screenshotHotkey = binding
            case .gif:
                self.settings.gifHotkey = binding
            }
            self.recordingTarget = nil
            Task { await self.save() }
        } onCancel: { [weak self] in
            self?.recordingTarget = nil
        }
    }

    func cancelRecording() {
        HotkeyRecorder.shared.stopRecording()
        recordingTarget = nil
    }
}
