import AppKit

@MainActor
enum SelectionCursor {
    private static let arm: CGFloat = 8
    private static let lineWidth: CGFloat = 2
    private static var active = false

    static func begin() {
        guard !active else { return }
        NSCursor.hide()
        active = true
    }

    static func end() {
        guard active else { return }
        NSCursor.unhide()
        NSCursor.arrow.set()
        active = false
    }

    static func draw(at point: CGPoint, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(lineWidth)
        context.setLineCap(.butt)

        context.beginPath()
        context.move(to: CGPoint(x: point.x - arm, y: point.y))
        context.addLine(to: CGPoint(x: point.x + arm, y: point.y))
        context.move(to: CGPoint(x: point.x, y: point.y - arm))
        context.addLine(to: CGPoint(x: point.x, y: point.y + arm))
        context.strokePath()

        context.restoreGState()
    }
}
