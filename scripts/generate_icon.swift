#!/usr/bin/env swift
// generate_icon.swift — Programmatically generate the Desk Plate app icon
// Usage: swift generate_icon.swift [output_dir]
//   Produces DeskPlate.icns in output_dir (default: ../build)

import Cocoa

let outputDir: String
if CommandLine.arguments.count > 1 {
    outputDir = CommandLine.arguments[1]
} else {
    let scriptDir = (CommandLine.arguments[0] as NSString).deletingLastPathComponent
    outputDir = (scriptDir as NSString).appendingPathComponent("../build")
}

// MARK: - Drawing

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = size / 1024.0

    // Background: rounded-rect app icon shape
    let outerRect = CGRect(x: 0, y: 0, width: size, height: size)
    let outerRadius = 224 * scale  // standard macOS icon corner radius at 1024
    let outerPath = CGPath(roundedRect: outerRect.insetBy(dx: 20 * scale, dy: 20 * scale),
                           cornerWidth: outerRadius, cornerHeight: outerRadius, transform: nil)

    // Clip to icon shape
    ctx.saveGState()
    ctx.addPath(outerPath)
    ctx.clip()

    // Background gradient (deep blue to indigo)
    let bgColors = [
        CGColor(red: 0.15, green: 0.20, blue: 0.50, alpha: 1.0),
        CGColor(red: 0.30, green: 0.15, blue: 0.55, alpha: 1.0),
    ]
    let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: bgColors as CFArray, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: size, y: 0),
                           options: [])

    // --- Desktop rectangles (two offset rounded rects) ---

    // Back desktop (offset up-left from front)
    let backRect = CGRect(x: 157 * scale, y: 382 * scale, width: 560 * scale, height: 380 * scale)
    let deskRadius = 28 * scale
    let backPath = CGPath(roundedRect: backRect, cornerWidth: deskRadius, cornerHeight: deskRadius, transform: nil)
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15))
    ctx.addPath(backPath)
    ctx.fillPath()
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25))
    ctx.setLineWidth(3 * scale)
    ctx.addPath(backPath)
    ctx.strokePath()

    // Front desktop (main, offset down-right from back)
    let frontRect = CGRect(x: 307 * scale, y: 262 * scale, width: 560 * scale, height: 380 * scale)
    let frontPath = CGPath(roundedRect: frontRect, cornerWidth: deskRadius, cornerHeight: deskRadius, transform: nil)

    // Subtle gradient fill for front desktop
    ctx.saveGState()
    ctx.addPath(frontPath)
    ctx.clip()
    let deskColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25),
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15),
    ]
    let deskGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: deskColors as CFArray, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(deskGradient,
                           start: CGPoint(x: frontRect.minX, y: frontRect.maxY),
                           end: CGPoint(x: frontRect.maxX, y: frontRect.minY),
                           options: [])
    ctx.restoreGState()

    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4))
    ctx.setLineWidth(3 * scale)
    ctx.addPath(frontPath)
    ctx.strokePath()

    // --- Label badge (capsule with "1") in bottom-right of front desktop ---

    let badgeWidth = 130 * scale
    let badgeHeight = 56 * scale
    let badgeX = frontRect.maxX - badgeWidth - 24 * scale
    let badgeY = frontRect.minY + 24 * scale
    let badgeRect = CGRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight)
    let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: badgeHeight / 2, cornerHeight: badgeHeight / 2, transform: nil)

    // White capsule background with slight transparency
    ctx.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.92))
    ctx.addPath(badgePath)
    ctx.fillPath()

    // Draw "1" text in the badge
    let fontSize = 32 * scale
    let font = CTFontCreateWithName("SFProRounded-Semibold" as CFString, fontSize, nil)
    // Fallback if SF Pro Rounded not available
    let actualFont: CTFont
    if CTFontCopyFamilyName(font) as String == ".AppleSystemUIFont" ||
       CTFontCopyFamilyName(font) as String != "SF Pro Rounded" {
        actualFont = CTFontCreateWithName(".AppleSystemUIFontRounded-Semibold" as CFString, fontSize, nil)
    } else {
        actualFont = font
    }

    let attrs: [NSAttributedString.Key: Any] = [
        .font: actualFont,
        .foregroundColor: NSColor(red: 0.18, green: 0.15, blue: 0.40, alpha: 1.0),
    ]
    let str = NSAttributedString(string: "1", attributes: attrs)
    let line = CTLineCreateWithAttributedString(str)
    let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

    let textX = badgeRect.midX - textBounds.width / 2 - textBounds.origin.x
    let textY = badgeRect.midY - textBounds.height / 2 - textBounds.origin.y
    ctx.textPosition = CGPoint(x: textX, y: textY)
    CTLineDraw(line, ctx)

    ctx.restoreGState()  // restore outer clip

    image.unlockFocus()
    return image
}

// MARK: - Export

func pngData(from image: NSImage, pixelSize: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                pixelsWide: pixelSize, pixelsHigh: pixelSize,
                                bitsPerSample: 8, samplesPerPixel: 4,
                                hasAlpha: true, isPlanar: false,
                                colorSpaceName: .deviceRGB,
                                bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])!
}

// iconutil requires specific filenames:
//   icon_<size>x<size>.png        (1x)
//   icon_<size>x<size>@2x.png     (2x, pixel size = size*2)
let iconSizes: [(pointSize: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

let fm = FileManager.default

// Create output dir if needed
try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let iconsetPath = (outputDir as NSString).appendingPathComponent("DeskPlate.iconset")
let icnsPath = (outputDir as NSString).appendingPathComponent("DeskPlate.icns")

// Remove old iconset if present
if fm.fileExists(atPath: iconsetPath) {
    try fm.removeItem(atPath: iconsetPath)
}
try fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Draw master icon at 1024
let masterIcon = drawIcon(size: 1024)

print("Generating icon PNGs...")
for entry in iconSizes {
    let pixelSize = entry.pointSize * entry.scale
    let suffix = entry.scale == 2 ? "@2x" : ""
    let filename = "icon_\(entry.pointSize)x\(entry.pointSize)\(suffix).png"
    let filePath = (iconsetPath as NSString).appendingPathComponent(filename)

    let data = pngData(from: masterIcon, pixelSize: pixelSize)
    try data.write(to: URL(fileURLWithPath: filePath))
    print("  \(filename) (\(pixelSize)x\(pixelSize) px)")
}

// Run iconutil to produce .icns
print("Creating .icns...")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath, "-o", icnsPath]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fputs("iconutil failed with exit code \(process.terminationStatus)\n", stderr)
    exit(1)
}

// Clean up iconset
try fm.removeItem(atPath: iconsetPath)

print("✅ Icon generated: \(icnsPath)")
