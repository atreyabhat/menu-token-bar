// Generates ccbar's app icon: a white starburst on a clay-orange rounded square.
// Drawn from scratch (not Anthropic's asset) so the icon is reproducible from
// source. Usage: swift tools/genicon.swift <output.iconset dir>
import AppKit

let clay = NSColor(srgbRed: 0.76, green: 0.36, blue: 0.22, alpha: 1)
let spokeCount = 12

func drawIcon(px: Int) -> Data {
    let size = CGFloat(px)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    // Rounded-square background (macOS squircle proportions).
    let margin = size * 0.085
    let rect = NSRect(x: margin, y: margin, width: size - 2 * margin, height: size - 2 * margin)
    let side = rect.width
    let radius = side * 0.2237
    let bg = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    clay.setFill()
    bg.fill()

    // Starburst: `spokeCount` blade spokes — thin at the centre, widening to
    // `halfWidth` at `wideFrac` out, tapering to sharp tips. Matches MenuGlyph.
    let center = NSPoint(x: rect.midX, y: rect.midY)
    let outer = side * 0.36
    let halfWidth = side * 0.061
    let wideFrac: CGFloat = 0.42
    NSColor.white.setFill()
    for i in 0..<spokeCount {
        let a = CGFloat(i) * (.pi * 2 / CGFloat(spokeCount))
        let dir = NSPoint(x: cos(a), y: sin(a))
        let perp = NSPoint(x: -sin(a), y: cos(a))
        let tip = NSPoint(x: center.x + dir.x * outer, y: center.y + dir.y * outer)
        let wide = NSPoint(x: center.x + dir.x * outer * wideFrac, y: center.y + dir.y * outer * wideFrac)
        let left = NSPoint(x: wide.x + perp.x * halfWidth, y: wide.y + perp.y * halfWidth)
        let right = NSPoint(x: wide.x - perp.x * halfWidth, y: wide.y - perp.y * halfWidth)
        let spoke = NSBezierPath()
        spoke.move(to: center)
        spoke.line(to: left)
        spoke.line(to: tip)
        spoke.line(to: right)
        spoke.close()
        spoke.fill()
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write("usage: genicon.swift <output.iconset>\n".data(using: .utf8)!)
    exit(1)
}
let outDir = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// (pixel size, iconset filenames)
let targets: [(Int, [String])] = [
    (16,   ["icon_16x16.png"]),
    (32,   ["icon_16x16@2x.png", "icon_32x32.png"]),
    (64,   ["icon_32x32@2x.png"]),
    (128,  ["icon_128x128.png"]),
    (256,  ["icon_128x128@2x.png", "icon_256x256.png"]),
    (512,  ["icon_256x256@2x.png", "icon_512x512.png"]),
    (1024, ["icon_512x512@2x.png"]),
]

for (px, names) in targets {
    let data = drawIcon(px: px)
    for name in names {
        let path = (outDir as NSString).appendingPathComponent(name)
        try! data.write(to: URL(fileURLWithPath: path))
    }
}
print("wrote \(targets.reduce(0) { $0 + $1.1.count }) png(s) to \(outDir)")
