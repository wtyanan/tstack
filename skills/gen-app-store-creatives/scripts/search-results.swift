// App Store search results video: renders the frames of one loop at 3840 x 2560.
// A fixed headline on the left; a drawn phone on the right whose screen moves
// through real app captures. Unique frames are rendered once and repeated frames
// are hard links, so the folder stays small.
//
// Usage (from the repo root):
//   swiftc -O <skill>/scripts/search-results.swift -o /tmp/search-results
//   /tmp/search-results docs/app-store/search-results/search-results.json
// Then encode with <skill>/scripts/header.swift using the same spec.
import AppKit
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Spec: Decodable {
    var frames: String
    var width: Int
    var height: Int
    var fps: Int
    var grounds: [String]   // one pigment per screen; wipes right to left with the push
    var feather: CGFloat
    var ink: String
    var headline: String
    var headlineSize: CGFloat
    var subhead: String
    var subheadSize: CGFloat
    var textLeft: CGFloat
    var textTop: CGFloat
    var textWidth: CGFloat
    var deviceLeft: CGFloat
    var deviceTop: CGFloat
    var deviceWidth: CGFloat
    var screens: [String]
    var hold: Double        // seconds each screen is fully shown
    var fade: Double        // seconds of the push into the next screen
}

let spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
let W = CGFloat(spec.width), H = CGFloat(spec.height)

func color(_ c: [CGFloat]) -> CGColor { CGColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: 1) }
func hex(_ s: String, _ a: CGFloat = 1) -> CGColor {
    let v = UInt32(s.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
    return CGColor(srgbRed: CGFloat(v >> 16 & 0xFF) / 255, green: CGFloat(v >> 8 & 0xFF) / 255,
                   blue: CGFloat(v & 0xFF) / 255, alpha: a)
}
func load(_ path: String) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("can't read \(path)") }
    return img
}
let screens = spec.screens.map(load)

func paragraph(_ text: String, _ font: NSFont, _ color: CGColor, lineHeight: CGFloat, kern: CGFloat) -> NSAttributedString {
    let p = NSMutableParagraphStyle()
    p.minimumLineHeight = lineHeight; p.maximumLineHeight = lineHeight
    return NSAttributedString(string: text, attributes: [
        .font: font, .foregroundColor: NSColor(cgColor: color)!, .paragraphStyle: p, .kern: kern])
}
/// Draws left-aligned text with its top at `top` (top-left coordinates); returns its height.
func drawText(_ s: NSAttributedString, _ ctx: CGContext, left: CGFloat, top: CGFloat, width: CGFloat) -> CGFloat {
    let setter = CTFramesetterCreateWithAttributedString(s)
    let size = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(), nil,
        CGSize(width: width, height: .greatestFiniteMagnitude), nil)
    let r = CGRect(x: left, y: H - top - ceil(size.height), width: width, height: ceil(size.height))
    CTFrameDraw(CTFramesetterCreateFrame(setter, CFRange(), CGPath(rect: r, transform: nil), nil), ctx)
    return ceil(size.height)
}

let serif: NSFont = {
    let base = NSFont.systemFont(ofSize: spec.headlineSize, weight: .semibold)
    return NSFont(descriptor: base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor, size: spec.headlineSize) ?? base
}()

// Device geometry, scaled from compose.swift (1092 px wide device, 26 px bezel, 150 px corner).
let k = spec.deviceWidth / 1092
let bezel = 26 * k, corner = 150 * k
let screenW = spec.deviceWidth - bezel * 2
let screenH = screenW * CGFloat(screens[0].height) / CGFloat(screens[0].width)
let device = CGRect(x: spec.deviceLeft, y: H - spec.deviceTop - (screenH + bezel * 2),
                    width: spec.deviceWidth, height: screenH + bezel * 2)
let screenRect = device.insetBy(dx: bezel, dy: bezel)

/// The still part of every frame: ground, text and the empty device.
func components(_ s: String) -> [CGFloat] { hex(s).components! }
let grounds = spec.grounds.map(components)
func smooth(_ x: CGFloat) -> CGFloat { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }

