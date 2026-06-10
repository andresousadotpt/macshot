import AppKit

@MainActor
enum CrosshairCursor {
    private static var pushed = false

    static func push() {
        guard !pushed else { return }
        NSCursor.crosshair.push()
        pushed = true
    }

    static func pop() {
        guard pushed else { return }
        NSCursor.pop()
        pushed = false
    }
}
