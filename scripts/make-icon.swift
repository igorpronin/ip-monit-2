// Рисует мастер-PNG иконки 1024×1024. Использование: swift make-icon.swift <out.png>
import AppKit

let size = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Сквиркл с полями по гайдлайнам macOS (иконка занимает ~82% холста)
let inset: CGFloat = 100
let rect = NSRect(x: inset, y: inset, width: CGFloat(size) - 2 * inset, height: CGFloat(size) - 2 * inset)
let squircle = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)

let gradient = NSGradient(
    starting: NSColor(calibratedRed: 0.04, green: 0.15, blue: 0.29, alpha: 1),
    ending: NSColor(calibratedRed: 0.10, green: 0.45, blue: 0.68, alpha: 1)
)!
gradient.draw(in: squircle, angle: 90)

// Глобус
let globe = "🌍" as NSString
let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 520)]
let gsize = globe.size(withAttributes: attrs)
globe.draw(
    at: NSPoint(x: (CGFloat(size) - gsize.width) / 2, y: (CGFloat(size) - gsize.height) / 2 + 20),
    withAttributes: attrs
)

// Зелёный индикатор "онлайн" с белой окантовкой
NSColor.white.setFill()
NSBezierPath(ovalIn: NSRect(x: 648, y: 216, width: 150, height: 150)).fill()
NSColor.systemGreen.setFill()
NSBezierPath(ovalIn: NSRect(x: 662, y: 230, width: 122, height: 122)).fill()

NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("written:", CommandLine.arguments[1])
