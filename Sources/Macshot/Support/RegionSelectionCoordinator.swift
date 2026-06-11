import AppKit
import MacshotCore

@MainActor
final class RegionSelectionCoordinator {
    private var controllers: [RegionSelectionWindowController] = []
    private var finished = false
    private let escapeMonitor = EscapeCancelMonitor()
    private var selectionMonitor: Any?
    private var activeView: RegionSelectionView?

    func selectRegion(
        snapshots: [DisplaySnapshot],
        dimOpacity: Double
    ) async -> CaptureRect? {
        await withCheckedContinuation { continuation in
            finished = false
            activeView = nil
            controllers = snapshots.map { snapshot in
                RegionSelectionWindowController(snapshot: snapshot, dimOpacity: CGFloat(dimOpacity))
            }

            let complete: (CaptureRect) -> Void = { [weak self] rect in
                self?.finish(returning: rect, continuation: continuation)
            }

            let cancel: () -> Void = { [weak self] in
                self?.finish(returning: nil, continuation: continuation)
            }

            NSApp.activate(ignoringOtherApps: true)

            for controller in controllers {
                controller.present(onComplete: complete, onCancel: cancel)
            }

            controller(at: NSEvent.mouseLocation)?.focus()
            startSelectionMonitor()

            escapeMonitor.start(onCancel: cancel)
            SelectionCursor.begin()
        }
    }

    private func controller(at mouseLocation: NSPoint) -> RegionSelectionWindowController? {
        controllers.first { $0.screenFrame.contains(mouseLocation) }
    }

    /// Route mouse events centrally so every display works regardless of key-window state.
    private func startSelectionMonitor() {
        selectionMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp, .mouseMoved]
        ) { [weak self] event in
            guard let self else { return event }

            var consumed = false
            if Thread.isMainThread {
                consumed = MainActor.assumeIsolated {
                    self.handleSelectionEvent(event)
                }
            } else {
                DispatchQueue.main.sync {
                    consumed = MainActor.assumeIsolated {
                        self.handleSelectionEvent(event)
                    }
                }
            }

            return consumed ? nil : event
        }
    }

    @discardableResult
    private func handleSelectionEvent(_ event: NSEvent) -> Bool {
        guard !finished else { return false }

        let location = NSEvent.mouseLocation

        switch event.type {
        case .leftMouseDown:
            guard let view = view(at: location) else { return false }
            activeView = view
            view.beginSelection(atScreen: location)
            return true

        case .leftMouseDragged:
            if let activeView {
                activeView.updateSelection(atScreen: location)
            } else if let view = view(at: location) {
                activeView = view
                view.beginSelection(atScreen: location)
            }
            return true

        case .leftMouseUp:
            defer { activeView = nil }
            guard let activeView else { return false }
            activeView.endSelection(atScreen: location)
            return true

        case .mouseMoved:
            for controller in controllers {
                if controller.screenFrame.contains(location) {
                    controller.regionView.updateHover(atScreen: location)
                } else {
                    controller.regionView.clearHover()
                }
            }
            return false

        default:
            return false
        }
    }

    private func view(at mouseLocation: NSPoint) -> RegionSelectionView? {
        controller(at: mouseLocation)?.regionView
    }

    /// Tear down after the current event finishes to avoid removing a monitor from its own callback.
    private func finish(
        returning rect: CaptureRect?,
        continuation: CheckedContinuation<CaptureRect?, Never>
    ) {
        guard !finished else { return }
        finished = true

        DispatchQueue.main.async { [weak self] in
            self?.dismiss()
            continuation.resume(returning: rect)
        }
    }

    private func stopSelectionMonitor() {
        if let selectionMonitor {
            NSEvent.removeMonitor(selectionMonitor)
            self.selectionMonitor = nil
        }
    }

    private func dismiss() {
        stopSelectionMonitor()
        activeView = nil
        escapeMonitor.stop()
        SelectionCursor.end()
        for controller in controllers {
            controller.close()
        }
        controllers = []
    }
}
