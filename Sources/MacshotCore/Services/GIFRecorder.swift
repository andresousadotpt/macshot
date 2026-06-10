import CoreGraphics
import Foundation

public actor GIFRecorder {
    private var frames: [CGImage] = []
    private var maxFrames: Int = 0
    private var isRecording = false
    private var lastFrameTime: CFAbsoluteTime = 0
    private var frameInterval: TimeInterval = 1.0 / 15.0

    public init() {}

    public func start(maxDuration: TimeInterval, fps: Int) {
        frames = []
        maxFrames = max(1, Int(maxDuration * Double(fps)))
        frameInterval = 1.0 / Double(max(1, fps))
        lastFrameTime = 0
        isRecording = true
    }

    public func appendFrame(_ image: CGImage) -> Bool {
        guard isRecording else { return false }

        let now = CFAbsoluteTimeGetCurrent()
        if lastFrameTime > 0, now - lastFrameTime < frameInterval {
            return true
        }
        lastFrameTime = now

        frames.append(image)
        if frames.count >= maxFrames {
            isRecording = false
            return false
        }
        return true
    }

    public func stop(fps: Int) -> Data? {
        isRecording = false
        let captured = frames
        frames = []
        guard !captured.isEmpty else { return nil }
        return GIFEncoder.encode(frames: captured, fps: fps)
    }

    public func cancel() {
        isRecording = false
        frames = []
        lastFrameTime = 0
    }

    public var frameCount: Int {
        frames.count
    }

    public var recording: Bool {
        isRecording
    }
}
