import XCTest
@testable import MacshotCore

final class HotkeyBindingTests: XCTestCase {
    func testDefaultGIFIsCommandShift3() {
        XCTAssertEqual(HotkeyBinding.defaultGIF.keyCode, 20)
        XCTAssertEqual(HotkeyBinding.defaultGIF.modifiers, 256 | 512)
        XCTAssertEqual(HotkeyBinding.defaultGIF.displayString(), "⌘⇧3")
    }

    func testDefaultScreenshotIsCommandShift4() {
        XCTAssertEqual(HotkeyBinding.defaultScreenshot.keyCode, 21)
        XCTAssertEqual(HotkeyBinding.defaultScreenshot.modifiers, 256 | 512)
        XCTAssertEqual(HotkeyBinding.defaultScreenshot.displayString(), "⌘⇧4")
    }

    func testMatchesComparesKeyCodeAndModifiers() {
        let binding = HotkeyBinding.defaultGIF
        XCTAssertTrue(binding.matches(keyCode: 20, modifiers: 256 | 512))
        XCTAssertFalse(binding.matches(keyCode: 21, modifiers: 256 | 512))
        XCTAssertFalse(binding.matches(keyCode: 20, modifiers: 256))
    }

    func testDisplayStringFormatsModifiers() {
        let binding = HotkeyBinding(keyCode: 49, modifiers: 256 | 2048)
        XCTAssertEqual(binding.displayString(), "⌘⌥Space")
    }

    func testAppSettingsDefaultsIncludeHotkeys() {
        let settings = AppSettings.default
        XCTAssertEqual(settings.gifHotkey, .defaultGIF)
        XCTAssertEqual(settings.screenshotHotkey, .defaultScreenshot)
        XCTAssertFalse(settings.hotkeysConflict)
    }
}
