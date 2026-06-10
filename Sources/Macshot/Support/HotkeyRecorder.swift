import AppKit
import Carbon
import MacshotCore

@MainActor
final class HotkeyRecorder {
    static let shared = HotkeyRecorder()

    private var monitor: Any?
    private var onCapture: ((HotkeyBinding) -> Void)?
    private var onCancel: (() -> Void)?

    private init() {}

    func startRecording(
        onCapture: @escaping (HotkeyBinding) -> Void,
        onCancel: @escaping () -> Void
    ) {
        stopRecording()
        self.onCapture = onCapture
        self.onCancel = onCancel

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self else { return event }
            return self.handle(event: event)
        }
    }

    func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        onCapture = nil
        onCancel = nil
    }

    private func handle(event: NSEvent) -> NSEvent? {
        if event.type == .keyDown {
            if event.keyCode == 53 {
                onCancel?()
                stopRecording()
                return nil
            }

            let modifiers = Self.carbonModifiers(from: event.modifierFlags)
            guard modifiers != 0, !Self.isModifierOnlyKey(event.keyCode) else {
                return nil
            }

            let binding = HotkeyBinding(keyCode: UInt16(event.keyCode), modifiers: modifiers)
            onCapture?(binding)
            stopRecording()
            return nil
        }

        return nil
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        return mods
    }

    private static func isModifierOnlyKey(_ keyCode: UInt16) -> Bool {
        switch keyCode {
        case 54, 55, 56, 57, 58, 59, 60, 61:
            return true
        default:
            return false
        }
    }
}
