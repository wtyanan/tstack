// App Store product page header video: the shared pipeline. It renders or takes
// the frames of one loop, encodes them for App Store Connect (16-bit in, dithered
// 8-bit BT.709 H.264 out, no doubled frame at the seam), writes the poster
// frame and a phone-crop review mock, and checks the outputs.
//
// Two sources of frames:
// - `frames`: a folder of numbered PNGs (8- or 16-bit) rendered by anything that
//   suits the app's concept: a mascot animation, a SwiftUI or Lottie scene, a
//   custom CoreGraphics script. Frame 0 is the poster.
// - The built-in "turn" scene: a fixed mark and wordmark over a ground that
//   turns, like a page, through a list of colours. One style among many; use it
//   only when it fits the concept.
//
// Usage (from the app repo root; compile once for speed):
//   swiftc -O <skill>/scripts/header.swift -o /tmp/header
//   /tmp/header <spec.json>            poster (+ phone mock if set) and video
//   /tmp/header <spec.json> --poster   poster and phone mock only
//   /tmp/header <spec.json> --check    validate the rendered video and poster
//
// See references/header.md for the spec fields and the review workflow.
import AppKit
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Spec: Decodable {
    struct Mark: Decodable {
        var image: String
        var crop: [CGFloat]?        // [x, y, w, h] in source pixels, top-left
        var height: CGFloat
        var top: CGFloat
    }
    struct Wordmark: Decodable {
        var text: String
        var font: String?           // serif, sans, rounded, or a PostScript name
        var weight: String?         // regular (default), medium, semibold, bold
        var size: CGFloat
        var color: String
        var baseline: CGFloat
    }
    var video: String
    var poster: String
    var phoneMock: String?
    var width: Int?                 // default 3840
    var height: Int?                // default 1646
    var safeArea: [CGFloat]?        // default [1097, 493, 1646, 661]
    var mark: Mark?
    var wordmark: Wordmark?
    struct Object: Decodable {
        var image: String           // transparent PNG (see cutout.swift)
        var box: [CGFloat]          // [x, y, w, h], top-left; fitted, bottom-centred
    }
    struct Page: Decodable {
        var color: String
        var objects: [Object]?
        var active: Int?            // index into labels.words to underline
    }
    struct Labels: Decodable {
        var words: [String]
        var centers: [CGFloat]
        var baseline: CGFloat
        var font: String?           // as wordmark.font; default sans
        var weight: String?
        var size: CGFloat
        var color: String
        var underline: [CGFloat]?   // [width, height, gap below baseline], default [72, 6, 16]
    }
    struct Shadow: Decodable {
        var opacity: CGFloat
        var blur: CGFloat
        var offset: [CGFloat]       // [x, y], positive y is down
    }
    var frames: String?             // folder of numbered PNGs; replaces the built-in scene
    var grounds: [String]?          // built-in turn scene: plain colour pages
    var pages: [Page]?              // built-in turn scene: pages with objects; replaces grounds
    var labels: Labels?             // a fixed row of words drawn above every page
    var grow: [CGFloat]?            // object scale over a page's slot, e.g. [0.86, 1]
    var shadow: Shadow?             // contact shadow under objects
    var fps: Int?                   // 30 (default) or 60
    var beat: Double?               // seconds per ground, default 7
    var turn: Double?               // seconds each turn takes, default 5
    var feather: CGFloat?           // soft-edge width in px, default 800
    var direction: String?          // "rtl" (default, a page turning) or "ltr"
    var ffmpeg: String?
}

