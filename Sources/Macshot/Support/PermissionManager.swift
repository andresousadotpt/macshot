import AppKit
import Foundation
import ScreenCaptureKit
import UserNotifications

struct PermissionStatus: Equatable, Sendable {
    var accessibility: Bool
    var screenRecording: Bool
    var notifications: Bool

    var allGranted: Bool {
        accessibility && screenRecording && notifications
    }

    var anyMissing: Bool {
        !allGranted
    }
}

@MainActor
enum PermissionManager {
    /// UserNotifications requires a packaged `.app` bundle; `swift run` uses `.build/.../debug` and crashes.
    static var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    static func currentStatus() async -> PermissionStatus {
        PermissionStatus(
            accessibility: HotkeyService.isAccessibilityGranted,
            screenRecording: await checkScreenRecording(),
            notifications: await checkNotifications()
        )
    }

    static func requestAll() async {
        // Notifications must be requested first while the app is still frontmost.
        // Accessibility and Screen Recording prompts open System Settings and prevent
        // the notification permission dialog from appearing.
        await requestNotifications()
        try? await Task.sleep(for: .milliseconds(600))
        requestAccessibility()
        try? await Task.sleep(for: .milliseconds(600))
        await requestScreenRecording()
    }

    static func requestAccessibility() {
        HotkeyService.promptForAccessibility()
    }

    static func requestScreenRecording() async {
        _ = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    static func requestNotifications() async {
        guard canUseUserNotifications else { return }
        NSApp.activate(ignoringOtherApps: true)
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    static func openAccessibilitySettings() {
        openSettings(url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    static func openScreenRecordingSettings() {
        openSettings(url: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    }

    static func openNotificationSettings() {
        openSettings(url: "x-apple.systempreferences:com.apple.preference.notifications")
    }

    private static func checkScreenRecording() async -> Bool {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return true
        } catch {
            return false
        }
    }

    private static func checkNotifications() async -> Bool {
        guard canUseUserNotifications else { return false }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    private static func openSettings(url: String) {
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }
}
