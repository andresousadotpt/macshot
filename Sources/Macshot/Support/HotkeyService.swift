import AppKit
import ApplicationServices
import Carbon
import CoreGraphics
import Foundation
import MacshotCore

enum HotkeyAction: Sendable {
    case screenshot
    case gif
}

/// Intercepts global key events via a CGEvent tap so Macshot can replace system screenshot shortcuts.
final class HotkeyService: NSObject, @unchecked Sendable {
    private let onAction: (HotkeyAction) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapThread: Thread?
    private var tapRunLoop: CFRunLoop?
    private var screenshotBinding = HotkeyBinding.defaultScreenshot
    private var gifBinding = HotkeyBinding.defaultGIF
    private let bindingLock = NSLock()
    private var isStopping = false

    init(onAction: @escaping (HotkeyAction) -> Void) {
        self.onAction = onAction
    }

    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    static func promptForAccessibility() {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }

    func register(screenshot: HotkeyBinding, gif: HotkeyBinding) {
        bindingLock.lock()
        screenshotBinding = screenshot
        gifBinding = gif
        bindingLock.unlock()

        unregister()
        guard Self.isAccessibilityGranted else { return }
        startEventTap()
    }

    func unregister() {
        isStopping = true

        if let loop = tapRunLoop {
            CFRunLoopPerformBlock(loop, CFRunLoopMode.defaultMode.rawValue) {
                CFRunLoopStop(loop)
            }
            CFRunLoopWakeUp(loop)
        }

        if let thread = tapThread {
            while thread.isExecuting {
                Thread.sleep(forTimeInterval: 0.005)
            }
        }

        tapThread = nil
        tapRunLoop = nil
        eventTap = nil
        runLoopSource = nil
        isStopping = false
    }

    private func startEventTap() {
        isStopping = false
        let thread = Thread { [weak self] in
            self?.runTapLoop()
        }
        thread.name = "MacshotHotkeyTap"
        tapThread = thread
        thread.start()
    }

    private func runTapLoop() {
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: HotkeyService.eventCallback,
            userInfo: userInfo
        ) else {
            return
        }

        eventTap = tap

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            return
        }
        runLoopSource = source

        let runLoop = CFRunLoopGetCurrent()
        tapRunLoop = runLoop
        CFRunLoopAddSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        CFRunLoopRun()
        CFRunLoopRemoveSource(runLoop, source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: false)
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let service = Unmanaged<HotkeyService>.fromOpaque(userInfo).takeUnretainedValue()
        return service.handleEvent(type: type, event: event)
    }

    nonisolated private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = Self.carbonModifiers(from: event.flags)

        bindingLock.lock()
        let screenshot = screenshotBinding
        let gif = gifBinding
        bindingLock.unlock()

        if screenshot.matches(keyCode: keyCode, modifiers: modifiers) {
            DispatchQueue.main.async { [weak self] in
                self?.onAction(.screenshot)
            }
            return nil
        }

        if gif.matches(keyCode: keyCode, modifiers: modifiers) {
            DispatchQueue.main.async { [weak self] in
                self?.onAction(.gif)
            }
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private static func carbonModifiers(from flags: CGEventFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.maskControl) { mods |= UInt32(controlKey) }
        if flags.contains(.maskAlternate) { mods |= UInt32(optionKey) }
        if flags.contains(.maskShift) { mods |= UInt32(shiftKey) }
        if flags.contains(.maskCommand) { mods |= UInt32(cmdKey) }
        return mods
    }

    deinit {
        unregister()
    }
}