let args = CommandLine.arguments
guard args.count > 1 else {
    fputs("usage: header <spec.json> [--poster | --check]\n", stderr); exit(2)
}
let spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: URL(fileURLWithPath: args[1])))
let W = spec.width ?? 3840, H = spec.height ?? 1646
let safeVals = spec.safeArea ?? [1097, 493, 1646, 661]
let safe = CGRect(x: safeVals[0], y: safeVals[1], width: safeVals[2], height: safeVals[3])
let fps = spec.fps ?? 30
let beat = spec.beat ?? 7, turn = min(spec.turn ?? 5, spec.beat ?? 7)
let feather = spec.feather ?? 800
let rtl = (spec.direction ?? "rtl") == "rtl"
let frameFiles: [String] = spec.frames.map { dir in
    ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? [])
        .filter { $0.lowercased().hasSuffix(".png") }.sorted().map { dir + "/" + $0 }
} ?? []
if spec.frames != nil, frameFiles.isEmpty { fatalError("no PNG frames in \(spec.frames!)") }
let pageColors = spec.pages?.map(\.color) ?? spec.grounds ?? []
if spec.frames == nil, pageColors.isEmpty { fatalError("set `frames`, `grounds` or `pages`") }
let duration = spec.frames != nil
    ? Double(frameFiles.count) / Double(fps)
    : beat * Double(max(1, pageColors.count))
let ffmpegPath = spec.ffmpeg ?? ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]
    .first { FileManager.default.isExecutableFile(atPath: $0) } ?? "ffmpeg"

func hex(_ s: String) -> [CGFloat] {
    let v = UInt32(s.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
    return [CGFloat(v >> 16 & 0xFF) / 255, CGFloat(v >> 8 & 0xFF) / 255, CGFloat(v & 0xFF) / 255]
}
func color(_ c: [CGFloat]) -> CGColor { CGColor(srgbRed: c[0], green: c[1], blue: c[2], alpha: 1) }
let grounds = pageColors.map(hex)

let markImage: CGImage? = spec.mark.map { m in
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: m.image) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("mark image missing: \(m.image)") }
    guard let c = m.crop else { return img }
    guard let cropped = img.cropping(to: CGRect(x: c[0], y: c[1], width: c[2], height: c[3])) else {
        fatalError("mark crop outside the image")
    }
    return cropped
}

func font(_ name: String, _ weightName: String?, _ size: CGFloat) -> CTFont {
    let weight: NSFont.Weight = ["medium": .medium, "semibold": .semibold, "bold": .bold][weightName ?? ""] ?? .regular
    switch name {
    case "serif", "rounded", "sans":
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        let design: NSFontDescriptor.SystemDesign = name == "rounded" ? .rounded : name == "sans" ? .default : .serif
        let desc = base.fontDescriptor.withDesign(design) ?? base.fontDescriptor
        return NSFont(descriptor: desc, size: size)! as CTFont
    default:
        guard let f = NSFont(name: name, size: size) else { fatalError("font not installed: \(name)") }
        return f as CTFont
    }
}
func font(_ w: Spec.Wordmark) -> CTFont { font(w.font ?? "serif", w.weight, w.size) }
let wordLine: CTLine? = spec.wordmark.map { w in
    CTLineCreateWithAttributedString(NSAttributedString(string: w.text, attributes: [
        .font: font(w), .foregroundColor: NSColor(cgColor: color(hex(w.color)))!]))
}

func ease(_ t: Double) -> Double { t * t * (3 - 2 * t) }

func loadImage(_ path: String) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("can't read \(path)") }
    return img
}
let pageObjects: [[(CGImage, CGRect)]] = (spec.pages ?? []).map { page in
    (page.objects ?? []).map { (loadImage($0.image), CGRect(x: $0.box[0], y: $0.box[1], width: $0.box[2], height: $0.box[3])) }
}
let hasObjects = pageObjects.contains { !$0.isEmpty }
let grow = spec.grow ?? [1, 1]
let labelLines: [CTLine] = spec.labels.map { l in
    let f = font(l.font ?? "sans", l.weight, l.size)
    return l.words.map { CTLineCreateWithAttributedString(NSAttributedString(string: $0, attributes: [
        .font: f, .foregroundColor: NSColor(cgColor: color(hex(l.color)))!])) }
} ?? []

