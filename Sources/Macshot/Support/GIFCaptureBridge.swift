import AppKit
import CoreGraphics
import CoreMedia
import CoreVideo
import Foundation
import MacshotCore
import ScreenCaptureKit

@MainActor
final class GIFCaptureBridge: NSObject, SCStreamOutput {
    private var stream: SCStream?
    private let queue = DispatchQueue(label: "com.macshot.gif-capture", qos: .userInitiated)
    private let delivery = FrameDelivery()

    func start(
        selection: CaptureRect,
        fps: Int,
        onFrame: @escaping @Sendable (CGImage) -> Void
    ) async throws {
        delivery.stopping = false
        delivery.handler = onFrame

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == selection.displayID }) else {
            throw GIFCaptureError.displayNotFound
        }

        guard let screen = NSScreen.screens.first(where: { screen in
            guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            return CGDirectDisplayID(number.uint32Value) == selection.displayID
        }) else {
            throw GIFCaptureError.displayNotFound
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.queueDepth = 6
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = true
        configuration.scalesToFit = false
        configuration.colorSpaceName = CGColorSpace.sRGB

        let sourceRect = Self.sourceRect(for: selection, screen: screen)
        let scale = screen.backingScaleFactor
        configuration.sourceRect = sourceRect
        configuration.width = max(1, Int(sourceRect.width * scale))
        configuration.height = max(1, Int(sourceRect.height * scale))
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(max(1, fps)))

        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
        try await stream.startCapture()
        self.stream = stream
    }

    func stop() async {
        delivery.stopping = true
        if let stream {
            try? await stream.stopCapture()
        }
        stream = nil
        try? await Task.sleep(for: .milliseconds(200))
        delivery.handler = nil
        delivery.stopping = false
    }

    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let cgImage = PixelBufferConverter.cgImage(from: imageBuffer) else { return }
        delivery.deliver(cgImage)
    }

    /// Converts a Cocoa bottom-left global selection rect to ScreenCaptureKit's top-left display-relative rect.
    static func sourceRect(for selection: CaptureRect, screen: NSScreen) -> CGRect {
        let screenFrame = screen.frame
        let localX = selection.globalRect.origin.x - screenFrame.origin.x
        let localBottomY = selection.globalRect.origin.y - screenFrame.origin.y
        let sourceY = screenFrame.height - localBottomY - selection.globalRect.height
        return CGRect(
            x: localX,
            y: sourceY,
            width: selection.globalRect.width,
            height: selection.globalRect.height
        )
    }
}

private final class FrameDelivery: @unchecked Sendable {
    var handler: (@Sendable (CGImage) -> Void)?
    var stopping = false

    func deliver(_ image: CGImage) {
        guard !stopping, let handler else { return }
        handler(image)
    }
}

enum GIFCaptureError: LocalizedError {
    case displayNotFound

    var errorDescription: String? {
        switch self {
        case .displayNotFound:
            return "Could not find the selected display for recording."
        }
    }
}
