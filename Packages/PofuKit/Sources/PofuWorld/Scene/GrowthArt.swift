#if os(iOS)
import PofuCore
import SwiftUI

/// One piece of the island's growth (`IslandGrowth`): the baked sprite named
/// `piece.art` when the pipeline has one, otherwise the code-drawn stand-in
/// (`GrowthArt`). It never takes a tap; moving pieces are offset by
/// `IslandGrowth.motion` and animate inside their canvas by `time`, which is
/// 0 in a still frame and under Reduce Motion.
struct GrowthView: View {
    let piece: GrowthPiece
    /// Its feet on the canvas.
    let point: CGPoint
    let level: Double
    let time: Double

    var body: some View {
        let motion = IslandGrowth.motion(of: piece, at: time)
        let at = CGPoint(x: point.x + CGFloat(motion.dx), y: point.y + CGFloat(motion.dy))
        let anchor = UnitPoint(x: at.x / IslandLayout.canvasWidth, y: at.y / IslandLayout.canvasHeight)
        Group {
            if let sprite = WorldArt.sprite(piece.art) {
                DepthImage(name: piece.art, sprite: sprite, level: level, anchor: at)
            } else {
                let size = GrowthArt.size(of: piece.kind)
                let kind = piece.kind, variant = piece.variant, phase = piece.phase, clock = time
                Canvas { context, canvasSize in
                    GrowthArt.draw(kind, variant: variant, time: clock, phase: phase, in: &context, size: canvasSize)
                }
                .standing(on: at, width: size.width, height: size.height)
            }
        }
        .rotationEffect(.degrees(motion.degrees), anchor: anchor)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Code-drawn stand-ins for the growth the Codex queue has not painted
/// (`growth-path-stone`, `growth-flag-pole`, `growth-terrace`, and so on).
/// Every stand-in is drawn in a box whose bottom centre is the piece's feet.
enum GrowthArt {
    private static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> Color {
        Color(red: r, green: g, blue: b, opacity: a)
    }

    static func size(of kind: GrowthKind) -> CGSize {
        switch kind {
        case .pathStone: CGSize(width: 20, height: 9)
        case .steppingStone: CGSize(width: 16, height: 8)
        case .hillStone: CGSize(width: 14, height: 7)
        case .flagPole: CGSize(width: 34, height: 58)
        case .gull: CGSize(width: 26, height: 12)
        case .steam: CGSize(width: 24, height: 40)
        case .bridge: CGSize(width: 100, height: 46)
        case .lilyPad: CGSize(width: 22, height: 11)
        case .reeds: CGSize(width: 24, height: 36)
        case .dragonfly: CGSize(width: 20, height: 12)
        case .terrace: CGSize(width: 220, height: 50)
        case .lanternString: CGSize(width: 200, height: 76)
        case .gate: CGSize(width: 84, height: 84)
        case .hilltop: CGSize(width: 130, height: 46)
        case .bench: CGSize(width: 30, height: 16)
        }
    }

    static func draw(
        _ kind: GrowthKind, variant: Int, time: Double, phase: Double,
        in context: inout GraphicsContext, size: CGSize
    ) {
        switch kind {
        case .pathStone: stone(&context, size, top: rgb(0.80, 0.74, 0.64), side: rgb(0.52, 0.45, 0.36), variant: variant)
        case .hillStone: stone(&context, size, top: rgb(0.76, 0.70, 0.60), side: rgb(0.50, 0.43, 0.34), variant: variant)
        case .steppingStone: steppingStone(&context, size, variant: variant)
        case .flagPole: flagPole(&context, size, time: time, phase: phase)
        case .gull: gull(&context, size, time: time, phase: phase)
        case .steam: steam(&context, size, time: time)
        case .bridge: bridge(&context, size)
        case .lilyPad: lilyPad(&context, size, variant: variant)
        case .reeds: reeds(&context, size, time: time, phase: phase)
        case .dragonfly: dragonfly(&context, size, time: time)
        case .terrace: mound(&context, size, grass: rgb(0.45, 0.62, 0.34), lip: rgb(0.52, 0.64, 0.36), face: rgb(0.60, 0.48, 0.36), time: time, phase: phase)
        case .hilltop: hilltop(&context, size, time: time, phase: phase)
        case .lanternString: lanterns(&context, size, time: time, phase: phase)
        case .gate: gate(&context, size, time: time, phase: phase)
        case .bench: bench(&context, size)
        }
    }

    // MARK: Ground

    private static func stone(_ c: inout GraphicsContext, _ s: CGSize, top: Color, side: Color, variant: Int) {
        let w = s.width, h = s.height
        let squash = 0.86 + 0.07 * Double(variant % 3)
        let body = CGRect(x: w * 0.06, y: h * 0.16, width: w * 0.88 * squash, height: h * 0.74)
        c.fill(Path(ellipseIn: body.offsetBy(dx: 0, dy: 1.4)), with: .color(side))
        c.fill(Path(ellipseIn: body), with: .linearGradient(
            Gradient(colors: [top.opacity(1), top.opacity(0.82)]),
            startPoint: CGPoint(x: body.midX, y: body.minY), endPoint: CGPoint(x: body.midX, y: body.maxY)
        ))
        c.fill(Path(ellipseIn: CGRect(x: body.minX + body.width * 0.18, y: body.minY + 1, width: body.width * 0.4, height: body.height * 0.28)), with: .color(.white.opacity(0.35)))
    }

    private static func steppingStone(_ c: inout GraphicsContext, _ s: CGSize, variant: Int) {
        let w = s.width, h = s.height
        let body = CGRect(x: 0.5, y: 0.5, width: w - 1, height: h - 1.5)
        c.fill(Path(ellipseIn: body.offsetBy(dx: 0, dy: 1.2)), with: .color(rgb(0.36, 0.34, 0.30)))
        c.fill(Path(ellipseIn: body), with: .color(rgb(0.66, 0.65, 0.60)))
        c.fill(Path(ellipseIn: CGRect(x: w * (variant % 2 == 0 ? 0.1 : 0.45), y: h * 0.2, width: w * 0.42, height: h * 0.36)), with: .color(rgb(0.42, 0.60, 0.32, 0.9)))
        c.fill(Path(ellipseIn: CGRect(x: w * 0.3, y: h * 0.1, width: w * 0.3, height: h * 0.2)), with: .color(.white.opacity(0.3)))
    }

    // MARK: Pond

    private static func lilyPad(_ c: inout GraphicsContext, _ s: CGSize, variant: Int) {
        let w = s.width, h = s.height
        let pad = CGRect(x: 1, y: 1, width: w - 2, height: h - 2)
        var notch = Path()
        notch.move(to: CGPoint(x: pad.midX, y: pad.midY))
        notch.addLine(to: CGPoint(x: pad.maxX + 1, y: pad.midY - 2))
        notch.addLine(to: CGPoint(x: pad.maxX + 1, y: pad.midY + 2))
        notch.closeSubpath()
        c.fill(Path(ellipseIn: pad), with: .color(rgb(0.34, 0.64, 0.36)))
        c.fill(Path(ellipseIn: pad.insetBy(dx: 2.5, dy: 1.4)), with: .color(rgb(0.46, 0.74, 0.42)))
        c.blendMode = .destinationOut
        c.fill(notch, with: .color(.black))
        c.blendMode = .normal
        if variant == 0 {
            for k in 0..<5 {
                let a = Double(k) / 5 * 2 * .pi
                let petal = CGRect(x: pad.midX - 1.6 + 2.6 * cos(a), y: pad.midY - 2.4 + 1.5 * sin(a), width: 3.2, height: 3.2)
                c.fill(Path(ellipseIn: petal), with: .color(rgb(0.98, 0.72, 0.80)))
            }
            c.fill(Path(ellipseIn: CGRect(x: pad.midX - 1.2, y: pad.midY - 2, width: 2.4, height: 2.4)), with: .color(rgb(0.99, 0.86, 0.40)))
        }
    }

    private static func reeds(_ c: inout GraphicsContext, _ s: CGSize, time: Double, phase: Double) {
        let w = s.width, h = s.height
        for i in 0..<4 {
            let f = Double(i) / 3
            let x = w * (0.18 + 0.64 * f)
            let height = h * (0.62 + 0.38 * (1 - abs(f - 0.45) * 1.4))
            let lean = (f - 0.5) * 4 + 2.2 * sin(time * 1.3 + phase + f * 2)
            var stalk = Path()
            stalk.move(to: CGPoint(x: x, y: h))
            stalk.addQuadCurve(to: CGPoint(x: x + lean, y: h - height), control: CGPoint(x: x, y: h - height * 0.5))
            c.stroke(stalk, with: .color(rgb(0.36, 0.56, 0.28)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            if i % 2 == 0 {
                c.fill(Path(roundedRect: CGRect(x: x + lean - 1.7, y: h - height - 2, width: 3.4, height: 8), cornerRadius: 1.7), with: .color(rgb(0.50, 0.32, 0.20)))
            }
        }
    }

    private static func dragonfly(_ c: inout GraphicsContext, _ s: CGSize, time: Double) {
        let w = s.width, h = s.height
        let beat = time > 0 ? 0.5 + 0.5 * sin(time * 40) : 0.7
        let wing = rgb(0.85, 0.95, 1, 0.75)
        for side in [-1.0, 1.0] {
            c.fill(Path(ellipseIn: CGRect(x: w / 2 - (side < 0 ? 8 : 0) , y: h * 0.18 - beat * 1.5, width: 8, height: 2.6 + beat)), with: .color(wing))
        }
        c.fill(Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.45, width: w * 0.4, height: 2), cornerRadius: 1), with: .color(rgb(0.25, 0.62, 0.78)))
        c.fill(Path(ellipseIn: CGRect(x: w * 0.64, y: h * 0.38, width: 3.4, height: 3.4)), with: .color(rgb(0.20, 0.50, 0.66)))
    }

    // MARK: The tea corner and the harbor side

    private static func steam(_ c: inout GraphicsContext, _ s: CGSize, time: Double) {
        let w = s.width, h = s.height
        for k in 0..<3 {
            let base = Double(k) / 3
            let t = (time * 0.22 + base).truncatingRemainder(dividingBy: 1)
            let x = w / 2 + 4.5 * sin(t * 6 + Double(k) * 2)
            let y = h - 4 - t * (h - 8)
            let r = 3.0 + 4.0 * t
            let alpha = 0.55 * sin(.pi * min(max(t, 0), 1))
            c.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(rgb(1, 1, 1, alpha + 0.12)))
        }
    }

    private static func flagPole(_ c: inout GraphicsContext, _ s: CGSize, time: Double, phase: Double) {
        let h = s.height
        let x = 8.0
        c.fill(Path(ellipseIn: CGRect(x: x - 5, y: h - 3, width: 10, height: 3)), with: .color(.black.opacity(0.18)))
        c.fill(Path(roundedRect: CGRect(x: x - 1.4, y: 4, width: 2.8, height: h - 5), cornerRadius: 1.2), with: .color(rgb(0.72, 0.52, 0.32)))
        c.fill(Path(ellipseIn: CGRect(x: x - 2.4, y: 1.5, width: 4.8, height: 4.8)), with: .color(rgb(0.96, 0.80, 0.36)))
        let wave = 2.6 * sin(time * 3.2 + phase)
        for (i, colour) in [rgb(0.85, 0.32, 0.30), rgb(0.97, 0.94, 0.88), rgb(0.26, 0.52, 0.74)].enumerated() {
            let y = 7.0 + Double(i) * 5.2
            var band = Path()
            band.move(to: CGPoint(x: x + 1, y: y))
            band.addQuadCurve(to: CGPoint(x: x + 24, y: y + 1 + wave), control: CGPoint(x: x + 12, y: y - 2 - wave))
            band.addLine(to: CGPoint(x: x + 24, y: y + 6 + wave))
            band.addQuadCurve(to: CGPoint(x: x + 1, y: y + 5.2), control: CGPoint(x: x + 12, y: y + 3 - wave))
            band.closeSubpath()
            c.fill(band, with: .color(colour))
        }
    }

    private static func gull(_ c: inout GraphicsContext, _ s: CGSize, time: Double, phase: Double) {
        let w = s.width, h = s.height
        let flap = 0.5 + 0.5 * sin(time * 3.1 + phase)
        let lift = h * (0.15 + 0.45 * flap)
        var wings = Path()
        wings.move(to: CGPoint(x: 1, y: h * 0.5 - lift * 0.4))
        wings.addQuadCurve(to: CGPoint(x: w / 2, y: h * 0.62), control: CGPoint(x: w * 0.25, y: h * 0.1 - lift * 0.3))
        wings.addQuadCurve(to: CGPoint(x: w - 1, y: h * 0.5 - lift * 0.4), control: CGPoint(x: w * 0.75, y: h * 0.1 - lift * 0.3))
        c.stroke(wings, with: .color(rgb(0.97, 0.97, 0.95)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
        c.fill(Path(ellipseIn: CGRect(x: w / 2 - 2.5, y: h * 0.5, width: 5, height: 3.4)), with: .color(rgb(0.97, 0.97, 0.95)))
    }

    private static func bridge(_ c: inout GraphicsContext, _ s: CGSize) {
        func point(_ t: Double) -> CGPoint {
            let p0 = CGPoint(x: 4, y: 12), cp = CGPoint(x: 46, y: 36), p1 = CGPoint(x: 96, y: 28)
            let u = 1 - t
            return CGPoint(x: u * u * p0.x + 2 * u * t * cp.x + t * t * p1.x, y: u * u * p0.y + 2 * u * t * cp.y + t * t * p1.y)
        }
        let rope = rgb(0.80, 0.68, 0.46), plank = rgb(0.66, 0.46, 0.28), dark = rgb(0.46, 0.31, 0.19)
        var deck = Path(), hand = Path()
        for i in 0...16 {
            let p = point(Double(i) / 16)
            if i == 0 { deck.move(to: p); hand.move(to: CGPoint(x: p.x, y: p.y - 11)) } else { deck.addLine(to: p); hand.addLine(to: CGPoint(x: p.x, y: p.y - 11)) }
        }
        c.stroke(deck, with: .color(dark), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        for i in 0...16 {
            let p = point(Double(i) / 16)
            c.fill(Path(roundedRect: CGRect(x: p.x - 2.6, y: p.y - 3, width: 5.2, height: 5), cornerRadius: 1), with: .color(i % 2 == 0 ? plank : plank.opacity(0.85)))
        }
        c.stroke(hand, with: .color(rope), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        for i in stride(from: 0, through: 16, by: 4) {
            let p = point(Double(i) / 16)
            var rail = Path()
            rail.move(to: CGPoint(x: p.x, y: p.y - 1))
            rail.addLine(to: CGPoint(x: p.x, y: p.y - 11))
            c.stroke(rail, with: .color(rope), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        }
        for p in [point(0), point(1)] {
            c.fill(Path(roundedRect: CGRect(x: p.x - 2.6, y: p.y - 16, width: 5.2, height: 20), cornerRadius: 2), with: .color(plank))
        }
    }

    // MARK: Terraces

    private static func mound(_ c: inout GraphicsContext, _ s: CGSize, grass: Color, lip: Color, face: Color, time: Double, phase: Double) {
        let w = s.width, h = s.height
        let rx = w / 2 - 1, topRy = h * 0.34, topY = h * 0.42, baseRy = 8.0
        let baseY = h - baseRy - 1
        // The face: a wall of earth and stone under the grass lip.
        var wall = Path()
        wall.move(to: CGPoint(x: w / 2 - rx, y: topY))
        wall.addLine(to: CGPoint(x: w / 2 - rx, y: baseY))
        wall.addEllipse(in: CGRect(x: w / 2 - rx, y: baseY - baseRy, width: rx * 2, height: baseRy * 2))
        wall.addRect(CGRect(x: w / 2 - rx, y: topY, width: rx * 2, height: baseY - topY))
        c.fill(wall, with: .linearGradient(
            Gradient(colors: [face.opacity(1), face.opacity(0.72)]),
            startPoint: CGPoint(x: w / 2, y: topY), endPoint: CGPoint(x: w / 2, y: h)
        ))
        for k in 0..<9 {
            let f = (Double(k) + 0.5) / 9
            let x = w / 2 - rx * 0.86 + rx * 1.72 * f
            let y = topY + (baseY - topY) * (0.38 + 0.3 * Double((k * 5) % 3) / 2)
            c.fill(Path(ellipseIn: CGRect(x: x - 5, y: y - 2.2, width: 10, height: 4.4)), with: .color(.white.opacity(0.22)))
        }
        c.fill(Path(ellipseIn: CGRect(x: w / 2 - rx, y: topY - topRy, width: rx * 2, height: topRy * 2)), with: .color(lip.opacity(1)))
        c.fill(Path(ellipseIn: CGRect(x: w / 2 - rx + 3, y: topY - topRy + 1, width: (rx - 3) * 2, height: topRy * 2 - 3.5)), with: .linearGradient(
            Gradient(colors: [grass.opacity(1), lip.opacity(1)]),
            startPoint: CGPoint(x: w / 2, y: topY - topRy), endPoint: CGPoint(x: w / 2, y: topY + topRy)
        ))
        // Grass and little flowers swaying along the top.
        for k in 0..<11 {
            let f = (Double(k) + 0.5) / 11
            let x = w / 2 - rx * 0.8 + rx * 1.6 * f
            let y = topY + topRy * 0.35 * sin(Double(k) * 1.7)
            let sway = 1.6 * sin(time * 1.5 + phase + Double(k))
            var blade = Path()
            blade.move(to: CGPoint(x: x, y: y))
            blade.addQuadCurve(to: CGPoint(x: x + sway, y: y - 6), control: CGPoint(x: x, y: y - 3))
            c.stroke(blade, with: .color(grass), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            if k % 3 == 1 {
                let blooms = [rgb(0.98, 0.84, 0.36), rgb(0.97, 0.66, 0.74), rgb(0.97, 0.97, 0.92)]
                c.fill(Path(ellipseIn: CGRect(x: x + sway - 1.8, y: y - 8, width: 3.6, height: 3.6)), with: .color(blooms[k % 3]))
            }
        }
    }

    private static func hilltop(_ c: inout GraphicsContext, _ s: CGSize, time: Double, phase: Double) {
        mound(&c, s, grass: rgb(0.52, 0.68, 0.38), lip: rgb(0.58, 0.72, 0.40), face: rgb(0.62, 0.50, 0.38), time: time, phase: phase)
        // A little round tree at the right of the top.
        let tx = s.width * 0.80, ty = s.height * 0.46
        c.fill(Path(roundedRect: CGRect(x: tx - 1.6, y: ty - 10, width: 3.2, height: 12), cornerRadius: 1.4), with: .color(rgb(0.50, 0.34, 0.22)))
        let rustle = 1.4 * sin(time * 1.2 + phase)
        c.fill(Path(ellipseIn: CGRect(x: tx - 10 + rustle, y: ty - 26, width: 20, height: 18)), with: .color(rgb(0.36, 0.58, 0.30)))
        c.fill(Path(ellipseIn: CGRect(x: tx - 6 + rustle, y: ty - 25, width: 11, height: 9)), with: .color(rgb(0.52, 0.74, 0.40)))
    }

    private static func bench(_ c: inout GraphicsContext, _ s: CGSize) {
        let w = s.width, h = s.height
        c.fill(Path(roundedRect: CGRect(x: 1, y: h * 0.25, width: w - 2, height: 3), cornerRadius: 1), with: .color(rgb(0.66, 0.46, 0.28)))
        c.fill(Path(roundedRect: CGRect(x: 1, y: h * 0.55, width: w - 2, height: 3.5), cornerRadius: 1), with: .color(rgb(0.72, 0.52, 0.32)))
        for x in [3.0, w - 5] {
            c.fill(Path(CGRect(x: x, y: h * 0.55, width: 2, height: h * 0.45)), with: .color(rgb(0.46, 0.31, 0.19)))
        }
    }

    private static func lanterns(_ c: inout GraphicsContext, _ s: CGSize, time: Double, phase: Double) {
        let w = s.width, h = s.height
        let left = CGPoint(x: 6, y: 6), right = CGPoint(x: w - 6, y: 6)
        let wood = rgb(0.58, 0.40, 0.24)
        for x in [left.x, right.x] {
            c.fill(Path(roundedRect: CGRect(x: x - 2, y: 4, width: 4, height: h - 4), cornerRadius: 1.6), with: .color(wood))
        }
        func rope(_ f: Double) -> CGPoint {
            CGPoint(x: left.x + (right.x - left.x) * f, y: 6 + 4 * sin(.pi * f) * 6)
        }
        var cord = Path()
        cord.move(to: left)
        for i in 1...24 { cord.addLine(to: rope(Double(i) / 24)) }
        c.stroke(cord, with: .color(rgb(0.42, 0.30, 0.20)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
        let tints: [Color] = [rgb(0.98, 0.66, 0.34), rgb(0.98, 0.82, 0.42), rgb(0.96, 0.54, 0.38)]
        for i in 1...7 {
            let f = Double(i) / 8
            let p = rope(f)
            let sway = time > 0 ? 1.8 * sin(time * 1.1 + phase + f * 5) : 0
            let drop = 7.0
            let centre = CGPoint(x: p.x + sway, y: p.y + drop + 5)
            let tint = tints[i % 3]
            c.fill(Path(ellipseIn: CGRect(x: centre.x - 13, y: centre.y - 13, width: 26, height: 26)), with: .radialGradient(
                Gradient(colors: [tint.opacity(0.42), tint.opacity(0)]), center: centre, startRadius: 0, endRadius: 13
            ))
            var thread = Path()
            thread.move(to: p)
            thread.addLine(to: CGPoint(x: centre.x, y: centre.y - 5))
            c.stroke(thread, with: .color(rgb(0.42, 0.30, 0.20)), style: StrokeStyle(lineWidth: 0.9))
            c.fill(Path(roundedRect: CGRect(x: centre.x - 4.4, y: centre.y - 5, width: 8.8, height: 11), cornerRadius: 4), with: .color(tint))
            c.fill(Path(roundedRect: CGRect(x: centre.x - 2.4, y: centre.y - 3.6, width: 3, height: 6), cornerRadius: 1.5), with: .color(.white.opacity(0.5)))
            c.fill(Path(CGRect(x: centre.x - 3, y: centre.y - 6.2, width: 6, height: 1.8)), with: .color(wood))
            c.fill(Path(CGRect(x: centre.x - 3, y: centre.y + 5.6, width: 6, height: 1.6)), with: .color(wood))
        }
    }

    // MARK: The gate

    private static func gate(_ c: inout GraphicsContext, _ s: CGSize, time: Double, phase: Double) {
        let w = s.width, h = s.height
        let pulse = 0.82 + 0.18 * sin(time * 1.4 + phase)
        let centre = CGPoint(x: w / 2, y: h - 26)
        // The soft glow behind the gate.
        c.fill(Path(ellipseIn: CGRect(x: centre.x - 40, y: centre.y - 40, width: 80, height: 80)), with: .radialGradient(
            Gradient(colors: [rgb(1, 0.88, 0.50, 0.55 * pulse), rgb(1, 0.86, 0.46, 0)]), center: centre, startRadius: 2, endRadius: 40
        ))
        let stone = rgb(0.70, 0.66, 0.58), stoneDark = rgb(0.48, 0.44, 0.38)
        let gw = 30.0, gh = 36.0
        let x0 = w / 2 - gw / 2, y1 = h - 3
        // The door's wood inside the arch.
        var door = Path()
        door.move(to: CGPoint(x: x0 + 4, y: y1))
        door.addLine(to: CGPoint(x: x0 + 4, y: y1 - gh + 12))
        door.addArc(center: CGPoint(x: w / 2, y: y1 - gh + 12), radius: gw / 2 - 4, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        door.addLine(to: CGPoint(x: x0 + gw - 4, y: y1))
        door.closeSubpath()
        c.fill(door, with: .color(rgb(0.56, 0.38, 0.22)))
        // The arch and its two pillars.
        var arch = Path()
        arch.move(to: CGPoint(x: x0, y: y1))
        arch.addLine(to: CGPoint(x: x0, y: y1 - gh + 15))
        arch.addArc(center: CGPoint(x: w / 2, y: y1 - gh + 15), radius: gw / 2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        arch.addLine(to: CGPoint(x: x0 + gw, y: y1))
        c.stroke(arch, with: .color(stoneDark), style: StrokeStyle(lineWidth: 6.4, lineCap: .butt, lineJoin: .round))
        c.stroke(arch, with: .color(stone), style: StrokeStyle(lineWidth: 4.6, lineCap: .butt, lineJoin: .round))
        // The sunflower carved in the door.
        let sun = CGPoint(x: w / 2, y: y1 - gh * 0.46)
        for k in 0..<10 {
            let a = Double(k) / 10 * 2 * .pi
            let petal = CGRect(x: sun.x + 5.4 * cos(a) - 1.8, y: sun.y + 5.4 * sin(a) - 1.8, width: 3.6, height: 3.6)
            c.fill(Path(ellipseIn: petal), with: .color(rgb(0.99, 0.84, 0.36, pulse)))
        }
        c.fill(Path(ellipseIn: CGRect(x: sun.x - 3.4, y: sun.y - 3.4, width: 6.8, height: 6.8)), with: .color(rgb(0.52, 0.34, 0.18)))
        // The glow leaking out round the door's foot.
        c.fill(Path(ellipseIn: CGRect(x: w / 2 - 15, y: y1 - 2, width: 30, height: 5)), with: .color(rgb(1, 0.9, 0.55, 0.45 * pulse)))
    }
}
#endif
