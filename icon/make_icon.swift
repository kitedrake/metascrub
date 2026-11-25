// Draws the MetaScrub app icon (1024×1024 PNG): a paper photo of a mountain and a pin, its corner folded back to
// blank paper, in red on a cream paper tile. Run by icon/make-icns.sh.
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
// The sibling apps' icon scripts share this part word for word: one glyph folded from paper in the app's own ink, a
// few flat facets lit from the top left, on a cream paper tile, with a gold accent. Only `ink` and the symbol differ
// between apps. Change all of them together.

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: 1)
}
/// `a` moved `t` of the way towards `b`.
func blend(_ a: CGColor, _ b: CGColor, _ t: CGFloat) -> CGColor {
    let x = a.components!, y = b.components!
    return CGColor(red: x[0] + (y[0] - x[0]) * t, green: x[1] + (y[1] - x[1]) * t, blue: x[2] + (y[2] - x[2]) * t, alpha: 1)
}
/// `hex` moved `amount` of the way towards white (positive) or black (negative).
func shade(_ hex: UInt32, _ amount: CGFloat) -> CGColor {
    blend(rgb(hex), rgb(amount > 0 ? 0xffffff : 0x000000), abs(amount))
}
let paper: UInt32 = 0xf6f0e4
let gold: UInt32 = 0xd9a23c
let ink: UInt32 = 0xc8432b  // kite red
// Each colour in three tones: facets facing the light, across it, and away from it.
let light = shade(ink, 0.16), mid = rgb(ink), dark = shade(ink, -0.26)
let goldLight = shade(gold, 0.18), goldMid = rgb(gold), goldDark = shade(gold, -0.24)
let cream = rgb(paper), creamShade = shade(paper, -0.12)

// The tile, on the macOS icon grid: cream paper inset from the canvas, with rounded corners and a drop shadow.
let inset: CGFloat = 100
let shape = CGPath(roundedRect: CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset),
                   cornerWidth: 185, cornerHeight: 185, transform: nil)
cg.saveGState()
cg.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: CGColor(gray: 0, alpha: 0.32))
cg.addPath(shape); cg.setFillColor(cream); cg.fillPath()
cg.restoreGState()
cg.saveGState()
cg.addPath(shape); cg.clip()
let tileShade = CGGradient(colorsSpace: space, colors: [shade(paper, 0.55), cream, shade(paper, -0.06)] as CFArray,
                           locations: [0, 0.55, 1])!
cg.drawLinearGradient(tileShade, start: CGPoint(x: 0, y: size - inset), end: CGPoint(x: 0, y: inset), options: [])
cg.restoreGState()

/// Draws `body` with a soft shadow under it, so the paper sits just above the tile.
func raised(_ body: () -> Void) {
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -10), blur: 22, color: CGColor(gray: 0, alpha: 0.22))
    cg.beginTransparencyLayer(auxiliaryInfo: nil)
    body()
    cg.endTransparencyLayer()
    cg.restoreGState()
}

/// Fills one flat facet. The thin stroke in the same colour closes the seams between neighbouring facets.
func facet(_ color: CGColor, _ points: [CGPoint]) {
    cg.move(to: points[0])
    for point in points.dropFirst() { cg.addLine(to: point) }
    cg.closePath()
    cg.setFillColor(color); cg.setStrokeColor(color); cg.setLineWidth(1.5); cg.setLineJoin(.round)
    cg.drawPath(using: .fillStroke)
}
func facet(_ color: CGColor, _ points: [(CGFloat, CGFloat)]) { facet(color, points.map { CGPoint(x: $0.0, y: $0.1) }) }

/// The tone of a facet that faces `angle` (radians, 0 = right): `lit` facing the top left, `unlit` the bottom right.
func tone(_ angle: CGFloat, _ lit: CGColor, _ unlit: CGColor) -> CGColor {
    blend(unlit, lit, (cos(angle - 3 * .pi / 4) + 1) / 2)
}

/// A paper strip `width` across, folded along `points`: each straight run is one facet, the creases are mitred, and the
/// runs take `tones` in turn.
func strip(_ points: [CGPoint], width: CGFloat, tones: [CGColor]) {
    let n = points.count
    let dirs = (0..<n - 1).map { i -> CGPoint in
        let dx = points[i + 1].x - points[i].x, dy = points[i + 1].y - points[i].y, l = hypot(dx, dy)
        return CGPoint(x: dx / l, y: dy / l)
    }
    var left: [CGPoint] = [], right: [CGPoint] = []
    for i in 0..<n {
        let a = dirs[max(i - 1, 0)], b = dirs[min(i, n - 2)]
        let na = CGPoint(x: -a.y, y: a.x), nb = CGPoint(x: -b.y, y: b.x)
        let mx = na.x + nb.x, my = na.y + nb.y, ml = hypot(mx, my)
        let length = width / 2 / ((mx * na.x + my * na.y) / ml)
        left.append(CGPoint(x: points[i].x + mx / ml * length, y: points[i].y + my / ml * length))
        right.append(CGPoint(x: points[i].x - mx / ml * length, y: points[i].y - my / ml * length))
    }
    for i in 0..<n - 1 { facet(tones[i % tones.count], [left[i], left[i + 1], right[i + 1], right[i]]) }
}

