import AppKit
import MacshotCore

final class RegionSelectionWindowController: NSWindowController {
    let displayID: CGDirectDisplayID
    private(set) var screenFrame: CGRect
    let regionView = RegionSelectionView()

    init(snapshot: DisplaySnapshot, dimOpacity: CGFloat) {
        displayID = snapshot.displayID
        screenFrame = snapshot.screenFrame

        let window = KeyableWindow(
            contentRect: snapshot.screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: Self.screen(for: snapshot.displayID)
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        super.init(window: window)

        regionView.snapshot = snapshot
        regionView.screenFrame = snapshot.screenFrame
        regionView.dimOpacity = dimOpacity
        window.contentView = regionView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(
        onComplete: @escaping (CaptureRect) -> Void,
        onCancel: @escaping () -> Void
    ) {
        if let screen = Self.screen(for: displayID) {
            screenFrame = screen.frame
            regionView.screenFrame = screen.frame
            window?.setFrame(screen.frame, display: true)
        }

        regionView.onComplete = onComplete
        regionView.onCancel = onCancel
        showWindow(nil)
        window?.orderFrontRegardless()
    }

    func focus() {
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(regionView)
    }

    private static func screen(for displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return CGDirectDisplayID(number.uint32Value) == displayID
        }
    }
}
