// Composes App Store screenshots from raw simulator captures, driven by a JSON spec.
//
//   swift compose.swift <spec.json> [slug-or-raw ...]      compose all frames, or only the named ones
//   swift compose.swift <spec.json> --sheet <out-dir>      write sheet.png (all frames) and thumbs.png (first three)
//
// Paths in the spec are relative to the current directory. Layout is designed in a
// 1320 x 2868 canvas and scaled uniformly to every size in `sizes`.
// Output: sRGB, 8-bit RGB, no alpha, ready for App Store Connect.
import AppKit
import CoreText
import ImageIO
import UniformTypeIdentifiers

// MARK: Spec

struct Spec: Decodable {
    var raw = "docs/app-store/screenshots/raw"
    var out = "docs/app-store/screenshots/en-US"
    var sizes: [String: [Int]] = ["6.9": [1320, 2868], "6.3": [1206, 2622]]
    var theme = Theme()
    let frames: [Frame]

    enum CodingKeys: String, CodingKey { case raw, out, sizes, theme, frames }
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        raw = try c.decodeIfPresent(String.self, forKey: .raw) ?? raw
        out = try c.decodeIfPresent(String.self, forKey: .out) ?? out
        sizes = try c.decodeIfPresent([String: [Int]].self, forKey: .sizes) ?? sizes
        theme = try c.decodeIfPresent(Theme.self, forKey: .theme) ?? theme
        frames = try c.decode([Frame].self, forKey: .frames)
    }
}

struct Theme: Decodable {
    /// "serif" (New York), "sans" (SF), "rounded", or a PostScript font name.
    var headlineFont = "serif"
    var headlineSize: Double = 128
    var light = Colors(canvas: "#F4F5F3", ink: "#17181A", secondary: "#5C5E62")
    var dark = Colors(canvas: "#0E0E0D", ink: "#F4F4F1", secondary: "#A5A6A2")

    enum CodingKeys: String, CodingKey { case headlineFont, headlineSize, light, dark }
    init() {}
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        headlineFont = try c.decodeIfPresent(String.self, forKey: .headlineFont) ?? headlineFont
        headlineSize = try c.decodeIfPresent(Double.self, forKey: .headlineSize) ?? headlineSize
        light = try c.decodeIfPresent(Colors.self, forKey: .light) ?? light
        dark = try c.decodeIfPresent(Colors.self, forKey: .dark) ?? dark
    }
}

struct Colors: Decodable { let canvas: String, ink: String, secondary: String }

struct Cover: Decodable { let rect: [Double]; let color: String }

struct Frame: Decodable {
    let slug: String
    /// Capture file name in `raw`, without `.png`.
    let raw: String
    let headline: String
    let subhead: String
    var footnote: String?
    /// Dark canvas and device; use with a dark-mode capture.
    var dark: Bool?
    /// Hex background; ink switches to light or dark by its luminance.
    var background: String?
    /// Raw-pixel rect [x, y, w, h] (top-left origin) drawn again, enlarged, over the device.
    var breakout: [Double]?
    var breakoutWidth: Double?
    /// Canvas y of the breakout's top; default centres it on its place on the screen.
    var breakoutTop: Double?
    /// Raw-pixel rect filled with a flat colour before the breakout is drawn.
    var cover: Cover?
    /// Default 1092 (bleeds off the bottom). About 960 shows the whole screen.
    var deviceWidth: Double?
    /// Canvas y of the device top; default sits 70 under the text, no higher than 760.
    var deviceTop: Double?
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("compose: \(message)\n".utf8))
    exit(1)
}

func rect(_ a: [Double], _ name: String) -> CGRect {
    guard a.count == 4 else { fail("\(name) must be [x, y, width, height]") }
    return CGRect(x: a[0], y: a[1], width: a[2], height: a[3])
}

func hex(_ s: String) -> CGColor {
    let digits = s.hasPrefix("#") ? String(s.dropFirst()) : s
    guard digits.count == 6, let v = UInt32(digits, radix: 16) else { fail("bad colour \(s)") }
    return CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                   blue: CGFloat(v & 0xFF) / 255, alpha: 1)
}

func luminance(_ c: CGColor) -> CGFloat {
    let p = c.components ?? [0, 0, 0]
    return 0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2]
}

// MARK: Type

func headlineFont(_ name: String, _ size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .semibold)
    switch name {
    case "sans": return base
    case "serif", "rounded":
        let design: NSFontDescriptor.SystemDesign = name == "serif" ? .serif : .rounded
        return NSFont(descriptor: base.fontDescriptor.withDesign(design) ?? base.fontDescriptor, size: size) ?? base
    default:
        guard let font = NSFont(name: name, size: size) else { fail("font not found: \(name)") }
        return font
    }
}