/// Page `i`'s objects. Each fits its box, bottom-centred, and scales about that
/// contact point; `s` is the scale and `alpha(box)` its opacity.
func drawObjects(_ ctx: CGContext, _ i: Int, scale s: CGFloat, alpha: (CGRect) -> CGFloat = { _ in 1 }) {
    guard i < pageObjects.count else { return }
    for (img, box) in pageObjects[i] {
        let a = alpha(box)
        guard a > 0 else { continue }
        let fit = min(box.width / CGFloat(img.width), box.height / CGFloat(img.height)) * s
        let w = CGFloat(img.width) * fit, h = CGFloat(img.height) * fit
        ctx.saveGState()
        ctx.setAlpha(a)
        if let sh = spec.shadow {
            // Shadow offsets are in device space (y up), unaffected by the flip.
            ctx.setShadow(offset: CGSize(width: sh.offset[0], height: -sh.offset[1]), blur: sh.blur,
                          color: CGColor(gray: 0, alpha: sh.opacity))
        }
        ctx.translateBy(x: box.midX - w / 2, y: box.maxY); ctx.scaleBy(x: 1, y: -1)
        ctx.interpolationQuality = .high
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        ctx.restoreGState()
    }
}

/// Coverage of the incoming page per column (0 = old page, 1 = new), for a turn
/// at eased progress `p`.
func turnCoverage(_ p: CGFloat, _ px: Int) -> CGFloat {
    let travel = CGFloat(W) + feather
    let edge = rtl ? CGFloat(W) + feather / 2 - travel * p : -feather / 2 + travel * p
    let raw = (CGFloat(px) + 0.5 - (edge - feather / 2)) / feather
    return min(1, max(0, rtl ? raw : 1 - raw))
}

/// Pages with objects: the next page's colour turns in behind a 16-bit-smooth
/// soft edge. Objects never double-expose: as the edge reaches an object's
/// centre, the old one fades out, then the new one fades in.
func drawPages(_ ctx: CGContext, at t: Double) {
    let n = grounds.count
    let i = Int(t / beat) % n, local = t - Double(i) * beat
    let g0 = grow[0], g1 = grow.count > 1 ? grow[1] : grow[0]
    let scale = g0 + (g1 - g0) * CGFloat(local / beat)
    ctx.setFillColor(color(grounds[i]))
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    let hold = beat - turn
    guard n > 1, local > hold else { drawObjects(ctx, i, scale: scale); return }
    let p = CGFloat(ease((local - hold) / turn))
    // The colour edge, one column at a time (CGGradient and 16-bit clip masks
    // both lose precision; flat column fills keep it).
    let a = grounds[i], b = grounds[(i + 1) % n]
    for px in 0..<W {
        let f = turnCoverage(p, px)
        guard f > 0 else { continue }
        ctx.setFillColor(CGColor(srgbRed: a[0] + (b[0] - a[0]) * f, green: a[1] + (b[1] - a[1]) * f,
                                 blue: a[2] + (b[2] - a[2]) * f, alpha: 1))
        ctx.fill(CGRect(x: CGFloat(px), y: 0, width: 1, height: CGFloat(H)))
    }
    func cov(_ box: CGRect) -> CGFloat { turnCoverage(p, Int(box.midX)) }
    func smooth(_ x: CGFloat) -> CGFloat { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }
    drawObjects(ctx, i, scale: scale) { 1 - smooth(cov($0) / 0.45) }
    drawObjects(ctx, (i + 1) % n, scale: g0) { smooth((cov($0) - 0.55) / 0.45) }
}

