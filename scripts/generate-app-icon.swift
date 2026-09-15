import AppKit
import Foundation

let canvas = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvas)
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Unable to create graphics context")
}

let bounds = NSRect(origin: .zero, size: canvas)
let background = NSGradient(colors: [
    NSColor(red: 0.07, green: 0.025, blue: 0.03, alpha: 1),
    NSColor(red: 0.28, green: 0.035, blue: 0.045, alpha: 1)
])!
background.draw(in: bounds, angle: -45)

context.saveGState()
context.translateBy(x: 512, y: 512)

let outerRing = NSBezierPath(ovalIn: NSRect(x: -350, y: -350, width: 700, height: 700))
outerRing.lineWidth = 24
NSColor(red: 0.82, green: 0.58, blue: 0.20, alpha: 0.72).setStroke()
outerRing.stroke()

for index in 0..<6 {
    context.saveGState()
    context.rotate(by: CGFloat(index) * .pi / 3)

    let petal = NSBezierPath()
    petal.move(to: NSPoint(x: 0, y: 112))
    petal.curve(to: NSPoint(x: 0, y: 382), controlPoint1: NSPoint(x: -150, y: 205), controlPoint2: NSPoint(x: -118, y: 330))
    petal.curve(to: NSPoint(x: 0, y: 112), controlPoint1: NSPoint(x: 118, y: 330), controlPoint2: NSPoint(x: 150, y: 205))
    petal.close()

    let petalGradient = NSGradient(colors: [
        NSColor(red: 0.92, green: 0.19, blue: 0.12, alpha: 1),
        NSColor(red: 0.42, green: 0.025, blue: 0.045, alpha: 1)
    ])!
    petalGradient.draw(in: petal, angle: 90)
    petal.lineWidth = 18
    NSColor(red: 0.92, green: 0.70, blue: 0.32, alpha: 1).setStroke()
    petal.stroke()
    context.restoreGState()
}

let centerOuter = NSBezierPath(ovalIn: NSRect(x: -132, y: -132, width: 264, height: 264))
NSColor(red: 0.92, green: 0.70, blue: 0.32, alpha: 1).setFill()
centerOuter.fill()

let centerInner = NSBezierPath(ovalIn: NSRect(x: -103, y: -103, width: 206, height: 206))
let centerGradient = NSGradient(colors: [
    NSColor(red: 0.96, green: 0.18, blue: 0.10, alpha: 1),
    NSColor(red: 0.26, green: 0.01, blue: 0.025, alpha: 1)
])!
centerGradient.draw(in: centerInner, relativeCenterPosition: NSPoint(x: -0.25, y: 0.28))

let glint = NSBezierPath(ovalIn: NSRect(x: -52, y: 38, width: 45, height: 25))
NSColor.white.withAlphaComponent(0.72).setFill()
glint.fill()

context.restoreGState()
image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Unable to encode icon")
}

let output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("YuhunBox/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try png.write(to: output, options: .atomic)
print("Generated \(output.path)")