func attributed(_ text: String, font: NSFont, color: CGColor, lineHeight: CGFloat, kern: CGFloat = 0) -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.minimumLineHeight = lineHeight
    paragraph.maximumLineHeight = lineHeight
    return NSAttributedString(string: text, attributes: [
        .font: font, .foregroundColor: NSColor(cgColor: color)!, .paragraphStyle: paragraph, .kern: kern,
    ])
}

/// Draws centred text with its top at `top` (top-left coordinates); returns its height.
func draw(_ text: NSAttributedString, in context: CGContext, top: CGFloat, canvasHeight: CGFloat) -> CGFloat {
    let width: CGFloat = 1180
    let setter = CTFramesetterCreateWithAttributedString(text)
    let size = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(), nil, CGSize(width: width, height: .greatestFiniteMagnitude), nil)
    let r = CGRect(x: (canvas.width - width) / 2, y: canvasHeight - top - size.height, width: width, height: ceil(size.height))
    CTFrameDraw(CTFramesetterCreateFrame(setter, CFRange(), CGPath(rect: r, transform: nil), nil), context)
    return size.height
}

// MARK: Compose (1320 x 2868 points; other sizes scale uniformly)

let canvas = CGSize(width: 1320, height: 2868)
let defaultDeviceWidth: CGFloat = 1092
let bezel: CGFloat = 26

func loadImage(_ path: String) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fail("cannot read \(path)") }
    return image
}

func makeContext(_ size: CGSize) -> CGContext {
    CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
}

func compose(_ frame: Frame, theme: Theme, raw: CGImage, size: CGSize) -> CGImage {
    let dark = frame.dark ?? false
    let base = dark ? theme.dark : theme.light
    let canvasColor = frame.background.map(hex) ?? hex(base.canvas)
    let onDark = luminance(canvasColor) < 0.5
    let ink = frame.background == nil ? hex(base.ink) : (onDark ? hex("#F4F4F1") : hex(theme.light.ink))
    let secondary = frame.background == nil ? hex(base.secondary)
        : (onDark ? CGColor(srgbRed: 0.957, green: 0.957, blue: 0.945, alpha: 0.82) : hex(theme.light.secondary))
    let bezelColor = dark ? hex("#2A2B2D") : hex("#17181A")
    let rimColor = dark ? hex("#55575A") : hex("#3A3B3E")

    let context = makeContext(size)
    context.interpolationQuality = .high
    context.setFillColor(canvasColor)
    context.fill(CGRect(origin: .zero, size: size))
    let scale = size.width / canvas.width
    let height = size.height / scale
    context.scaleBy(x: scale, y: scale)

    // Caption.
    let hs = CGFloat(theme.headlineSize)
    var top: CGFloat = 150
    top += draw(attributed(frame.headline, font: headlineFont(theme.headlineFont, hs), color: ink, lineHeight: hs * 1.08, kern: -1.4),
                in: context, top: top, canvasHeight: height)
    top += 34
    top += draw(attributed(frame.subhead, font: NSFont.systemFont(ofSize: 56), color: secondary, lineHeight: 70),
                in: context, top: top, canvasHeight: height)
    if let footnote = frame.footnote {
        top += 22
        top += draw(attributed(footnote, font: NSFont.systemFont(ofSize: 40, weight: .medium), color: secondary, lineHeight: 50),
                    in: context, top: top, canvasHeight: height)
    }

    // Device: a drawn bezel around the capture.
    let deviceTop = frame.deviceTop.map { max(top + 50, CGFloat($0)) } ?? max(top + 70, 760)
    let deviceWidth = frame.deviceWidth.map { CGFloat($0) } ?? defaultDeviceWidth
    let corner = 150 * deviceWidth / defaultDeviceWidth
    let screenWidth = deviceWidth - bezel * 2
    let screenHeight = screenWidth * CGFloat(raw.height) / CGFloat(raw.width)
    let deviceRect = CGRect(x: (canvas.width - deviceWidth) / 2, y: height - deviceTop - (screenHeight + bezel * 2),
                            width: deviceWidth, height: screenHeight + bezel * 2)
    let screenRect = deviceRect.insetBy(dx: bezel, dy: bezel)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -30), blur: 90, color: CGColor(gray: 0, alpha: dark ? 0.6 : 0.20))
    context.addPath(CGPath(roundedRect: deviceRect, cornerWidth: corner + bezel, cornerHeight: corner + bezel, transform: nil))
    context.setFillColor(bezelColor)
    context.fillPath()
    context.restoreGState()
    context.addPath(CGPath(roundedRect: deviceRect.insetBy(dx: 2, dy: 2), cornerWidth: corner + bezel - 2, cornerHeight: corner + bezel - 2, transform: nil))
    context.setStrokeColor(rimColor)
    context.setLineWidth(4)
    context.strokePath()

    context.saveGState()
    context.addPath(CGPath(roundedRect: screenRect, cornerWidth: corner, cornerHeight: corner, transform: nil))
    context.clip()
    context.draw(raw, in: screenRect)
    let rawScale = screenRect.width / CGFloat(raw.width)
    func onScreen(_ r: CGRect) -> CGRect {
        CGRect(x: screenRect.minX + r.minX * rawScale, y: screenRect.maxY - r.maxY * rawScale,
               width: r.width * rawScale, height: r.height * rawScale)
    }
    let cover = frame.cover.map { (rect: rect($0.rect, "\(frame.slug).cover.rect"), color: hex($0.color)) }
    if let cover {
        context.setFillColor(cover.color)
        context.fill(onScreen(cover.rect))
    }
    context.restoreGState()

    // Breakout: the same pixels, enlarged and floating over the device.
    if let b = frame.breakout {
        let region = rect(b, "\(frame.slug).breakout")
        guard let crop = raw.cropping(to: region) else { fail("\(frame.slug): breakout is outside the capture") }
        let w = CGFloat(frame.breakoutWidth ?? 1220)
        let h = w * region.height / region.width
        let topY = frame.breakoutTop.map { height - CGFloat($0) } ?? (onScreen(region).midY + h / 2)
        let r = CGRect(x: (canvas.width - w) / 2, y: topY - h, width: w, height: h)
        let path = CGPath(roundedRect: r, cornerWidth: 44, cornerHeight: 44, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -24), blur: 70, color: CGColor(gray: 0, alpha: dark ? 0.7 : 0.18))
        context.addPath(path)
        context.setFillColor(dark ? hex(theme.dark.canvas) : hex("#FFFFFF"))
        context.fillPath()
        context.restoreGState()
        context.saveGState()
        context.addPath(path)
        context.clip()
        if let cover, cover.rect.intersects(region) {
            context.setFillColor(cover.color)
            context.fill(r)
        }
        context.draw(crop, in: r)
        context.restoreGState()
    }
    return context.makeImage()!
}

