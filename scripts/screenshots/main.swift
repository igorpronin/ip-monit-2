// Renders README screenshots offscreen with fake data (no real IP involved).
// Built by scripts/make-screenshots.sh together with the app sources.
import AppKit
import SwiftUI

MainActor.assumeIsolated {
    _ = NSApplication.shared
    let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs"
    try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    L10n.shared.lang = "en"

    @MainActor func renderPanel(v4: StackResult?, v6: StackResult?, offline: Bool, out: String) {
        let monitor = IPMonitor()
        monitor.v4 = v4
        monitor.v6 = v6
        monitor.offline = offline

        let host = NSHostingView(rootView: ContentView(monitor: monitor))
        let size = host.fittingSize
        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: host.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()

        let scale: CGFloat = 2
        let panelRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        panelRep.size = size
        host.cacheDisplay(in: host.bounds, to: panelRep)
        let panelImage = NSImage(size: size)
        panelImage.addRepresentation(panelRep)

        // Композиция на градиентном "обое", чтобы была видна полупрозрачность
        let pad: CGFloat = 22
        let bgSize = NSSize(width: size.width + pad * 2, height: size.height + pad * 2)
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(bgSize.width * scale), pixelsHigh: Int(bgSize.height * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        rep.size = bgSize

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSGradient(
            starting: NSColor(calibratedRed: 0.35, green: 0.42, blue: 0.78, alpha: 1),
            ending: NSColor(calibratedRed: 0.20, green: 0.60, blue: 0.65, alpha: 1)
        )!.draw(in: NSRect(origin: .zero, size: bgSize), angle: 35)
        panelImage.draw(in: NSRect(x: pad, y: pad, width: size.width, height: size.height))
        NSGraphicsContext.restoreGraphicsState()

        let png = rep.representation(using: .png, properties: [:])!
        try! png.write(to: URL(fileURLWithPath: "\(outDir)/\(out)"))
        print("written: \(outDir)/\(out)")
    }

    // Документационные адреса (RFC 5737 / RFC 3849) — не настоящие IP
    let v4 = StackResult(ip: "203.0.113.42", countryCode: "NL")
    let v6 = StackResult(ip: "2001:db8:85a3::8a2e:370:7334", countryCode: "NL")
    let v6leak = StackResult(ip: "2001:db8:85a3::8a2e:370:7334", countryCode: "DE")

    renderPanel(v4: v4, v6: v6, offline: false, out: "screenshot-normal.png")
    renderPanel(v4: v4, v6: v6leak, offline: false, out: "screenshot-mismatch.png")
    renderPanel(v4: nil, v6: nil, offline: true, out: "screenshot-offline.png")
}
