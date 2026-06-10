import AppKit
import CoreGraphics
import MacshotCore

enum DisplayCaptureBridge {
    static func allDisplayInfos() -> [DisplayInfo] {
        NSScreen.screens.compactMap { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            return DisplayInfo(
                displayID: CGDirectDisplayID(screenNumber.uint32Value),
                screenFrame: screen.frame,
                scaleFactor: screen.backingScaleFactor
            )
        }
    }

    static func captureAllDisplays() -> [DisplaySnapshot] {
        DisplaySnapshotService.captureAll(displays: allDisplayInfos())
    }
}