func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fail("cannot write \(path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fail("cannot write \(path)") }
}

/// Lays `images` out in a row at `cell` size with a 10-point gutter.
func strip(_ images: [CGImage], cell: CGSize, background: CGFloat) -> CGImage {
    let n = CGFloat(images.count)
    let context = makeContext(CGSize(width: cell.width * n + 10 * (n + 1), height: cell.height + 20))
    context.interpolationQuality = .high
    context.setFillColor(CGColor(gray: background, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: context.width, height: context.height))
    for (i, image) in images.enumerated() {
        context.draw(image, in: CGRect(x: 10 + CGFloat(i) * (cell.width + 10), y: 10, width: cell.width, height: cell.height))
    }
    return context.makeImage()!
}

// MARK: Main

var args = Array(CommandLine.arguments.dropFirst())
guard !args.isEmpty else { fail("usage: compose.swift <spec.json> [slug ...] | --sheet <dir>") }
let specPath = args.removeFirst()
let spec: Spec
do { spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: URL(fileURLWithPath: specPath))) }
catch { fail("\(specPath): \(error)") }
guard let hero = spec.sizes.max(by: { $0.value[0] < $1.value[0] }) else { fail("no sizes") }
let slugs = Set(spec.frames.map(\.slug))
guard slugs.count == spec.frames.count else { fail("duplicate frame slugs") }

if args.first == "--sheet" {
    guard args.count == 2 else { fail("usage: --sheet <dir>") }
    let images = spec.frames.map { loadImage("\(spec.out)/\(hero.key)/\($0.slug).png") }
    writePNG(strip(images, cell: CGSize(width: 600, height: 1304), background: 1), to: "\(args[1])/sheet.png")
    // App Store search results show the first three frames at roughly this size.
    writePNG(strip(Array(images.prefix(3)), cell: CGSize(width: 170, height: 370), background: 0.78), to: "\(args[1])/thumbs.png")
    print("\(args[1])/sheet.png\n\(args[1])/thumbs.png")
    exit(0)
}

let requested = Set(args)
for frame in spec.frames where requested.isEmpty || requested.contains(frame.slug) || requested.contains(frame.raw) {
    let raw = loadImage("\(spec.raw)/\(frame.raw).png")
    for (folder, wh) in spec.sizes.sorted(by: { $0.key > $1.key }) {
        guard wh.count == 2 else { fail("size \(folder) must be [width, height]") }
        let path = "\(spec.out)/\(folder)/\(frame.slug).png"
        writePNG(compose(frame, theme: spec.theme, raw: raw, size: CGSize(width: wh[0], height: wh[1])), to: path)
        print(path)
    }
}
