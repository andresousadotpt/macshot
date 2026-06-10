import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum GIFEncoder {
    public static func encode(frames: [CGImage], fps: Int, loopCount: Int = 0) -> Data? {
        guard !frames.isEmpty, fps > 0 else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else {
            return nil
        }

        let frameDelay = 1.0 / Double(fps)
        let loopProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: loopCount,
            ],
        ]
        CGImageDestinationSetProperties(destination, loopProperties as CFDictionary)

        let frameProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay,
                kCGImagePropertyGIFUnclampedDelayTime: frameDelay,
            ],
        ]

        for frame in frames {
            CGImageDestinationAddImage(destination, frame, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }
}
