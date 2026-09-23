import AppKit

// Vector artwork rendered at every macOS icon size. Coordinates use a 1024-point canvas.
let output = URL(
  fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1] : "build/Windower.iconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
  NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawIcon(pixels: Int) throws {
  let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  bitmap.size = NSSize(width: pixels, height: pixels)
  let context = NSGraphicsContext(bitmapImageRep: bitmap)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  context.imageInterpolation = .high
  let scale = CGFloat(pixels) / 1024
  context.cgContext.scaleBy(x: scale, y: scale)

  // Inset silhouette keeps the icon aligned with other macOS application icons.
  let tile = rounded(NSRect(x: 100, y: 100, width: 824, height: 824), 186)
  NSGraphicsContext.saveGraphicsState()
  let shadow = NSShadow()
  shadow.shadowColor = NSColor.black.withAlphaComponent(0.23)
  shadow.shadowBlurRadius = 24
  shadow.shadowOffset = NSSize(width: 0, height: -12)
  shadow.set()
  NSColor(calibratedRed: 0.10, green: 0.34, blue: 0.76, alpha: 1).setFill()
  tile.fill()
  NSGraphicsContext.restoreGraphicsState()
  NSGradient(colors: [
    NSColor(calibratedRed: 0.08, green: 0.32, blue: 0.78, alpha: 1),
    NSColor(calibratedRed: 0.20, green: 0.62, blue: 0.98, alpha: 1),
  ])!.draw(in: tile, angle: 90)
  NSColor.white.withAlphaComponent(0.18).setStroke()
  tile.lineWidth = 3
  tile.stroke()

  let window = rounded(NSRect(x: 218, y: 280, width: 588, height: 464), 44)
  NSGraphicsContext.saveGraphicsState()
  let windowShadow = NSShadow()
  windowShadow.shadowColor = NSColor(calibratedWhite: 0.05, alpha: 0.20)
  windowShadow.shadowBlurRadius = 20
  windowShadow.shadowOffset = NSSize(width: 0, height: -10)
  windowShadow.set()
  NSColor.white.setFill()
  window.fill()
  NSGraphicsContext.restoreGraphicsState()

  let blue = NSColor(calibratedRed: 0.12, green: 0.43, blue: 0.84, alpha: 1)
  // A small title bar and three panes communicate window arrangement at small sizes.
  blue.withAlphaComponent(0.45).setFill()
  for x in [CGFloat(250), 280, 310] {
    NSBezierPath(ovalIn: NSRect(x: x, y: 693, width: 14, height: 14)).fill()
  }
  blue.withAlphaComponent(0.12).setFill()
  NSBezierPath(rect: NSRect(x: 242, y: 664, width: 540, height: 3)).fill()
  blue.setFill()
  rounded(NSRect(x: 246, y: 310, width: 250, height: 330), 16).fill()
  blue.withAlphaComponent(0.34).setFill()
  rounded(NSRect(x: 520, y: 487, width: 258, height: 153), 16).fill()
  blue.withAlphaComponent(0.16).setFill()
  rounded(NSRect(x: 520, y: 310, width: 258, height: 153), 16).fill()
  NSGraphicsContext.restoreGraphicsState()

  let data = bitmap.representation(using: .png, properties: [:])!
  for (points, retina) in [(pixels, false), (pixels / 2, true)] {
    guard [16, 32, 128, 256, 512].contains(points), !retina || pixels >= 32 else { continue }
    let suffix = retina ? "@2x" : ""
    try data.write(to: output.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
  }
}

for pixels in [16, 32, 64, 128, 256, 512, 1024] { try drawIcon(pixels: pixels) }
