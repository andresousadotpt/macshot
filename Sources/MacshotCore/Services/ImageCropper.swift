import CoreGraphics
import Foundation

public enum ImageCropper {
    public static func crop(image: CGImage, to pixelRect: CGRect) -> CGImage? {
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        let clamped = pixelRect.intersection(bounds)
        guard !clamped.isNull, clamped.width >= 1, clamped.height >= 1 else {
            return nil
        }
        return image.cropping(to: clamped)
    }

    /// Crops a display snapshot using a global selection rect in screen points.
    public static func crop(snapshot: DisplaySnapshot, selection: CaptureRect) -> CGImage? {
        let localRect = CGRect(
            x: selection.globalRect.origin.x - snapshot.screenFrame.origin.x,
            y: selection.globalRect.origin.y - snapshot.screenFrame.origin.y,
            width: selection.globalRect.width,
            height: selection.globalRect.height
        )
        // CGImage uses a top-left origin; Cocoa screen coordinates use bottom-left.
        let sourceY = snapshot.screenFrame.height - localRect.origin.y - localRect.height
        let pixelRect = CGRect(
            x: localRect.origin.x * snapshot.scaleFactor,
            y: sourceY * snapshot.scaleFactor,
            width: localRect.width * snapshot.scaleFactor,
            height: localRect.height * snapshot.scaleFactor
        )
        return crop(image: snapshot.image, to: pixelRect)
    }
}
