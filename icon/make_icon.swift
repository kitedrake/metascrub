// Draws the MetaScrub app icon (1024×1024 PNG): a photo with a location pin and an eraser resting on its
// lower corner, on a red tile. Run by icon/make-icns.sh.
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments[1]
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                                 samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("no context") }
NSGraphicsContext.current = context
let cg = context.cgContext
let space = CGColorSpaceCreateDeviceRGB()

// MARK: Family style
// The sibling apps' icon scripts share this part word for word: a solid colour tile shaded slightly lighter at the
// top and one bold cream symbol with a gold accent. Only `tile` and the symbol differ between apps. Change all of them
// together.

func rgb(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}
/// `hex` moved `amount` of the way towards white (positive) or black (negative).
func shade(_ hex: UInt32, _ amount: CGFloat) -> CGColor {
    let c = rgb(hex).components!
    let target: CGFloat = amount > 0 ? 1 : 0
    let t = abs(amount)
    return CGColor(red: c[0] + (target - c[0]) * t, green: c[1] + (target - c[1]) * t, blue: c[2] + (target - c[2]) * t, alpha: 1)
}
let cream = rgb(0xf6f0e4)
let gold = rgb(0xe2b552)
let tile: UInt32 = 0xc8432b  // kite red

// The tile, on the macOS icon grid: inset from the canvas, with rounded corners and a drop shadow.
let inset: CGFloat = 100
let shape = CGPath(roundedRect: CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset),
                   cornerWidth: 185, cornerHeight: 185, transform: nil)
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: CGColor(gray: 0, alpha: 0.35))
cg.addPath(shape); cg.setFillColor(rgb(tile)); cg.fillPath()
cg.restoreGState()
cg.saveGState()
cg.addPath(shape); cg.clip()
let tileShade = CGGradient(colorsSpace: space, colors: [shade(tile, 0.10), rgb(tile), shade(tile, -0.10)] as CFArray,
                           locations: [0, 0.5, 1])!
cg.drawLinearGradient(tileShade, start: CGPoint(x: 0, y: size - inset), end: CGPoint(x: 0, y: inset), options: [])
cg.restoreGState()

/// Draws `body` with a soft shadow under it, so the symbol sits just above the tile.
func raised(_ body: () -> Void) {
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: CGColor(gray: 0, alpha: 0.18))
    cg.beginTransparencyLayer(auxiliaryInfo: nil)
    body()
    cg.endTransparencyLayer()
    cg.restoreGState()
}

// MARK: Symbol

// A photo with a location pin, an eraser resting on its lower corner, and two gold sparkles.

func sparkle(_ center: CGPoint, _ radius: CGFloat) {
    let star = CGMutablePath()
    for index in 0..<8 {
        let angle = CGFloat(index) * .pi / 4 + .pi / 2
        let r = index % 2 == 0 ? radius : radius * 0.26
        let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
        if index == 0 { star.move(to: point) } else { star.addLine(to: point) }
    }
    star.closeSubpath()
    cg.addPath(star); cg.setFillColor(gold); cg.fillPath()
}

raised {
    // The photo, tilted a little: a thick cream frame around a picture of hills under a pin.
    cg.saveGState()
    cg.translateBy(x: 470, y: 590)
    cg.rotate(by: 6 * .pi / 180)
    let card = CGRect(x: -215, y: -175, width: 430, height: 350)
    cg.addPath(CGPath(roundedRect: card, cornerWidth: 34, cornerHeight: 34, transform: nil))
    cg.setFillColor(cream); cg.fillPath()
    // The picture: only the sky above the hills is filled, so the hills join the frame without a seam.
    let picture = card.insetBy(dx: 36, dy: 36)
    cg.saveGState()
    cg.addPath(CGPath(roundedRect: picture, cornerWidth: 10, cornerHeight: 10, transform: nil)); cg.clip()
    let sky = CGMutablePath()
    sky.move(to: CGPoint(x: picture.minX - 1, y: picture.maxY + 1))
    sky.addLine(to: CGPoint(x: picture.minX - 1, y: -50))
    sky.addLine(to: CGPoint(x: -95, y: 15))
    sky.addLine(to: CGPoint(x: -30, y: -40))
    sky.addLine(to: CGPoint(x: 50, y: 30))
    sky.addLine(to: CGPoint(x: picture.maxX + 1, y: -70))
    sky.addLine(to: CGPoint(x: picture.maxX + 1, y: picture.maxY + 1))
    sky.closeSubpath()
    cg.addPath(sky); cg.setFillColor(rgb(tile)); cg.fillPath()
    cg.restoreGState()
    // The pin: a teardrop pointing down, with a hole.
    let pin = CGPoint(x: 100, y: 62), pr: CGFloat = 32
    let drop = CGMutablePath()
    drop.move(to: CGPoint(x: pin.x, y: pin.y - pr * 2.3))
    drop.addArc(tangent1End: CGPoint(x: pin.x - pr * 1.2, y: pin.y - pr * 0.4), tangent2End: CGPoint(x: pin.x - pr, y: pin.y),
                radius: pr * 0.4)
    drop.addArc(center: pin, radius: pr, startAngle: .pi, endAngle: 0, clockwise: true)
    drop.addArc(tangent1End: CGPoint(x: pin.x + pr * 1.2, y: pin.y - pr * 0.4), tangent2End: CGPoint(x: pin.x, y: pin.y - pr * 2.3),
                radius: pr * 0.4)
    drop.closeSubpath()
    cg.addPath(drop); cg.setFillColor(cream); cg.fillPath()
    cg.addEllipse(in: CGRect(x: pin.x - 12, y: pin.y - 12, width: 24, height: 24))
    cg.setFillColor(rgb(tile)); cg.fillPath()
    cg.restoreGState()

    // The eraser, tilted down to the right: its cream rubber end rests on the photo's lower corner and its gold sleeve
    // reaches off the photo. A gap is cut around it so it reads as lying on top.
    cg.saveGState()
    cg.translateBy(x: 642, y: 352)
    cg.rotate(by: -34 * .pi / 180)
    let body = CGPath(roundedRect: CGRect(x: -168, y: -62, width: 336, height: 124), cornerWidth: 34, cornerHeight: 34,
                      transform: nil)
    cg.setBlendMode(.clear)
    cg.addPath(body); cg.setLineWidth(30); cg.strokePath()
    cg.setBlendMode(.normal)
    cg.addPath(body); cg.setFillColor(cream); cg.fillPath()
    cg.saveGState()
    cg.addPath(body); cg.clip()
    cg.setFillColor(gold); cg.fill(CGRect(x: -20, y: -70, width: 200, height: 140))
    cg.restoreGState()
    cg.restoreGState()

    sparkle(CGPoint(x: 806, y: 588), 54)
    sparkle(CGPoint(x: 800, y: 470), 30)
}

NSGraphicsContext.current = nil
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("no png") }
try! png.write(to: URL(fileURLWithPath: out))