/// The fixed row of words, and an underline under the active page's word that
/// cross-fades in place while the turn passes the centre.
func drawLabels(_ ctx: CGContext, at t: Double) {
    guard let l = spec.labels else { return }
    let u = l.underline ?? [72, 6, 16]
    ctx.saveGState()
    ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
    for (k, line) in labelLines.enumerated() {
        let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
        ctx.textPosition = CGPoint(x: l.centers[k] - width / 2, y: CGFloat(H) - l.baseline)
        CTLineDraw(line, ctx)
    }
    ctx.restoreGState()
    guard let pages = spec.pages else { return }
    let n = pages.count, i = Int(t / beat) % n, local = t - Double(i) * beat
    let mid = beat - turn / 2, fade = 0.2
    let into = min(1, max(0, (local - (mid - fade / 2)) / fade))
    let ink = hex(l.color)
    for (page, alpha) in [(pages[i], 1 - into), (pages[(i + 1) % n], into)] where alpha > 0 {
        guard let k = page.active else { continue }
        ctx.setFillColor(CGColor(srgbRed: ink[0], green: ink[1], blue: ink[2], alpha: CGFloat(alpha)))
        ctx.fill(CGRect(x: l.centers[k] - u[0] / 2, y: l.baseline + u[2], width: u[0], height: u[1]))
    }
}

/// The ground at time `t`: a hold, then the next colour sweeps in behind a soft
/// edge. A pure function of `t`, so the last frame flows into frame 0.
func drawGround(_ ctx: CGContext, at t: Double) {
    let i = Int(t / beat) % grounds.count
    let local = t - Double(i) * beat
    let a = grounds[i], b = grounds[(i + 1) % grounds.count]
    ctx.setFillColor(color(a))
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
    let hold = beat - turn
    guard grounds.count > 1, local > hold else { return }
    let p = CGFloat(ease((local - hold) / turn))
    // `f` is how far each column has turned to the new colour; the edge travels
    // from fully off one side to fully off the other.
    let travel = CGFloat(W) + feather
    let edge = rtl ? CGFloat(W) + feather / 2 - travel * p : -feather / 2 + travel * p
    // Whole pixel columns: the soft edge covers [lo, hi); the new colour fills the
    // side the edge has passed.
    let left = edge - feather / 2
    let lo = min(W, max(0, Int(left.rounded(.down)))), hi = min(W, max(0, Int((left + feather).rounded(.up))))
    ctx.setFillColor(color(b))
    ctx.fill(rtl ? CGRect(x: hi, y: 0, width: W - hi, height: H) : CGRect(x: 0, y: 0, width: lo, height: H))
    // CGGradient shades at 8 bits even in a 16-bit context and bands; flat
    // per-column fills keep full precision for the dithered encode.
    for px in lo..<max(lo, hi) {
        let raw = (CGFloat(px) + 0.5 - left) / feather      // 0 at the edge's left, 1 at its right
        let f = min(1, max(0, rtl ? raw : 1 - raw))
        ctx.setFillColor(color([a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f]))
        ctx.fill(CGRect(x: CGFloat(px), y: 0, width: 1, height: CGFloat(H)))
    }
}

/// Frame `n` of an externally rendered sequence, scaled to fill the canvas.
func drawFrameFile(_ ctx: CGContext, _ n: Int) {
    let path = frameFiles[n % frameFiles.count]
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("unreadable frame \(path)") }
    if img.width != W || img.height != H { fatalError("\(path) is \(img.width)x\(img.height), expected \(W)x\(H)") }
    ctx.saveGState()
    ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))   // flatten any alpha onto black
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: W, height: H))
    ctx.restoreGState()
}

