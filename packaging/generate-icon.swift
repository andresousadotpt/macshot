import AppKit

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"

let size = NSSize(width: 512, height: 512)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let background = NSColor(calibratedRed: 0.12, green: 0.45, blue: 0.95, alpha: 1)
background.setFill()
NSBezierPath(roundedRect: rect, xRadius: 96, yRadius: 96).fill()

let symbolConfig = NSImage.SymbolConfiguration(pointSize: 220, weight: .semibold)
if let symbol = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: nil)?
    .withSymbolConfiguration(symbolConfig) {
    let symbolRect = NSRect(
        x: (size.width - 260) / 2,
        y: (size.height - 260) / 2,
        width: 260,
        height: 260
    )
    symbol.draw(in: symbolRect)
}

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to generate icon\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
