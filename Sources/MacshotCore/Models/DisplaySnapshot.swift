import CoreGraphics
import Foundation

public struct DisplaySnapshot: Sendable {
    public let displayID: CGDirectDisplayID
    public let screenFrame: CGRect
    public let scaleFactor: CGFloat
    public let image: CGImage

    public init(
        displayID: CGDirectDisplayID,
        screenFrame: CGRect,
        scaleFactor: CGFloat,
        image: CGImage
    ) {
        self.displayID = displayID
        self.screenFrame = screenFrame
        self.scaleFactor = scaleFactor
        self.image = image
    }
}
