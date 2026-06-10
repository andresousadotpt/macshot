import CoreGraphics
import XCTest
@testable import MacshotCore

final class ImageCropperTests: XCTestCase {
    func testCropExtractsSubregion() {
        let image = makeSolidImage(width: 100, height: 100, red: 1, green: 0, blue: 0)
        let cropped = ImageCropper.crop(image: image, to: CGRect(x: 10, y: 20, width: 30, height: 40))
        XCTAssertNotNil(cropped)
        XCTAssertEqual(cropped?.width, 30)
        XCTAssertEqual(cropped?.height, 40)
    }

    func testCropSnapshotUsesGlobalSelection() {
        let image = makeSolidImage(width: 200, height: 200, red: 0, green: 0, blue: 1)
        let snapshot = DisplaySnapshot(
            displayID: 1,
            screenFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
            scaleFactor: 1,
            image: image
        )
        let selection = CaptureRect(
            globalRect: CGRect(x: 25, y: 30, width: 50, height: 60),
            displayID: 1,
            scaleFactor: 1
        )
        let cropped = ImageCropper.crop(snapshot: snapshot, selection: selection)
        XCTAssertEqual(cropped?.width, 50)
        XCTAssertEqual(cropped?.height, 60)
    }

    private func makeSolidImage(width: Int, height: Int, red: CGFloat, green: CGFloat, blue: CGFloat) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }
}
