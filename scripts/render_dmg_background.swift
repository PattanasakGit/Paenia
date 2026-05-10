#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.arguments.count > 1 else {
  fputs("usage: render_dmg_background.swift <output.png>\n", stderr)
  exit(1)
}
let outURL = URL(fileURLWithPath: CommandLine.arguments[1])

let pw = 640
let ph = 360
guard let rep = NSBitmapImageRep(
  bitmapDataPlanes: nil,
  pixelsWide: pw,
  pixelsHigh: ph,
  bitsPerSample: 8,
  samplesPerPixel: 4,
  hasAlpha: true,
  isPlanar: false,
  colorSpaceName: .deviceRGB,
  bytesPerRow: 0,
  bitsPerPixel: 0
) else {
  fputs("bitmap rep failed\n", stderr)
  exit(1)
}
rep.size = NSSize(width: CGFloat(pw), height: CGFloat(ph))

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let w = CGFloat(pw)
let h = CGFloat(ph)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
  NSColor(
    calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
    green: CGFloat((hex >> 8) & 0xff) / 255,
    blue: CGFloat(hex & 0xff) / 255,
    alpha: alpha
  )
}

func drawText(_ string: String, attrs: [NSAttributedString.Key: Any], centerX: CGFloat, topY: CGFloat) {
  let size = (string as NSString).size(withAttributes: attrs)
  (string as NSString).draw(
    at: NSPoint(x: centerX - size.width / 2, y: h - topY - size.height),
    withAttributes: attrs
  )
}

let rect = NSRect(x: 0, y: 0, width: w, height: h)
if let gradient = NSGradient(
  colors: [
    color(0xfff7ff),
    color(0xf2eeff),
    color(0xe7f9ff)
  ],
  atLocations: [0, 0.52, 1],
  colorSpace: .deviceRGB
) {
  gradient.draw(in: rect, angle: -14)
}

if let glow = NSGradient(
  colors: [color(0xff4fd8, 0.2), color(0xff4fd8, 0)],
  atLocations: [0, 1],
  colorSpace: .deviceRGB
) {
  let center = NSPoint(x: 160, y: 335)
  glow.draw(fromCenter: center, radius: 0, toCenter: center, radius: 230, options: [])
}

if let glow = NSGradient(
  colors: [color(0x00d4ff, 0.18), color(0x5cff95, 0.08), color(0x00d4ff, 0)],
  atLocations: [0, 0.42, 1],
  colorSpace: .deviceRGB
) {
  let center = NSPoint(x: 680, y: 165)
  glow.draw(fromCenter: center, radius: 0, toCenter: center, radius: 260, options: [])
}

let titleAttrs: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: 24, weight: .bold),
  .foregroundColor: color(0x241642),
  .kern: 0
]
let subtitleAttrs: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: 13, weight: .medium),
  .foregroundColor: color(0x534566),
  .kern: 0
]
let captionAttrs: [NSAttributedString.Key: Any] = [
  .font: NSFont.systemFont(ofSize: 11, weight: .regular),
  .foregroundColor: color(0x7c6a99),
  .kern: 0
]

drawText("ติดตั้ง Paenia", attrs: titleAttrs, centerX: w / 2, topY: 26)
drawText("ลาก Paenia ไปวางบนโฟลเดอร์ Applications", attrs: subtitleAttrs, centerX: w / 2, topY: 58)
drawText("Drag Paenia onto Applications", attrs: captionAttrs, centerX: w / 2, topY: 78)

let arrowY: CGFloat = 174
let startX: CGFloat = 250
let endX: CGFloat = 390
let shadow = NSBezierPath()
shadow.move(to: NSPoint(x: startX, y: arrowY - 1))
shadow.line(to: NSPoint(x: endX, y: arrowY - 1))
shadow.lineWidth = 7
shadow.lineCapStyle = .round
color(0x241642, 0.08).setStroke()
shadow.stroke()

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: startX, y: arrowY))
arrow.line(to: NSPoint(x: endX, y: arrowY))
arrow.lineWidth = 3
arrow.lineCapStyle = .round
color(0x9d4edd, 0.34).setStroke()
arrow.stroke()

let head = NSBezierPath()
head.move(to: NSPoint(x: endX - 15, y: arrowY + 12))
head.line(to: NSPoint(x: endX, y: arrowY))
head.line(to: NSPoint(x: endX - 15, y: arrowY - 12))
head.lineWidth = 3
head.lineCapStyle = .round
head.lineJoinStyle = .round
head.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
  fputs("png encode failed\n", stderr)
  exit(1)
}
do {
  try png.write(to: outURL)
} catch {
  fputs("\(error)\n", stderr)
  exit(1)
}
