// Renders the Sidekey app icon ("Lit key"): a near-black plate with a 3 x 3 grid of graphite
// keycaps whose centre key glows amber, as if just pressed.
//
// Usage: swift tools/render_app_icon.swift <output.png>
// Output is a 1024 x 1024 opaque PNG (iOS applies the rounded mask itself).

import AppKit
import CoreGraphics

let size = 1024
let outputPath = CommandLine.arguments.dropFirst().first ?? "AppIcon-1024.png"

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else { fatalError("Could not create bitmap context") }

let full = CGRect(x: 0, y: 0, width: size, height: size)

// Plate: graphite with a faint top-down falloff.
let plate = CGGradient(colorsSpace: space, colors: [rgb(0x1A1D24), rgb(0x0B0C10)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(plate, start: CGPoint(x: 0, y: CGFloat(size)), end: .zero, options: [])

// 3 x 3 keycap grid.
let grid: CGFloat = 640
let gap: CGFloat = 44
let cap = (grid - gap * 2) / 3
let origin = (CGFloat(size) - grid) / 2
let radius = cap * 0.2

func capRect(_ row: Int, _ column: Int) -> CGRect {
    CGRect(x: origin + CGFloat(column) * (cap + gap), y: origin + CGFloat(row) * (cap + gap), width: cap, height: cap)
}

// Amber bloom spilling from the lit centre key onto its neighbours.
let centre = capRect(1, 1)
let bloom = CGGradient(colorsSpace: space, colors: [rgb(0xFF9A10, 0.55), rgb(0xFF7A00, 0.0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(bloom, startCenter: CGPoint(x: centre.midX, y: centre.midY), startRadius: cap * 0.2,
                       endCenter: CGPoint(x: centre.midX, y: centre.midY), endRadius: cap * 2.1, options: [])

for row in 0..<3 {
    for column in 0..<3 {
        let rect = capRect(row, column)
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        let isLit = row == 1 && column == 1

        // Drop shadow under each cap.
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: rgb(0x000000, 0.6))
        ctx.addPath(path)
        ctx.setFillColor(isLit ? rgb(0xFF8A00) : rgb(0x1E2127))
        ctx.fillPath()
        ctx.restoreGState()

        // Cap face: lit amber or graphite, lighter at the top edge.
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let face = isLit
            ? CGGradient(colorsSpace: space, colors: [rgb(0xFFC34D), rgb(0xFF8A00)] as CFArray, locations: [0, 1])!
            : CGGradient(colorsSpace: space, colors: [rgb(0x2B2F37), rgb(0x1B1E24)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(face, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
        ctx.restoreGState()

        // Hairline highlight along the cap edge.
        ctx.saveGState()
        ctx.addPath(path)
        ctx.setStrokeColor(isLit ? rgb(0xFFE0A0, 0.55) : rgb(0xFFFFFF, 0.08))
        ctx.setLineWidth(3)
        ctx.strokePath()
        ctx.restoreGState()
    }
}

guard let image = ctx.makeImage() else { fatalError("Could not render icon") }
let rep = NSBitmapImageRep(cgImage: image)
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("Could not encode PNG") }
try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath) (\(size)x\(size))")
