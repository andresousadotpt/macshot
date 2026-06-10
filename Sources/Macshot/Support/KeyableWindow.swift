import AppKit

/// Borderless capture overlays must be key windows to receive keyboard events.
final class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
