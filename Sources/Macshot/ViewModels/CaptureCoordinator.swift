import AppKit
import MacshotCore
import UserNotifications

@MainActor
@Observable
final class CaptureCoordinator {
    private let regionSelector = RegionSelectionCoordinator()
    private let gifCapture = GIFCaptureBridge()
    private let gifRecorder = GIFRecorder()
    private var recordingHUD: RecordingHUDWindowController?
    private var isFinishingRecording = false
    private let escapeMonitor = EscapeCancelMonitor()
    private let settingsStore: SettingsStore

    var isCapturing = false
    var lastError: String?

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func captureScreenshot() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        let settings = await settingsStore.current()
        let snapshots = DisplayCaptureBridge.captureAllDisplays()
        guard !snapshots.isEmpty else {
            lastError = "Could not capture display snapshots."
            return
        }

        guard let selection = await regionSelector.selectRegion(
            snapshots: snapshots,
            dimOpacity: settings.dimOpacity
        ) else {
            return
        }

        guard let snapshot = DisplaySnapshotService.snapshot(for: selection, in: snapshots),
              let cropped = ImageCropper.crop(snapshot: snapshot, selection: selection),
              let pngData = PNGExporter.pngData(from: cropped) else {
            lastError = "Could not process the screenshot."
            return
        }

        ClipboardBridge.copyPNG(pngData)
        lastError = nil
    }

    func captureGIF() async {
        guard !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }

        let settings = await settingsStore.current()
        let snapshots = DisplayCaptureBridge.captureAllDisplays()
        guard !snapshots.isEmpty else {
            lastError = "Could not capture display snapshots."
            return
        }

        guard let selection = await regionSelector.selectRegion(
            snapshots: snapshots,
            dimOpacity: settings.dimOpacity
        ) else {
            return
        }

        await gifRecorder.start(maxDuration: settings.maxRecordingDuration, fps: settings.gifFPS)

        let hud = RecordingHUDWindowController(selection: selection)
        recordingHUD = hud

        hud.onStop = { [weak self] in
            Task { @MainActor in
                await self?.finishGIFRecording(fps: settings.gifFPS)
            }
        }
        hud.show()

        escapeMonitor.start { [weak self] in
            Task { @MainActor in
                await self?.cancelGIFRecording()
            }
        }

        do {
            try await gifCapture.start(selection: selection, fps: settings.gifFPS) { [weak self] image in
                guard let self else { return }
                Task {
                    let shouldContinue = await self.gifRecorder.appendFrame(image)
                    if !shouldContinue {
                        await self.finishGIFRecording(fps: settings.gifFPS)
                    }
                }
            }
        } catch {
            lastError = error.localizedDescription
            await finishGIFRecording(fps: settings.gifFPS)
        }
    }

    private func cancelGIFRecording() async {
        guard !isFinishingRecording else { return }
        isFinishingRecording = true
        defer { isFinishingRecording = false }

        escapeMonitor.stop()
        recordingHUD?.dismiss()
        recordingHUD = nil
        await gifCapture.stop()
        await gifRecorder.cancel()
        lastError = nil
    }

    private func finishGIFRecording(fps: Int) async {
        guard !isFinishingRecording else { return }
        isFinishingRecording = true
        defer { isFinishingRecording = false }

        escapeMonitor.stop()
        recordingHUD?.dismiss()
        recordingHUD = nil
        await gifCapture.stop()

        let frameCount = await gifRecorder.frameCount
        guard let gifData = await gifRecorder.stop(fps: fps) else {
            let message = frameCount == 0
                ? "No frames were captured. Check Screen Recording permission for Macshot."
                : "Could not encode the GIF."
            lastError = message
            showNotification(title: "GIF recording failed", body: message)
            return
        }

        ClipboardBridge.copyGIF(gifData)
        lastError = nil
        showNotification(
            title: "GIF copied to clipboard",
            body: "Recorded \(frameCount) frame\(frameCount == 1 ? "" : "s"). Paste into your app."
        )
    }

    private func showNotification(title: String, body: String) {
        guard PermissionManager.canUseUserNotifications else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}
