import AppKit

let destination = URL(fileURLWithPath: CommandLine.arguments[1])
let pixels = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
    isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create app icon bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
let scale = CGFloat(pixels) / 256
let transform = NSAffineTransform()
transform.scaleX(by: scale, yBy: scale)
transform.concat()

NSColor(calibratedRed: 0.85, green: 0.96, blue: 0.91, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 256, height: 256), xRadius: 56, yRadius: 56).fill()

let bookmark = NSBezierPath()
bookmark.move(to: NSPoint(x: 67, y: 219))
bookmark.curve(to: NSPoint(x: 80, y: 232), controlPoint1: NSPoint(x: 67, y: 227), controlPoint2: NSPoint(x: 72, y: 232))
bookmark.line(to: NSPoint(x: 176, y: 232))
bookmark.curve(to: NSPoint(x: 189, y: 219), controlPoint1: NSPoint(x: 184, y: 232), controlPoint2: NSPoint(x: 189, y: 227))
bookmark.line(to: NSPoint(x: 189, y: 35))
bookmark.line(to: NSPoint(x: 128, y: 79))
bookmark.line(to: NSPoint(x: 67, y: 35))
bookmark.close()
NSColor(calibratedRed: 0.20, green: 0.66, blue: 0.52, alpha: 1).setFill()
NSColor(calibratedRed: 0.09, green: 0.42, blue: 0.34, alpha: 1).setStroke()
bookmark.lineWidth = 6
bookmark.fill()
bookmark.stroke()

NSColor(calibratedRed: 0.07, green: 0.23, blue: 0.20, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: 94, y: 146, width: 16, height: 22)).fill()
NSBezierPath(ovalIn: NSRect(x: 146, y: 146, width: 16, height: 22)).fill()
let smile = NSBezierPath()
smile.move(to: NSPoint(x: 110, y: 125))
smile.curve(to: NSPoint(x: 146, y: 125), controlPoint1: NSPoint(x: 120, y: 108), controlPoint2: NSPoint(x: 136, y: 108))
smile.lineWidth = 7
smile.lineCapStyle = .round
smile.stroke()

NSColor(calibratedRed: 0.99, green: 0.65, blue: 0.63, alpha: 0.8).setFill()
NSBezierPath(ovalIn: NSRect(x: 78, y: 121, width: 18, height: 18)).fill()
NSBezierPath(ovalIn: NSRect(x: 160, y: 121, width: 18, height: 18)).fill()

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode app icon")
}
try png.write(to: destination)
