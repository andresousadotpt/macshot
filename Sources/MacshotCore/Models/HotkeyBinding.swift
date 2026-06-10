import Foundation

public struct HotkeyBinding: Codable, Sendable, Equatable, Hashable {
    public var keyCode: UInt16
    public var modifiers: UInt32

    public init(keyCode: UInt16, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// ⌘⇧4 — replaces the system region screenshot shortcut while Macshot is running.
    public static let defaultScreenshot = HotkeyBinding(keyCode: 21, modifiers: 256 | 512)

    /// ⌘⇧3 — replaces the system full-screen screenshot shortcut while Macshot is running.
    public static let defaultGIF = HotkeyBinding(keyCode: 20, modifiers: 256 | 512)

    public var isValid: Bool {
        keyCode != 0 && modifiers != 0
    }

    public func matches(keyCode: UInt16, modifiers: UInt32) -> Bool {
        self.keyCode == keyCode && self.modifiers == modifiers
    }

    public func displayString(keyLabels: [UInt16: String] = HotkeyBinding.defaultKeyLabels) -> String {
        var parts: [String] = []
        if modifiers & 4096 != 0 { parts.append("⌃") }
        if modifiers & 256 != 0 { parts.append("⌘") }
        if modifiers & 512 != 0 { parts.append("⇧") }
        if modifiers & 2048 != 0 { parts.append("⌥") }
        parts.append(keyLabels[keyCode] ?? "Key \(keyCode)")
        return parts.joined()
    }

    public static let defaultKeyLabels: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
        20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
        29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
        39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".",
        49: "Space", 36: "Return", 48: "Tab", 51: "Delete", 53: "Esc",
        123: "←", 124: "→", 125: "↓", 126: "↑",
    ]
}
