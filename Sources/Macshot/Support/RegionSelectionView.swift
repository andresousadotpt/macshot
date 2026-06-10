import AppKit
import MacshotCore

final class RegionSelectionView: NSView {
    var snapshot: DisplaySnapshot?
    var dimOpacity: CGFloat = 0.35
    var onComplete: ((CaptureRect) -> Void)?
    var onCancel: (() -> Void)?

    private var anchorPoint: CGPoint?
    private var currentPoint: CGPoint?
    private var trackingArea: NSTrackingArea?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        updateTrackingAreas()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .enabledDuringMouseDrag, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let snapshot, let context = NSGraphicsContext.current?.cgContext else { return }

        context.draw(snapshot.image, in: bounds)

        context.setFillColor(NSColor.black.withAlphaComponent(dimOpacity).cgColor)

        if let selection = currentSelectionRect() {
            context.addRect(bounds)
            context.addRect(selection)
            context.fillPath(using: .evenOdd)

            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(1)
            context.stroke(selection)

            let label = "\(Int(selection.width)) × \(Int(selection.height))"
            drawSizeLabel(label, near: selection)
        } else {
            context.fill(bounds)
        }
    }

    override func mouseDown(with event: NSEvent) {
        anchorPoint = convert(event.locationInWindow, from: nil)
        currentPoint = anchorPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        guard let snapshot, let selection = currentSelectionRect(), selection.width >= 1, selection.height >= 1 else {
            onCancel?()
            return
        }

        let globalRect = CGRect(
            x: selection.origin.x + snapshot.screenFrame.origin.x,
            y: selection.origin.y + snapshot.screenFrame.origin.y,
            width: selection.width,
            height: selection.height
        )
        let capture = CaptureRect(
            globalRect: globalRect,
            displayID: snapshot.displayID,
            scaleFactor: snapshot.scaleFactor
        )
        onComplete?(capture)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelSelection()
            return
        }
        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        cancelSelection()
    }

    private func cancelSelection() {
        anchorPoint = nil
        currentPoint = nil
        onCancel?()
    }

    private func currentSelectionRect() -> CGRect? {
        guard let anchorPoint, let currentPoint else { return nil }
        return CaptureRect.rectFromPoints(anchorPoint, currentPoint)
    }

    private func drawSizeLabel(_ text: String, near rect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let padding: CGFloat = 6
        let labelOrigin = CGPoint(
            x: rect.minX,
            y: min(rect.maxY + 8, bounds.maxY - size.height - padding)
        )
        let background = CGRect(
            x: labelOrigin.x - padding,
            y: labelOrigin.y - padding / 2,
            width: size.width + padding * 2,
            height: size.height + padding
        )
        NSColor.black.withAlphaComponent(0.7).setFill()
        NSBezierPath(roundedRect: background, xRadius: 4, yRadius: 4).fill()
        (text as NSString).draw(at: labelOrigin, withAttributes: attributes)
    }
}