/// One frame, top-left coordinates. In the turn scene the lockup never moves;
/// a mark or wordmark in the spec is also drawn over external frames.
func frame(_ ctx: CGContext, at t: Double) {
    if spec.frames != nil { drawFrameFile(ctx, Int((t * Double(fps)).rounded())) }
    else if hasObjects { drawPages(ctx, at: t) } else { drawGround(ctx, at: t) }
    drawLabels(ctx, at: t)
    if let m = spec.mark, let img = markImage {
        let h = m.height, w = h * CGFloat(img.width) / CGFloat(img.height)
        ctx.saveGState()
        ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
        ctx.interpolationQuality = .high
        ctx.draw(img, in: CGRect(x: CGFloat(W) / 2 - w / 2, y: CGFloat(H) - m.top - h, width: w, height: h))
        ctx.restoreGState()
    }
    if let w = spec.wordmark, let line = wordLine {
        let glyphs = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        ctx.saveGState()
        ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
        ctx.textPosition = CGPoint(x: CGFloat(W) / 2 - glyphs.midX, y: CGFloat(H) - w.baseline)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}

func makeContext(deep: Bool) -> CGContext {
    let info = deep
        ? CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        : CGImageAlphaInfo.noneSkipLast.rawValue
    let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: deep ? 16 : 8,
                        bytesPerRow: W * (deep ? 8 : 4),
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info)!
    ctx.translateBy(x: 0, y: CGFloat(H)); ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func writePNG(_ image: CGImage, _ path: String) {
    try? FileManager.default.createDirectory(at: URL(fileURLWithPath: path).deletingLastPathComponent(),
                                             withIntermediateDirectories: true)
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                               UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("could not write \(path)") }
}

/// Every frame of one loop, as 16-bit RGB into ffmpeg, which dithers to 8-bit
/// BT.709 H.264. Frame N (= frame 0) is not written, so the loop has no doubled frame.
func renderVideo() {
    try? FileManager.default.createDirectory(at: URL(fileURLWithPath: spec.video).deletingLastPathComponent(),
                                             withIntermediateDirectories: true)
    let ffmpeg = Process()
    ffmpeg.executableURL = URL(fileURLWithPath: ffmpegPath)
    ffmpeg.arguments = ["-v", "error", "-y",
                        "-f", "rawvideo", "-pix_fmt", "rgba64le", "-s", "\(W)x\(H)", "-r", "\(fps)", "-i", "-",
                        "-vf", "scale=out_color_matrix=bt709:out_range=tv:flags=accurate_rnd+full_chroma_int:sws_dither=ed,"
                            + "setparams=color_primaries=bt709:color_trc=bt709:colorspace=bt709:range=tv",
                        "-c:v", "libx264", "-preset", "slow", "-crf", "12", "-profile:v", "high",
                        "-tune", "grain", "-x264-params", "aq-mode=3", "-pix_fmt", "yuv420p",
                        "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
                        "-color_range", "tv", "-movflags", "+faststart", "-an", spec.video]
    let pipe = Pipe()
    ffmpeg.standardInput = pipe
    do { try ffmpeg.run() } catch { fatalError("ffmpeg not found at \(ffmpegPath)") }
    let ctx = makeContext(deep: true)
    for n in 0..<Int(duration * Double(fps)) {
        frame(ctx, at: Double(n) / Double(fps))
        pipe.fileHandleForWriting.write(Data(bytes: ctx.data!, count: W * H * 8))
    }
    try? pipe.fileHandleForWriting.close()
    ffmpeg.waitUntilExit()
    guard ffmpeg.terminationStatus == 0 else { fatalError("ffmpeg failed") }
}

/// The header roughly as an iPhone shows it: full height, about two thirds of
/// the width around the centre, at 3x of a 402 pt screen. Red: safe area.
/// Grey: estimated back/share buttons. An estimate; confirm in ASC's preview.
func writePhoneMock(_ poster: CGImage, _ path: String) {
    let cropW = Int(Double(H) * 1.558), x0 = (W - cropW) / 2
    let crop = poster.cropping(to: CGRect(x: x0, y: 0, width: cropW, height: H))!
    let pw = 1206, ph = Int(Double(pw) * Double(H) / Double(cropW)), s = CGFloat(pw) / CGFloat(cropW)
    let ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.draw(crop, in: CGRect(x: 0, y: 0, width: pw, height: ph))
    ctx.setStrokeColor(CGColor(srgbRed: 1, green: 0.3, blue: 0.3, alpha: 0.8)); ctx.setLineWidth(3)
    ctx.stroke(CGRect(x: (safe.minX - CGFloat(x0)) * s, y: CGFloat(ph) - safe.maxY * s,
                      width: safe.width * s, height: safe.height * s))
    ctx.setFillColor(CGColor(gray: 0.5, alpha: 0.6))
    for x in [CGFloat(48), CGFloat(pw) - 48 - 132] {
        ctx.fillEllipse(in: CGRect(x: x, y: CGFloat(ph) - 174 - 132, width: 132, height: 132))
    }
    writePNG(ctx.makeImage()!, path)
}