func base(_ a: Int, _ b: Int, _ p: CGFloat) -> CGContext {
    let ctx = CGContext(data: nil, width: spec.width, height: spec.height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.setFillColor(color(grounds[a])); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    if p > 0 {
        // A soft edge travels from right to left; flat column fills avoid 8-bit gradient banding.
        let f = spec.feather, edge = W + f / 2 - p * (W + f)
        let ga = grounds[a], gb = grounds[b]
        for x in 0..<spec.width {
            let c = smooth((CGFloat(x) - edge) / f + 0.5); guard c > 0 else { continue }
            ctx.setFillColor(CGColor(srgbRed: ga[0] + (gb[0] - ga[0]) * c, green: ga[1] + (gb[1] - ga[1]) * c,
                                     blue: ga[2] + (gb[2] - ga[2]) * c, alpha: 1))
            ctx.fill(CGRect(x: CGFloat(x), y: 0, width: 1, height: H))
        }
    }
    var top = spec.textTop
    let hs = spec.headlineSize
    top += drawText(paragraph(spec.headline, serif, hex(spec.ink), lineHeight: hs * 1.08, kern: -hs * 0.011),
                    ctx, left: spec.textLeft, top: top, width: spec.textWidth)
    top += spec.subheadSize * 0.9
    _ = drawText(paragraph(spec.subhead, NSFont.systemFont(ofSize: spec.subheadSize), hex(spec.ink, 0.82),
                           lineHeight: spec.subheadSize * 1.25, kern: 0),
                 ctx, left: spec.textLeft, top: top, width: spec.textWidth)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -40 * k), blur: 120 * k, color: CGColor(gray: 0, alpha: 0.45))
    ctx.addPath(CGPath(roundedRect: device, cornerWidth: corner + bezel, cornerHeight: corner + bezel, transform: nil))
    ctx.setFillColor(hex("#17181A")); ctx.fillPath()
    ctx.restoreGState()
    ctx.addPath(CGPath(roundedRect: device.insetBy(dx: 2 * k, dy: 2 * k), cornerWidth: corner + bezel - 2 * k,
                       cornerHeight: corner + bezel - 2 * k, transform: nil))
    ctx.setStrokeColor(hex("#3A3B3E")); ctx.setLineWidth(4 * k); ctx.strokePath()
    return ctx
}

func frame(_ a: Int, _ b: Int, mix: CGFloat) -> CGImage {
    let ctx = base(a, b, mix)
    ctx.addPath(CGPath(roundedRect: screenRect, cornerWidth: corner, cornerHeight: corner, transform: nil))
    ctx.clip()
    // A push, like iOS navigation: the next screen slides in over the old one,
    // which moves left at 0.3 of the speed.
    ctx.draw(screens[a], in: screenRect.offsetBy(dx: -0.3 * screenRect.width * mix, dy: 0))
    if mix > 0 { ctx.draw(screens[b], in: screenRect.offsetBy(dx: screenRect.width * (1 - mix), dy: 0)) }
    return ctx.makeImage()!
}

func write(_ img: CGImage, _ path: String) {
    let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(d, img, nil)
    guard CGImageDestinationFinalize(d) else { fatalError("can't write \(path)") }
}

let fm = FileManager.default
try? fm.removeItem(atPath: spec.frames)
try fm.createDirectory(atPath: spec.frames, withIntermediateDirectories: true)
let fps = Double(spec.fps)
let slot = spec.hold + spec.fade
let total = Int((slot * Double(screens.count) * fps).rounded())
var holdFrame: [Int: String] = [:]
for f in 0..<total {
    let t = Double(f) / fps
    let i = Int(t / slot) % screens.count, local = t - Double(i) * slot
    let path = String(format: "%@/%05d.png", spec.frames, f)
    if local < spec.hold {
        if let first = holdFrame[i] { try fm.linkItem(atPath: first, toPath: path); continue }
        write(frame(i, i, mix: 0), path); holdFrame[i] = path
    } else {
        let p = (local - spec.hold) / spec.fade
        write(frame(i, (i + 1) % screens.count, mix: CGFloat(p * p * (3 - 2 * p))), path)
    }
}
print("\(total) frames, \(Double(total) / fps) s, device \(device.integral), screen top \(Int(spec.deviceTop + bezel))")
