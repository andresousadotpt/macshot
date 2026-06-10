import CoreGraphics
import CoreImage
import CoreVideo

enum PixelBufferConverter {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func cgImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}
