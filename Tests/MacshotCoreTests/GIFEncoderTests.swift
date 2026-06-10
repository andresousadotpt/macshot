import CoreGraphics
import ImageIO
import XCTest
@testable import MacshotCore

final class GIFEncoderTests: XCTestCase {
    func testEncodeProducesValidGIFData() {
        let frames = [
            makeSolidImage(width: 4, height: 4, red: 1, green: 0, blue: 0),
            makeSolidImage(width: 4, height: 4, red: 0, green: 1, blue: 0),
            makeSolidImage(width: 4, height: 4, red: 0, green: 0, blue: 1),
        ]
        let data = GIFEncoder.encode(frames: frames, fps: 10)
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 100)

        let source = CGImageSourceCreateWithData(data! as CFData, nil)
        XCTAssertNotNil(source)
        XCTAssertEqual(CGImageSourceGetCount(source!), 3)
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
