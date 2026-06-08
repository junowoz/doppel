import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: create_dmg_background.swift <output.png>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 640, height: 400)
let image = NSImage(size: size)

image.lockFocus()

let bounds = NSRect(origin: .zero, size: size)
NSColor(calibratedRed: 0.96, green: 0.98, blue: 1.0, alpha: 1.0).setFill()
bounds.fill()

let accent = NSColor(calibratedRed: 0.04, green: 0.46, blue: 0.86, alpha: 1.0)
let muted = NSColor(calibratedWhite: 0.36, alpha: 1.0)
let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 30, weight: .bold),
    .foregroundColor: NSColor(calibratedWhite: 0.12, alpha: 1.0)
]
let bodyAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 15, weight: .medium),
    .foregroundColor: muted
]

let title = "Install Doppel" as NSString
title.draw(at: NSPoint(x: 226, y: 328), withAttributes: titleAttributes)

let subtitle = "Drag Doppel to Applications" as NSString
subtitle.draw(at: NSPoint(x: 226, y: 304), withAttributes: bodyAttributes)

let arrow = NSBezierPath()
arrow.lineWidth = 8
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.move(to: NSPoint(x: 238, y: 192))
arrow.line(to: NSPoint(x: 402, y: 192))
arrow.move(to: NSPoint(x: 376, y: 164))
arrow.line(to: NSPoint(x: 406, y: 192))
arrow.line(to: NSPoint(x: 376, y: 220))
accent.setStroke()
arrow.stroke()

let dotted = NSBezierPath()
dotted.lineWidth = 2
dotted.setLineDash([7, 7], count: 2, phase: 0)
dotted.appendRoundedRect(NSRect(x: 66, y: 118, width: 126, height: 126), xRadius: 28, yRadius: 28)
dotted.appendRoundedRect(NSRect(x: 448, y: 118, width: 126, height: 126), xRadius: 28, yRadius: 28)
NSColor(calibratedWhite: 0.78, alpha: 1.0).setStroke()
dotted.stroke()

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("failed to render DMG background\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL, options: .atomic)
