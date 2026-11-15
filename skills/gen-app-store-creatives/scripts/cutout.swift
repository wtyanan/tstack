// Lifts the subject out of a photo (Vision's foreground mask) and writes a
// transparent PNG trimmed to the subject, with a small margin. Images that
// already have real alpha are only trimmed.
// Usage: swift cutout.swift <in.png> <out.png> [<in2.png> <out2.png> ...]
import AppKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers
import Vision

func load(_ path: String) -> CGImage {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fatalError("can't read \(path)") }
    return img
}

func hasRealAlpha(_ img: CGImage) -> Bool {
    guard ![.none, .noneSkipLast, .noneSkipFirst].contains(img.alphaInfo) else { return false }
    // Any pixel noticeably transparent?
    let w = 64, h = 64
    var px = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    return stride(from: 3, to: px.count, by: 4).contains { px[$0] < 200 }
}

func lift(_ img: CGImage) -> CGImage {
    let req = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: img)
    try! handler.perform([req])
    guard let obs = req.results?.first else { fatalError("no subject found") }
    let buf = try! obs.generateMaskedImage(ofInstances: obs.allInstances, from: handler, croppedToInstancesExtent: false)
    let ci = CIImage(cvPixelBuffer: buf)
    return CIContext().createCGImage(ci, from: ci.extent, format: .RGBA8,
                                     colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)!
}

/// Crops to pixels with alpha above 32 (ignores faint specks), plus `margin` px.
func trim(_ img: CGImage, margin: Int = 8) -> CGImage {
    let w = img.width, h = img.height
    var px = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
    var minX = w, minY = h, maxX = -1, maxY = -1
    for y in 0..<h { for x in 0..<w where px[(y * w + x) * 4 + 3] > 32 {
        minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
    } }
    guard maxX >= 0 else { fatalError("empty mask") }
    // Buffer rows run top-down for CGImage cropping.
    let r = CGRect(x: max(0, minX - margin), y: max(0, minY - margin),
                   width: min(w, maxX + margin + 1) - max(0, minX - margin),
                   height: min(h, maxY + margin + 1) - max(0, minY - margin))
    return ctx.makeImage()!.cropping(to: r)!
}

let a = Array(CommandLine.arguments.dropFirst())
guard a.count >= 2, a.count % 2 == 0 else { fputs("usage: cutout <in> <out> [...]\n", stderr); exit(2) }
for i in stride(from: 0, to: a.count, by: 2) {
    let img = load(a[i])
    let out = trim(hasRealAlpha(img) ? img : lift(img))
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: a[i + 1]) as CFURL,
                                               UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, out, nil)
    guard CGImageDestinationFinalize(dest) else { fatalError("can't write \(a[i + 1])") }
    print("\(a[i + 1]) \(out.width)x\(out.height)")
}