/// A four-pointed gold star folded from paper: each point is two facets meeting along its spine.
func sparkle(_ center: CGPoint, _ radius: CGFloat) {
    for k in 0..<4 {
        let a = CGFloat(k) * .pi / 2 + .pi / 2
        let tip = CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius)
        for side: CGFloat in [-1, 1] {
            let s = a + side * .pi / 4
            let corner = CGPoint(x: center.x + cos(s) * radius * 0.3, y: center.y + sin(s) * radius * 0.3)
            facet(tone(a + side * .pi / 2, goldLight, goldDark), [center, tip, corner])
        }
    }
}

// MARK: Symbol

// A paper photo of a mountain under a location pin, tilted a little, its lower corner folded back to blank paper as if
// the picture's data were peeled away; two gold sparkles where the corner was.

raised {
    cg.saveGState()
    cg.translateBy(x: 486, y: 540)
    cg.rotate(by: -7 * .pi / 180)
    let w: CGFloat = 250, h: CGFloat = 282
    // The fold runs from the bottom edge to the right edge.
    let p1 = CGPoint(x: 30, y: -h), p2 = CGPoint(x: w, y: -50)
    let card = [CGPoint(x: -w, y: h), CGPoint(x: w, y: h), p2, p1, CGPoint(x: -w, y: -h)]
    facet(mid, card)

    // The picture, inside the card: two peaks on dark ground, snow on the taller one, and a pin.
    cg.saveGState()
    cg.move(to: card[0]); for point in card.dropFirst() { cg.addLine(to: point) }; cg.closePath(); cg.clip()
    let slope = shade(ink, -0.14), shadow = shade(ink, -0.34)
    facet(shadow, [(-w - 10, -196), (w + 10, -196), (w + 10, -h - 10), (-w - 10, -h - 10)])
    facet(slope, [(-20, -196), (112, 46), (112, -196)])
    facet(shadow, [(112, 46), (270, -196), (112, -196)])
    facet(slope, [(-300, -196), (-70, 156), (-70, -196)])
    facet(shadow, [(-70, 156), (156, -196), (-70, -196)])
    facet(cream, [(-70, 156), (-117, 84), (-92, 98), (-70, 78)])
    facet(creamShade, [(-70, 156), (-70, 78), (-48, 96), (-24, 84)])
    // The pin: a teardrop pointing down, shaded on its right half, with a hole.
    let pin = CGPoint(x: 118, y: 168), pr: CGFloat = 36
    let drop = CGMutablePath()
    drop.move(to: CGPoint(x: pin.x, y: pin.y - pr * 2.3))
    drop.addArc(tangent1End: CGPoint(x: pin.x - pr * 1.2, y: pin.y - pr * 0.4), tangent2End: CGPoint(x: pin.x - pr, y: pin.y),
                radius: pr * 0.4)
    drop.addArc(center: pin, radius: pr, startAngle: .pi, endAngle: 0, clockwise: true)
    drop.addArc(tangent1End: CGPoint(x: pin.x + pr * 1.2, y: pin.y - pr * 0.4), tangent2End: CGPoint(x: pin.x, y: pin.y - pr * 2.3),
                radius: pr * 0.4)
    drop.closeSubpath()
    cg.addPath(drop); cg.setFillColor(shade(ink, -0.3)); cg.fillPath()
    cg.saveGState()
    cg.clip(to: CGRect(x: pin.x, y: pin.y - pr * 3, width: pr * 2, height: pr * 4))
    cg.addPath(drop); cg.setFillColor(shade(ink, -0.46)); cg.fillPath()
    cg.restoreGState()
    cg.addEllipse(in: CGRect(x: pin.x - 13, y: pin.y - 13, width: 26, height: 26))
    cg.setFillColor(cream); cg.fillPath()
    cg.restoreGState()

    // The folded corner: the corner reflected across the fold, showing the paper's blank back, with a soft shadow.
    let corner = CGPoint(x: w, y: -h)
    let ux = p2.x - p1.x, uy = p2.y - p1.y, ul = hypot(ux, uy)
    let t = ((corner.x - p1.x) * ux + (corner.y - p1.y) * uy) / ul
    let foot = CGPoint(x: p1.x + ux / ul * t, y: p1.y + uy / ul * t)
    let folded = CGPoint(x: 2 * foot.x - corner.x, y: 2 * foot.y - corner.y)
    let crease = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: -6, height: 6), blur: 18, color: CGColor(gray: 0, alpha: 0.3))
    cg.beginTransparencyLayer(auxiliaryInfo: nil)
    facet(cream, [p1, crease, folded])
    facet(creamShade, [crease, p2, folded])
    cg.endTransparencyLayer()
    cg.restoreGState()
    cg.restoreGState()

    sparkle(CGPoint(x: 694, y: 292), 62)
    sparkle(CGPoint(x: 790, y: 388), 34)
}

NSGraphicsContext.current = nil
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("no png") }
try! png.write(to: URL(fileURLWithPath: out))
