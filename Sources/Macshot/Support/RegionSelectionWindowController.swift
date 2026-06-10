import AppKit
import MacshotCore

final class RegionSelectionWindowController: NSWindowController {
    private let selectionView = RegionSelectionView()

    init(snapshot: DisplaySnapshot, dimOpacity: CGFloat) {
        let window = KeyableWindow(
            contentRect: snapshot.screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: NSScreen.screens.first { screen in
                guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                    return false
                }
                return CGDirectDisplayID(number.uint32Value) == snapshot.displayID
            }
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        super.init(window: window)

        selectionView.snapshot = snapshot
        selectionView.dimOpacity = dimOpacity
        window.contentView = selectionView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(
        onComplete: @escaping (CaptureRect) -> Void,
        onCancel: @escaping () -> Void
    ) {
        selectionView.onComplete = onComplete
        selectionView.onCancel = onCancel
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(selectionView)
    }
}
