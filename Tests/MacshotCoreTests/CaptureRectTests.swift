import CoreGraphics
import XCTest
@testable import MacshotCore

final class CaptureRectTests: XCTestCase {
    func testRectFromPointsNormalizesCorners() {
        let rect = CaptureRect.rectFromPoints(CGPoint(x: 10, y: 20), CGPoint(x: 30, y: 5))
        XCTAssertEqual(rect, CGRect(x: 10, y: 5, width: 20, height: 15))
    }

    func testGlobalLocalConversionRoundTrip() {
        let screenFrame = CGRect(x: 100, y: 200, width: 1440, height: 900)
        let global = CGPoint(x: 250, y: 450)
        let local = CaptureRect.globalToLocal(point: global, screenFrame: screenFrame)
        let roundTrip = CaptureRect.localToGlobal(point: local, screenFrame: screenFrame)
        XCTAssertEqual(roundTrip, global)
    }

    func testPixelRectScalesByFactor() {
        let capture = CaptureRect(
            globalRect: CGRect(x: 0, y: 0, width: 100, height: 50),
            displayID: 0,
            scaleFactor: 2
        )
        XCTAssertEqual(capture.pixelRect, CGRect(x: 0, y: 0, width: 200, height: 100))
    }
}
