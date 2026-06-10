import AppKit
import MacshotCore

@MainActor
final class RegionSelectionCoordinator {
    private var controllers: [RegionSelectionWindowController] = []
    private var finished = false
    private let escapeMonitor = EscapeCancelMonitor()

    func selectRegion(
        snapshots: [DisplaySnapshot],
        dimOpacity: Double
    ) async -> CaptureRect? {
        await withCheckedContinuation { continuation in
            finished = false
            controllers = snapshots.map { snapshot in
                RegionSelectionWindowController(snapshot: snapshot, dimOpacity: CGFloat(dimOpacity))
            }

            let complete: (CaptureRect) -> Void = { [weak self] rect in
                guard let self, !self.finished else { return }
                self.finished = true
                self.dismiss()
                continuation.resume(returning: rect)
            }

            let cancel: () -> Void = { [weak self] in
                guard let self, !self.finished else { return }
                self.finished = true
                self.dismiss()
                continuation.resume(returning: nil)
            }

            for controller in controllers {
                controller.present(onComplete: complete, onCancel: cancel)
            }

            escapeMonitor.start(onCancel: cancel)
            CrosshairCursor.push()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func dismiss() {
        escapeMonitor.stop()
        CrosshairCursor.pop()
        for controller in controllers {
            controller.close()
        }
        controllers = []
    }
}
