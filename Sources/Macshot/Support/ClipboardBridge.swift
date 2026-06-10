import AppKit
import UniformTypeIdentifiers

enum ClipboardBridge {
    private static let gifFilenamePrefix = "macshot-"

    static func copyPNG(_ data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
    }

    /// Copies an animated GIF by placing a temp file URL on the pasteboard.
    /// Raw GIF bytes cause macOS to attach a PNG/TIFF preview that apps paste instead.
    static func copyGIF(_ data: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let url = temporaryGIFURL()
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return
        }

        cleanupOldGIFTempFiles()
        pasteboard.writeObjects([url as NSURL])
    }

    private static func temporaryGIFURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(gifFilenamePrefix)\(UUID().uuidString).gif")
    }

    private static func cleanupOldGIFTempFiles() {
        let directory = FileManager.default.temporaryDirectory
        let cutoff = Date().addingTimeInterval(-3600)
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for file in files where file.lastPathComponent.hasPrefix(gifFilenamePrefix) {
            guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modified = values.contentModificationDate,
                  modified < cutoff else {
                continue
            }
            try? FileManager.default.removeItem(at: file)
        }
    }
}
