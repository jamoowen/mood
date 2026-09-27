import AppKit
import Foundation

func renderIcon(pixelSize: Int) -> Data {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixelSize, pixelsHigh: pixelSize,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
        fatalError("could not create bitmap")
    }
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let s = CGFloat(pixelSize)
    let inset = s * 0.16
    let rounded = CGRect(x: 0, y: 0, width: s, height: s).insetBy(dx: inset, dy: inset)
    let radius = s * 0.22
    let path = NSBezierPath(roundedRect: rounded, xRadius: radius, yRadius: radius)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.49, green: 0.40, blue: 0.96, alpha: 1.0),
        NSColor(calibratedRed: 0.30, green: 0.62, blue: 0.90, alpha: 1.0)
    ])!
    gradient.draw(in: path, angle: -60)

    let mark = NSBezierPath()
    mark.lineWidth = s * 0.13
    mark.lineCapStyle = .round
    mark.lineJoinStyle = .round
    mark.move(to: NSPoint(x: s * 0.34, y: s * 0.50))
    mark.line(to: NSPoint(x: s * 0.46, y: s * 0.63))
    mark.line(to: NSPoint(x: s * 0.68, y: s * 0.37))
    NSColor.white.setStroke()
    mark.stroke()

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("could not encode png")
    }
    return png
}

func main() {
    let args = CommandLine.arguments
    let output = args.count > 1 ? args[1] : "AppIcon.icns"
    let iconset = FileManager.default.temporaryDirectory
        .appendingPathComponent("mood.iconset", isDirectory: true)

    try? FileManager.default.removeItem(at: iconset)
    try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

    let entries: [(String, Int)] = [
        ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
    ]
    for (name, size) in entries {
        let data = renderIcon(pixelSize: size)
        try! data.write(to: iconset.appendingPathComponent(name))
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconset.path, "-o", output]
    try! process.run()
    process.waitUntilExit()

    if process.terminationStatus == 0 {
        print("Wrote \(output)")
    } else {
        print("iconutil failed")
        exit(1)
    }
}

main()
