import AppKit
import MacshotCore

@MainActor
final class RecordingHUDWindowController: NSWindowController {
    private let stopButton = NSButton(title: "Stop", target: nil, action: nil)
    private let timerLabel = NSTextField(labelWithString: "0.0s")
    private let indicator = NSView()
    private var timer: Timer?
    private var startDate = Date()
    var onStop: (() -> Void)?

    init(selection: CaptureRect) {
        let hudSize = NSSize(width: 140, height: 44)
        let origin = CGPoint(
            x: selection.globalRect.midX - hudSize.width / 2,
            y: selection.globalRect.maxY + 12
        )
        let window = KeyableWindow(
            contentRect: CGRect(origin: origin, size: hudSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        super.init(window: window)
        setupContent()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }

    func dismiss() {
        timer?.invalidate()
        timer = nil
        close()
    }

    private func setupContent() {
        guard let contentView = window?.contentView else { return }

        let panel = NSVisualEffectView(frame: contentView.bounds)
        panel.autoresizingMask = [.width, .height]
        panel.material = .hudWindow
        panel.state = .active
        panel.wantsLayer = true
        panel.layer?.cornerRadius = 10
        contentView.addSubview(panel)

        indicator.frame = CGRect(x: 12, y: 16, width: 12, height: 12)
        indicator.wantsLayer = true
        indicator.layer?.backgroundColor = NSColor.systemRed.cgColor
        indicator.layer?.cornerRadius = 6
        panel.addSubview(indicator)

        timerLabel.frame = CGRect(x: 32, y: 12, width: 48, height: 20)
        timerLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        timerLabel.textColor = .labelColor
        panel.addSubview(timerLabel)

        stopButton.frame = CGRect(x: 84, y: 8, width: 48, height: 28)
        stopButton.bezelStyle = .rounded
        stopButton.target = self
        stopButton.action = #selector(stopPressed)
        panel.addSubview(stopButton)
    }

    private func updateTimer() {
        let elapsed = Date().timeIntervalSince(startDate)
        timerLabel.stringValue = String(format: "%.1fs", elapsed)
    }

    @objc private func stopPressed() {
        onStop?()
    }
}
