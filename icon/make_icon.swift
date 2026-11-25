// Draws the MetaScrub app icon (1024×1024 PNG): a photo with a location pin, its lower part wiped away by a brush
// stroke, on a red tile. Run by icon/make-icns.sh.
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

// A photo with a location pin, its lower part wiped away by one broad brush stroke, and two gold sparkles.

/// A tapered brush streak from `a` to `b`, `width` across at its widest point (`peak` of the way along).
func streak(_ a: CGPoint, _ b: CGPoint, width: CGFloat, peak: CGFloat = 0.35) -> CGPath {
    let dx = b.x - a.x, dy = b.y - a.y
    let length = (dx * dx + dy * dy).squareRoot()
    let normal = CGPoint(x: -dy / length, y: dx / length)
    let at = CGPoint(x: a.x + dx * peak, y: a.y + dy * peak)
    let path = CGMutablePath()
    path.move(to: a)
    path.addQuadCurve(to: b, control: CGPoint(x: at.x + normal.x * width, y: at.y + normal.y * width))
    path.addQuadCurve(to: a, control: CGPoint(x: at.x - normal.x * width, y: at.y - normal.y * width))
    path.closeSubpath()
    return path
}

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
    cg.translateBy(x: 490, y: 575)
    cg.rotate(by: 6 * .pi / 180)
    let card = CGRect(x: -215, y: -175, width: 430, height: 350)
    cg.addPath(CGPath(roundedRect: card, cornerWidth: 34, cornerHeight: 34, transform: nil))
    cg.setFillColor(cream); cg.fillPath()
    let picture = card.insetBy(dx: 36, dy: 36)
    cg.addPath(CGPath(roundedRect: picture, cornerWidth: 10, cornerHeight: 10, transform: nil))
    cg.setFillColor(rgb(tile)); cg.fillPath()
    cg.saveGState()
    cg.addPath(CGPath(roundedRect: picture, cornerWidth: 10, cornerHeight: 10, transform: nil)); cg.clip()
    let hills = CGMutablePath()
    hills.move(to: CGPoint(x: picture.minX, y: picture.minY))
    hills.addLine(to: CGPoint(x: picture.minX, y: -50))
    hills.addLine(to: CGPoint(x: -95, y: 15))
    hills.addLine(to: CGPoint(x: -30, y: -40))
    hills.addLine(to: CGPoint(x: 50, y: 30))
    hills.addLine(to: CGPoint(x: picture.maxX, y: -70))
    hills.addLine(to: CGPoint(x: picture.maxX, y: picture.minY))
    hills.closeSubpath()
    cg.addPath(hills); cg.setFillColor(cream); cg.fillPath()
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

    // The brush stroke: a broad band rising to the right, ragged where the brush came down and tapering to a point,
    // with a thin dry streak along each side. A gap is cut around it so it reads as lying on top of the photo.
    let band = CGMutablePath()
    band.move(to: CGPoint(x: 214, y: 404))
    band.addQuadCurve(to: CGPoint(x: 772, y: 482), control: CGPoint(x: 500, y: 474))
    band.addQuadCurve(to: CGPoint(x: 244, y: 246), control: CGPoint(x: 580, y: 268))
    for point in [(196, 276), (232, 300), (176, 328), (224, 350), (186, 378)] as [(CGFloat, CGFloat)] {
        band.addLine(to: CGPoint(x: point.0, y: point.1))
    }
    band.closeSubpath()
    let streaks: [CGPath] = [
        band,
        streak(CGPoint(x: 236, y: 448), CGPoint(x: 470, y: 494), width: 18, peak: 0.4),
        streak(CGPoint(x: 268, y: 206), CGPoint(x: 500, y: 250), width: 16, peak: 0.4),
    ]
    cg.setBlendMode(.clear)
    for path in streaks { cg.addPath(path) }
    cg.setLineWidth(30); cg.setLineJoin(.round); cg.strokePath()
    cg.setBlendMode(.normal)
    for path in streaks { cg.addPath(path) }
    cg.setFillColor(cream); cg.fillPath()

    sparkle(CGPoint(x: 790, y: 560), 54)
    sparkle(CGPoint(x: 770, y: 440), 30)
}

NSGraphicsContext.current = nil
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("no png") }
try! png.write(to: URL(fileURLWithPath: out))
