import CoreGraphics
import Foundation

public struct DisplayInfo: Sendable {
    public let displayID: CGDirectDisplayID
    public let screenFrame: CGRect
    public let scaleFactor: CGFloat

    public init(displayID: CGDirectDisplayID, screenFrame: CGRect, scaleFactor: CGFloat) {
        self.displayID = displayID
        self.screenFrame = screenFrame
        self.scaleFactor = scaleFactor
    }
}

public enum DisplaySnapshotService {
    public static func captureAll(displays: [DisplayInfo]) -> [DisplaySnapshot] {
        displays.compactMap { capture(display: $0) }
    }

    public static func capture(display: DisplayInfo) -> DisplaySnapshot? {
        guard let image = CGDisplayCreateImage(display.displayID) else {
            return nil
        }
        return DisplaySnapshot(
            displayID: display.displayID,
            screenFrame: display.screenFrame,
            scaleFactor: display.scaleFactor,
            image: image
        )
    }

    public static func snapshot(
        for selection: CaptureRect,
        in snapshots: [DisplaySnapshot]
    ) -> DisplaySnapshot? {
        snapshots.first { $0.displayID == selection.displayID }
    }
}
