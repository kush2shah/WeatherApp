import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let S = 1024.0

struct Beam { let r: Double; let g: Double; let b: Double; let yc: Double; let amp: Double; let phase: Double; let slope: Double }

// Same beams (and order) as the approved icon: blue, red, green, orange, purple
let beams: [Beam] = [
    Beam(r: 0.20, g: 0.55, b: 1.00, yc: 0.78, amp: 0.16, phase: 0.4,  slope:  0.26), // 0 blue  - Apple
    Beam(r: 1.00, g: 0.27, b: 0.30, yc: 0.60, amp: 0.20, phase: 2.1,  slope: -0.18), // 1 red   - Google
    Beam(r: 0.20, g: 0.85, b: 0.45, yc: 0.46, amp: 0.17, phase: 3.6,  slope:  0.16), // 2 green - NOAA
    Beam(r: 1.00, g: 0.62, b: 0.15, yc: 0.32, amp: 0.19, phase: 1.2,  slope: -0.24), // 3 orange- OWM
    Beam(r: 0.70, g: 0.40, b: 1.00, yc: 0.18, amp: 0.22, phase: 5.0,  slope:  0.20), // 4 purple- Tomorrow.io
]

func curvePath(_ b: Beam, size: Double) -> CGPath {
    let p = CGMutablePath()
    let steps = 256
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let x = t * size
        let wave = sin(t * Double.pi * 2.0 * 0.62 + b.phase)
        let y = (b.yc + b.amp * wave + b.slope * (t - 0.5)) * size
        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
        else { p.addLine(to: CGPoint(x: x, y: y)) }
    }
    return p
}

func makeContext(size: Double) -> CGContext {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    return CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8,
                     bytesPerRow: 0, space: cs,
                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func writePNG(_ ctx: CGContext, to path: String) {
    let img = ctx.makeImage()!
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

// Draw the given subset of beam indices onto a transparent canvas
func drawLayer(indices: [Int], to path: String) {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = makeContext(size: S)        // fully transparent to start
    ctx.setLineCap(.round)
    for i in indices {
        let b = beams[i]
        ctx.saveGState()
        ctx.addPath(curvePath(b, size: S))
        ctx.setStrokeColor(CGColor(colorSpace: cs, components: [b.r, b.g, b.b, 1.0])!)
        ctx.setLineWidth(S * 0.105)
        ctx.strokePath()
        ctx.restoreGState()
    }
    writePNG(ctx, to: path)
}

let outDir = CommandLine.arguments[1]

// Opaque white-gradient background (bottom-most layer)
do {
    let ctx = makeContext(size: S)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let colors = [CGColor(colorSpace: cs, components: [1.0, 1.0, 1.0, 1])!,
                  CGColor(colorSpace: cs, components: [0.95, 0.96, 0.98, 1])!] as CFArray
    let grad = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: 0, y: 0), options: [])
    writePNG(ctx, to: "\(outDir)/0-Background.png")
}

// Foreground bar layers, back -> front (preserves the approved composite)
drawLayer(indices: [0, 1], to: "\(outDir)/1-Bars-Back.png")   // blue + red
drawLayer(indices: [2, 3], to: "\(outDir)/2-Bars-Mid.png")    // green + orange
drawLayer(indices: [4],    to: "\(outDir)/3-Bars-Front.png")  // purple

print("done")
