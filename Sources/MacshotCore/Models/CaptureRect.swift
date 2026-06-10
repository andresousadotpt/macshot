import CoreGraphics
import Foundation

public struct CaptureRect: Sendable, Equatable {
    public let globalRect: CGRect
    public let displayID: CGDirectDisplayID
    public let scaleFactor: CGFloat

    public init(globalRect: CGRect, displayID: CGDirectDisplayID, scaleFactor: CGFloat) {
        self.globalRect = globalRect
        self.displayID = displayID
        self.scaleFactor = scaleFactor
    }

    public var pixelRect: CGRect {
        CGRect(
            x: globalRect.origin.x * scaleFactor,
            y: globalRect.origin.y * scaleFactor,
            width: globalRect.width * scaleFactor,
            height: globalRect.height * scaleFactor
        )
    }

    public var isValid: Bool {
        globalRect.width >= 1 && globalRect.height >= 1
    }

    /// Converts a point in global screen coordinates (origin bottom-left) to
    /// view-local coordinates for an overlay covering `screenFrame`.
    public static func globalToLocal(point: CGPoint, screenFrame: CGRect) -> CGPoint {
        CGPoint(
            x: point.x - screenFrame.origin.x,
            y: point.y - screenFrame.origin.y
        )
    }

    /// Converts view-local coordinates back to global screen coordinates.
    public static func localToGlobal(point: CGPoint, screenFrame: CGRect) -> CGPoint {
        CGPoint(
            x: point.x + screenFrame.origin.x,
            y: point.y + screenFrame.origin.y
        )
    }

    /// Normalizes two corner points into a CGRect with positive width/height.
    public static func rectFromPoints(_ a: CGPoint, _ b: CGPoint) -> CGRect {
        CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(a.x - b.x),
            height: abs(a.y - b.y)
        )
    }
}