func check() -> Bool {
    var ok = true
    func fail(_ s: String) { print("FAIL \(s)"); ok = false }
    // Poster: PNG, exact size, opaque, 8-bit RGB.
    if let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: spec.poster) as CFURL, nil),
       CGImageSourceGetType(src) as String? == UTType.png.identifier,
       let img = CGImageSourceCreateImageAtIndex(src, 0, nil) {
        if img.width != W || img.height != H { fail("poster is \(img.width)x\(img.height)") }
        if ![.none, .noneSkipLast, .noneSkipFirst].contains(img.alphaInfo) { fail("poster has alpha") }
        if img.bitsPerComponent != 8 { fail("poster is \(img.bitsPerComponent)-bit") }
    } else { fail("poster missing or not PNG: \(spec.poster)") }
    // Video: ffprobe dimensions, frame rate, duration, codec, colour tags.
    let probe = Process(), out = Pipe()
    probe.executableURL = URL(fileURLWithPath: (ffmpegPath as NSString).deletingLastPathComponent + "/ffprobe")
    probe.arguments = ["-v", "error", "-select_streams", "v:0", "-show_entries",
                       "stream=codec_name,width,height,r_frame_rate,pix_fmt,color_primaries,color_transfer,color_space:format=duration",
                       "-of", "default=nw=1", spec.video]
    probe.standardOutput = out
    do { try probe.run() } catch { fail("ffprobe not found"); return ok }
    probe.waitUntilExit()
    let text = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    var kv: [String: String] = [:]
    for line in text.split(separator: "\n") {
        let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
        if parts.count == 2, kv[parts[0]] == nil { kv[parts[0]] = parts[1] }
    }
    if kv["width"] != "\(W)" || kv["height"] != "\(H)" { fail("video is \(kv["width"] ?? "?")x\(kv["height"] ?? "?")") }
    if !["30/1", "60/1"].contains(kv["r_frame_rate"] ?? "") { fail("frame rate \(kv["r_frame_rate"] ?? "?")") }
    let d = Double(kv["duration"] ?? "") ?? 0
    if d < 5 || d > 30 { fail(String(format: "duration %.2f s (5-30)", d)) }
    if !["h264", "hevc", "prores"].contains(kv["codec_name"] ?? "") { fail("codec \(kv["codec_name"] ?? "?")") }
    if kv["pix_fmt"] != "yuv420p", kv["codec_name"] == "h264" { fail("pix_fmt \(kv["pix_fmt"] ?? "?")") }
    for key in ["color_primaries", "color_transfer", "color_space"] where kv[key] != "bt709" {
        fail("\(key) \(kv[key] ?? "unset")")
    }
    if ok { print(String(format: "PASS %@ %dx%d %@ %.2fs; %@", spec.video, W, H, kv["r_frame_rate"]!, d, spec.poster)) }
    return ok
}

if args.contains("--check") { exit(check() ? 0 : 1) }
let posterCtx = makeContext(deep: false)
frame(posterCtx, at: 0)
let poster = posterCtx.makeImage()!
writePNG(poster, spec.poster)
if let mock = spec.phoneMock { writePhoneMock(poster, mock) }
if !args.contains("--poster") {
    guard duration >= 5, duration <= 30 else { fatalError("loop is \(duration) s; Apple accepts 5-30 s") }
    renderVideo()
}
print("rendered \(spec.poster)\(args.contains("--poster") ? "" : ", \(spec.video)")")
